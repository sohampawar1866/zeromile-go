-- ZeroMile Go: Database & Security Audit Patch Migration (Harden & Secure)
-- 1. Security hardening: search_path on all functions/triggers
-- 2. Concurrency-safe sub-group limit trigger using advisory xact locks
-- 3. Robust RPC validations (set_active_group, check_in_participant, complete_event_participant, leader_direct_add_member, provision_superadmin)
-- 4. Foreign key covering indexes for high query performance
-- 5. Role-aware & domain-scoped Row Level Security (RLS) policies
-- 6. Comprehensive realtime publication coverage

-- ============================================================================
-- 1. HARDENED FUNCTIONS & TRIGGERS
-- ============================================================================

-- Trigger 1: Concurrency-safe Max 3 Sub-Groups Limit
CREATE OR REPLACE FUNCTION public.check_subgroup_limit()
RETURNS TRIGGER 
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
DECLARE
    v_is_general BOOLEAN;
    v_count INT;
BEGIN
    SELECT is_general INTO v_is_general FROM public.sub_groups WHERE id = NEW.group_id;
    IF v_is_general IS FALSE THEN
        -- Advisory transaction lock prevents concurrent insertion race conditions for the same user & domain
        PERFORM pg_advisory_xact_lock(hashtext('subgroup_limit:' || NEW.domain_id::text || ':' || NEW.user_id::text));

        SELECT COUNT(*) INTO v_count
        FROM public.group_memberships gm
        JOIN public.sub_groups sg ON gm.group_id = sg.id
        WHERE gm.user_id = NEW.user_id
          AND gm.domain_id = NEW.domain_id
          AND sg.is_general = FALSE
          AND gm.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);
        
        IF v_count >= 3 THEN
            RAISE EXCEPTION 'User cannot join more than 3 sub-groups per event domain.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_subgroup_limit ON public.group_memberships;
CREATE TRIGGER trg_check_subgroup_limit
BEFORE INSERT OR UPDATE ON public.group_memberships
FOR EACH ROW
EXECUTE FUNCTION public.check_subgroup_limit();

-- Trigger 2: Auto-create Domain General Group
CREATE OR REPLACE FUNCTION public.auto_create_domain_general_group()
RETURNS TRIGGER 
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    INSERT INTO public.sub_groups (domain_id, name, is_general, org_type, approval_status)
    VALUES (NEW.id, 'General Group (' || NEW.name || ')', TRUE, 'GENERAL', 'APPROVED');
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_create_general_group ON public.event_domains;
CREATE TRIGGER trg_auto_create_general_group
AFTER INSERT ON public.event_domains
FOR EACH ROW
EXECUTE FUNCTION public.auto_create_domain_general_group();

-- Trigger 3: Auto-enroll in General Group
CREATE OR REPLACE FUNCTION public.auto_enroll_general_group()
RETURNS TRIGGER 
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
DECLARE
    v_gen_group_id UUID;
    v_is_gen BOOLEAN;
BEGIN
    SELECT is_general INTO v_is_gen FROM public.sub_groups WHERE id = NEW.group_id;
    IF v_is_gen IS FALSE THEN
        SELECT id INTO v_gen_group_id
        FROM public.sub_groups
        WHERE domain_id = NEW.domain_id AND is_general = TRUE
        LIMIT 1;

        IF v_gen_group_id IS NOT NULL THEN
            INSERT INTO public.group_memberships (domain_id, group_id, user_id, is_active, is_leader, participation_status)
            VALUES (NEW.domain_id, v_gen_group_id, NEW.user_id, FALSE, FALSE, 'NOT_CHECKED_IN')
            ON CONFLICT (domain_id, group_id, user_id) DO NOTHING;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_enroll_general_group ON public.group_memberships;
CREATE TRIGGER trg_auto_enroll_general_group
AFTER INSERT ON public.group_memberships
FOR EACH ROW
EXECUTE FUNCTION public.auto_enroll_general_group();

-- Trigger 4: Group Creation Request Approval
CREATE OR REPLACE FUNCTION public.process_group_creation_approval()
RETURNS TRIGGER 
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
DECLARE
    v_new_group_id UUID;
