-- F2: take EXECUTE away from unauthenticated callers.
--
-- Seventeen SECURITY DEFINER functions in `public` were callable by `anon`.
-- Most are harmless on their own -- they read `auth.uid()`, which is null for an
-- anonymous caller -- but three take the identity to check as a *parameter* and
-- only default it to auth.uid():
--     can_view_profile(p_profile_id, p_viewer_id)
--     is_group_creator(p_group_id, p_user_id)
--     is_group_member(p_group_id, p_user_id)
-- so an unauthenticated POST to /rest/v1/rpc/can_view_profile with two chosen
-- UUIDs answered "are these two people friends, or in a group together" about
-- users the caller was neither of. Four more (enforce_group_avatar_admin,
-- enforce_group_creator_admin, handle_splixa_user_signup,
-- sync_group_transaction_status) are trigger functions that have no business
-- being in the REST surface at all; triggers fire without the caller holding
-- EXECUTE, so revoking costs nothing.
--
-- Eleven of the seventeen also carry a grant to the PUBLIC pseudo-role, and
-- privileges are additive -- revoking from `anon` alone would have left PUBLIC
-- granting it straight back. Hence `from anon, public`. Every one of them has
-- its own explicit `authenticated` and `service_role` grant, so signed-in users
-- and the backend are unaffected. Verified in a rolled-back transaction: anon
-- denied, while `is_group_member`, `get_auth_group_ids` and selects against the
-- RLS-protected ledger tables all still succeed as `authenticated`.

revoke execute on function public.acknowledge_debt_participant(uuid) from anon, public;
revoke execute on function public.approve_debt_participant(uuid) from anon, public;
revoke execute on function public.archive_group_transaction(uuid) from anon, public;
revoke execute on function public.can_view_profile(uuid, uuid) from anon, public;
revoke execute on function public.confirm_payment_received(uuid, uuid) from anon, public;
revoke execute on function public.enforce_group_avatar_admin() from anon, public;
revoke execute on function public.enforce_group_creator_admin() from anon, public;
revoke execute on function public.get_auth_created_group_ids() from anon, public;
revoke execute on function public.get_auth_group_ids() from anon, public;
revoke execute on function public.get_user_groups() from anon, public;
revoke execute on function public.handle_splixa_user_signup() from anon, public;
revoke execute on function public.is_group_creator(uuid, uuid) from anon, public;
revoke execute on function public.is_group_storage_admin(text) from anon, public;
revoke execute on function public.mark_notifications_read() from anon, public;
revoke execute on function public.mark_payment_sent(uuid) from anon, public;
revoke execute on function public.reject_debt_participant(uuid) from anon, public;
revoke execute on function public.sync_group_transaction_status() from anon, public;

-- F3: pin the signup trigger's search_path.
--
-- It is the one SECURITY DEFINER function in the project without it, so it runs
-- as its owner with a caller-influenced schema resolution order. Exploiting that
-- needs CREATE on a schema in the path, which anon and authenticated do not
-- have, so this is hardening rather than an open door -- but every other
-- function here already does it. The body only touches `public.profiles`, which
-- is already schema-qualified, and pg_catalog stays implicitly first, so an
-- empty search_path needs no change to the body.
alter function public.handle_splixa_user_signup() set search_path = '';
