
create table public.group_chat_reads (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  last_read_at timestamptz not null default timezone('utc', now()),
  primary key (group_id, user_id)
);

alter table public.group_chat_reads enable row level security;

create policy group_chat_reads_select on public.group_chat_reads
  for select
  using (user_id = auth.uid());

create policy group_chat_reads_insert on public.group_chat_reads
  for insert
  with check (user_id = auth.uid() and group_id = any (get_auth_group_ids()));

create policy group_chat_reads_update on public.group_chat_reads
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

alter publication supabase_realtime add table public.group_chat_reads;
;