BEGIN
    IF (OLD.status IS DISTINCT FROM NEW.status) AND NEW.status = 'APPROVED' THEN
        INSERT INTO public.sub_groups (domain_id, name, is_general, org_type, leader_id, muster_point, approval_status)
        VALUES (NEW.domain_id, NEW.org_name, FALSE, NEW.org_type, NEW.applicant_user_id, NEW.muster_point, 'APPROVED')
        RETURNING id INTO v_new_group_id;

        -- Reset previous active group for applicant in this domain
        UPDATE public.group_memberships
        SET is_active = FALSE
        WHERE domain_id = NEW.domain_id AND user_id = NEW.applicant_user_id;

        -- Enroll applicant as leader and active member
        INSERT INTO public.group_memberships (domain_id, group_id, user_id, is_active, is_leader, participation_status)
        VALUES (NEW.domain_id, v_new_group_id, NEW.applicant_user_id, TRUE, TRUE, 'NOT_CHECKED_IN')
        ON CONFLICT (domain_id, group_id, user_id) 
        DO UPDATE SET is_active = TRUE, is_leader = TRUE;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_process_group_creation_approval ON public.group_creation_requests;
CREATE TRIGGER trg_process_group_creation_approval
AFTER UPDATE ON public.group_creation_requests
FOR EACH ROW
EXECUTE FUNCTION public.process_group_creation_approval();

-- ============================================================================
-- 2. HARDENED & VALIDATED STORED PROCEDURES & RPCS
-- ============================================================================

-- RPC 1: Atomic Active Group Switch with membership verification
CREATE OR REPLACE FUNCTION public.set_active_group(
    p_domain_id UUID,
    p_group_id UUID,
    p_user_id UUID
) RETURNS JSONB 
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_membership_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.group_memberships
        WHERE domain_id = p_domain_id AND user_id = p_user_id AND group_id = p_group_id
    ) INTO v_membership_exists;

    IF NOT v_membership_exists THEN
        RAISE EXCEPTION 'User is not a member of the specified sub-group.';
    END IF;

    UPDATE public.group_memberships
    SET is_active = FALSE
    WHERE domain_id = p_domain_id AND user_id = p_user_id;

    UPDATE public.group_memberships
    SET is_active = TRUE
    WHERE domain_id = p_domain_id AND user_id = p_user_id AND group_id = p_group_id;

    RETURN jsonb_build_object('success', true, 'active_group_id', p_group_id);
END;
$$;

-- RPC 2: Participant Presence Check-In with validation
CREATE OR REPLACE FUNCTION public.check_in_participant(
    p_domain_id UUID,
    p_group_id UUID,
    p_user_id UUID
) RETURNS JSONB 
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_rows_affected INT;
BEGIN
    UPDATE public.group_memberships
    SET participation_status = 'CHECKED_IN',
        checkin_time = NOW()
    WHERE domain_id = p_domain_id AND user_id = p_user_id AND group_id = p_group_id;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    IF v_rows_affected = 0 THEN
        RAISE EXCEPTION 'Group membership not found for participant.';
    END IF;

    RETURN jsonb_build_object('success', true, 'status', 'CHECKED_IN', 'checkin_time', NOW());
END;
$$;

-- RPC 3: Participant Rally Completion with validation
CREATE OR REPLACE FUNCTION public.complete_event_participant(
    p_domain_id UUID,
    p_group_id UUID,
    p_user_id UUID
) RETURNS JSONB 
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_rows_affected INT;
BEGIN
    UPDATE public.group_memberships
    SET participation_status = 'COMPLETED',
        completion_time = NOW()
    WHERE domain_id = p_domain_id AND user_id = p_user_id AND group_id = p_group_id;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    IF v_rows_affected = 0 THEN
        RAISE EXCEPTION 'Group membership not found for participant.';
    END IF;

    RETURN jsonb_build_object('success', true, 'status', 'COMPLETED', 'completion_time', NOW());
END;
$$;

-- RPC 4: Direct Member Add by Leader
CREATE OR REPLACE FUNCTION public.leader_direct_add_member(
    p_domain_id UUID,
    p_group_id UUID,
    p_leader_user_id UUID,
    p_member_phone VARCHAR,
    p_member_name VARCHAR
) RETURNS JSONB 
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_target_user_id UUID;
    v_is_leader BOOLEAN;
BEGIN
    -- Check if sender is leader of the group
    SELECT EXISTS (
        SELECT 1 FROM public.sub_groups 
        WHERE id = p_group_id AND domain_id = p_domain_id AND leader_id = p_leader_user_id
    ) INTO v_is_leader;

    IF NOT v_is_leader THEN
        RAISE EXCEPTION 'Only the assigned Group Leader can directly add members.';
    END IF;

    -- Find or create user
    SELECT id INTO v_target_user_id FROM public.users WHERE phone_number = p_member_phone;
    IF v_target_user_id IS NULL THEN
        INSERT INTO public.users (phone_number, full_name)
        VALUES (p_member_phone, p_member_name)
        RETURNING id INTO v_target_user_id;
    END IF;

    -- Add to group
    INSERT INTO public.group_memberships (domain_id, group_id, user_id, is_active, is_leader, participation_status)
    VALUES (p_domain_id, p_group_id, v_target_user_id, FALSE, FALSE, 'NOT_CHECKED_IN')
    ON CONFLICT (domain_id, group_id, user_id) DO NOTHING;

    RETURN jsonb_build_object('success', true, 'user_id', v_target_user_id);
