
create table public.group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  message text not null,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.group_messages enable row level security;

create policy group_messages_select on public.group_messages
  for select
  using (group_id = any (get_auth_group_ids()));

create policy group_messages_insert on public.group_messages
  for insert
  with check (sender_id = auth.uid() and group_id = any (get_auth_group_ids()));

alter publication supabase_realtime add table public.group_messages;
;
