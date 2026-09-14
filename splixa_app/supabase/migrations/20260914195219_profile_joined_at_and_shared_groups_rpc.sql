-- B5: give another person's profile something worth opening -- how long they
-- have been on Splixa, and which groups you actually share with them.

-- 1. "Member since". `profiles` had no creation timestamp at all; the real one
--    lives on auth.users, which clients cannot read. Copy it onto the profile
--    row instead. Existing rows are backfilled from auth.users so the number is
--    true for everyone, not just people who sign up from here on; the default
--    covers new rows, since the signup trigger inserts without naming it.
alter table public.profiles
  add column if not exists created_at timestamptz not null default now();

update public.profiles p
set created_at = u.created_at
from auth.users u
where u.id = p.id
  and u.created_at is not null
  and p.created_at > u.created_at;

grant select (created_at) on public.profiles to authenticated;

-- 2. Shared groups.
--
-- Deliberately NOT a plain select against group_members from the client: the
-- viewer is read from auth.uid() inside the function rather than taken as an
-- argument. A `shared_groups(viewer, other)` shape would be exactly the
-- caller-supplied-identity oracle that had to be closed on can_view_profile and
-- is_group_member, where anyone could ask about any two strangers.
create or replace function public.shared_groups_with_v1(p_other_user_id uuid)
returns table (id uuid, name text, avatar_url text)
language sql
stable
security definer
set search_path = ''
as $$
  select g.id, g.name, g.avatar_url
  from public.groups g
  join public.group_members mine
    on mine.group_id = g.id and mine.user_id = auth.uid()
  join public.group_members theirs
    on theirs.group_id = g.id and theirs.user_id = p_other_user_id
  where auth.uid() is not null
    and p_other_user_id is not null
  order by g.name;
$$;

revoke execute on function public.shared_groups_with_v1(uuid) from anon, public;
grant execute on function public.shared_groups_with_v1(uuid) to authenticated, service_role;
