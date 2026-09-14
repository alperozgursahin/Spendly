-- Close the anonymous read path into public.profiles, and stop exposing
-- e-mail addresses across accounts.
--
-- WHAT WAS WRONG
-- `profiles` carried two permissive SELECT policies granted to the PUBLIC
-- pseudo-role with `using (true)`:
--   "Public profiles are viewable by everyone"  SELECT  {public}  using (true)
--   profiles_select                             SELECT  {public}  using (true)
-- Permissive policies are OR-ed together, so these two overrode every narrower
-- policy on the table. PUBLIC includes `anon`, and the `anon` key ships inside
-- the published APK, so in practice the whole table -- id, username, e-mail,
-- avatar, bio -- was readable by anybody who pointed a client at the project.
--
-- Confirmed before writing this migration by running, inside a transaction that
-- was then rolled back:
--     set local role anon;  select count(*) from public.profiles;
-- which returned every row, e-mail column included.
--
-- WHAT THIS CHANGES
-- 1. The two `using (true)` SELECT policies are dropped. `profiles_select_
--    authenticated` already covers what the app actually needs, so no screen
--    loses access.
-- 2. The {public} write policies are dropped too. They are duplicates of the
--    {authenticated} policies added later and are all `auth.uid()`-based, so
--    they never granted anon anything -- but two policies per command make it
--    genuinely hard to see which one is in force, which is how the SELECT pair
--    survived this long.
-- 3. Row access has to stay wide for signed-in users: username search and group
--    member lists both read profiles the viewer is not friends with. So rather
--    than narrowing rows and breaking those features, the `email` column is
--    removed from the API surface. No screen reads another user's
--    `profiles.email`, and a user's own address is already on the session JWT.
--    Column privileges only take effect once the table-level grant is gone,
--    hence revoke-then-grant rather than a bare column revoke.
--
-- After this, `select *` on profiles fails for the app. The one caller that did
-- that (currentUserProfileProvider) now lists its columns explicitly.

drop policy if exists "Public profiles are viewable by everyone" on public.profiles;
drop policy if exists profiles_select on public.profiles;
drop policy if exists profiles_insert on public.profiles;
drop policy if exists profiles_update on public.profiles;
drop policy if exists profiles_delete on public.profiles;

revoke select on public.profiles from anon, authenticated;

grant select (
  id,
  full_name,
  avatar_url,
  updated_at,
  username,
  streak_count,
  last_active_date,
  bio,
  is_deleted,
  deleted_at,
  timezone,
  debt_reminders_enabled
) on public.profiles to authenticated;

