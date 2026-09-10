-- Splixa group media + enforceable creator-admin rules.
-- Run once in the Supabase SQL editor before enabling group image uploads.

alter table public.groups
  add column if not exists avatar_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  8388608,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists splixa_avatar_public_read on storage.objects;
create policy splixa_avatar_public_read
on storage.objects for select
using (bucket_id = 'avatars');

drop policy if exists splixa_avatar_owner_insert on storage.objects;
create policy splixa_avatar_owner_insert
on storage.objects for insert to authenticated
with check (
  bucket_id = 'avatars'
  and (
    (
      (storage.foldername(name))[1] = 'users'
      and (storage.foldername(name))[2] = auth.uid()::text
    )
    or (
      (storage.foldername(name))[1] = 'groups'
      and exists (
        select 1 from public.groups g
        where g.id::text = (storage.foldername(name))[2]
          and g.created_by = auth.uid()
      )
    )
  )
);

drop policy if exists splixa_avatar_owner_update on storage.objects;
create policy splixa_avatar_owner_update
on storage.objects for update to authenticated
using (
  bucket_id = 'avatars'
  and (
    ((storage.foldername(name))[1] = 'users' and (storage.foldername(name))[2] = auth.uid()::text)
    or exists (
      select 1 from public.groups g
      where (storage.foldername(name))[1] = 'groups'
        and g.id::text = (storage.foldername(name))[2]
        and g.created_by = auth.uid()
    )
  )
);

create or replace function public.enforce_group_creator_admin()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_group_id uuid;
  target_user_id uuid;
  creator_id uuid;
begin
  if auth.uid() is null then
    return coalesce(new, old);
  end if;

  target_group_id := coalesce(new.group_id, old.group_id);
  target_user_id := coalesce(new.user_id, old.user_id);
  select created_by into creator_id from public.groups where id = target_group_id;

  if tg_op = 'INSERT' and auth.uid() <> creator_id then
    raise exception 'Only the group admin can add members';
  end if;

  if tg_op = 'DELETE'
     and auth.uid() <> creator_id
     and auth.uid() <> target_user_id then
    raise exception 'Only the group admin can remove another member';
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists enforce_group_creator_admin_trigger on public.group_members;
create trigger enforce_group_creator_admin_trigger
before insert or delete on public.group_members
for each row execute function public.enforce_group_creator_admin();

create or replace function public.enforce_group_avatar_admin()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null
     and new.avatar_url is distinct from old.avatar_url
     and auth.uid() <> old.created_by then
    raise exception 'Only the group admin can change the group picture';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_group_avatar_admin_trigger on public.groups;
create trigger enforce_group_avatar_admin_trigger
before update of avatar_url on public.groups
for each row execute function public.enforce_group_avatar_admin();
