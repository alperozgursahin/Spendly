begin;

alter table public.profiles
  add column if not exists email text,
  add column if not exists bio text;

update public.profiles as profile
set email = lower(auth_user.email)
from auth.users as auth_user
where profile.id = auth_user.id
  and profile.email is distinct from lower(auth_user.email);

create unique index if not exists profiles_username_lower_uidx
  on public.profiles (lower(username)) where username is not null;
create index if not exists profiles_email_lower_idx
  on public.profiles (lower(email)) where email is not null;

create or replace function public.handle_splixa_user_signup()
returns trigger language plpgsql security definer set search_path = public
as $$
declare
  v_username text := lower(trim(coalesce(new.raw_user_meta_data ->> 'username', '')));
begin
  if v_username = '' then raise exception 'A username is required'; end if;
  if v_username !~ '^[a-z0-9_]{3,30}$' then
    raise exception 'Username must be 3-30 characters using letters, numbers, or underscores';
  end if;
  insert into public.profiles (id, username, email)
  values (new.id, v_username, lower(new.email))
  on conflict (id) do update
    set username = excluded.username, email = excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_splixa_profile on auth.users;
create trigger on_auth_user_created_splixa_profile
after insert on auth.users for each row
execute function public.handle_splixa_user_signup();

create or replace function public.check_username_exists(p_username text)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where lower(p.username) = lower(trim(leading '@' from trim(p_username)))
  );
$$;

revoke all on function public.check_username_exists(text) from public, anon, authenticated;
grant execute on function public.check_username_exists(text) to authenticated, service_role;

-- RLS-safe membership helper used by read-receipt policies. SECURITY DEFINER
-- prevents recursive evaluation of group_members' own policies; the empty
-- search_path and fully qualified table keep the boundary safe.
create or replace function public.is_group_member(
  p_group_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean language sql stable security definer set search_path = ''
as $$
  select p_user_id is not null and exists (
    select 1 from public.group_members member
    where member.group_id = p_group_id and member.user_id = p_user_id
  );
$$;

revoke all on function public.is_group_member(uuid, uuid) from public, anon, authenticated;
grant execute on function public.is_group_member(uuid, uuid) to authenticated, service_role;

create table if not exists public.group_chat_reads (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  last_read_at timestamptz not null default timezone('utc', now()),
  primary key (group_id, user_id)
);
alter table public.group_chat_reads
  add column if not exists last_read_at timestamptz default timezone('utc', now());
update public.group_chat_reads set last_read_at = timezone('utc', now())
where last_read_at is null;
alter table public.group_chat_reads
  alter column last_read_at set default timezone('utc', now()),
  alter column last_read_at set not null;

create index if not exists group_chat_reads_user_group_idx
  on public.group_chat_reads (user_id, group_id);
create index if not exists group_messages_group_id_created_at_idx
  on public.group_messages (group_id, created_at desc);
create index if not exists group_transactions_group_id_created_at_idx
  on public.group_transactions (group_id, created_at desc);

alter table public.group_chat_reads enable row level security;
drop policy if exists group_chat_reads_select_own on public.group_chat_reads;
create policy group_chat_reads_select_own on public.group_chat_reads
for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists group_chat_reads_insert_own on public.group_chat_reads;
create policy group_chat_reads_insert_own on public.group_chat_reads
for insert to authenticated with check (
  user_id = (select auth.uid()) and public.is_group_member(group_id)
);
drop policy if exists group_chat_reads_update_own on public.group_chat_reads;
create policy group_chat_reads_update_own on public.group_chat_reads
for update to authenticated using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()) and public.is_group_member(group_id));
drop policy if exists group_chat_reads_delete_own on public.group_chat_reads;
create policy group_chat_reads_delete_own on public.group_chat_reads
for delete to authenticated using (user_id = (select auth.uid()));

alter table public.direct_messages
  add column if not exists read_status boolean default false;
update public.direct_messages set read_status = false where read_status is null;
alter table public.direct_messages
  alter column read_status set default false,
  alter column read_status set not null;
create index if not exists direct_messages_unread_receiver_sender_idx
  on public.direct_messages (receiver_id, sender_id, created_at desc)
  where read_status = false;

drop policy if exists direct_messages_update_receiver on public.direct_messages;
create policy direct_messages_update_receiver on public.direct_messages
for update to authenticated using (receiver_id = (select auth.uid()))
with check (receiver_id = (select auth.uid()));

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'group_chat_reads'
  ) then
    alter publication supabase_realtime add table public.group_chat_reads;
  end if;
end
$$;

commit;
