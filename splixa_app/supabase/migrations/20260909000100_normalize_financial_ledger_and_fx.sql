-- Phase 0 / Task 1: normalize Splixa's financial ledger and lock FX facts.
--
-- Deployment model (expand -> migrate -> verify -> later contract):
--   * The legacy Flutter client remains authoritative during the transition.
--   * Existing group_transactions rows are backfilled into expenses/shares.
--   * Compatibility triggers mirror subsequent legacy writes.
--   * New tables are read-only to authenticated clients until atomic mutation
--     RPCs and the Flutter client are shipped in the next task.
--   * No historical source currency is guessed. Legacy values that were already
--     converted to TRY are represented as TRY/TRY at rate 1 and are explicitly
--     labelled legacy_try_canonical.

begin;

-- Fail early if this migration is accidentally run against a different schema.
do $$
begin
  if to_regclass('public.groups') is null
     or to_regclass('public.group_transactions') is null
     or to_regclass('public.transactions') is null then
    raise exception
      'Splixa financial migration requires public.groups, public.group_transactions, and public.transactions';
  end if;
end
$$;

-- Currency identifiers intentionally allow crypto codes such as USDT.
-- exchange_rate convention throughout this migration:
--   1 original currency unit = exchange_rate base currency units
--   base_amount ~= original_amount * exchange_rate

do $$
begin
  create type public.expense_split_type as enum (
    'equal',
    'percentage',
    'exact',
    'shares',
    'itemized'
  );
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.expense_share_status as enum (
    'not_owed',
    'pending',
    'approved',
    'payment_pending',
    'settled',
    'rejected'
  );
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.settlement_status as enum (
    'proposed',
    'payment_pending',
    'settled',
    'rejected',
    'cancelled'
  );
exception
  when duplicate_object then null;
end
$$;

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,

  -- Deliberately not foreign-keyed to auth.users. Financial history must remain
  -- readable after a future GDPR/account-deletion flow anonymizes a user.
  created_by uuid not null,
  payer_id uuid not null,

  description text not null check (length(btrim(description)) between 1 and 500),
  category text,
  notes text,
  expense_date date not null default current_date,
  split_type public.expense_split_type not null,

  original_amount numeric(20, 8) not null check (original_amount > 0),
  currency_code text not null
    check (currency_code ~ '^[A-Z0-9]{3,10}$'),
  base_amount numeric(20, 8) not null check (base_amount > 0),
  base_currency_code text not null default 'TRY'
    check (base_currency_code ~ '^[A-Z0-9]{3,10}$'),
  exchange_rate numeric(24, 12) not null check (exchange_rate > 0),
  rate_source text not null check (length(btrim(rate_source)) between 1 and 100),
  rate_locked_at timestamptz not null,

  source text not null default 'native_v1'
    check (source in ('native_v1', 'legacy_group_transactions')),
  archived_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  version integer not null default 1 check (version > 0),

  constraint expenses_fx_math_check check (
    abs(base_amount - (original_amount * exchange_rate)) <= 0.01000000
  )
);

comment on table public.expenses is
  'Immutable monetary facts for group expenses; workflow state lives on expense_shares.';
comment on column public.expenses.exchange_rate is
  'Base-currency units per one original-currency unit, locked when the expense is created.';
comment on column public.expenses.rate_source is
  'Provider/manual provenance. legacy_try_canonical means the original FX fact was unavailable.';

create table public.expense_shares (
  expense_id uuid not null references public.expenses(id) on delete cascade,
  participant_id uuid not null,

  original_share_amount numeric(20, 8) not null
    check (original_share_amount >= 0),
  base_share_amount numeric(20, 8) not null
    check (base_share_amount >= 0),
  share_percentage numeric(9, 6)
    check (share_percentage is null or share_percentage between 0 and 100),
  share_units numeric(20, 8)
    check (share_units is null or share_units > 0),

  status public.expense_share_status not null default 'pending',
  status_updated_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  version integer not null default 1 check (version > 0),

  primary key (expense_id, participant_id)
);

comment on table public.expense_shares is
  'One relational obligation/workflow row per expense participant. No JSONB financial state.';

