-- Splixa Storage bootstrap and RLS fix.
-- Safe to run repeatedly in Supabase SQL Editor.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values
  (
    'avatars',
    'avatars',
    true,
    8388608,
    array['image/jpeg', 'image/png', 'image/webp', 'image/heic']::text[]
  ),
  (
    'group_avatars',
    'group_avatars',
    true,
    8388608,
    array['image/jpeg', 'image/png', 'image/webp', 'image/heic']::text[]
  )
on conflict (id) do update set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Remove both current and earlier Splixa policy names so this script is
-- deterministic even if a previous migration was partially applied.
drop policy if exists splixa_media_select on storage.objects;
drop policy if exists splixa_media_insert on storage.objects;
drop policy if exists splixa_media_update on storage.objects;
drop policy if exists splixa_media_delete on storage.objects;
drop policy if exists splixa_avatar_public_read on storage.objects;
drop policy if exists splixa_avatar_owner_insert on storage.objects;
drop policy if exists splixa_avatar_owner_update on storage.objects;

-- Public SELECT is intentional because both buckets use getPublicUrl().
create policy splixa_media_select
on storage.objects
for select
to public
using (bucket_id in ('avatars', 'group_avatars'));

-- SECURITY DEFINER avoids group-table RLS interfering while Storage evaluates
-- whether the current user is the creator/admin of the requested group folder.
create or replace function public.is_group_storage_admin(group_id_text text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.groups g
    where g.id::text = group_id_text
      and g.created_by = auth.uid()
  );
$$;

revoke all on function public.is_group_storage_admin(text) from public;
grant execute on function public.is_group_storage_admin(text) to authenticated;

create policy splixa_media_insert
on storage.objects
for insert
to authenticated
with check (
  (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  or (
    bucket_id = 'group_avatars'
    and public.is_group_storage_admin((storage.foldername(name))[1])
  )
);

create policy splixa_media_update
on storage.objects
for update
to authenticated
using (
  (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  or (
    bucket_id = 'group_avatars'
    and public.is_group_storage_admin((storage.foldername(name))[1])
  )
)
with check (
  (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  or (
    bucket_id = 'group_avatars'
    and public.is_group_storage_admin((storage.foldername(name))[1])
  )
);

create policy splixa_media_delete
on storage.objects
for delete
to authenticated
using (
  (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  or (
    bucket_id = 'group_avatars'
    and public.is_group_storage_admin((storage.foldername(name))[1])
  )
);

-- The application stores profile images as:
--   avatars/<user-id>/avatar_<timestamp>.<extension>
-- and group images as:
--   group_avatars/<group-id>/avatar_<timestamp>.<extension>
