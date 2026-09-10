-- 1. Remove leftover overly-permissive policy (USING true / WITH CHECK true for ALL
--    commands) that was left in place next to the correct, narrower policies which
--    already use safe non-recursive helper functions (get_auth_group_ids /
--    get_auth_created_group_ids). This policy let any authenticated user read,
--    insert, update or delete ANY row in group_members regardless of membership.
drop policy if exists "Full access to authenticated users members" on public.group_members;

-- 2. Allow a new notification type for final payment-settlement confirmations.
alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type = any (array[
    'debt_request'::text,
    'payment_confirmation'::text,
    'debt_approved'::text,
    'debt_rejected'::text,
    'debt_settled'::text,
    'group_invite'::text,
    'group_activity'::text
  ]));

-- 3. Debtor acknowledges (pending -> approved): notify the creditor.
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

  if lower(coalesce(v_payload ->> 'status', 'pending')) <> 'pending' then
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

-- 4. Debtor marks approved -> payment_pending: notify the creditor.
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

  if lower(coalesce(v_payload ->> 'status', 'pending')) <> 'approved' then
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

-- 5. Creditor confirms payment_pending -> settled: notify the debtor.
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

  if lower(coalesce(v_payload ->> 'status', 'pending')) <> 'payment_pending' then
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

-- 6. Debtor rejects a pending share: notify the creditor.
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

  insert into public.notifications (recipient_id, sender_id, group_id, expense_id, type, is_read)
  values (v_payer_id, v_user_id, v_group_id, p_transaction_id, 'debt_rejected', false);
end;
$function$;
;
