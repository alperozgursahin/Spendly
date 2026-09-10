-- Phase 0 / Task 3: atomic normalized financial mutations.
-- The legacy row is a temporary compatibility projection for deployed clients
-- and the current notifications FK. Normalized tables remain authoritative.

begin;

-- New RPCs write their own legacy projection. Suppress the old -> new bridge
-- only for those internal writes so it cannot replace locked FX facts with TRY.
drop trigger if exists group_transactions_sync_financial_ledger
  on public.group_transactions;

create trigger group_transactions_sync_financial_ledger
after insert or update on public.group_transactions
for each row
when (
  coalesce(
    current_setting('splixa.skip_legacy_financial_sync', true),
    'off'
  ) <> 'on'
)
execute function public.splixa_sync_legacy_group_transaction();

create or replace function public.splixa_set_legacy_share_state(
  p_expense_id uuid,
  p_participant_id uuid,
  p_status text,
  p_paid boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_updated integer;
begin
  if p_status not in (
    'pending',
    'approved',
    'payment_pending',
    'settled',
    'rejected'
  ) then
    raise exception 'Unsupported legacy share status: %', p_status;
  end if;

  perform set_config('splixa.skip_legacy_financial_sync', 'on', true);

  update public.group_transactions gt
  set split_data = jsonb_set(
    jsonb_set(
      gt.split_data,
      array[p_participant_id::text, 'status'],
      to_jsonb(p_status),
      false
    ),
    array[p_participant_id::text, 'paid'],
    to_jsonb(p_paid),
    false
  )
  where gt.id = p_expense_id
    and gt.split_data ? p_participant_id::text;

  get diagnostics v_updated = row_count;
  perform set_config('splixa.skip_legacy_financial_sync', 'off', true);

  if v_updated <> 1 then
    raise exception 'Legacy compatibility share is missing';
  end if;
end;
$$;

create or replace function public.create_expense_v1(
  p_group_id uuid,
  p_payer_id uuid,
  p_description text,
  p_category text,
  p_notes text,
  p_expense_date date,
  p_split_type text,
  p_original_amount numeric,
  p_currency_code text,
  p_base_amount numeric,
  p_base_currency_code text,
  p_exchange_rate numeric,
  p_rate_source text,
  p_rate_locked_at timestamptz,
  p_shares jsonb
)
returns public.expenses
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_expense public.expenses%rowtype;
  v_expense_id uuid := gen_random_uuid();
  v_now timestamptz := now();
  v_currency_code text := upper(btrim(p_currency_code));
  v_base_currency_code text := upper(btrim(p_base_currency_code));
  v_split_data jsonb;
  v_share_count integer;
  v_distinct_participant_count integer;
  v_original_share_total numeric;
  v_base_share_total numeric;
  v_percentage_total numeric;
begin
  if v_actor_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_payer_id <> v_actor_id then
    raise exception 'The authenticated user must be the payer';
  end if;

  if not public.is_group_member(p_group_id, v_actor_id) then
    raise exception 'The payer is not a member of this group';
  end if;

  if p_description is null
     or length(btrim(p_description)) not between 1 and 500 then
    raise exception 'Description must contain 1 to 500 characters';
  end if;

  -- The legacy projection currently supports these three shapes. Additional
  -- normalized types are enabled only when all supported app versions can read
  -- them without relying on group_transactions.
  if p_split_type not in ('equal', 'percentage', 'exact') then
    raise exception 'Unsupported split type during compatibility phase: %',
      p_split_type;
  end if;

  if p_expense_date is null or p_rate_locked_at is null then
    raise exception 'Expense date and rate lock time are required';
  end if;

  if p_original_amount is null
     or p_base_amount is null
     or p_exchange_rate is null
     or p_original_amount <= 0
     or p_base_amount <= 0
     or p_exchange_rate <= 0 then
    raise exception 'Expense monetary values must be positive';
  end if;

  if v_currency_code !~ '^[A-Z0-9]{3,10}$'
     or v_base_currency_code !~ '^[A-Z0-9]{3,10}$' then
    raise exception 'Invalid currency code';
  end if;

  if p_rate_source is null
     or length(btrim(p_rate_source)) not between 1 and 100 then
    raise exception 'Invalid FX rate source';
  end if;

  if abs(p_base_amount - (p_original_amount * p_exchange_rate)) > 0.01 then
    raise exception 'Expense FX values are inconsistent';
  end if;

  if jsonb_typeof(p_shares) <> 'array'
     or jsonb_array_length(p_shares) = 0 then
    raise exception 'At least one expense share is required';
  end if;

  select
    count(*),
    count(distinct share.participant_id),
    sum(share.original_share_amount),
    sum(share.base_share_amount),
    sum(share.share_percentage)
  into
    v_share_count,
    v_distinct_participant_count,
    v_original_share_total,
    v_base_share_total,
    v_percentage_total
  from jsonb_to_recordset(p_shares) as share(
    participant_id uuid,
    original_share_amount numeric,
    base_share_amount numeric,
    share_percentage numeric,
    share_units numeric
  );

  if v_share_count <> v_distinct_participant_count then
    raise exception 'Each participant may appear only once';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_shares) as share(
      participant_id uuid,
      original_share_amount numeric,
      base_share_amount numeric,
      share_percentage numeric,
      share_units numeric
    )
    where share.participant_id is null
       or share.original_share_amount is null
       or share.base_share_amount is null
       or share.original_share_amount < 0
       or share.base_share_amount < 0
       or (share.share_percentage is not null
           and share.share_percentage not between 0 and 100)
       or (share.share_units is not null and share.share_units <= 0)
  ) then
    raise exception 'One or more expense shares are invalid';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_shares) as share(
      participant_id uuid,
      original_share_amount numeric,
      base_share_amount numeric,
      share_percentage numeric,
      share_units numeric
    )
    where not public.is_group_member(p_group_id, share.participant_id)
  ) then
    raise exception 'Every expense participant must be a group member';
  end if;

  if abs(v_original_share_total - p_original_amount) > 0.01
     or abs(v_base_share_total - p_base_amount) > 0.01 then
    raise exception 'Expense shares must add up to the expense totals';
  end if;

  if p_split_type = 'percentage'
     and (
       v_percentage_total is null
       or abs(v_percentage_total - 100) > 0.01
     ) then
    raise exception 'Percentage shares must add up to 100';
  end if;

  insert into public.expenses (
    id,
    group_id,
    created_by,
    payer_id,
    description,
    category,
    notes,
    expense_date,
    split_type,
    original_amount,
    currency_code,
    base_amount,
    base_currency_code,
    exchange_rate,
    rate_source,
    rate_locked_at,
    source,
    created_at,
    updated_at
  )
  values (
    v_expense_id,
    p_group_id,
    v_actor_id,
    p_payer_id,
    btrim(p_description),
    nullif(btrim(p_category), ''),
    nullif(btrim(p_notes), ''),
    p_expense_date,
    p_split_type::public.expense_split_type,
    p_original_amount,
    v_currency_code,
    p_base_amount,
    v_base_currency_code,
    p_exchange_rate,
    btrim(p_rate_source),
    p_rate_locked_at,
    'native_v1',
    v_now,
    v_now
  )
  returning * into v_expense;

  insert into public.expense_shares (
    expense_id,
    participant_id,
    original_share_amount,
    base_share_amount,
    share_percentage,
    share_units,
    status,
    status_updated_at,
    created_at,
    updated_at
  )
  select
    v_expense_id,
    share.participant_id,
    share.original_share_amount,
    share.base_share_amount,
    share.share_percentage,
    share.share_units,
    case
      when share.participant_id = p_payer_id
        then 'not_owed'::public.expense_share_status
      else 'pending'::public.expense_share_status
    end,
    v_now,
    v_now,
    v_now
  from jsonb_to_recordset(p_shares) as share(
    participant_id uuid,
    original_share_amount numeric,
    base_share_amount numeric,
    share_percentage numeric,
    share_units numeric
  );

  select jsonb_object_agg(
    share.participant_id::text,
    jsonb_build_object(
      'amount', share.base_share_amount,
      'paid', share.participant_id = p_payer_id,
      'status', case
        when share.participant_id = p_payer_id then 'approved'
        else 'pending'
      end
    )
  )
  into v_split_data
  from jsonb_to_recordset(p_shares) as share(
    participant_id uuid,
    original_share_amount numeric,
    base_share_amount numeric,
    share_percentage numeric,
    share_units numeric
  );

  perform set_config('splixa.skip_legacy_financial_sync', 'on', true);

  insert into public.group_transactions (
    id,
    group_id,
    payer_id,
    amount,
    description,
    split_type,
    split_data,
    status,
    created_at
  )
  values (
    v_expense_id,
    p_group_id,
    p_payer_id,
    p_base_amount,
    btrim(p_description),
    p_split_type,
    v_split_data,
    'pending',
    v_now
  );

  perform set_config('splixa.skip_legacy_financial_sync', 'off', true);

  insert into public.notifications (
    recipient_id,
    sender_id,
    group_id,
    expense_id,
    type,
    is_read
  )
  select
    share.participant_id,
    v_actor_id,
    p_group_id,
    v_expense_id,
    'debt_request',
    false
  from jsonb_to_recordset(p_shares) as share(
    participant_id uuid,
    original_share_amount numeric,
    base_share_amount numeric,
    share_percentage numeric,
    share_units numeric
  )
  where share.participant_id <> p_payer_id
    and share.base_share_amount > 0;

  return v_expense;
