-- Recurring expenses were only ever materialised by the hourly cron, so a
-- template created at 14:05 produced nothing until 15:00 -- and one created
-- before its own 09:00 anchor waited until the next day. The balance is derived
-- from `transactions`, so until that row existed the expense simply did not
-- exist to the user. This makes creation emit its first occurrence inline when
-- the start moment has already passed, and moves the "what is one occurrence"
-- logic into a single function both paths call.

-- Shared occurrence writer. Not user-callable: it trusts the template row it is
-- given and performs no ownership check, so the two callers below are
-- responsible for authorising first.
create or replace function public.emit_recurring_occurrence_v1(
  p_template_id uuid,
  p_rate numeric,
  p_rate_source text,
  p_rate_locked_at timestamptz
) returns uuid
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_t public.recurring_expense_templates%rowtype;
  v_tx uuid;
  v_base numeric;
  v_next_local timestamp;
begin
  select * into v_t
  from public.recurring_expense_templates
  where id = p_template_id
  for update;
  if not found then
    return null;
  end if;

  if p_rate is null or p_rate <= 0 then
    raise exception 'INVALID_RATE';
  end if;

  v_base := round(v_t.original_amount * p_rate, 2);

  -- (template_id, due_at) is the primary key, so a second attempt at the same
  -- occurrence inserts nothing and FOUND stays false. That is what makes the
  -- inline path and the cron path safe to both fire for one due moment.
  insert into public.recurring_expense_runs (template_id, due_at)
  values (v_t.id, v_t.next_run_at)
  on conflict do nothing;

  if found then
    insert into public.transactions (
      user_id, group_id, amount, original_amount, currency_code,
      base_amount, base_currency_code, exchange_rate, rate_source,
      rate_locked_at, category, date, type
    ) values (
      v_t.user_id, null, v_base,
      v_t.original_amount, v_t.currency_code,
      v_base, v_t.base_currency_code,
      p_rate, p_rate_source,
      coalesce(p_rate_locked_at, now()),
      v_t.category,
      (v_t.next_run_at at time zone v_t.timezone)::date,
      'expense'
    ) returning id into v_tx;

    update public.recurring_expense_runs
    set transaction_id = v_tx
    where template_id = v_t.id
      and due_at = v_t.next_run_at;
  end if;

  -- Advance from the due moment, not from now(): a run that fires late must not
  -- drag the whole schedule later with it.
  v_next_local := v_t.next_run_at at time zone v_t.timezone;
  v_next_local := case v_t.frequency
    when 'weekly' then v_next_local + make_interval(weeks => v_t.interval_count)
    else v_next_local + make_interval(months => v_t.interval_count)
  end;

  update public.recurring_expense_templates
  set next_run_at = v_next_local at time zone v_t.timezone,
      updated_at = timezone('utc', now())
  where id = v_t.id;

  return v_tx;
end;
$$;

revoke all on function public.emit_recurring_occurrence_v1(uuid, numeric, text, timestamptz) from public;
revoke all on function public.emit_recurring_occurrence_v1(uuid, numeric, text, timestamptz) from anon, authenticated;

-- User-facing creation. Replaces the client's direct INSERT so that the
-- template and its first expense are one atomic act, and so that the amounts
-- and ownership are decided server-side rather than trusted from the client.
create or replace function public.create_recurring_expense_v1(
  p_title text,
  p_category text,
  p_original_amount numeric,
  p_currency_code text,
  p_exchange_rate numeric,
  p_rate_source text,
  p_rate_locked_at timestamptz,
  p_frequency text,
  p_timezone text,
  p_next_run_at timestamptz
) returns public.recurring_expense_templates
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_user uuid := auth.uid();
  v_id uuid;
  v_row public.recurring_expense_templates%rowtype;
  v_rate numeric;
  v_source text;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED';
  end if;
  if not public.has_active_pro_entitlement(v_user) then
    raise exception 'PRO_REQUIRED';
  end if;
  if p_title is null or length(btrim(p_title)) not between 1 and 120 then
    raise exception 'INVALID_TITLE';
  end if;
  if p_category is null or length(btrim(p_category)) not between 1 and 60 then
    raise exception 'INVALID_CATEGORY';
  end if;
  if p_original_amount is null
     or p_original_amount <= 0
     or p_original_amount > 1000000000 then
    raise exception 'INVALID_AMOUNT';
  end if;
  if p_currency_code is null or p_currency_code !~ '^[A-Z]{3}$' then
    raise exception 'INVALID_CURRENCY';
  end if;
  if p_frequency is null or p_frequency not in ('weekly', 'monthly') then
    raise exception 'INVALID_FREQUENCY';
  end if;
  if p_timezone is null
     or not exists (select 1 from pg_catalog.pg_timezone_names z where z.name = p_timezone) then
    raise exception 'INVALID_TIMEZONE';
  end if;
  if p_next_run_at is null
     or p_next_run_at < now() - interval '2 days'
     or p_next_run_at > now() + interval '400 days' then
    raise exception 'INVALID_START';
  end if;

  -- TRY against TRY is always 1:1 whatever the client computed; anything else
  -- keeps the rate the client locked at the moment the user confirmed, so the
  -- first charge matches the figure they were shown.
  if p_currency_code = 'TRY' then
    v_rate := 1;
    v_source := 'recurring:identity';
  else
    if p_exchange_rate is null or p_exchange_rate <= 0 then
      raise exception 'INVALID_RATE';
    end if;
    if p_rate_source is null
       or length(btrim(p_rate_source)) not between 1 and 80 then
      raise exception 'INVALID_RATE_SOURCE';
    end if;
    v_rate := p_exchange_rate;
    v_source := 'recurring:' || btrim(p_rate_source);
  end if;

  insert into public.recurring_expense_templates (
    user_id, title, category, original_amount, currency_code,
    base_amount, base_currency_code, exchange_rate, rate_source,
    rate_locked_at, frequency, interval_count, timezone, next_run_at
  ) values (
    v_user, btrim(p_title), btrim(p_category), p_original_amount, p_currency_code,
    round(p_original_amount * v_rate, 2), 'TRY', v_rate,
    case when p_currency_code = 'TRY' then 'identity' else btrim(p_rate_source) end,
    coalesce(p_rate_locked_at, now()), p_frequency, 1, p_timezone, p_next_run_at
  ) returning id into v_id;

  -- The whole point of this function: if the start moment has already passed,
  -- the expense lands now rather than at the next hourly tick.
  if p_next_run_at <= now() then
    perform public.emit_recurring_occurrence_v1(
      v_id, v_rate, v_source, coalesce(p_rate_locked_at, now())
    );
  end if;

  select * into v_row from public.recurring_expense_templates where id = v_id;
  return v_row;
