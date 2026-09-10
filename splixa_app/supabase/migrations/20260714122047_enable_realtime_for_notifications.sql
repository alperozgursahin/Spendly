-- notifications was missing from the supabase_realtime publication, so the
-- app's .stream() on this table (userNotificationsProvider) never received
-- live pushes for debt approvals/rejections/settlements or debt_request —
-- only a manual re-navigation to the screen picked up new rows.
alter publication supabase_realtime add table public.notifications;;