create table public.settlements (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  expense_id uuid references public.expenses(id) on delete set null,

  created_by uuid not null,
  paid_by uuid not null,
  received_by uuid not null,

  original_amount numeric(20, 8) not null check (original_amount > 0),
  currency_code text not null
    check (currency_code ~ '^[A-Z0-9]{3,10}$'),
  base_amount numeric(20, 8) not null check (base_amount > 0),
  base_currency_code text not null default 'TRY'
    check (base_currency_code ~ '^[A-Z0-9]{3,10}$'),
  exchange_rate numeric(24, 12) not null check (exchange_rate > 0),
  rate_source text not null check (length(btrim(rate_source)) between 1 and 100),
  rate_locked_at timestamptz not null,

  status public.settlement_status not null default 'proposed',
  notes text,
  paid_at timestamptz,
  confirmed_at timestamptz,
  source text not null default 'native_v1'
    check (source in ('native_v1', 'legacy_settled_share')),

  -- Populated only by the compatibility bridge. It makes a legacy settled
  -- share idempotent without restricting future partial/native settlements.
  legacy_migration_key text unique,

  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  version integer not null default 1 check (version > 0),

  constraint settlements_parties_differ_check check (paid_by <> received_by),
  constraint settlements_fx_math_check check (
    abs(base_amount - (original_amount * exchange_rate)) <= 0.01000000
  ),
  constraint settlements_confirmation_check check (
    status <> 'settled' or confirmed_at is not null
  ),
  constraint settlements_legacy_key_check check (
    (source = 'legacy_settled_share' and legacy_migration_key is not null)
    or (source = 'native_v1' and legacy_migration_key is null)
  )
);

comment on table public.settlements is
  'Cash/value transfers. Expenses create obligations; settled settlements offset those obligations.';

create index expenses_group_date_idx
  on public.expenses (group_id, expense_date desc, created_at desc);
create index expenses_payer_idx
  on public.expenses (payer_id, created_at desc);
create index expense_shares_participant_status_idx
  on public.expense_shares (participant_id, status, expense_id);
create index expense_shares_expense_status_idx
  on public.expense_shares (expense_id, status);
create index settlements_group_status_created_idx
  on public.settlements (group_id, status, created_at desc);
create index settlements_paid_by_idx
  on public.settlements (paid_by, created_at desc);
create index settlements_received_by_idx
  on public.settlements (received_by, created_at desc);
create index settlements_expense_idx
  on public.settlements (expense_id)
  where expense_id is not null;

create or replace function public.set_financial_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

create trigger expenses_set_updated_at
before update on public.expenses
for each row execute function public.set_financial_updated_at();

create trigger expense_shares_set_updated_at
before update on public.expense_shares
for each row execute function public.set_financial_updated_at();

create trigger settlements_set_updated_at
before update on public.settlements
for each row execute function public.set_financial_updated_at();

revoke all on function public.set_financial_updated_at()
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Legacy JSONB decoding helpers
-- ---------------------------------------------------------------------------