end;
$$;

revoke all on function public.create_recurring_expense_v1(text, text, numeric, text, numeric, text, timestamptz, text, text, timestamptz) from public;
grant execute on function public.create_recurring_expense_v1(text, text, numeric, text, numeric, text, timestamptz, text, text, timestamptz) to authenticated;

-- The scheduled job now delegates the write, so "one occurrence" has exactly
-- one definition. Its own responsibilities are unchanged: pick due templates,
-- pause the ones that lost Pro, resolve the FX rate for the run.
create or replace function public.generate_due_recurring_expenses_v1(
  p_usd_per_try numeric default null,
  p_eur_per_try numeric default null,
  p_rate_locked_at timestamptz default null,
  p_rate_source text default 'scheduled_open_er_api',
  p_limit integer default 200
) returns integer
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_template public.recurring_expense_templates%rowtype;
  v_generated integer := 0;
  v_run_rate numeric;
  v_run_rate_source text;
  v_run_rate_locked_at timestamptz;
  v_tx uuid;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if p_limit not between 1 and 1000 then
    raise exception 'INVALID_LIMIT';
  end if;
  if p_rate_source is null
     or length(btrim(p_rate_source)) not between 1 and 80 then
    raise exception 'INVALID_RATE_SOURCE';
  end if;

  update public.recurring_expense_templates r
  set is_active = false, updated_at = timezone('utc', now())
  where r.is_active
    and r.next_run_at <= now()
    and not public.has_active_pro_entitlement(r.user_id);

  for v_template in
    select r.*
    from public.recurring_expense_templates r
    where r.is_active
      and r.next_run_at <= now()
      and public.has_active_pro_entitlement(r.user_id)
    order by r.next_run_at
    limit p_limit
    for update skip locked
  loop
    if v_template.currency_code = v_template.base_currency_code then
      v_run_rate := 1;
      v_run_rate_source := 'recurring:identity';
      v_run_rate_locked_at := coalesce(p_rate_locked_at, now());
    elsif v_template.rate_source = 'manual_user_locked' then
      v_run_rate := v_template.exchange_rate;
      v_run_rate_source := 'recurring:manual_user_locked';
      v_run_rate_locked_at := v_template.rate_locked_at;
    elsif v_template.currency_code = 'USD'
          and p_usd_per_try is not null and p_usd_per_try > 0 then
      v_run_rate := 1 / p_usd_per_try;
      v_run_rate_source := 'recurring:' || btrim(p_rate_source);
      v_run_rate_locked_at := coalesce(p_rate_locked_at, now());
    elsif v_template.currency_code = 'EUR'
          and p_eur_per_try is not null and p_eur_per_try > 0 then
      v_run_rate := 1 / p_eur_per_try;
      v_run_rate_source := 'recurring:' || btrim(p_rate_source);
      v_run_rate_locked_at := coalesce(p_rate_locked_at, now());
    else
      -- Leave this occurrence due so a later healthy run can retry it.
      continue;
    end if;

    v_tx := public.emit_recurring_occurrence_v1(
      v_template.id, v_run_rate, v_run_rate_source, v_run_rate_locked_at
    );
    if v_tx is not null then
      v_generated := v_generated + 1;
    end if;
  end loop;

  return v_generated;
end;
$$;
