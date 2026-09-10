begin;

create extension if not exists pgcrypto;

do $$
begin
  create type public.debt_status as enum ('pending', 'approved', 'rejected');
exception
  when duplicate_object then null;
end $$;

create or replace function public.is_group_member(
  p_group_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select
    p_user_id is not null
    and exists (
      select 1
      from public.group_members gm
      where gm.group_id = p_group_id
        and gm.user_id = p_user_id
    );
$$;

create or replace function public.is_group_creator(
  p_group_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select
    p_user_id is not null
    and exists (
      select 1
      from public.groups g
      where g.id = p_group_id
        and g.created_by = p_user_id
    );
$$;

create or replace function public.can_view_profile(
  p_profile_id uuid,
  p_viewer_id uuid default auth.uid()
)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select
    p_viewer_id is not null
    and (
      p_viewer_id = p_profile_id
      or exists (
        select 1
        from public.friendships f
        where f.status = 'accepted'
          and (
            (f.user_id1 = p_viewer_id and f.user_id2 = p_profile_id)
            or (f.user_id2 = p_viewer_id and f.user_id1 = p_profile_id)
          )
      )
      or exists (
        select 1
        from public.group_members gm_viewer
        join public.group_members gm_target
          on gm_target.group_id = gm_viewer.group_id
        where gm_viewer.user_id = p_viewer_id
          and gm_target.user_id = p_profile_id
      )
    );
$$;

create or replace function public.sync_group_transaction_status()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.split_data is null then
    new.split_data := '{}'::jsonb;
  end if;

  if exists (
    select 1
    from jsonb_each(new.split_data) as split_item(participant_id, payload)
    where lower(coalesce(payload->>'status', 'approved')) = 'rejected'
  ) then
    new.status := 'rejected'::public.debt_status;
  elsif exists (
    select 1
    from jsonb_each(new.split_data) as split_item(participant_id, payload)
    where lower(coalesce(payload->>'status', 'approved')) = 'pending'
  ) then
    new.status := 'pending'::public.debt_status;
  else
    new.status := 'approved'::public.debt_status;
  end if;

  return new;
end;
$$;

create or replace function public.approve_debt_participant(p_transaction_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_split_data jsonb;
  v_current_status text;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select gt.split_data
    into v_split_data
  from public.group_transactions gt
  where gt.id = p_transaction_id
  for update;

  if not found then
    raise exception 'Transaction not found';
  end if;

  if not (v_split_data ? v_user_id::text) then
    raise exception 'Participant not found on transaction';
  end if;

  v_current_status := lower(coalesce(v_split_data -> v_user_id::text ->> 'status', 'pending'));
  if v_current_status <> 'pending' then
    raise exception 'Only pending debts can be approved';
  end if;

  update public.group_transactions
  set split_data = jsonb_set(
        coalesce(split_data, '{}'::jsonb),
        array[v_user_id::text, 'status'],
        to_jsonb('approved'::text),
        true
      )
  where id = p_transaction_id;
end;
$$;

create or replace function public.reject_debt_participant(p_transaction_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_split_data jsonb;
  v_current_status text;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select gt.split_data
    into v_split_data
  from public.group_transactions gt
  where gt.id = p_transaction_id
  for update;

  if not found then
    raise exception 'Transaction not found';
  end if;

  if not (v_split_data ? v_user_id::text) then
    raise exception 'Participant not found on transaction';
  end if;

  v_current_status := lower(coalesce(v_split_data -> v_user_id::text ->> 'status', 'pending'));
  if v_current_status <> 'pending' then
    raise exception 'Only pending debts can be rejected';
  end if;

  update public.group_transactions
  set split_data = jsonb_set(
        coalesce(split_data, '{}'::jsonb),
        array[v_user_id::text, 'status'],
        to_jsonb('rejected'::text),
        true
      )
  where id = p_transaction_id;
end;
$$;

alter table public.group_transactions
  add column if not exists status public.debt_status not null default 'pending';

update public.group_transactions
set status = case
  when exists (
    select 1
    from jsonb_each(coalesce(split_data, '{}'::jsonb)) as split_item(participant_id, payload)
    where lower(coalesce(payload->>'status', 'approved')) = 'rejected'
  ) then 'rejected'::public.debt_status
  when exists (
    select 1
    from jsonb_each(coalesce(split_data, '{}'::jsonb)) as split_item(participant_id, payload)
    where lower(coalesce(payload->>'status', 'approved')) = 'pending'
  ) then 'pending'::public.debt_status
  else 'approved'::public.debt_status
end;

drop trigger if exists trg_sync_group_transaction_status on public.group_transactions;
create trigger trg_sync_group_transaction_status
before insert or update of split_data on public.group_transactions
for each row
execute function public.sync_group_transaction_status();

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users (id) on delete cascade,
  sender_id uuid not null references auth.users (id) on delete cascade,
  group_id uuid null references public.groups (id) on delete cascade,
  expense_id uuid null references public.group_transactions (id) on delete cascade,
  type text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  constraint notifications_type_check check (
    type in (
      'debt_request',
      'payment_confirmation',
      'debt_approved',
      'debt_rejected',
      'group_invite',
      'group_activity'
    )
  )
);

create index if not exists group_transactions_group_id_created_at_idx
  on public.group_transactions (group_id, created_at desc);

create index if not exists group_transactions_payer_id_created_at_idx
  on public.group_transactions (payer_id, created_at desc);

create index if not exists group_transactions_status_idx
  on public.group_transactions (status);

create index if not exists group_members_group_id_user_id_idx
  on public.group_members (group_id, user_id);

create index if not exists group_members_user_id_group_id_idx
  on public.group_members (user_id, group_id);

create index if not exists direct_messages_sender_receiver_created_at_idx
  on public.direct_messages (sender_id, receiver_id, created_at desc);

create index if not exists direct_messages_receiver_read_status_created_at_idx
  on public.direct_messages (receiver_id, read_status, created_at desc);

create index if not exists friendships_user_id1_user_id2_status_idx
  on public.friendships (user_id1, user_id2, status);

create index if not exists friendships_user_id2_user_id1_status_idx
  on public.friendships (user_id2, user_id1, status);

create index if not exists notifications_recipient_is_read_created_at_idx
  on public.notifications (recipient_id, is_read, created_at desc);

create index if not exists notifications_sender_created_at_idx
  on public.notifications (sender_id, created_at desc);

create index if not exists notifications_group_id_created_at_idx
  on public.notifications (group_id, created_at desc);

create index if not exists notifications_expense_id_created_at_idx
  on public.notifications (expense_id, created_at desc);

create index if not exists transactions_user_id_date_idx
  on public.transactions (user_id, date desc);

create index if not exists transactions_group_id_date_idx
  on public.transactions (group_id, date desc);

create index if not exists transactions_type_date_idx
  on public.transactions (type, date desc);

create index if not exists groups_created_by_created_at_idx
  on public.groups (created_by, created_at desc);

alter table public.profiles enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.group_transactions enable row level security;
alter table public.transactions enable row level security;
alter table public.friendships enable row level security;
alter table public.direct_messages enable row level security;
alter table public.notifications enable row level security;

drop policy if exists profiles_select_viewable on public.profiles;
create policy profiles_select_viewable
on public.profiles
for select
to authenticated
using (public.can_view_profile(id));

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists profiles_delete_own on public.profiles;
create policy profiles_delete_own
on public.profiles
for delete
to authenticated
using (auth.uid() = id);

drop policy if exists groups_select_member on public.groups;
create policy groups_select_member
on public.groups
for select
to authenticated
using (public.is_group_member(id) or created_by = auth.uid());

drop policy if exists groups_insert_creator on public.groups;
create policy groups_insert_creator
on public.groups
for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists groups_update_creator on public.groups;
create policy groups_update_creator
on public.groups
for update
to authenticated
using (created_by = auth.uid())
with check (created_by = auth.uid());

drop policy if exists groups_delete_creator on public.groups;
create policy groups_delete_creator
on public.groups
for delete
to authenticated
using (created_by = auth.uid());

drop policy if exists group_members_select_member on public.group_members;
create policy group_members_select_member
on public.group_members
for select
to authenticated
using (public.is_group_member(group_id) or public.is_group_creator(group_id) or user_id = auth.uid());

drop policy if exists group_members_insert_creator on public.group_members;
create policy group_members_insert_creator
on public.group_members
for insert
to authenticated
with check (public.is_group_creator(group_id, auth.uid()));

drop policy if exists group_members_delete_creator_or_self on public.group_members;
create policy group_members_delete_creator_or_self
on public.group_members
for delete
to authenticated
using (public.is_group_creator(group_id, auth.uid()) or user_id = auth.uid());

drop policy if exists group_transactions_select_group_member on public.group_transactions;
create policy group_transactions_select_group_member
on public.group_transactions
for select
to authenticated
using (
  payer_id = auth.uid()
  or public.is_group_member(group_id)
  or exists (
    select 1
    from jsonb_each(coalesce(split_data, '{}'::jsonb)) as split_item(participant_id, payload)
    where participant_id = auth.uid()::text
  )
);

drop policy if exists group_transactions_insert_payer_member on public.group_transactions;
create policy group_transactions_insert_payer_member
on public.group_transactions
for insert
to authenticated
with check (
  payer_id = auth.uid()
  and (group_id is null or public.is_group_member(group_id, auth.uid()))
);

drop policy if exists group_transactions_update_payer on public.group_transactions;
create policy group_transactions_update_payer
on public.group_transactions
for update
to authenticated
using (payer_id = auth.uid())
with check (payer_id = auth.uid());

drop policy if exists group_transactions_delete_payer on public.group_transactions;
create policy group_transactions_delete_payer
on public.group_transactions
for delete
to authenticated
using (payer_id = auth.uid());

drop policy if exists transactions_select_owner_or_group on public.transactions;
create policy transactions_select_owner_or_group
on public.transactions
for select
to authenticated
using (
  user_id = auth.uid()
  or (group_id is not null and public.is_group_member(group_id))
);

drop policy if exists transactions_insert_owner_or_group on public.transactions;
create policy transactions_insert_owner_or_group
on public.transactions
for insert
to authenticated
with check (
  user_id = auth.uid()
  and (group_id is null or public.is_group_member(group_id, auth.uid()))
);

drop policy if exists transactions_update_owner_or_group on public.transactions;
create policy transactions_update_owner_or_group
on public.transactions
for update
to authenticated
using (
  user_id = auth.uid()
  or (group_id is not null and public.is_group_member(group_id))
)
with check (
  user_id = auth.uid()
  or (group_id is not null and public.is_group_member(group_id))
);

drop policy if exists transactions_delete_owner_or_group on public.transactions;
create policy transactions_delete_owner_or_group
on public.transactions
for delete
to authenticated
using (
  user_id = auth.uid()
  or (group_id is not null and public.is_group_member(group_id))
);

drop policy if exists friendships_select_involved on public.friendships;
create policy friendships_select_involved
on public.friendships
for select
to authenticated
using (user_id1 = auth.uid() or user_id2 = auth.uid());

drop policy if exists friendships_insert_sender on public.friendships;
create policy friendships_insert_sender
on public.friendships
for insert
to authenticated
with check (user_id1 = auth.uid());

drop policy if exists friendships_update_involved on public.friendships;
create policy friendships_update_involved
on public.friendships
for update
to authenticated
using (user_id1 = auth.uid() or user_id2 = auth.uid())
with check (user_id1 = auth.uid() or user_id2 = auth.uid());

drop policy if exists friendships_delete_involved on public.friendships;
create policy friendships_delete_involved
on public.friendships
for delete
to authenticated
using (user_id1 = auth.uid() or user_id2 = auth.uid());

drop policy if exists direct_messages_select_participant on public.direct_messages;
create policy direct_messages_select_participant
on public.direct_messages
for select
to authenticated
using (sender_id = auth.uid() or receiver_id = auth.uid());

drop policy if exists direct_messages_insert_sender on public.direct_messages;
create policy direct_messages_insert_sender
on public.direct_messages
for insert
to authenticated
with check (sender_id = auth.uid());

drop policy if exists direct_messages_update_receiver on public.direct_messages;
create policy direct_messages_update_receiver
on public.direct_messages
for update
to authenticated
using (receiver_id = auth.uid())
with check (receiver_id = auth.uid());

drop policy if exists direct_messages_delete_participant on public.direct_messages;
create policy direct_messages_delete_participant
on public.direct_messages
for delete
to authenticated
using (sender_id = auth.uid() or receiver_id = auth.uid());

drop policy if exists notifications_select_visible on public.notifications;
create policy notifications_select_visible
on public.notifications
for select
to authenticated
using (
  recipient_id = auth.uid()
  or sender_id = auth.uid()
  or (group_id is not null and public.is_group_member(group_id))
);

drop policy if exists notifications_insert_sender on public.notifications;
create policy notifications_insert_sender
on public.notifications
for insert
to authenticated
with check (sender_id = auth.uid());

drop policy if exists notifications_update_recipient on public.notifications;
create policy notifications_update_recipient
on public.notifications
for update
to authenticated
using (recipient_id = auth.uid())
with check (recipient_id = auth.uid());

drop policy if exists notifications_delete_sender_or_recipient on public.notifications;
create policy notifications_delete_sender_or_recipient
on public.notifications
for delete
to authenticated
using (recipient_id = auth.uid() or sender_id = auth.uid());

commit;