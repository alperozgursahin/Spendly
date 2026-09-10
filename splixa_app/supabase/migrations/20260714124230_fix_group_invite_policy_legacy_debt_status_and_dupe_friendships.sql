-- 1. Clean up existing duplicate friendship rows for the same unordered pair
--    (kept the earliest row per pair, dropped the redundant duplicate).
delete from public.friendships where id = '1c03e69c-d28c-4f24-bcda-5c13596eea71'; -- dup of 9345232b (ilayda/alper, both accepted)
delete from public.friendships where id = '290be010-9820-45ba-8f15-afe07ff1b1f4'; -- redundant pending, already accepted via a498d022 (alper/tavuk)

-- 2. Prevent future duplicate friendship rows for the same unordered pair,
--    regardless of which side sent the request.
create unique index if not exists friendships_unique_pair
  on public.friendships (least(user_id1, user_id2), greatest(user_id1, user_id2));

-- 3. group_members_insert only allowed the group CREATOR to add members, but
--    the app's invite-a-friend flow is available to any existing group
--    member (see InviteFriendModal), not just the creator. This was exposed
--    after dropping the old catch-all USING(true) policy. Allow both: the
--    creator, or any current member of the group, using the same safe
--    non-recursive helper functions.
drop policy if exists "group_members_insert" on public.group_members;
create policy "group_members_insert" on public.group_members
for insert to authenticated
with check (
  group_id = any (get_auth_created_group_ids())
  or group_id = any (get_auth_group_ids())
);

-- 4. Legacy group_transactions rows created before the approval-status
--    system existed have no 'status' key in their split_data payload. The
--    Dart client (participantApprovalStatus) already treats a missing
--    status as 'approved' for backward compatibility, but these RPCs
--    defaulted a missing status to 'pending', so server-side validation
--    rejected actions (e.g. "Mark as Paid") that the client UI allowed for
--    those old rows. Align the server default with the client's.
create or replace function public.mark_payment_sent(p_transaction_id uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
declare
  v_actor_id uuid := auth.uid();
  v_payer_id uuid;
  v_group_id uuid;
  v_split_data jsonb;
  v_payload jsonb;
begin
  if v_actor_id is null then
    raise exception 'Not authenticated';
  end if;

  select payer_id, group_id, split_data
  into v_payer_id, v_group_id, v_split_data
  from public.group_transactions
  where id = p_transaction_id
  for update;

  if not found then
    raise exception 'Transaction not found';
  end if;

  if v_actor_id = v_payer_id then
    raise exception 'The creditor cannot mark a debtor share as paid';
  end if;

  v_payload := v_split_data -> v_actor_id::text;
  if jsonb_typeof(v_payload) <> 'object' then
    raise exception 'Participant share not found';
  end if;

  if lower(coalesce(v_payload ->> 'status', 'approved')) <> 'approved' then
    raise exception 'Only approved debts can be marked as paid';
  end if;

  update public.group_transactions
  set split_data = jsonb_set(
    split_data,
    array[v_actor_id::text, 'status'],
    to_jsonb('payment_pending'::text),
    false
  )
  where id = p_transaction_id;

  insert into public.notifications (recipient_id, sender_id, group_id, expense_id, type, is_read)
  values (v_payer_id, v_actor_id, v_group_id, p_transaction_id, 'payment_confirmation', false);
end;
$function$;

create or replace function public.acknowledge_debt_participant(p_transaction_id uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
declare
  v_actor_id uuid := auth.uid();
  v_payer_id uuid;
  v_group_id uuid;
  v_split_data jsonb;
  v_payload jsonb;
begin
  if v_actor_id is null then
    raise exception 'Not authenticated';
  end if;

  select payer_id, group_id, split_data
  into v_payer_id, v_group_id, v_split_data
  from public.group_transactions
  where id = p_transaction_id
  for update;

  if not found then
    raise exception 'Transaction not found';
  end if;

  if v_actor_id = v_payer_id then
    raise exception 'The creditor cannot acknowledge a debtor share';
  end if;

  v_payload := v_split_data -> v_actor_id::text;
  if jsonb_typeof(v_payload) <> 'object' then
    raise exception 'Participant share not found';
  end if;

  if lower(coalesce(v_payload ->> 'status', 'approved')) <> 'pending' then
    raise exception 'Only pending debts can be acknowledged';
  end if;

  update public.group_transactions
  set split_data = jsonb_set(
    split_data,
    array[v_actor_id::text, 'status'],
    to_jsonb('approved'::text),
    false
  )
  where id = p_transaction_id;

  insert into public.notifications (recipient_id, sender_id, group_id, expense_id, type, is_read)
  values (v_payer_id, v_actor_id, v_group_id, p_transaction_id, 'debt_approved', false);
end;
$function$;

create or replace function public.confirm_payment_received(p_transaction_id uuid, p_participant_id uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
declare
  v_actor_id uuid := auth.uid();
  v_payer_id uuid;
  v_group_id uuid;
  v_split_data jsonb;
  v_payload jsonb;
begin
  if v_actor_id is null then
    raise exception 'Not authenticated';
  end if;

  select payer_id, group_id, split_data
  into v_payer_id, v_group_id, v_split_data
  from public.group_transactions
  where id = p_transaction_id
  for update;

  if not found then
    raise exception 'Transaction not found';
  end if;

  if v_actor_id <> v_payer_id then
    raise exception 'Only the creditor can confirm payment';
  end if;

  if p_participant_id = v_payer_id then
    raise exception 'The payer is not a debtor participant';
  end if;

  v_payload := v_split_data -> p_participant_id::text;
  if jsonb_typeof(v_payload) <> 'object' then
    raise exception 'Participant share not found';
  end if;

  if lower(coalesce(v_payload ->> 'status', 'approved')) <> 'payment_pending' then
    raise exception 'Only payment-pending debts can be settled';
  end if;

  update public.group_transactions
  set split_data = jsonb_set(
    split_data,
    array[p_participant_id::text, 'status'],
    to_jsonb('settled'::text),
    false
  )
  where id = p_transaction_id;

  insert into public.notifications (recipient_id, sender_id, group_id, expense_id, type, is_read)
  values (p_participant_id, v_actor_id, v_group_id, p_transaction_id, 'debt_settled', false);
end;
$function$;

create or replace function public.reject_debt_participant(p_transaction_id uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
declare
  v_user_id uuid := auth.uid();
  v_payer_id uuid;
  v_group_id uuid;
  v_split_data jsonb;
  v_current_status text;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select gt.payer_id, gt.group_id, gt.split_data
    into v_payer_id, v_group_id, v_split_data
  from public.group_transactions gt
  where gt.id = p_transaction_id
  for update;

  if not found then
    raise exception 'Transaction not found';
  end if;

  if not (v_split_data ? v_user_id::text) then
    raise exception 'Participant not found on transaction';
  end if;

  v_current_status := lower(coalesce(v_split_data -> v_user_id::text ->> 'status', 'approved'));
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

  insert into public.notifications (recipient_id, sender_id, group_id, expense_id, type, is_read)
  values (v_payer_id, v_user_id, v_group_id, p_transaction_id, 'debt_rejected', false);
end;
$function$;
;