create or replace function public.splixa_legacy_share_amount(p_payload jsonb)
returns numeric
language plpgsql
immutable
set search_path = ''
as $$
begin
  if jsonb_typeof(p_payload) = 'object' then
    return nullif(p_payload ->> 'amount', '')::numeric;
  elsif jsonb_typeof(p_payload) = 'number' then
    return (p_payload #>> '{}')::numeric;
  end if;

  return null;
exception
  when invalid_text_representation or numeric_value_out_of_range then
    return null;
end;
$$;

create or replace function public.splixa_legacy_share_status(
  p_payload jsonb,
  p_participant_id uuid,
  p_payer_id uuid
)
returns public.expense_share_status
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_status text;
begin
  if p_participant_id = p_payer_id then
    return 'not_owed'::public.expense_share_status;
  end if;

  if jsonb_typeof(p_payload) = 'object' then
    v_status := lower(nullif(p_payload ->> 'status', ''));
  end if;

  -- This is deliberately identical to the current Dart compatibility rule:
  -- rows without a status remain financially active.
  v_status := coalesce(v_status, 'approved');

  return case v_status
    when 'pending' then 'pending'::public.expense_share_status
    when 'approved' then 'approved'::public.expense_share_status
    when 'payment_pending' then 'payment_pending'::public.expense_share_status
    when 'settled' then 'settled'::public.expense_share_status
    when 'rejected' then 'rejected'::public.expense_share_status
    else null
  end;
end;
$$;

revoke all on function public.splixa_legacy_share_amount(jsonb)
  from public, anon, authenticated;
revoke all on function public.splixa_legacy_share_status(jsonb, uuid, uuid)
  from public, anon, authenticated;

-- Abort before writing any migrated rows if legacy data cannot be represented
-- without guessing. Fix the reported rows first, then rerun the migration.
do $$
begin
  if exists (
    select 1
    from public.group_transactions gt
    where gt.group_id is null
       or gt.payer_id is null
       or gt.amount is null
       or gt.amount::numeric <= 0
       or gt.description is null
       or length(btrim(gt.description)) not between 1 and 500
       or gt.split_type is null
       or lower(gt.split_type) not in ('equal', 'percentage', 'exact')
       or jsonb_typeof(coalesce(gt.split_data, '{}'::jsonb)) <> 'object'
  ) then
    raise exception
      'Legacy group_transactions contain invalid required fields, split types, or non-object split_data';
  end if;

  if exists (
    select 1
    from public.group_transactions gt
    cross join lateral jsonb_each(coalesce(gt.split_data, '{}'::jsonb)) entry
    where entry.key !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  ) then
    raise exception 'Legacy split_data contains a participant key that is not a UUID';
  end if;

  if exists (
    select 1
    from public.group_transactions gt
    cross join lateral jsonb_each(coalesce(gt.split_data, '{}'::jsonb)) entry
    where public.splixa_legacy_share_amount(entry.value) is null
       or public.splixa_legacy_share_amount(entry.value) < 0
       or public.splixa_legacy_share_status(
            entry.value,
            entry.key::uuid,
            gt.payer_id
          ) is null
  ) then
    raise exception 'Legacy split_data contains an invalid amount or unknown status';
  end if;

  if exists (
    select 1
    from public.transactions t
    where t.amount is null or t.amount::numeric < 0
  ) then
    raise exception 'Legacy personal transactions contain a null or negative amount';
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- Backfill group expenses, shares, and synthetic legacy settlement facts
-- ---------------------------------------------------------------------------

insert into public.expenses (
  id,
  group_id,
  created_by,
  payer_id,
  description,
  category,
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
  archived_at,
  created_at,
  updated_at
)
select
  gt.id,
  gt.group_id,
  gt.payer_id,
  gt.payer_id,
  gt.description,
  'uncategorized',
  timezone('utc', coalesce(gt.created_at, timezone('utc', now())))::date,
  lower(gt.split_type)::public.expense_split_type,
  gt.amount::numeric(20, 8),
  'TRY',
  gt.amount::numeric(20, 8),
  'TRY',
  1::numeric(24, 12),
  'legacy_try_canonical',
  coalesce(gt.created_at, timezone('utc', now())),
  'legacy_group_transactions',
  gt.archived_at,
  coalesce(gt.created_at, timezone('utc', now())),
  coalesce(gt.created_at, timezone('utc', now()))
from public.group_transactions gt;

insert into public.expense_shares (
  expense_id,
  participant_id,
  original_share_amount,
  base_share_amount,
  share_percentage,
  status,
  status_updated_at,
  created_at,
  updated_at
)
select
  gt.id,
  entry.key::uuid,
  public.splixa_legacy_share_amount(entry.value)::numeric(20, 8),
  public.splixa_legacy_share_amount(entry.value)::numeric(20, 8),
  case
    when lower(gt.split_type) = 'percentage' and gt.amount::numeric > 0
      then round(
        (public.splixa_legacy_share_amount(entry.value) / gt.amount::numeric) * 100,
        6
      )
    else null
  end,
  public.splixa_legacy_share_status(entry.value, entry.key::uuid, gt.payer_id),
  coalesce(gt.created_at, timezone('utc', now())),
  coalesce(gt.created_at, timezone('utc', now())),
  coalesce(gt.created_at, timezone('utc', now()))
from public.group_transactions gt
cross join lateral jsonb_each(coalesce(gt.split_data, '{}'::jsonb)) entry;

-- Current Splixa removes a share from net balances when its JSON status becomes
-- settled. The normalized ledger instead retains the expense obligation and
-- offsets it with a settlement. Because legacy data has no payment timestamp,
-- created_at is used only as an explicit, documented proxy.
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
  legacy_migration_key,
  created_at,
  updated_at
)
select
  gt.group_id,
  gt.id,
  gt.payer_id,
  entry.key::uuid,
  gt.payer_id,
  public.splixa_legacy_share_amount(entry.value)::numeric(20, 8),
  'TRY',
  public.splixa_legacy_share_amount(entry.value)::numeric(20, 8),
  'TRY',
  1::numeric(24, 12),
  'legacy_try_canonical',
  coalesce(gt.created_at, timezone('utc', now())),
  'settled',
  'Derived from legacy split_data status; original payment timestamp was not stored.',
  coalesce(gt.created_at, timezone('utc', now())),
  coalesce(gt.created_at, timezone('utc', now())),
  'legacy_settled_share',
  'group_transaction:' || gt.id::text || ':participant:' || entry.key,
  coalesce(gt.created_at, timezone('utc', now())),
  coalesce(gt.created_at, timezone('utc', now()))
