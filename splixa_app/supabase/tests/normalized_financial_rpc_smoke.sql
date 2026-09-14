-- Safe remote smoke test: exercises the normalized lifecycle and rolls back
-- every generated expense, share, settlement, legacy mirror, and notification.

begin;

do $smoke$
declare
  v_group_id uuid;
  v_payer_id uuid;
  v_participant_id uuid;
  v_expense public.expenses%rowtype;
  v_settlement public.settlements%rowtype;
  v_legacy_status text;
begin
  select gt.group_id, gt.payer_id, gm.user_id
    into v_group_id, v_payer_id, v_participant_id
  from public.group_transactions gt
  join public.group_members gm
    on gm.group_id = gt.group_id
   and gm.user_id <> gt.payer_id
  join auth.users payer on payer.id = gt.payer_id
  join auth.users participant on participant.id = gm.user_id
  order by gt.created_at
  limit 1;

  if not found then
    raise exception 'Smoke test requires a group with a payer and another member';
  end if;

  perform set_config('request.jwt.claim.sub', v_payer_id::text, true);
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_payer_id::text)::text,
    true
  );

  v_expense := public.create_expense_v1(
    p_group_id => v_group_id,
    p_payer_id => v_payer_id,
    p_description => 'ROLLBACK_ONLY_NORMALIZED_RPC_SMOKE_TEST',
    p_category => 'Diğer',
    p_notes => 'This row must never survive the surrounding rollback.',
    p_expense_date => current_date,
    p_split_type => 'exact',
    p_original_amount => 1.00,
    p_currency_code => 'TRY',
    p_base_amount => 1.00,
    p_base_currency_code => 'TRY',
    p_exchange_rate => 1.00,
    p_rate_source => 'automated_rollback_smoke_test',
    p_rate_locked_at => now(),
    p_shares => jsonb_build_array(
      jsonb_build_object(
        'participant_id', v_participant_id,
        'original_share_amount', 1.00,
        'base_share_amount', 1.00
      )
    )
  );

  if v_expense.id is null or v_expense.source <> 'native_v1' then
    raise exception 'create_expense_v1 did not return a native expense';
  end if;

  if not exists (
    select 1
    from public.expense_shares es
    where es.expense_id = v_expense.id
      and es.participant_id = v_participant_id
      and es.status = 'pending'
      and es.base_share_amount = 1.00
  ) then
    raise exception 'Normalized pending share was not created';
  end if;

  if not exists (
    select 1
    from public.group_transactions gt
    where gt.id = v_expense.id
      and gt.amount = 1.00
      and gt.split_data ? v_participant_id::text
  ) then
    raise exception 'Legacy compatibility mirror was not created';
  end if;

  if not exists (
    select 1
    from public.notifications n
    where n.expense_id = v_expense.id
      and n.recipient_id = v_participant_id
      and n.type = 'debt_request'
  ) then
    raise exception 'Debt-request notification was not created';
  end if;

  perform set_config('request.jwt.claim.sub', v_participant_id::text, true);
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_participant_id::text)::text,
    true
  );

  perform public.acknowledge_expense_share_v1(v_expense.id);
  perform public.mark_expense_payment_sent_v1(v_expense.id);

  if not exists (
    select 1
    from public.expense_shares es
    where es.expense_id = v_expense.id
      and es.participant_id = v_participant_id
      and es.status = 'payment_pending'
  ) then
    raise exception 'Normalized payment-pending transition failed';
  end if;

  perform set_config('request.jwt.claim.sub', v_payer_id::text, true);
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_payer_id::text)::text,
    true
  );

  v_settlement := public.confirm_expense_payment_v1(
    v_expense.id,
    v_participant_id
  );

  if v_settlement.id is null
     or v_settlement.source <> 'native_v1'
     or v_settlement.status <> 'settled' then
    raise exception 'Native settlement was not created';
  end if;

  select gt.split_data -> v_participant_id::text ->> 'status'
    into v_legacy_status
  from public.group_transactions gt
  where gt.id = v_expense.id;

  if v_legacy_status <> 'settled' then
    raise exception 'Legacy lifecycle mirror did not reach settled';
  end if;

  if exists (
    select component.user_id
    from public.group_balance_components_v1 component
    where component.source_id in (v_expense.id, v_settlement.id)
    group by component.user_id
    having sum(component.balance_delta) <> 0
  ) then
    raise exception 'Settled test expense did not net to zero';
  end if;

  perform public.archive_expense_v1(v_expense.id);

  if not exists (
    select 1
    from public.expenses e
    join public.group_transactions gt on gt.id = e.id
    where e.id = v_expense.id
      and e.archived_at is not null
      and gt.archived_at is not null
  ) then
    raise exception 'Normalized/legacy archive synchronization failed';
  end if;

  raise notice
    'NORMALIZED_RPC_SMOKE_TEST_PASSED create/approve/payment/settle/archive; all writes will be rolled back';
end
$smoke$;

rollback;
