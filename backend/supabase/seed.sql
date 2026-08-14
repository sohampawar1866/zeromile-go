-- ZeroMile Go Seed Script
DO $$
DECLARE
    -- Domains
    v_cycling_id UUID;
    v_marathon_id UUID;
    v_walkathon_id UUID;

    -- Users (SuperAdmins)
    v_admin1_id UUID;
    v_admin2_id UUID;
    v_admin3_id UUID;
    v_admin4_id UUID;
    v_admin5_id UUID;

    -- Users (Leaders)
    v_leader_vnit_id UUID;
    v_leader_orange_id UUID;

    -- Users (Participants)
    v_user_priya_id UUID;
    v_user_rohan_id UUID;
    v_user_sneha_id UUID;
    v_user_rahul_id UUID;
    v_user_pooja_id UUID;
    v_user_sameer_id UUID;

    -- Groups
    v_group_vnit_id UUID;
    v_group_orange_id UUID;
    v_gen_cycling_id UUID;
BEGIN
    -- 1. Insert Event Domains
    INSERT INTO public.event_domains (name, slug, type, status, start_time, end_time, route_geojson)
    VALUES (
        'Cycling Rally 2026',
        'cycling-2026',
        'CYCLING',
        'LIVE_ACTIVE',
        NOW() - INTERVAL '1 hour',
        NOW() + INTERVAL '4 hours',
        '{
            "type": "FeatureCollection",
            "features": [
                {
                    "type": "Feature",
                    "geometry": {
                        "type": "LineString",
                        "coordinates": [
                            [79.0806, 21.1498],
                            [79.0882, 21.1465],
                            [79.0682, 21.1378],
                            [79.0550, 21.1420],
                            [79.0664, 21.1278]
                        ]
                    },
                    "properties": { "name": "Official 24km Nagpur Loop" }
                }
            ]
        }'::jsonb
    ) RETURNING id INTO v_cycling_id;

    INSERT INTO public.event_domains (name, slug, type, status, start_time, end_time)
    VALUES (
        'Nagpur City Marathon 2026',
        'marathon-2026',
        'MARATHON',
        'UPCOMING',
        NOW() + INTERVAL '7 days',
        NOW() + INTERVAL '7 days 5 hours'
    ) RETURNING id INTO v_marathon_id;

    INSERT INTO public.event_domains (name, slug, type, status, start_time, end_time)
    VALUES (
        'Citizen Environmental Walkathon',
        'walkathon-2026',
        'WALKATHON',
        'CONCLUDED',
        NOW() - INTERVAL '3 days',
        NOW() - INTERVAL '3 days' + INTERVAL '3 hours'
    ) RETURNING id INTO v_walkathon_id;

    -- 2. Insert Users (SuperAdmins)
    INSERT INTO public.users (phone_number, full_name, avatar_url, emergency_contact)
    VALUES ('+91 98220 11111', 'Rajesh Sharma (SuperAdmin)', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb', '+91 98220 99991')
    RETURNING id INTO v_admin1_id;

    INSERT INTO public.users (phone_number, full_name, avatar_url, emergency_contact)
    VALUES ('+91 98220 22222', 'Sunita Deshmukh (SuperAdmin)', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2', '+91 98220 99992')
    RETURNING id INTO v_admin2_id;

    INSERT INTO public.users (phone_number, full_name, avatar_url, emergency_contact)
    VALUES ('+91 98220 33333', 'Amit Patel (SuperAdmin)', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d', '+91 98220 99993')
    RETURNING id INTO v_admin3_id;

    INSERT INTO public.users (phone_number, full_name, avatar_url, emergency_contact)
    VALUES ('+91 98220 44444', 'Kavita Joshi (SuperAdmin)', 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2', '+91 98220 99994')
    RETURNING id INTO v_admin4_id;

    INSERT INTO public.users (phone_number, full_name, avatar_url, emergency_contact)
    VALUES ('+91 98220 55555', 'Vikram Rathi (SuperAdmin)', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e', '+91 98220 99995')
    RETURNING id INTO v_admin5_id;

    -- Provision SuperAdmins for Cycling Domain
    INSERT INTO public.domain_superadmins (domain_id, user_id, created_by_dev)
    VALUES 
        (v_cycling_id, v_admin1_id, 'dev_master'),
        (v_cycling_id, v_admin2_id, 'dev_master'),
        (v_cycling_id, v_admin3_id, 'dev_master'),
        (v_cycling_id, v_admin4_id, 'dev_master'),
        (v_cycling_id, v_admin5_id, 'dev_master');

    -- 3. Insert Users (Group Leaders)
    INSERT INTO public.users (phone_number, full_name, avatar_url, emergency_contact)
    VALUES ('+91 98230 11111', 'Aniket Deshmukh (VNIT Leader)', 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d', '+91 98230 99991')
    RETURNING id INTO v_leader_vnit_id;

    INSERT INTO public.users (phone_number, full_name, avatar_url, emergency_contact)
    VALUES ('+91 98230 22222', 'Neha Verma (Orange City Leader)', 'https://images.unsplash.com/photo-1517841905240-472988babdf9', '+91 98230 99992')
    RETURNING id INTO v_leader_orange_id;

    -- 4. Insert Users (Participants)
    INSERT INTO public.users (phone_number, full_name, avatar_url, emergency_contact)
    VALUES ('+91 98240 11111', 'Priya Verma', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330', '+91 98240 99991')
    RETURNING id INTO v_user_priya_id;

    INSERT INTO public.users (phone_number, full_name, avatar_url, emergency_contact)
    VALUES ('+91 98240 22222', 'Rohan Gupta', 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61', '+91 98240 99992')
    RETURNING id INTO v_user_rohan_id;

    INSERT INTO public.users (phone_number, full_name, avatar_url, emergency_contact)
    VALUES ('+91 98240 33333', 'Sneha Kulkarni', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb', '+91 98240 99993')
    RETURNING id INTO v_user_sneha_id;

    INSERT INTO public.users (phone_number, full_name, avatar_url, emergency_contact)
    VALUES ('+91 98240 44444', 'Rahul Wankhede', 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7', '+91 98240 99994')
    RETURNING id INTO v_user_rahul_id;

    INSERT INTO public.users (phone_number, full_name, avatar_url, emergency_contact)
    VALUES ('+91 98240 55555', 'Pooja Nair', 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1', '+91 98240 99995')
    RETURNING id INTO v_user_pooja_id;

    INSERT INTO public.users (phone_number, full_name, avatar_url, emergency_contact)
    VALUES ('+91 98240 66666', 'Sameer Khan', 'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea', '+91 98240 99996')
    RETURNING id INTO v_user_sameer_id;

    -- 5. Insert Sub-Groups
    INSERT INTO public.sub_groups (domain_id, name, is_general, org_type, leader_id, muster_point, approval_status)
    VALUES (v_cycling_id, 'VNIT Cycling Club', FALSE, 'COLLEGE', v_leader_vnit_id, 'Ambazari Gate, VNIT Campus', 'APPROVED')
    RETURNING id INTO v_group_vnit_id;

    INSERT INTO public.sub_groups (domain_id, name, is_general, org_type, leader_id, muster_point, approval_status)
    VALUES (v_cycling_id, 'Orange City Sprinters', FALSE, 'SPORTS_CLUB', v_leader_orange_id, 'Samvidhan Square, Nagpur', 'APPROVED')
    RETURNING id INTO v_group_orange_id;

    -- 6. Insert Memberships (Triggers will auto-enroll into General Group)
    -- Leader VNIT
    INSERT INTO public.group_memberships (domain_id, group_id, user_id, is_active, is_leader, participation_status, checkin_time)
    VALUES (v_cycling_id, v_group_vnit_id, v_leader_vnit_id, TRUE, TRUE, 'CHECKED_IN', NOW() - INTERVAL '40 minutes');

    -- Leader Orange City
    INSERT INTO public.group_memberships (domain_id, group_id, user_id, is_active, is_leader, participation_status, checkin_time)
    VALUES (v_cycling_id, v_group_orange_id, v_leader_orange_id, TRUE, TRUE, 'CHECKED_IN', NOW() - INTERVAL '35 minutes');

    -- Priya (VNIT Active Member)
    INSERT INTO public.group_memberships (domain_id, group_id, user_id, is_active, is_leader, participation_status, checkin_time)
    VALUES (v_cycling_id, v_group_vnit_id, v_user_priya_id, TRUE, FALSE, 'CHECKED_IN', NOW() - INTERVAL '30 minutes');

    -- Rohan (VNIT Active Member)
    INSERT INTO public.group_memberships (domain_id, group_id, user_id, is_active, is_leader, participation_status, checkin_time)
    VALUES (v_cycling_id, v_group_vnit_id, v_user_rohan_id, TRUE, FALSE, 'CHECKED_IN', NOW() - INTERVAL '25 minutes');

    -- Sneha (Orange City Active Member)
    INSERT INTO public.group_memberships (domain_id, group_id, user_id, is_active, is_leader, participation_status, checkin_time)
    VALUES (v_cycling_id, v_group_orange_id, v_user_sneha_id, TRUE, FALSE, 'CHECKED_IN', NOW() - INTERVAL '20 minutes');

    -- Sameer (Enrolled in VNIT as inactive, Orange City as active)
    INSERT INTO public.group_memberships (domain_id, group_id, user_id, is_active, is_leader, participation_status, checkin_time)
    VALUES (v_cycling_id, v_group_vnit_id, v_user_sameer_id, FALSE, FALSE, 'NOT_CHECKED_IN', NULL);
    
    INSERT INTO public.group_memberships (domain_id, group_id, user_id, is_active, is_leader, participation_status, checkin_time)
    VALUES (v_cycling_id, v_group_orange_id, v_user_sameer_id, TRUE, FALSE, 'CHECKED_IN', NOW() - INTERVAL '10 minutes');

    -- Rahul & Pooja: General Participants
    SELECT id INTO v_gen_cycling_id FROM public.sub_groups WHERE domain_id = v_cycling_id AND is_general = TRUE LIMIT 1;
    
    INSERT INTO public.group_memberships (domain_id, group_id, user_id, is_active, is_leader, participation_status)
    VALUES (v_cycling_id, v_gen_cycling_id, v_user_rahul_id, FALSE, FALSE, 'NOT_CHECKED_IN')
    ON CONFLICT DO NOTHING;

    INSERT INTO public.group_memberships (domain_id, group_id, user_id, is_active, is_leader, participation_status)
    VALUES (v_cycling_id, v_gen_cycling_id, v_user_pooja_id, FALSE, FALSE, 'NOT_CHECKED_IN')
    ON CONFLICT DO NOTHING;

    -- 7. Insert Route Checkpoints
    INSERT INTO public.route_checkpoints (domain_id, checkpoint_type, name, latitude, longitude, sequence_order)
    VALUES 
        (v_cycling_id, 'START', 'Zero Mile Monument (Flag-off)', 21.1498, 79.0806, 1),
        (v_cycling_id, 'WATER_STATION', 'Samvidhan Square Water Point', 21.1465, 79.0882, 2),
        (v_cycling_id, 'WATER_STATION', 'Shankar Nagar Hydration Station', 21.1378, 79.0682, 3),
        (v_cycling_id, 'MEDICAL_POST', 'Law College Square Medical Aid Tent', 21.1420, 79.0550, 4),
        (v_cycling_id, 'FINISH', 'Deekshabhoomi Ground Finish Line', 21.1278, 79.0664, 5);

    -- 8. Insert Broadcasts
    INSERT INTO public.broadcasts (domain_id, sender_id, sender_role, target_type, message_text)
    VALUES (
        v_cycling_id, 
        v_admin1_id, 
        'SUPERADMIN', 
        'GENERAL', 
        '🚨 Official Flag-off at 06:00 AM from Zero Mile Monument. Please ensure helmets are buckled and stay within marshaled lanes.'
    );

    INSERT INTO public.broadcasts (domain_id, sender_id, sender_role, target_type, target_group_id, message_text)
    VALUES (
        v_cycling_id, 
        v_leader_vnit_id, 
        'GROUP_LEADER', 
        'SPECIFIC_GROUP', 
        v_group_vnit_id, 
        '📣 VNIT contingent assemble at Ambazari Gate by 05:30 AM sharp for team roll call!'
    );

    -- 9. Insert Telemetry (Live Locations)
    INSERT INTO public.user_live_locations (domain_id, user_id, active_group_id, latitude, longitude, speed_kmh, heading)
    VALUES 
        (v_cycling_id, v_leader_vnit_id, v_group_vnit_id, 21.1470, 79.0830, 22.4, 215.0),
        (v_cycling_id, v_user_priya_id, v_group_vnit_id, 21.1462, 79.0820, 18.5, 210.0),
        (v_cycling_id, v_user_rohan_id, v_group_vnit_id, 21.1450, 79.0810, 19.8, 220.0),
        (v_cycling_id, v_leader_orange_id, v_group_orange_id, 21.1420, 79.0750, 24.1, 230.0),
        (v_cycling_id, v_user_sneha_id, v_group_orange_id, 21.1415, 79.0745, 21.0, 228.0),
        (v_cycling_id, v_user_sameer_id, v_group_orange_id, 21.1400, 79.0720, 20.2, 225.0),
        (v_cycling_id, v_user_rahul_id, NULL, 21.1480, 79.0840, 15.0, 205.0)
    ON CONFLICT (domain_id, user_id) 
    DO UPDATE SET latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude, speed_kmh = EXCLUDED.speed_kmh, updated_at = NOW();

    -- 10. Insert 1 Sample Pending Group Creation Request
    INSERT INTO public.group_creation_requests (domain_id, applicant_user_id, org_name, org_type, expected_count, muster_point, leader_notes, status)
    VALUES (
        v_cycling_id, 
        v_user_rahul_id, 
        'Nagpur Citizen Front', 
        'NGO', 
        75, 
        'Samvidhan Square, Nagpur', 
        'Peaceful civic awareness contingent participating in Cycling Rally.', 
        'PENDING'
    );

    -- 11. Insert 1 Sample SOS Event
    INSERT INTO public.sos_events (domain_id, sender_user_id, active_sub_group_id, emergency_type, latitude, longitude, status, forwarded_by_leader_id, leader_notes)
    VALUES (
        v_cycling_id,
        v_user_priya_id,
        v_group_vnit_id,
        'MEDICAL',
        21.1462,
        79.0820,
        'FORWARDED_TO_ADMIN',
        v_leader_vnit_id,
        'Rider experienced mild heat dizziness near Samvidhan Square. First aid water provided, ambulance escort requested.'
    );

END $$;