from public.group_transactions gt
cross join lateral jsonb_each(coalesce(gt.split_data, '{}'::jsonb)) entry
where entry.key::uuid <> gt.payer_id
  and public.splixa_legacy_share_amount(entry.value) > 0
  and public.splixa_legacy_share_status(
        entry.value,
        entry.key::uuid,
        gt.payer_id
      ) = 'settled';

-- ---------------------------------------------------------------------------
-- Personal transactions: add locked FX facts without breaking old clients
-- ---------------------------------------------------------------------------

alter table public.transactions
  add column if not exists original_amount numeric(20, 8),
  add column if not exists currency_code text,
  add column if not exists base_amount numeric(20, 8),
  add column if not exists base_currency_code text,
  add column if not exists exchange_rate numeric(24, 12),
  add column if not exists rate_source text,
  add column if not exists rate_locked_at timestamptz;

update public.transactions t
set
  original_amount = coalesce(t.original_amount, t.amount::numeric(20, 8)),
  currency_code = coalesce(t.currency_code, 'TRY'),
  base_amount = coalesce(t.base_amount, t.amount::numeric(20, 8)),
  base_currency_code = coalesce(t.base_currency_code, 'TRY'),
  exchange_rate = coalesce(t.exchange_rate, 1::numeric(24, 12)),
  rate_source = coalesce(t.rate_source, 'legacy_try_canonical'),
  rate_locked_at = coalesce(
    t.rate_locked_at,
    t.created_at,
    t.date::timestamptz,
    timezone('utc', now())
  );

alter table public.transactions
  alter column original_amount set not null,
  alter column currency_code set not null,
  alter column base_amount set not null,
  alter column base_currency_code set not null,
  alter column exchange_rate set not null,
  alter column rate_source set not null,
  alter column rate_locked_at set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.transactions'::regclass
      and conname = 'transactions_original_amount_check'
  ) then
    alter table public.transactions
      add constraint transactions_original_amount_check
      check (original_amount >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.transactions'::regclass
      and conname = 'transactions_base_amount_check'
  ) then
    alter table public.transactions
      add constraint transactions_base_amount_check
      check (base_amount >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.transactions'::regclass
      and conname = 'transactions_currency_code_check'
  ) then
    alter table public.transactions
      add constraint transactions_currency_code_check
      check (
        currency_code ~ '^[A-Z0-9]{3,10}$'
        and base_currency_code ~ '^[A-Z0-9]{3,10}$'
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.transactions'::regclass
      and conname = 'transactions_exchange_rate_check'
  ) then
    alter table public.transactions
      add constraint transactions_exchange_rate_check
      check (
        exchange_rate > 0
        and abs(base_amount - (original_amount * exchange_rate)) <= 0.01000000
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.transactions'::regclass
      and conname = 'transactions_rate_source_check'
  ) then
    alter table public.transactions
      add constraint transactions_rate_source_check
      check (length(btrim(rate_source)) between 1 and 100);
  end if;
end
$$;

