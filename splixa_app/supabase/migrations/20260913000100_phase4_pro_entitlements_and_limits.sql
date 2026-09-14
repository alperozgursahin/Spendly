-- Phase 4: server-authoritative Pro entitlements and freemium limits.
--
-- RevenueCat remains the billing source of truth. public.user_entitlements is
-- a read-only-to-clients projection maintained by signed Edge Functions.
-- Quotas are also enforced by triggers so older clients and direct REST calls
-- cannot bypass them while the V1 RPC rollout is in progress.

begin;

create table if not exists public.user_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  entitlement_id text not null default 'pro',
  is_active boolean not null default false,
  product_id text,
  store text,
  expires_at timestamptz,
  original_purchase_at timestamptz,
  last_event_id text,
  last_event_at timestamptz,
  updated_at timestamptz not null default now(),
  constraint user_entitlements_entitlement_check
    check (entitlement_id = 'pro'),
  constraint user_entitlements_product_length_check
    check (product_id is null or length(product_id) between 1 and 255),
  constraint user_entitlements_store_length_check
    check (store is null or length(store) between 1 and 50)
);

alter table public.user_entitlements enable row level security;
revoke all on table public.user_entitlements from public, anon, authenticated;
grant select on table public.user_entitlements to authenticated;

drop policy if exists user_entitlements_select_own
  on public.user_entitlements;
create policy user_entitlements_select_own
on public.user_entitlements
for select
to authenticated
using (user_id = (select auth.uid()));

create index if not exists user_entitlements_active_lookup_idx
  on public.user_entitlements (user_id, expires_at)
  where is_active;

alter table public.profiles
  add column if not exists timezone text not null default 'UTC';

create or replace function public.has_active_pro_entitlement(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_entitlements ue
    where ue.user_id = p_user_id
      and ue.entitlement_id = 'pro'
      and ue.is_active
      and (ue.expires_at is null or ue.expires_at > now())
  );
$$;

revoke all on function public.has_active_pro_entitlement(uuid)
  from public, anon, authenticated;

create or replace function public.splixa_actor_has_pro()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.has_active_pro_entitlement((select auth.uid()))
    or coalesce(
      ((select auth.jwt()) -> 'app_metadata' ->> 'play_review')::boolean,
      false
    );
$$;

revoke all on function public.splixa_actor_has_pro()
  from public, anon;
grant execute on function public.splixa_actor_has_pro()
  to authenticated, service_role;

