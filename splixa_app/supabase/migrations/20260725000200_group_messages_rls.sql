-- Restrict group messages to authenticated group members and message owners.
alter table public.group_messages enable row level security;

revoke all on table public.group_messages from anon;
grant select, insert, update, delete on table public.group_messages to authenticated;

-- PostgreSQL combines permissive policies with OR. Remove every legacy policy so
-- an older, broader rule cannot bypass the policies defined below.
do $$
declare
  existing_policy record;
begin
  for existing_policy in
    select policyname
    from pg_policies
    where schemaname = 'public' and tablename = 'group_messages'
  loop
    execute format(
      'drop policy if exists %I on public.group_messages',
      existing_policy.policyname
    );
  end loop;
end
$$;

create policy group_messages_select_member
on public.group_messages
for select
to authenticated
using (
  public.is_group_member(group_id, (select auth.uid()))
);

create policy group_messages_insert_sender
on public.group_messages
for insert
to authenticated
with check (
  sender_id = (select auth.uid())
  and public.is_group_member(group_id, (select auth.uid()))
);

create policy group_messages_update_sender
on public.group_messages
for update
to authenticated
using (
  sender_id = (select auth.uid())
  and public.is_group_member(group_id, (select auth.uid()))
)
with check (
  sender_id = (select auth.uid())
  and public.is_group_member(group_id, (select auth.uid()))
);

create policy group_messages_delete_sender
on public.group_messages
for delete
to authenticated
using (
  sender_id = (select auth.uid())
  and public.is_group_member(group_id, (select auth.uid()))
);