create or replace function public.splixa_fill_transaction_fx_compat()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_is_legacy_write boolean;
begin
  if tg_op = 'INSERT' then
    v_is_legacy_write := new.original_amount is null
      or new.currency_code is null
      or new.base_amount is null
      or new.base_currency_code is null
      or new.exchange_rate is null
      or new.rate_source is null
      or new.rate_locked_at is null;
  else
    -- An old app only changes amount. A new client changes the normalized FX
    -- columns and amount is maintained as the temporary base-amount alias.
    v_is_legacy_write := new.amount is distinct from old.amount
      and new.original_amount is not distinct from old.original_amount
      and new.currency_code is not distinct from old.currency_code
      and new.base_amount is not distinct from old.base_amount
      and new.base_currency_code is not distinct from old.base_currency_code
      and new.exchange_rate is not distinct from old.exchange_rate
      and new.rate_source is not distinct from old.rate_source
      and new.rate_locked_at is not distinct from old.rate_locked_at;
  end if;

  if v_is_legacy_write then
    new.original_amount := new.amount::numeric(20, 8);
    new.currency_code := 'TRY';
    new.base_amount := new.amount::numeric(20, 8);
    new.base_currency_code := 'TRY';
    new.exchange_rate := 1::numeric(24, 12);
    new.rate_source := 'legacy_try_canonical';
    new.rate_locked_at := coalesce(new.created_at, new.date::timestamptz, timezone('utc', now()));
  else
    -- Keep the legacy amount column readable during the staged app rollout.
    new.amount := new.base_amount;
  end if;

  return new;
end;
$$;

create trigger transactions_fill_fx_compat
before insert or update on public.transactions
for each row execute function public.splixa_fill_transaction_fx_compat();

revoke all on function public.splixa_fill_transaction_fx_compat()
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Compatibility bridge: mirror future writes from still-deployed old clients
-- ---------------------------------------------------------------------------