create or replace function public.set_profile_timezone_v1(p_timezone text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_timezone text := btrim(p_timezone);
begin
  if v_actor_id is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  if not exists (
    select 1 from pg_catalog.pg_timezone_names where name = v_timezone
  ) then
    raise exception 'INVALID_TIMEZONE';
  end if;

  update public.profiles
  set timezone = v_timezone
  where id = v_actor_id;

  if not found then
    raise exception 'PROFILE_NOT_FOUND';
  end if;

  return v_timezone;
end;
$$;

revoke all on function public.set_profile_timezone_v1(text)
  from public, anon;
grant execute on function public.set_profile_timezone_v1(text)
  to authenticated;

create or replace function public.splixa_group_count(p_user_id uuid)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::integer
  from (
    select gm.group_id
    from public.group_members gm
    where gm.user_id = p_user_id
    union
    select g.id
    from public.groups g
    where g.created_by = p_user_id
  ) memberships;
$$;

revoke all on function public.splixa_group_count(uuid)
  from public, anon, authenticated;

create or replace function public.splixa_personal_expense_period(
  p_user_id uuid,
  out period_start timestamptz,
  out period_end timestamptz
)
returns record
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_timezone text := 'UTC';
  v_local_month_start timestamp;
begin
  select coalesce(nullif(p.timezone, ''), 'UTC')
  into v_timezone
  from public.profiles p
  where p.id = p_user_id;

  if not exists (
    select 1 from pg_catalog.pg_timezone_names where name = v_timezone
  ) then
    v_timezone := 'UTC';
  end if;

  v_local_month_start := date_trunc('month', now() at time zone v_timezone);
  period_start := v_local_month_start at time zone v_timezone;
  period_end := (v_local_month_start + interval '1 month') at time zone v_timezone;
end;
$$;

revoke all on function public.splixa_personal_expense_period(uuid)
  from public, anon, authenticated;

create or replace function public.splixa_personal_expense_count(p_user_id uuid)
returns integer
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_start timestamptz;
  v_end timestamptz;
  v_count integer;
begin
  select period_start, period_end
  into v_start, v_end
  from public.splixa_personal_expense_period(p_user_id);

  select count(*)::integer
  into v_count
  from public.transactions t
  where t.user_id = p_user_id
    and t.group_id is null
    and t.type = 'expense'
    and t.created_at >= v_start
    and t.created_at < v_end;

  return v_count;
end;
$$;

revoke all on function public.splixa_personal_expense_count(uuid)
  from public, anon, authenticated;

create or replace function public.pro_usage_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_start timestamptz;
  v_end timestamptz;
begin
  if v_actor_id is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  select period_start, period_end
  into v_start, v_end
  from public.splixa_personal_expense_period(v_actor_id);

  return jsonb_build_object(
    'is_pro', public.splixa_actor_has_pro(),
    'group_count', public.splixa_group_count(v_actor_id),
    'group_limit', 2,
    'personal_expense_count',
      public.splixa_personal_expense_count(v_actor_id),
    'personal_expense_limit', 50,
    'period_start', v_start,
    'period_end', v_end
  );
end;
$$;

revoke all on function public.pro_usage_v1()
  from public, anon;
grant execute on function public.pro_usage_v1()
  to authenticated;

create or replace function public.splixa_enforce_group_quota()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role text := coalesce(auth.role(), '');
begin
  if v_role = 'service_role' then
    return new;
  end if;

  if auth.uid() is null or new.created_by <> auth.uid() then
    raise exception 'GROUP_CREATOR_MUST_MATCH_AUTH_USER';
  end if;

  if public.splixa_actor_has_pro() then
    return new;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('splixa:groups:' || auth.uid()::text, 0)
  );

  if public.splixa_group_count(auth.uid()) >= 2 then
    raise exception 'FREE_GROUP_LIMIT_REACHED';
  end if;

  return new;
end;
$$;

drop trigger if exists groups_enforce_freemium_quota on public.groups;
create trigger groups_enforce_freemium_quota
before insert on public.groups
for each row execute function public.splixa_enforce_group_quota();

revoke all on function public.splixa_enforce_group_quota()
  from public, anon, authenticated;

create or replace function public.splixa_enforce_membership_quota()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role text := coalesce(auth.role(), '');
  v_is_review_user boolean := false;
begin
  if v_role = 'service_role'
     or public.has_active_pro_entitlement(new.user_id) then
    return new;
  end if;

  if new.user_id = auth.uid() then
    v_is_review_user := coalesce(
      ((select auth.jwt()) -> 'app_metadata' ->> 'play_review')::boolean,
      false
    );
  end if;
  if v_is_review_user then
    return new;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('splixa:groups:' || new.user_id::text, 0)
  );

  if not exists (
    select 1
    from public.group_members gm
    where gm.group_id = new.group_id
      and gm.user_id = new.user_id
  ) and not exists (
    -- A just-created group already contributes to splixa_group_count via
    -- groups.created_by; adding its creator membership must not count twice.
    select 1
    from public.groups g
    where g.id = new.group_id
      and g.created_by = new.user_id
  ) and public.splixa_group_count(new.user_id) >= 2 then
    raise exception 'FREE_GROUP_LIMIT_REACHED';
  end if;

  return new;
end;
$$;

drop trigger if exists group_members_enforce_freemium_quota
  on public.group_members;
create trigger group_members_enforce_freemium_quota
before insert on public.group_members
for each row execute function public.splixa_enforce_membership_quota();

revoke all on function public.splixa_enforce_membership_quota()
  from public, anon, authenticated;

