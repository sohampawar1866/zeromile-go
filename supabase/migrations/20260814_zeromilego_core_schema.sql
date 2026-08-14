-- ZeroMile Go: Multi-Rally & Event Management Platform
-- Core Schema Migration: 10 Tables, Triggers, Constraints, RPCs, RLS, Realtime

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. CORE TABLES

-- Table 1: event_domains
CREATE TABLE IF NOT EXISTS public.event_domains (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'CYCLING', 'MARATHON', 'PROTEST', 'WALKATHON'
    status VARCHAR(20) NOT NULL DEFAULT 'UPCOMING', -- 'UPCOMING', 'LIVE_ACTIVE', 'CONCLUDED', 'ARCHIVED'
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    route_geojson JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table 2: users
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    emergency_contact VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table 3: domain_superadmins
CREATE TABLE IF NOT EXISTS public.domain_superadmins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_id UUID NOT NULL REFERENCES public.event_domains(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_by_dev VARCHAR(50) NOT NULL DEFAULT 'developer',
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_domain_superadmin UNIQUE (domain_id, user_id)
);

-- Table 4: sub_groups
CREATE TABLE IF NOT EXISTS public.sub_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_id UUID NOT NULL REFERENCES public.event_domains(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    is_general BOOLEAN NOT NULL DEFAULT FALSE,
    org_type VARCHAR(60) NOT NULL, -- 'GENERAL', 'COLLEGE', 'NGO', 'LABOR_UNION', 'CORPORATE', 'SPORTS_CLUB', 'RWA', 'GRASSROOTS'
    leader_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    muster_point TEXT,
    approval_status VARCHAR(20) NOT NULL DEFAULT 'APPROVED', -- 'PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table 5: group_memberships
CREATE TABLE IF NOT EXISTS public.group_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_id UUID NOT NULL REFERENCES public.event_domains(id) ON DELETE CASCADE,
    group_id UUID NOT NULL REFERENCES public.sub_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    is_leader BOOLEAN NOT NULL DEFAULT FALSE,
    participation_status VARCHAR(20) NOT NULL DEFAULT 'NOT_CHECKED_IN', -- 'NOT_CHECKED_IN', 'CHECKED_IN', 'IN_TRANSIT', 'COMPLETED', 'DROPPED_OUT'
    checkin_time TIMESTAMPTZ,
    completion_time TIMESTAMPTZ,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_group_membership UNIQUE (domain_id, group_id, user_id)
);

-- Partial Unique Index: Exactly 1 Active Group per User per Domain
CREATE UNIQUE INDEX IF NOT EXISTS unique_active_group_per_user_domain 
ON public.group_memberships (user_id, domain_id) 
WHERE is_active = TRUE;

-- Table 6: group_creation_requests
CREATE TABLE IF NOT EXISTS public.group_creation_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_id UUID NOT NULL REFERENCES public.event_domains(id) ON DELETE CASCADE,
    applicant_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    org_name VARCHAR(120) NOT NULL,
    org_type VARCHAR(60) NOT NULL,
    expected_count INT NOT NULL DEFAULT 20,
    muster_point TEXT NOT NULL,
    leader_notes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'REJECTED'
    reviewed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table 7: broadcasts
CREATE TABLE IF NOT EXISTS public.broadcasts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_id UUID NOT NULL REFERENCES public.event_domains(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    sender_role VARCHAR(20) NOT NULL, -- 'SUPERADMIN', 'GROUP_LEADER'
    target_type VARCHAR(20) NOT NULL, -- 'GENERAL', 'SPECIFIC_GROUP'
    target_group_id UUID REFERENCES public.sub_groups(id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table 8: sos_events
CREATE TABLE IF NOT EXISTS public.sos_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_id UUID NOT NULL REFERENCES public.event_domains(id) ON DELETE CASCADE,
    sender_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    active_sub_group_id UUID REFERENCES public.sub_groups(id) ON DELETE SET NULL,
    emergency_type VARCHAR(30) NOT NULL, -- 'MEDICAL', 'BREAKDOWN', 'THREAT', 'LOST', 'OTHER'
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'TRIGGERED', -- 'TRIGGERED', 'FORWARDED_TO_ADMIN', 'RESOLVED'
    forwarded_by_leader_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    leader_notes TEXT,
    resolved_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table 9: user_live_locations
CREATE TABLE IF NOT EXISTS public.user_live_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_id UUID NOT NULL REFERENCES public.event_domains(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    active_group_id UUID REFERENCES public.sub_groups(id) ON DELETE SET NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    speed_kmh REAL NOT NULL DEFAULT 0.0,
    heading REAL NOT NULL DEFAULT 0.0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_domain_live_location UNIQUE (domain_id, user_id)
);

-- Table 10: route_checkpoints
CREATE TABLE IF NOT EXISTS public.route_checkpoints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_id UUID NOT NULL REFERENCES public.event_domains(id) ON DELETE CASCADE,
    checkpoint_type VARCHAR(30) NOT NULL, -- 'START', 'WATER_STATION', 'MEDICAL_POST', 'DIVERSION', 'FINISH'
    name VARCHAR(100) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    sequence_order INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. FUNCTIONS & TRIGGERS

-- Trigger 1: Max 3 Sub-Groups Limit
CREATE OR REPLACE FUNCTION public.check_subgroup_limit()
RETURNS TRIGGER AS $$
DECLARE
    v_is_general BOOLEAN;
    v_count INT;
BEGIN
    SELECT is_general INTO v_is_general FROM public.sub_groups WHERE id = NEW.group_id;
    IF v_is_general IS FALSE THEN
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_subgroup_limit ON public.group_memberships;
CREATE TRIGGER trg_check_subgroup_limit
BEFORE INSERT OR UPDATE ON public.group_memberships
FOR EACH ROW
EXECUTE FUNCTION public.check_subgroup_limit();

-- Trigger 2: Auto-create Domain General Group
CREATE OR REPLACE FUNCTION public.auto_create_domain_general_group()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.sub_groups (domain_id, name, is_general, org_type, approval_status)
    VALUES (NEW.id, 'General Group (' || NEW.name || ')', TRUE, 'GENERAL', 'APPROVED');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auto_create_general_group ON public.event_domains;
CREATE TRIGGER trg_auto_create_general_group
AFTER INSERT ON public.event_domains
FOR EACH ROW
EXECUTE FUNCTION public.auto_create_domain_general_group();

-- Trigger 3: Auto-enroll in General Group
CREATE OR REPLACE FUNCTION public.auto_enroll_general_group()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auto_enroll_general_group ON public.group_memberships;
CREATE TRIGGER trg_auto_enroll_general_group
AFTER INSERT ON public.group_memberships
FOR EACH ROW
EXECUTE FUNCTION public.auto_enroll_general_group();

-- Trigger 4: Group Creation Request Approval
CREATE OR REPLACE FUNCTION public.process_group_creation_approval()
RETURNS TRIGGER AS $$
DECLARE
    v_new_group_id UUID;
BEGIN
    IF OLD.status = 'PENDING' AND NEW.status = 'APPROVED' THEN
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_process_group_creation_approval ON public.group_creation_requests;
CREATE TRIGGER trg_process_group_creation_approval
AFTER UPDATE ON public.group_creation_requests
FOR EACH ROW
EXECUTE FUNCTION public.process_group_creation_approval();

-- 4. STORED PROCEDURES & RPCS

-- RPC 1: Atomic Active Group Switch
CREATE OR REPLACE FUNCTION public.set_active_group(
    p_domain_id UUID,
    p_group_id UUID,
    p_user_id UUID
) RETURNS JSONB AS $$
BEGIN
    UPDATE public.group_memberships
    SET is_active = FALSE
    WHERE domain_id = p_domain_id AND user_id = p_user_id;

    UPDATE public.group_memberships
    SET is_active = TRUE
    WHERE domain_id = p_domain_id AND user_id = p_user_id AND group_id = p_group_id;

    RETURN jsonb_build_object('success', true, 'active_group_id', p_group_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC 2: Participant Presence Check-In
CREATE OR REPLACE FUNCTION public.check_in_participant(
    p_domain_id UUID,
    p_group_id UUID,
    p_user_id UUID
) RETURNS JSONB AS $$
BEGIN
    UPDATE public.group_memberships
    SET participation_status = 'CHECKED_IN',
        checkin_time = NOW()
    WHERE domain_id = p_domain_id AND user_id = p_user_id AND group_id = p_group_id;

    RETURN jsonb_build_object('success', true, 'status', 'CHECKED_IN', 'checkin_time', NOW());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC 3: Participant Rally Completion
CREATE OR REPLACE FUNCTION public.complete_event_participant(
    p_domain_id UUID,
    p_group_id UUID,
    p_user_id UUID
) RETURNS JSONB AS $$
BEGIN
    UPDATE public.group_memberships
    SET participation_status = 'COMPLETED',
        completion_time = NOW()
    WHERE domain_id = p_domain_id AND user_id = p_user_id AND group_id = p_group_id;

    RETURN jsonb_build_object('success', true, 'status', 'COMPLETED', 'completion_time', NOW());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC 4: Direct Phone Add Member (Used by Group Leaders)
CREATE OR REPLACE FUNCTION public.leader_direct_add_member(
    p_domain_id UUID,
    p_group_id UUID,
    p_leader_user_id UUID,
    p_member_phone VARCHAR,
    p_member_name VARCHAR
) RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. ROW LEVEL SECURITY (RLS) & POLICIES
ALTER TABLE public.event_domains ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.domain_superadmins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sub_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_creation_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broadcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sos_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_live_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_checkpoints ENABLE ROW LEVEL SECURITY;

-- Liberal Development & App Policies (Public read/write for seamless multi-role access)
CREATE POLICY "Allow all read on event_domains" ON public.event_domains FOR SELECT USING (true);
CREATE POLICY "Allow all write on event_domains" ON public.event_domains FOR ALL USING (true);

CREATE POLICY "Allow all read on users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Allow all write on users" ON public.users FOR ALL USING (true);

CREATE POLICY "Allow all read on domain_superadmins" ON public.domain_superadmins FOR SELECT USING (true);
CREATE POLICY "Allow all write on domain_superadmins" ON public.domain_superadmins FOR ALL USING (true);

CREATE POLICY "Allow all read on sub_groups" ON public.sub_groups FOR SELECT USING (true);
CREATE POLICY "Allow all write on sub_groups" ON public.sub_groups FOR ALL USING (true);

CREATE POLICY "Allow all read on group_memberships" ON public.group_memberships FOR SELECT USING (true);
CREATE POLICY "Allow all write on group_memberships" ON public.group_memberships FOR ALL USING (true);

CREATE POLICY "Allow all read on group_creation_requests" ON public.group_creation_requests FOR SELECT USING (true);
CREATE POLICY "Allow all write on group_creation_requests" ON public.group_creation_requests FOR ALL USING (true);

CREATE POLICY "Allow all read on broadcasts" ON public.broadcasts FOR SELECT USING (true);
CREATE POLICY "Allow all write on broadcasts" ON public.broadcasts FOR ALL USING (true);

CREATE POLICY "Allow all read on sos_events" ON public.sos_events FOR SELECT USING (true);
CREATE POLICY "Allow all write on sos_events" ON public.sos_events FOR ALL USING (true);

CREATE POLICY "Allow all read on user_live_locations" ON public.user_live_locations FOR SELECT USING (true);
CREATE POLICY "Allow all write on user_live_locations" ON public.user_live_locations FOR ALL USING (true);

CREATE POLICY "Allow all read on route_checkpoints" ON public.route_checkpoints FOR SELECT USING (true);
CREATE POLICY "Allow all write on route_checkpoints" ON public.route_checkpoints FOR ALL USING (true);

-- 6. ENABLE REALTIME PUBLICATIONS
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
END $$;