create or replace function public.splixa_sync_legacy_group_transaction()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := timezone('utc', now());
begin
  if jsonb_typeof(coalesce(new.split_data, '{}'::jsonb)) <> 'object' then
    raise exception 'split_data must be a JSON object';
  end if;

  if new.group_id is null or new.payer_id is null then
    raise exception 'Legacy group transaction requires a group and payer';
  end if;

  if new.amount is null or new.amount::numeric <= 0 then
    raise exception 'Legacy group transaction amount must be positive';
  end if;

  if new.split_type is null
     or lower(new.split_type) not in ('equal', 'percentage', 'exact') then
    raise exception 'Unsupported legacy split type: %', new.split_type;
  end if;

  if exists (
    select 1
    from jsonb_each(coalesce(new.split_data, '{}'::jsonb)) entry
    where entry.key !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
       or public.splixa_legacy_share_amount(entry.value) is null
       or public.splixa_legacy_share_amount(entry.value) < 0
       or public.splixa_legacy_share_status(
            entry.value,
            entry.key::uuid,
            new.payer_id
          ) is null
  ) then
    raise exception 'Invalid legacy split_data participant, amount, or status';
  end if;

  insert into public.expenses as e (
    id,
    group_id,
    created_by,
    payer_id,
    description,
    category,
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
    archived_at,
    created_at,
    updated_at
  )
  values (
    new.id,
    new.group_id,
    new.payer_id,
    new.payer_id,
    new.description,
    'uncategorized',
    timezone('utc', coalesce(new.created_at, v_now))::date,
    lower(new.split_type)::public.expense_split_type,
    new.amount::numeric(20, 8),
    'TRY',
    new.amount::numeric(20, 8),
    'TRY',
    1::numeric(24, 12),
    'legacy_try_canonical',
    coalesce(new.created_at, v_now),
    'legacy_group_transactions',
    new.archived_at,
    coalesce(new.created_at, v_now),
    v_now
  )
  on conflict (id) do update
  set
    group_id = excluded.group_id,
    payer_id = excluded.payer_id,
    description = excluded.description,
    expense_date = excluded.expense_date,
    split_type = excluded.split_type,
    original_amount = excluded.original_amount,
    currency_code = excluded.currency_code,
    base_amount = excluded.base_amount,
    base_currency_code = excluded.base_currency_code,
    exchange_rate = excluded.exchange_rate,
    rate_source = excluded.rate_source,
    rate_locked_at = excluded.rate_locked_at,
    archived_at = excluded.archived_at,
    version = e.version + 1;

  -- Remove participants that an old client removed from split_data.
  delete from public.expense_shares es
  where es.expense_id = new.id
    and not exists (
      select 1
      from jsonb_each(coalesce(new.split_data, '{}'::jsonb)) entry
      where entry.key::uuid = es.participant_id
    );

  insert into public.expense_shares as es (
    expense_id,
    participant_id,
    original_share_amount,
    base_share_amount,
    share_percentage,
    status,
    status_updated_at,
    created_at,
    updated_at
  )
  select
    new.id,
    entry.key::uuid,
    public.splixa_legacy_share_amount(entry.value)::numeric(20, 8),
    public.splixa_legacy_share_amount(entry.value)::numeric(20, 8),
    case
      when lower(new.split_type) = 'percentage' and new.amount::numeric > 0
        then round(
          (public.splixa_legacy_share_amount(entry.value) / new.amount::numeric) * 100,
          6
        )
      else null
    end,
    public.splixa_legacy_share_status(entry.value, entry.key::uuid, new.payer_id),
    v_now,
    coalesce(new.created_at, v_now),
    v_now
  from jsonb_each(coalesce(new.split_data, '{}'::jsonb)) entry
  on conflict (expense_id, participant_id) do update
  set
    original_share_amount = excluded.original_share_amount,
    base_share_amount = excluded.base_share_amount,
    share_percentage = excluded.share_percentage,
    status = excluded.status,
    status_updated_at = case
      when es.status is distinct from excluded.status then excluded.status_updated_at
      else es.status_updated_at
    end,
    version = es.version + 1;

  -- Keep only settlements represented by the current legacy JSON state.
  delete from public.settlements s
  where s.source = 'legacy_settled_share'
    and s.expense_id = new.id
    and not exists (
      select 1
      from jsonb_each(coalesce(new.split_data, '{}'::jsonb)) entry
      where entry.key::uuid <> new.payer_id
        and public.splixa_legacy_share_amount(entry.value) > 0
        and public.splixa_legacy_share_status(
              entry.value,
              entry.key::uuid,
              new.payer_id
            ) = 'settled'
        and s.legacy_migration_key =
          'group_transaction:' || new.id::text || ':participant:' || entry.key
    );

  insert into public.settlements as s (
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
    legacy_migration_key,
    created_at,
    updated_at
  )
  select
    new.group_id,
    new.id,
    coalesce(auth.uid(), new.payer_id),
    entry.key::uuid,
    new.payer_id,
    public.splixa_legacy_share_amount(entry.value)::numeric(20, 8),
    'TRY',
    public.splixa_legacy_share_amount(entry.value)::numeric(20, 8),
    'TRY',
    1::numeric(24, 12),
    'legacy_try_canonical',
    case when tg_op = 'UPDATE' then v_now else coalesce(new.created_at, v_now) end,
    'settled',
    'Derived from legacy split_data status; original payment timestamp was not stored.',
    case when tg_op = 'UPDATE' then v_now else coalesce(new.created_at, v_now) end,
    case when tg_op = 'UPDATE' then v_now else coalesce(new.created_at, v_now) end,
    'legacy_settled_share',
    'group_transaction:' || new.id::text || ':participant:' || entry.key,
    case when tg_op = 'UPDATE' then v_now else coalesce(new.created_at, v_now) end,
    v_now
  from jsonb_each(coalesce(new.split_data, '{}'::jsonb)) entry
  where entry.key::uuid <> new.payer_id
    and public.splixa_legacy_share_amount(entry.value) > 0
    and public.splixa_legacy_share_status(
          entry.value,
          entry.key::uuid,
          new.payer_id
        ) = 'settled'
  on conflict (legacy_migration_key) do update
  set
    group_id = excluded.group_id,
    expense_id = excluded.expense_id,
    paid_by = excluded.paid_by,
    received_by = excluded.received_by,
    original_amount = excluded.original_amount,
    base_amount = excluded.base_amount,
    version = s.version + 1;

  return new;
end;
$$;

create or replace function public.splixa_delete_legacy_group_transaction()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Synthetic settlements are compatibility artifacts for this legacy row.
  -- Remove them before deleting the expense; expense_id itself uses SET NULL
  -- so future native settlement history is not erased with an expense.
  delete from public.settlements
  where source = 'legacy_settled_share'
    and expense_id = old.id;

  delete from public.expenses where id = old.id;
  return old;
end;
$$;

create trigger group_transactions_sync_financial_ledger
after insert or update on public.group_transactions
for each row execute function public.splixa_sync_legacy_group_transaction();

create trigger group_transactions_delete_financial_ledger
after delete on public.group_transactions
for each row execute function public.splixa_delete_legacy_group_transaction();

revoke all on function public.splixa_sync_legacy_group_transaction()
  from public, anon, authenticated;
revoke all on function public.splixa_delete_legacy_group_transaction()
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- RLS and read model
-- ---------------------------------------------------------------------------