create or replace function public.splixa_enforce_personal_expense_quota()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role text := coalesce(auth.role(), '');
begin
  if v_role = 'service_role'
     or new.group_id is not null
     or new.type <> 'expense' then
    return new;
  end if;

  if auth.uid() is null or new.user_id <> auth.uid() then
    raise exception 'TRANSACTION_OWNER_MUST_MATCH_AUTH_USER';
  end if;

  if public.splixa_actor_has_pro() then
    return new;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'splixa:personal-expenses:' || auth.uid()::text,
      0
    )
  );

  if public.splixa_personal_expense_count(auth.uid()) >= 50 then
    raise exception 'FREE_PERSONAL_EXPENSE_LIMIT_REACHED';
  end if;

  return new;
end;
$$;

drop trigger if exists transactions_enforce_freemium_quota
  on public.transactions;
create trigger transactions_enforce_freemium_quota
before insert on public.transactions
for each row execute function public.splixa_enforce_personal_expense_quota();

revoke all on function public.splixa_enforce_personal_expense_quota()
  from public, anon, authenticated;

create or replace function public.create_group_v1(p_name text)
returns public.groups
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_group public.groups%rowtype;
begin
  if v_actor_id is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;
  if p_name is null or length(btrim(p_name)) not between 1 and 100 then
    raise exception 'INVALID_GROUP_NAME';
  end if;

  insert into public.groups (name, created_by)
  values (btrim(p_name), v_actor_id)
  returning * into v_group;

  insert into public.group_members (group_id, user_id)
  values (v_group.id, v_actor_id);

  return v_group;
end;
$$;

revoke all on function public.create_group_v1(text)
  from public, anon;
grant execute on function public.create_group_v1(text)
  to authenticated;

create or replace function public.create_personal_transaction_v1(
  p_original_amount numeric,
  p_currency_code text,
  p_base_amount numeric,
  p_base_currency_code text,
  p_exchange_rate numeric,
  p_rate_source text,
  p_rate_locked_at timestamptz,
  p_category text,
  p_date date,
  p_type text
)
returns public.transactions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_transaction public.transactions%rowtype;
  v_currency_code text := upper(btrim(p_currency_code));
  v_base_currency_code text := upper(btrim(p_base_currency_code));
begin
  if v_actor_id is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;
  if p_original_amount is null or p_original_amount < 0
     or p_base_amount is null or p_base_amount < 0
     or p_exchange_rate is null or p_exchange_rate <= 0
     or abs(p_base_amount - (p_original_amount * p_exchange_rate)) > 0.01 then
    raise exception 'INVALID_TRANSACTION_AMOUNT';
  end if;
  if v_currency_code !~ '^[A-Z0-9]{3,10}$'
     or v_base_currency_code !~ '^[A-Z0-9]{3,10}$' then
    raise exception 'INVALID_CURRENCY_CODE';
  end if;
  if p_rate_source is null
     or length(btrim(p_rate_source)) not between 1 and 100
     or p_rate_locked_at is null then
    raise exception 'INVALID_EXCHANGE_RATE';
  end if;
  if p_category is null
     or length(btrim(p_category)) not between 1 and 100 then
    raise exception 'INVALID_CATEGORY';
  end if;
  if p_date is null or p_type not in ('income', 'expense') then
    raise exception 'INVALID_TRANSACTION';
  end if;

  insert into public.transactions (
    user_id,
    group_id,
    amount,
    original_amount,
    currency_code,
    base_amount,
    base_currency_code,
    exchange_rate,
    rate_source,
    rate_locked_at,
    category,
    date,
    type
  )
  values (
    v_actor_id,
    null,
    p_base_amount,
    p_original_amount,
    v_currency_code,
    p_base_amount,
    v_base_currency_code,
    p_exchange_rate,
    btrim(p_rate_source),
    p_rate_locked_at,
    btrim(p_category),
    p_date,
    p_type
  )
  returning * into v_transaction;

  return v_transaction;
end;
$$;

revoke all on function public.create_personal_transaction_v1(
  numeric,
  text,
  numeric,
  text,
  numeric,
  text,
  timestamptz,
  text,
  date,
  text
) from public, anon;
grant execute on function public.create_personal_transaction_v1(
  numeric,
  text,
  numeric,
  text,
  numeric,
  text,
  timestamptz,
  text,
  date,
  text
) to authenticated;

commit;
