-- Remove the legacy username-to-email RPC and every privilege attached to it.
-- DROP FUNCTION also removes the function's ACL entries, including anon grants.
drop function if exists public.get_email_by_username(text);