alter table public.expenses enable row level security;
alter table public.expense_shares enable row level security;
alter table public.settlements enable row level security;

revoke all on table public.expenses, public.expense_shares, public.settlements
  from public, anon, authenticated;
grant select on table public.expenses, public.expense_shares, public.settlements
  to authenticated;

create policy expenses_select_group_members
on public.expenses
for select
to authenticated
using (
  public.is_group_member(group_id, (select auth.uid()))
  or created_by = (select auth.uid())
  or payer_id = (select auth.uid())
);

create policy expense_shares_select_group_members
on public.expense_shares
for select
to authenticated
using (
  participant_id = (select auth.uid())
  or exists (
    select 1
    from public.expenses e
    where e.id = expense_shares.expense_id
      and (
        public.is_group_member(e.group_id, (select auth.uid()))
        or e.created_by = (select auth.uid())
        or e.payer_id = (select auth.uid())
      )
  )
);

create policy settlements_select_group_members
on public.settlements
for select
to authenticated
using (
  public.is_group_member(group_id, (select auth.uid()))
  or created_by = (select auth.uid())
  or paid_by = (select auth.uid())
  or received_by = (select auth.uid())
);

-- Positive delta means the user is owed money; negative means the user owes.
-- Approved/payment-pending/settled expense obligations remain in the ledger.
-- A confirmed settlement contributes the inverse movement.
create view public.group_balance_components_v1
with (security_invoker = true)
as
select
  e.group_id,
  e.id as source_id,
  'expense_share'::text as source_kind,
  es.participant_id as user_id,
  e.base_currency_code as currency_code,
  -es.base_share_amount as balance_delta
from public.expenses e
join public.expense_shares es on es.expense_id = e.id
where es.participant_id <> e.payer_id
  and es.base_share_amount > 0
  and es.status in ('approved', 'payment_pending', 'settled')

union all

select
  e.group_id,
  e.id as source_id,
  'expense_payer'::text as source_kind,
  e.payer_id as user_id,
  e.base_currency_code as currency_code,
  es.base_share_amount as balance_delta
from public.expenses e
join public.expense_shares es on es.expense_id = e.id
where es.participant_id <> e.payer_id
  and es.base_share_amount > 0
  and es.status in ('approved', 'payment_pending', 'settled')

union all

select
  s.group_id,
  s.id as source_id,
  'settlement_paid'::text as source_kind,
  s.paid_by as user_id,
  s.base_currency_code as currency_code,
  s.base_amount as balance_delta
from public.settlements s
where s.status = 'settled'

union all

select
  s.group_id,
  s.id as source_id,
  'settlement_received'::text as source_kind,
  s.received_by as user_id,
  s.base_currency_code as currency_code,
  -s.base_amount as balance_delta
from public.settlements s
where s.status = 'settled';

create view public.group_balances_v1
with (security_invoker = true)
as
select
  group_id,
  user_id,
  currency_code,
  sum(balance_delta)::numeric(20, 8) as balance
from public.group_balance_components_v1
group by group_id, user_id, currency_code;

create view public.expense_share_totals_v1
with (security_invoker = true)
as
select
  e.id as expense_id,
  e.group_id,
  e.base_currency_code as currency_code,
  e.base_amount,
  coalesce(sum(es.base_share_amount), 0)::numeric(20, 8) as allocated_amount,
  (coalesce(sum(es.base_share_amount), 0) - e.base_amount)::numeric(20, 8)
    as allocation_difference,
  abs(coalesce(sum(es.base_share_amount), 0) - e.base_amount) > 0.01000000
    as requires_review
from public.expenses e
left join public.expense_shares es on es.expense_id = e.id
group by e.id, e.group_id, e.base_currency_code, e.base_amount;

revoke all on table public.group_balance_components_v1,
  public.group_balances_v1,
  public.expense_share_totals_v1
  from public, anon;
grant select on table public.group_balance_components_v1,
  public.group_balances_v1,
  public.expense_share_totals_v1
  to authenticated;

-- ---------------------------------------------------------------------------
-- Transactional proof: normalized balances must exactly match today's Dart
-- balance engine before this migration is allowed to commit.
-- ---------------------------------------------------------------------------

do $$
declare
  v_legacy_expense_count bigint;
  v_new_expense_count bigint;
  v_legacy_share_count bigint;
  v_new_share_count bigint;
  v_balance_mismatch_count bigint;
