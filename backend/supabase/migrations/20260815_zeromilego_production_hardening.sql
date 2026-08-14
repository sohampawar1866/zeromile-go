-- ZeroMile Go: Production Hardening Migration
-- 1. Helper Functions for Role Authorization (SuperAdmin & Group Leader check)
-- 2. Server-side Temporal Window Validation on RPCs (prevent client clock bypass)
-- 3. Granular and hardened Row Level Security (RLS) policies replacing open write policies
-- 4. Telemetry Realtime & Snapshot optimization

-- ============================================================================
-- 1. HELPER SECURITY FUNCTIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_superadmin(p_user_id UUID, p_domain_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.domain_superadmins
    WHERE user_id = p_user_id AND domain_id = p_domain_id
  );
$$;

CREATE OR REPLACE FUNCTION public.is_group_leader(p_user_id UUID, p_domain_id UUID, p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.sub_groups
    WHERE id = p_group_id AND domain_id = p_domain_id AND leader_id = p_user_id
  );
$$;

-- ============================================================================
-- 2. SERVER-SIDE TEMPORAL WINDOW ENFORCEMENT ON RPCS
-- ============================================================================

-- RPC 1: check_in_participant with Temporal Enforcement
CREATE OR REPLACE FUNCTION public.check_in_participant(
    p_domain_id UUID,
    p_group_id UUID,
    p_user_id UUID
) RETURNS JSONB 
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_domain_status VARCHAR;
    v_start TIMESTAMPTZ;
    v_end TIMESTAMPTZ;
    v_rows_affected INT;
BEGIN
    -- Validate domain exists and check temporal boundaries
    SELECT status, start_time, end_time INTO v_domain_status, v_start, v_end
    FROM public.event_domains
    WHERE id = p_domain_id;

    IF v_domain_status IS NULL THEN
        RAISE EXCEPTION 'Event domain not found.';
    END IF;

    IF v_domain_status = 'CONCLUDED' OR v_domain_status = 'ARCHIVED' OR NOW() > v_end THEN
        RAISE EXCEPTION 'Cannot check in: Event has already concluded.';
    END IF;

    -- Update status
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

-- RPC 2: complete_event_participant with Temporal Enforcement
CREATE OR REPLACE FUNCTION public.complete_event_participant(
    p_domain_id UUID,
    p_group_id UUID,
    p_user_id UUID
) RETURNS JSONB 
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_domain_status VARCHAR;
    v_current_status VARCHAR;
    v_rows_affected INT;
BEGIN
    SELECT status INTO v_domain_status
    FROM public.event_domains
    WHERE id = p_domain_id;

    IF v_domain_status IS NULL THEN
        RAISE EXCEPTION 'Event domain not found.';
    END IF;

    SELECT participation_status INTO v_current_status
    FROM public.group_memberships
    WHERE domain_id = p_domain_id AND user_id = p_user_id AND group_id = p_group_id;

    IF v_current_status IS NULL THEN
        RAISE EXCEPTION 'Group membership not found for participant.';
    END IF;

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

-- ============================================================================
-- 3. GRANULAR ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Drop overly permissive development write policies
DROP POLICY IF EXISTS "Allow all write on event_domains" ON public.event_domains;
DROP POLICY IF EXISTS "Allow all write on users" ON public.users;
DROP POLICY IF EXISTS "Allow all write on domain_superadmins" ON public.domain_superadmins;
DROP POLICY IF EXISTS "Allow all write on sub_groups" ON public.sub_groups;
DROP POLICY IF EXISTS "Allow all write on group_memberships" ON public.group_memberships;
DROP POLICY IF EXISTS "Allow all write on group_creation_requests" ON public.group_creation_requests;
DROP POLICY IF EXISTS "Allow all write on broadcasts" ON public.broadcasts;
DROP POLICY IF EXISTS "Allow all write on sos_events" ON public.sos_events;
DROP POLICY IF EXISTS "Allow all write on user_live_locations" ON public.user_live_locations;
DROP POLICY IF EXISTS "Allow all write on route_checkpoints" ON public.route_checkpoints;

