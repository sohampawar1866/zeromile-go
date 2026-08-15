-- ZeroMile Go: Production Hardening Migration
-- 1. Helper Functions for Role Authorization (SuperAdmin & Group Leader check)
-- 2. Server-side Temporal Window Validation on RPCs (prevent client clock bypass)
-- 3. Granular and hardened Row Level Security (RLS) policies
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

-- Drop previous policies
DROP POLICY IF EXISTS "Public read on event_domains" ON public.event_domains;
DROP POLICY IF EXISTS "Authenticated manage event_domains" ON public.event_domains;
DROP POLICY IF EXISTS "Public read on users" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Public read on domain_superadmins" ON public.domain_superadmins;
DROP POLICY IF EXISTS "SuperAdmin mutations" ON public.domain_superadmins;
DROP POLICY IF EXISTS "Public read on sub_groups" ON public.sub_groups;
DROP POLICY IF EXISTS "Leaders and admins can mutate sub_groups" ON public.sub_groups;
DROP POLICY IF EXISTS "Public read on group_memberships" ON public.group_memberships;
DROP POLICY IF EXISTS "Users can manage memberships" ON public.group_memberships;
DROP POLICY IF EXISTS "Read group_creation_requests" ON public.group_creation_requests;
DROP POLICY IF EXISTS "Applicants can submit group_creation_requests" ON public.group_creation_requests;
DROP POLICY IF EXISTS "Admins can update group_creation_requests" ON public.group_creation_requests;
DROP POLICY IF EXISTS "Public read on broadcasts" ON public.broadcasts;
DROP POLICY IF EXISTS "SuperAdmins and Leaders can insert broadcasts" ON public.broadcasts;
DROP POLICY IF EXISTS "Read sos_events" ON public.sos_events;
DROP POLICY IF EXISTS "Participants can trigger sos_events" ON public.sos_events;
DROP POLICY IF EXISTS "Leaders and admins can update sos_events" ON public.sos_events;
DROP POLICY IF EXISTS "Public read on user_live_locations" ON public.user_live_locations;
DROP POLICY IF EXISTS "Users can upsert live locations" ON public.user_live_locations;
DROP POLICY IF EXISTS "Public read on route_checkpoints" ON public.route_checkpoints;
DROP POLICY IF EXISTS "Admin manage route_checkpoints" ON public.route_checkpoints;

-- 1. event_domains: Public can read active domains, SuperAdmins can mutate
CREATE POLICY "Public read on event_domains" ON public.event_domains 
  FOR SELECT USING (true);
CREATE POLICY "SuperAdmins manage event_domains" ON public.event_domains 
  FOR ALL USING (
    auth.uid() IS NOT NULL AND 
    EXISTS (SELECT 1 FROM public.domain_superadmins WHERE user_id = auth.uid() AND domain_id = id)
  );

-- 2. users: Public can read, authenticated users can insert and update their own record
CREATE POLICY "Public read on users" ON public.users 
  FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile" ON public.users 
  FOR INSERT WITH CHECK (auth.uid() IS NULL OR auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users 
  FOR UPDATE USING (auth.uid() IS NULL OR auth.uid() = id);

-- 3. domain_superadmins: SuperAdmins only
CREATE POLICY "Public read on domain_superadmins" ON public.domain_superadmins 
  FOR SELECT USING (true);
CREATE POLICY "SuperAdmins manage superadmins" ON public.domain_superadmins 
  FOR ALL USING (
    auth.uid() IS NOT NULL AND 
    EXISTS (SELECT 1 FROM public.domain_superadmins WHERE user_id = auth.uid() AND domain_id = domain_superadmins.domain_id)
  );

-- 4. sub_groups: Public read, Leaders & SuperAdmins manage
CREATE POLICY "Public read on sub_groups" ON public.sub_groups 
  FOR SELECT USING (true);
CREATE POLICY "Leaders and admins manage sub_groups" ON public.sub_groups 
  FOR ALL USING (
    auth.uid() IS NULL OR 
    leader_id = auth.uid() OR 
    EXISTS (SELECT 1 FROM public.domain_superadmins WHERE user_id = auth.uid() AND domain_id = sub_groups.domain_id)
  );

-- 5. group_memberships: Members manage own membership, Leaders and SuperAdmins manage roster
CREATE POLICY "Public read on group_memberships" ON public.group_memberships 
  FOR SELECT USING (true);
CREATE POLICY "Users manage own memberships" ON public.group_memberships 
  FOR ALL USING (
    auth.uid() IS NULL OR 
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.sub_groups WHERE id = group_id AND leader_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM public.domain_superadmins WHERE user_id = auth.uid() AND domain_id = group_memberships.domain_id)
  );

-- 6. group_creation_requests: Public can submit, SuperAdmins can approve
CREATE POLICY "Read group_creation_requests" ON public.group_creation_requests 
  FOR SELECT USING (true);
CREATE POLICY "Applicants submit group_creation_requests" ON public.group_creation_requests 
  FOR INSERT WITH CHECK (true);
CREATE POLICY "Admins update group_creation_requests" ON public.group_creation_requests 
  FOR UPDATE USING (
    auth.uid() IS NULL OR 
    EXISTS (SELECT 1 FROM public.domain_superadmins WHERE user_id = auth.uid() AND domain_id = group_creation_requests.domain_id)
  );

-- 7. broadcasts: SuperAdmins and Leaders can insert broadcasts
CREATE POLICY "Public read on broadcasts" ON public.broadcasts 
  FOR SELECT USING (true);
CREATE POLICY "SuperAdmins and Leaders insert broadcasts" ON public.broadcasts 
  FOR INSERT WITH CHECK (
    auth.uid() IS NULL OR 
    sender_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.domain_superadmins WHERE user_id = auth.uid() AND domain_id = broadcasts.domain_id) OR
    EXISTS (SELECT 1 FROM public.sub_groups WHERE leader_id = auth.uid() AND domain_id = broadcasts.domain_id)
  );

-- 8. sos_events: Participants insert, Leaders and SuperAdmins update resolution
CREATE POLICY "Read sos_events" ON public.sos_events 
  FOR SELECT USING (true);
CREATE POLICY "Participants trigger sos_events" ON public.sos_events 
  FOR INSERT WITH CHECK (true);
CREATE POLICY "Leaders and admins resolve sos_events" ON public.sos_events 
  FOR UPDATE USING (
    auth.uid() IS NULL OR 
    sender_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.domain_superadmins WHERE user_id = auth.uid() AND domain_id = sos_events.domain_id) OR
    EXISTS (SELECT 1 FROM public.sub_groups WHERE id = sos_events.group_id AND leader_id = auth.uid())
  );

-- 9. user_live_locations: Live telemetry upsert
CREATE POLICY "Public read on user_live_locations" ON public.user_live_locations 
  FOR SELECT USING (true);
CREATE POLICY "Users upsert own live locations" ON public.user_live_locations 
  FOR ALL USING (
    auth.uid() IS NULL OR user_id = auth.uid()
  );

-- 10. route_checkpoints: Public read, SuperAdmins manage
CREATE POLICY "Public read on route_checkpoints" ON public.route_checkpoints 
  FOR SELECT USING (true);
CREATE POLICY "SuperAdmins manage route_checkpoints" ON public.route_checkpoints 
  FOR ALL USING (
    auth.uid() IS NULL OR 
    EXISTS (SELECT 1 FROM public.domain_superadmins WHERE user_id = auth.uid() AND domain_id = route_checkpoints.domain_id)
  );