begin
  select count(*) into v_legacy_expense_count
  from public.group_transactions;

  select count(*) into v_new_expense_count
  from public.expenses
  where source = 'legacy_group_transactions';

  if v_legacy_expense_count <> v_new_expense_count then
    raise exception
      'Expense migration count mismatch: legacy %, normalized %',
      v_legacy_expense_count,
      v_new_expense_count;
  end if;

  select count(*)
    into v_legacy_share_count
  from public.group_transactions gt
  cross join lateral jsonb_each(coalesce(gt.split_data, '{}'::jsonb)) entry;

  select count(*) into v_new_share_count
  from public.expense_shares es
  join public.expenses e on e.id = es.expense_id
  where e.source = 'legacy_group_transactions';

  if v_legacy_share_count <> v_new_share_count then
    raise exception
      'Share migration count mismatch: legacy %, normalized %',
      v_legacy_share_count,
      v_new_share_count;
  end if;

  with legacy_components as (
    select
      gt.group_id,
      entry.key::uuid as user_id,
      -public.splixa_legacy_share_amount(entry.value) as delta
    from public.group_transactions gt
    cross join lateral jsonb_each(coalesce(gt.split_data, '{}'::jsonb)) entry
    where entry.key::uuid <> gt.payer_id
      and public.splixa_legacy_share_amount(entry.value) > 0
      and public.splixa_legacy_share_status(
            entry.value,
            entry.key::uuid,
            gt.payer_id
          ) in ('approved', 'payment_pending')

    union all

    select
      gt.group_id,
      gt.payer_id as user_id,
      public.splixa_legacy_share_amount(entry.value) as delta
    from public.group_transactions gt
    cross join lateral jsonb_each(coalesce(gt.split_data, '{}'::jsonb)) entry
    where entry.key::uuid <> gt.payer_id
      and public.splixa_legacy_share_amount(entry.value) > 0
      and public.splixa_legacy_share_status(
            entry.value,
            entry.key::uuid,
            gt.payer_id
          ) in ('approved', 'payment_pending')
  ),
  legacy_balances as (
    select group_id, user_id, sum(delta)::numeric(20, 8) as balance
    from legacy_components
    group by group_id, user_id
  ),
  normalized_components as (
    select
      e.group_id,
      es.participant_id as user_id,
      -es.base_share_amount as delta
    from public.expenses e
    join public.expense_shares es on es.expense_id = e.id
    where e.source = 'legacy_group_transactions'
      and es.participant_id <> e.payer_id
      and es.base_share_amount > 0
      and es.status in ('approved', 'payment_pending', 'settled')

    union all

    select
      e.group_id,
      e.payer_id as user_id,
      es.base_share_amount as delta
    from public.expenses e
    join public.expense_shares es on es.expense_id = e.id
    where e.source = 'legacy_group_transactions'
      and es.participant_id <> e.payer_id
      and es.base_share_amount > 0
      and es.status in ('approved', 'payment_pending', 'settled')

    union all

    select s.group_id, s.paid_by as user_id, s.base_amount as delta
    from public.settlements s
    where s.source = 'legacy_settled_share'
      and s.status = 'settled'

    union all

    select s.group_id, s.received_by as user_id, -s.base_amount as delta
    from public.settlements s
    where s.source = 'legacy_settled_share'
      and s.status = 'settled'
  ),
  normalized_balances as (
    select group_id, user_id, sum(delta)::numeric(20, 8) as balance
    from normalized_components
    group by group_id, user_id
  )
  select count(*) into v_balance_mismatch_count
  from legacy_balances legacy
  full outer join normalized_balances normalized
    on normalized.group_id = legacy.group_id
   and normalized.user_id = legacy.user_id
  where abs(coalesce(legacy.balance, 0) - coalesce(normalized.balance, 0))
    > 0.00000001;

  if v_balance_mismatch_count > 0 then
    raise exception
      'Financial migration aborted: % group/user balances differ from the legacy engine',
      v_balance_mismatch_count;
  end if;
end
$$;

commit;

-- Post-deploy, read-only smoke checks (expected: zero rows for both):
--
-- select *
-- from public.expense_share_totals_v1
-- where requires_review;
--
-- select group_id, currency_code, sum(balance)
-- from public.group_balances_v1
-- group by group_id, currency_code
-- having abs(sum(balance)) > 0.00000001;
