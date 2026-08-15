-- ZeroMile Go: UX Performance & Aggregation RPCs
-- 1. Optimized Index for Active GPS Streams (< 15 min freshness)
-- 2. Leader Squad Summary RPC (1 roundtrip for Leader HUD Header)
-- 3. Sector Density Aggregation RPC (for SuperAdmin & Leader Real-time Map)

-- 1. Freshness Index
CREATE INDEX IF NOT EXISTS idx_user_live_locations_freshness 
ON public.user_live_locations (domain_id, updated_at DESC);

-- 2. Leader Squad Summary RPC
CREATE OR REPLACE FUNCTION public.get_leader_squad_summary(
    p_domain_id UUID,
    p_group_id UUID
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
STABLE
AS $$
DECLARE
    v_total_enrolled INT := 0;
    v_checked_in INT := 0;
    v_completed INT := 0;
    v_active_telemetry INT := 0;
    v_pending_sos INT := 0;
    v_group_name TEXT := '';
    v_muster_point TEXT := '';
BEGIN
    -- Fetch group details
    SELECT name, muster_point INTO v_group_name, v_muster_point
    FROM public.sub_groups
    WHERE id = p_group_id AND domain_id = p_domain_id;

    -- Aggregate roster status counts
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE participation_status = 'CHECKED_IN'),
        COUNT(*) FILTER (WHERE participation_status = 'COMPLETED')
    INTO v_total_enrolled, v_checked_in, v_completed
    FROM public.group_memberships
    WHERE domain_id = p_domain_id AND group_id = p_group_id;

    -- Count active live location feeds in last 15 minutes
    SELECT COUNT(*)
    INTO v_active_telemetry
    FROM public.user_live_locations
    WHERE domain_id = p_domain_id 
      AND active_group_id = p_group_id 
      AND updated_at > (NOW() - INTERVAL '15 minutes');

    -- Count unresolved SOS alerts for this squad
    SELECT COUNT(*)
    INTO v_pending_sos
    FROM public.sos_events
    WHERE domain_id = p_domain_id 
      AND active_sub_group_id = p_group_id 
      AND status != 'RESOLVED';

    RETURN jsonb_build_object(
        'group_id', p_group_id,
        'group_name', COALESCE(v_group_name, 'Unknown Squad'),
        'muster_point', COALESCE(v_muster_point, 'General Assembly'),
        'total_enrolled', v_total_enrolled,
        'checked_in', v_checked_in,
        'completed', v_completed,
        'active_telemetry', v_active_telemetry,
        'pending_sos', v_pending_sos,
        'checkin_percentage', CASE WHEN v_total_enrolled > 0 THEN ROUND((v_checked_in::NUMERIC / v_total_enrolled::NUMERIC) * 100, 1) ELSE 0.0 END,
        'completion_percentage', CASE WHEN v_total_enrolled > 0 THEN ROUND((v_completed::NUMERIC / v_total_enrolled::NUMERIC) * 100, 1) ELSE 0.0 END
    );
END;
$$;

-- 3. Sector Density Aggregation RPC
CREATE OR REPLACE FUNCTION public.get_sector_density_metrics(
    p_domain_id UUID
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
STABLE
AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'checkpoint_id', cp.id,
            'sequence_order', cp.sequence_order,
            'name', cp.name,
            'checkpoint_type', cp.checkpoint_type,
            'latitude', cp.latitude,
            'longitude', cp.longitude,
            'active_riders_nearby', (
                SELECT COUNT(*)
                FROM public.user_live_locations loc
                WHERE loc.domain_id = p_domain_id
                  AND loc.updated_at > (NOW() - INTERVAL '15 minutes')
                  AND loc.latitude BETWEEN (cp.latitude - 0.005) AND (cp.latitude + 0.005)
                  AND loc.longitude BETWEEN (cp.longitude - 0.005) AND (cp.longitude + 0.005)
            )
        ) ORDER BY cp.sequence_order ASC
    ) INTO v_result
    FROM public.route_checkpoints cp
    WHERE cp.domain_id = p_domain_id;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- Grant execution to all standard roles
GRANT EXECUTE ON FUNCTION public.get_leader_squad_summary(UUID, UUID) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_sector_density_metrics(UUID) TO anon, authenticated, service_role;