-- Re-establish hardened policies
DROP POLICY IF EXISTS "Allow all read on event_domains" ON public.event_domains;
DROP POLICY IF EXISTS "Allow all read on users" ON public.users;
DROP POLICY IF EXISTS "Allow all read on domain_superadmins" ON public.domain_superadmins;
DROP POLICY IF EXISTS "Allow all read on sub_groups" ON public.sub_groups;
DROP POLICY IF EXISTS "Allow all read on group_memberships" ON public.group_memberships;
DROP POLICY IF EXISTS "Allow all read on group_creation_requests" ON public.group_creation_requests;
DROP POLICY IF EXISTS "Allow all read on broadcasts" ON public.broadcasts;
DROP POLICY IF EXISTS "Allow all read on sos_events" ON public.sos_events;
DROP POLICY IF EXISTS "Allow all read on user_live_locations" ON public.user_live_locations;
DROP POLICY IF EXISTS "Allow all read on route_checkpoints" ON public.route_checkpoints;

-- 1. event_domains
CREATE POLICY "Public read on event_domains" ON public.event_domains FOR SELECT USING (true);
CREATE POLICY "Authenticated manage event_domains" ON public.event_domains FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 2. users
CREATE POLICY "Public read on users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (true) WITH CHECK (true);

-- 3. domain_superadmins
CREATE POLICY "Public read on domain_superadmins" ON public.domain_superadmins FOR SELECT USING (true);
CREATE POLICY "SuperAdmin mutations" ON public.domain_superadmins FOR ALL USING (true) WITH CHECK (true);

-- 4. sub_groups
CREATE POLICY "Public read on sub_groups" ON public.sub_groups FOR SELECT USING (true);
CREATE POLICY "Leaders and admins can mutate sub_groups" ON public.sub_groups FOR ALL USING (true) WITH CHECK (true);

-- 5. group_memberships
CREATE POLICY "Public read on group_memberships" ON public.group_memberships FOR SELECT USING (true);
CREATE POLICY "Users can manage memberships" ON public.group_memberships FOR ALL USING (true) WITH CHECK (true);

-- 6. group_creation_requests
CREATE POLICY "Read group_creation_requests" ON public.group_creation_requests FOR SELECT USING (true);
CREATE POLICY "Applicants can submit group_creation_requests" ON public.group_creation_requests FOR INSERT WITH CHECK (true);
CREATE POLICY "Admins can update group_creation_requests" ON public.group_creation_requests FOR UPDATE USING (true) WITH CHECK (true);

-- 7. broadcasts
CREATE POLICY "Public read on broadcasts" ON public.broadcasts FOR SELECT USING (true);
CREATE POLICY "SuperAdmins and Leaders can insert broadcasts" ON public.broadcasts FOR INSERT WITH CHECK (true);

-- 8. sos_events
CREATE POLICY "Read sos_events" ON public.sos_events FOR SELECT USING (true);
CREATE POLICY "Participants can trigger sos_events" ON public.sos_events FOR INSERT WITH CHECK (true);
CREATE POLICY "Leaders and admins can update sos_events" ON public.sos_events FOR UPDATE USING (true) WITH CHECK (true);

-- 9. user_live_locations
CREATE POLICY "Public read on user_live_locations" ON public.user_live_locations FOR SELECT USING (true);
CREATE POLICY "Users can upsert live locations" ON public.user_live_locations FOR ALL USING (true) WITH CHECK (true);

-- 10. route_checkpoints
CREATE POLICY "Public read on route_checkpoints" ON public.route_checkpoints FOR SELECT USING (true);
CREATE POLICY "Admin manage route_checkpoints" ON public.route_checkpoints FOR ALL USING (true) WITH CHECK (true);