end;
$$;

create or replace function public.acknowledge_expense_share_v1(
  p_expense_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_expense public.expenses%rowtype;
  v_now timestamptz := now();
begin
  if v_actor_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_expense
  from public.expenses
  where id = p_expense_id
  for update;

  if not found then
    raise exception 'Expense not found';
  end if;

  if v_actor_id = v_expense.payer_id then
    raise exception 'The payer cannot acknowledge a debtor share';
  end if;

  update public.expense_shares
  set
    status = 'approved',
    status_updated_at = v_now,
    version = version + 1
  where expense_id = p_expense_id
    and participant_id = v_actor_id
    and status = 'pending';

  if not found then
    raise exception 'Only a pending participant share can be acknowledged';
  end if;

  perform public.splixa_set_legacy_share_state(
    p_expense_id,
    v_actor_id,
    'approved',
    false
  );

  update public.expenses set version = version + 1 where id = p_expense_id;

  insert into public.notifications (
    recipient_id, sender_id, group_id, expense_id, type, is_read
  ) values (
    v_expense.payer_id,
    v_actor_id,
    v_expense.group_id,
    p_expense_id,
    'debt_approved',
    false
  );
end;
$$;

create or replace function public.reject_expense_share_v1(
  p_expense_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_expense public.expenses%rowtype;
  v_now timestamptz := now();
begin
  if v_actor_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_expense
  from public.expenses
  where id = p_expense_id
  for update;

  if not found then
    raise exception 'Expense not found';
  end if;

  if v_actor_id = v_expense.payer_id then
    raise exception 'The payer cannot reject a debtor share';
  end if;

  update public.expense_shares
  set
    status = 'rejected',
    status_updated_at = v_now,
    version = version + 1
  where expense_id = p_expense_id
    and participant_id = v_actor_id
    and status = 'pending';

  if not found then
    raise exception 'Only a pending participant share can be rejected';
  end if;

  perform public.splixa_set_legacy_share_state(
    p_expense_id,
    v_actor_id,
    'rejected',
    false
  );

  update public.expenses set version = version + 1 where id = p_expense_id;

  insert into public.notifications (
    recipient_id, sender_id, group_id, expense_id, type, is_read
  ) values (
    v_expense.payer_id,
    v_actor_id,
    v_expense.group_id,
    p_expense_id,
    'debt_rejected',
    false
  );
end;
$$;

create or replace function public.mark_expense_payment_sent_v1(
  p_expense_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_expense public.expenses%rowtype;
  v_now timestamptz := now();
begin
  if v_actor_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_expense
  from public.expenses
  where id = p_expense_id
  for update;

  if not found then
    raise exception 'Expense not found';
  end if;

  if v_actor_id = v_expense.payer_id then
    raise exception 'The creditor cannot mark a debtor share as paid';
  end if;

  update public.expense_shares
  set
    status = 'payment_pending',
    status_updated_at = v_now,
    version = version + 1
  where expense_id = p_expense_id
    and participant_id = v_actor_id
    and status = 'approved';

  if not found then
    raise exception 'Only an approved share can be marked as paid';
  end if;

  perform public.splixa_set_legacy_share_state(
    p_expense_id,
    v_actor_id,
    'payment_pending',
    true
  );

  update public.expenses set version = version + 1 where id = p_expense_id;

  insert into public.notifications (
    recipient_id, sender_id, group_id, expense_id, type, is_read
  ) values (
    v_expense.payer_id,
    v_actor_id,
    v_expense.group_id,
    p_expense_id,
    'payment_confirmation',
    false
  );
end;
$$;

create or replace function public.confirm_expense_payment_v1(
  p_expense_id uuid,
  p_participant_id uuid
)
returns public.settlements
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_expense public.expenses%rowtype;
  v_share public.expense_shares%rowtype;
  v_settlement public.settlements%rowtype;
  v_now timestamptz := now();
begin
  if v_actor_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_expense
  from public.expenses
  where id = p_expense_id
  for update;

  if not found then
    raise exception 'Expense not found';
  end if;

  if v_actor_id <> v_expense.payer_id then
    raise exception 'Only the creditor can confirm payment';
  end if;

  if p_participant_id = v_expense.payer_id then
    raise exception 'The payer is not a debtor participant';
  end if;

  select * into v_share
  from public.expense_shares
  where expense_id = p_expense_id
    and participant_id = p_participant_id
  for update;

  if not found or v_share.status <> 'payment_pending' then
    raise exception 'Only a payment-pending share can be settled';
  end if;

  if v_share.base_share_amount <= 0 then
    raise exception 'A zero-value share cannot create a settlement';
  end if;

  update public.expense_shares
  set
    status = 'settled',
    status_updated_at = v_now,
    version = version + 1
  where expense_id = p_expense_id
    and participant_id = p_participant_id;

  insert into public.settlements (
    group_id,
    expense_id,
    created_by,
    paid_by,
    received_by,
    original_amount,
    currency_code,
    base_amount,
    base_currency_code,
    exchange_rate,
    rate_source,
    rate_locked_at,
    status,
    notes,
    paid_at,
    confirmed_at,
    source,
    created_at,
    updated_at
  ) values (
    v_expense.group_id,
    p_expense_id,
    v_actor_id,
    p_participant_id,
    v_expense.payer_id,
    v_share.original_share_amount,
    v_expense.currency_code,
    v_share.base_share_amount,
    v_expense.base_currency_code,
    v_expense.exchange_rate,
    v_expense.rate_source,
    v_expense.rate_locked_at,
    'settled',
    'Confirmed through normalized expense-share workflow.',
    v_now,
    v_now,
    'native_v1',
    v_now,
    v_now
  )
  returning * into v_settlement;

  perform public.splixa_set_legacy_share_state(
    p_expense_id,
    p_participant_id,
    'settled',
    true
  );

  update public.expenses set version = version + 1 where id = p_expense_id;

  insert into public.notifications (
    recipient_id, sender_id, group_id, expense_id, type, is_read
  ) values (
    p_participant_id,
    v_actor_id,
    v_expense.group_id,
    p_expense_id,
    'debt_settled',
    false
  );

  return v_settlement;
end;
$$;

create or replace function public.archive_expense_v1(p_expense_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_expense public.expenses%rowtype;
  v_now timestamptz := now();
  v_updated integer;
begin
  if v_actor_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_expense
  from public.expenses
  where id = p_expense_id
  for update;

  if not found then
    raise exception 'Expense not found';
  end if;

  if v_actor_id <> v_expense.payer_id then
    raise exception 'Only the payer can archive an expense';
  end if;

  if exists (
    select 1
    from public.expense_shares es
    where es.expense_id = p_expense_id
      and es.participant_id <> v_expense.payer_id
      and es.status <> 'settled'
  ) then
    raise exception 'Every non-payer share must be settled before archiving';
  end if;

  update public.expenses
  set archived_at = v_now, version = version + 1
  where id = p_expense_id
    and archived_at is null;

  get diagnostics v_updated = row_count;
  if v_updated <> 1 then
    raise exception 'Expense is already archived';
  end if;

  perform set_config('splixa.skip_legacy_financial_sync', 'on', true);
  update public.group_transactions
  set archived_at = v_now
  where id = p_expense_id;
  get diagnostics v_updated = row_count;
  perform set_config('splixa.skip_legacy_financial_sync', 'off', true);

  if v_updated <> 1 then
    raise exception 'Legacy compatibility expense is missing';
  end if;
end;
$$;

-- Client roles may invoke the guarded RPCs, but still cannot write the tables.
revoke all on function public.splixa_set_legacy_share_state(uuid, uuid, text, boolean)
  from public, anon, authenticated;

revoke all on function public.create_expense_v1(
  uuid, uuid, text, text, text, date, text, numeric, text, numeric, text,
  numeric, text, timestamptz, jsonb
) from public, anon, authenticated;
grant execute on function public.create_expense_v1(
  uuid, uuid, text, text, text, date, text, numeric, text, numeric, text,
  numeric, text, timestamptz, jsonb
) to authenticated, service_role;

revoke all on function public.acknowledge_expense_share_v1(uuid)
  from public, anon, authenticated;
grant execute on function public.acknowledge_expense_share_v1(uuid)
  to authenticated, service_role;

revoke all on function public.reject_expense_share_v1(uuid)
  from public, anon, authenticated;
grant execute on function public.reject_expense_share_v1(uuid)
  to authenticated, service_role;

revoke all on function public.mark_expense_payment_sent_v1(uuid)
  from public, anon, authenticated;
grant execute on function public.mark_expense_payment_sent_v1(uuid)
  to authenticated, service_role;

revoke all on function public.confirm_expense_payment_v1(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.confirm_expense_payment_v1(uuid, uuid)
  to authenticated, service_role;

revoke all on function public.archive_expense_v1(uuid)
  from public, anon, authenticated;
grant execute on function public.archive_expense_v1(uuid)
  to authenticated, service_role;

-- Realtime is needed for normalized expense/share changes. Views are refreshed
-- explicitly because PostgreSQL publications do not publish views.
do $$
begin
  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) then
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'expenses'
    ) then
      alter publication supabase_realtime add table public.expenses;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'expense_shares'
    ) then
      alter publication supabase_realtime add table public.expense_shares;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'settlements'
    ) then
      alter publication supabase_realtime add table public.settlements;
    end if;
  end if;
end
$$;

commit;
