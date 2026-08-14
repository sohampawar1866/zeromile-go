-- Migration: Revoke public execution of administrative and internal helper RPCs from anon role
REVOKE EXECUTE ON FUNCTION public.provision_superadmin(uuid, varchar, varchar, varchar) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_superadmin(uuid, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_group_leader(uuid, uuid, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.leader_direct_add_member(uuid, uuid, uuid, varchar, varchar) FROM anon;