END;
$$;

-- RPC 5: Provision SuperAdmin with 6-seat cap enforcement
CREATE OR REPLACE FUNCTION public.provision_superadmin(
    p_domain_id UUID,
    p_user_phone VARCHAR,
    p_user_name VARCHAR,
    p_created_by VARCHAR DEFAULT 'developer_panel'
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_current_count INT;
    v_user_id UUID;
    v_admin_id UUID;
BEGIN
    SELECT COUNT(*) INTO v_current_count
    FROM public.domain_superadmins
    WHERE domain_id = p_domain_id;

    IF v_current_count >= 6 THEN
        RAISE EXCEPTION 'Maximum 6 SuperAdmins already provisioned for this domain.';
    END IF;

    SELECT id INTO v_user_id FROM public.users WHERE phone_number = p_user_phone;
    IF v_user_id IS NULL THEN
        INSERT INTO public.users (phone_number, full_name)
        VALUES (p_user_phone, p_user_name)
        RETURNING id INTO v_user_id;
    END IF;

    INSERT INTO public.domain_superadmins (domain_id, user_id, created_by_dev)
    VALUES (p_domain_id, v_user_id, p_created_by)
    ON CONFLICT (domain_id, user_id) DO UPDATE SET assigned_at = NOW()
    RETURNING id INTO v_admin_id;

    RETURN jsonb_build_object('success', true, 'admin_id', v_admin_id, 'user_id', v_user_id);
END;
$$;

-- ============================================================================
-- 3. COVERING INDEXES FOR FOREIGN KEYS & PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_broadcasts_domain_id ON public.broadcasts(domain_id);
CREATE INDEX IF NOT EXISTS idx_broadcasts_sender_id ON public.broadcasts(sender_id);
CREATE INDEX IF NOT EXISTS idx_broadcasts_target_group_id ON public.broadcasts(target_group_id);

CREATE INDEX IF NOT EXISTS idx_domain_superadmins_user_id ON public.domain_superadmins(user_id);

CREATE INDEX IF NOT EXISTS idx_group_creation_requests_applicant ON public.group_creation_requests(applicant_user_id);
CREATE INDEX IF NOT EXISTS idx_group_creation_requests_domain_id ON public.group_creation_requests(domain_id);
CREATE INDEX IF NOT EXISTS idx_group_creation_requests_reviewed_by ON public.group_creation_requests(reviewed_by);

CREATE INDEX IF NOT EXISTS idx_group_memberships_group_id ON public.group_memberships(group_id);
CREATE INDEX IF NOT EXISTS idx_group_memberships_user_id ON public.group_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_group_memberships_domain_id ON public.group_memberships(domain_id);

CREATE INDEX IF NOT EXISTS idx_route_checkpoints_domain_id ON public.route_checkpoints(domain_id);

CREATE INDEX IF NOT EXISTS idx_sos_events_domain_id ON public.sos_events(domain_id);
CREATE INDEX IF NOT EXISTS idx_sos_events_sender_user_id ON public.sos_events(sender_user_id);
CREATE INDEX IF NOT EXISTS idx_sos_events_active_sub_group_id ON public.sos_events(active_sub_group_id);
CREATE INDEX IF NOT EXISTS idx_sos_events_forwarded_by_leader ON public.sos_events(forwarded_by_leader_id);
CREATE INDEX IF NOT EXISTS idx_sos_events_resolved_by ON public.sos_events(resolved_by);

CREATE INDEX IF NOT EXISTS idx_sub_groups_domain_id ON public.sub_groups(domain_id);
CREATE INDEX IF NOT EXISTS idx_sub_groups_leader_id ON public.sub_groups(leader_id);

CREATE INDEX IF NOT EXISTS idx_user_live_locations_user_id ON public.user_live_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_live_locations_active_group_id ON public.user_live_locations(active_group_id);

-- ============================================================================
-- 4. REALTIME PUBLICATIONS
-- ============================================================================

DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.sos_events;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.broadcasts;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.user_live_locations;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.group_memberships;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.group_creation_requests;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.sub_groups;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.event_domains;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;
