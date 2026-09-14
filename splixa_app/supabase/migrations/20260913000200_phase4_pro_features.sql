-- Phase 4: durable storage and server authorization for Pro features.
-- Client-side RevenueCat checks are UX only. Every paid mutation below also
-- verifies the server-side entitlement projection created in 20260913000100.

begin;

-- ---------------------------------------------------------------------------
-- Reusable custom categories
-- ---------------------------------------------------------------------------

create table public.custom_categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 40),
  emoji text not null check (length(emoji) between 1 and 16),
  -- Flutter Color.value is an unsigned 32-bit ARGB value. PostgreSQL integer
  -- is signed and cannot represent values such as 0xFF0E7490.
  color_value bigint not null check (color_value between 0 and 4294967295),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index custom_categories_user_name_unique
  on public.custom_categories (user_id, lower(btrim(name)));

alter table public.custom_categories enable row level security;
revoke all on table public.custom_categories from public, anon;
grant select, insert, update, delete on table public.custom_categories
  to authenticated;

create policy custom_categories_select_own
on public.custom_categories for select to authenticated
using (user_id = (select auth.uid()));

create policy custom_categories_insert_pro
on public.custom_categories for insert to authenticated
with check (
  user_id = (select auth.uid()) and public.splixa_actor_has_pro()
);

create policy custom_categories_update_pro
on public.custom_categories for update to authenticated
using (user_id = (select auth.uid()) and public.splixa_actor_has_pro())
with check (user_id = (select auth.uid()) and public.splixa_actor_has_pro());

create policy custom_categories_delete_pro
on public.custom_categories for delete to authenticated
using (user_id = (select auth.uid()) and public.splixa_actor_has_pro());

-- A modified client must not bypass Custom Categories or Custom FX by writing
-- straight to the ledger. Existing built-in categories remain available to
-- everyone; any other category and every user-locked rate require Pro.
create or replace function public.splixa_enforce_paid_ledger_features()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role text := coalesce(auth.role(), '');
  v_owner_id uuid;
begin
  if v_role = 'service_role' then
    return new;
  end if;

  -- One trigger function serves two tables that name the owner column
  -- differently: transactions.user_id and expenses.created_by. A CASE over
  -- new.user_id / new.created_by cannot be used here — PostgreSQL resolves
  -- every field reference in the expression during parse analysis, including
  -- the branch that will not be taken, so the function raises
  -- 'record "new" has no field "created_by"' on transactions and the mirror
  -- error on expenses. Going through to_jsonb keeps the lookup by name, where
  -- an absent key is simply null.
  v_owner_id := (
    to_jsonb(new) ->> case tg_table_name
      when 'transactions' then 'user_id'
      when 'expenses' then 'created_by'
      else null
    end
  )::uuid;

  if auth.uid() is null or v_owner_id is distinct from auth.uid() then
    raise exception 'LEDGER_OWNER_MUST_MATCH_AUTH_USER';
  end if;
  if public.splixa_actor_has_pro() then
    return new;
  end if;
  if new.rate_source = 'manual_user_locked' then
    raise exception 'PRO_REQUIRED_CUSTOM_EXCHANGE_RATE';
  end if;
  if new.category is not null
     and btrim(new.category) not in (
       'Market', 'Yemek', 'Ulaşım', 'Eğlence',
       'Maaş', 'Aidat', 'Fatura', 'Diğer'
     ) then
    raise exception 'PRO_REQUIRED_CUSTOM_CATEGORY';
  end if;

  return new;
end;
$$;

drop trigger if exists transactions_enforce_paid_features
  on public.transactions;
create trigger transactions_enforce_paid_features
before insert or update of category, rate_source on public.transactions
for each row execute function public.splixa_enforce_paid_ledger_features();

drop trigger if exists expenses_enforce_paid_features on public.expenses;
create trigger expenses_enforce_paid_features
before insert or update of category, rate_source on public.expenses
for each row execute function public.splixa_enforce_paid_ledger_features();

revoke all on function public.splixa_enforce_paid_ledger_features()
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Private receipt attachments (one target per row)
-- ---------------------------------------------------------------------------

create table public.expense_attachments (
  id uuid primary key default gen_random_uuid(),
  expense_id uuid references public.expenses(id) on delete cascade,
  transaction_id uuid references public.transactions(id) on delete cascade,
  uploaded_by uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  mime_type text not null check (mime_type in ('image/jpeg', 'image/png', 'image/webp')),
  byte_size integer not null check (byte_size between 1 and 5242880),
  created_at timestamptz not null default timezone('utc', now()),
  constraint expense_attachments_exactly_one_target check (
    (expense_id is not null)::integer + (transaction_id is not null)::integer = 1
  ),
  constraint expense_attachments_owned_path check (
    split_part(storage_path, '/', 1) = uploaded_by::text
  )
);

create index expense_attachments_expense_idx
  on public.expense_attachments (expense_id) where expense_id is not null;
create index expense_attachments_transaction_idx
  on public.expense_attachments (transaction_id)
  where transaction_id is not null;

alter table public.expense_attachments enable row level security;
revoke all on table public.expense_attachments from public, anon;
grant select, insert, delete on table public.expense_attachments
  to authenticated;

create policy expense_attachments_select_authorized
on public.expense_attachments for select to authenticated
using (
  uploaded_by = (select auth.uid())
  or exists (
    select 1 from public.transactions t
    where t.id = expense_attachments.transaction_id
      and t.user_id = (select auth.uid())
  )
  or exists (
    select 1 from public.expenses e
    where e.id = expense_attachments.expense_id
      and (
        public.is_group_member(e.group_id, (select auth.uid()))
        or e.created_by = (select auth.uid())
        or e.payer_id = (select auth.uid())
      )
  )
);

create policy expense_attachments_insert_pro
on public.expense_attachments for insert to authenticated
with check (
  uploaded_by = (select auth.uid())
  and public.splixa_actor_has_pro()
  and (
    exists (
      select 1 from public.transactions t
      where t.id = expense_attachments.transaction_id
        and t.user_id = (select auth.uid())
    )
    or exists (
      select 1 from public.expenses e
      where e.id = expense_attachments.expense_id
        and (
          e.created_by = (select auth.uid())
          or e.payer_id = (select auth.uid())
        )
    )
  )
);

create policy expense_attachments_delete_owner
on public.expense_attachments for delete to authenticated
using (uploaded_by = (select auth.uid()) and public.splixa_actor_has_pro());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'receipt-attachments',
  'receipt-attachments',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy receipt_objects_insert_own_folder
on storage.objects for insert to authenticated
with check (
  bucket_id = 'receipt-attachments'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and public.splixa_actor_has_pro()
);

create policy receipt_objects_select_authorized
on storage.objects for select to authenticated
using (
  bucket_id = 'receipt-attachments'
  and exists (
    select 1 from public.expense_attachments a
    where a.storage_path = storage.objects.name
      and (
        a.uploaded_by = (select auth.uid())
        or exists (
          select 1 from public.transactions t
          where t.id = a.transaction_id and t.user_id = (select auth.uid())
        )
        or exists (
          select 1 from public.expenses e
          where e.id = a.expense_id
            and public.is_group_member(e.group_id, (select auth.uid()))
        )
      )
  )
);

create policy receipt_objects_delete_owner
on storage.objects for delete to authenticated
using (
  bucket_id = 'receipt-attachments'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and public.splixa_actor_has_pro()
);

-- Storage objects live outside PostgreSQL, so FK cascades cannot delete the
-- underlying bytes. Every attachment-row deletion enters a private queue; the
-- scheduled service-role job removes the object through the Storage API.
create table public.receipt_storage_deletion_queue (
  storage_path text primary key,
  queued_at timestamptz not null default timezone('utc', now()),
  attempts integer not null default 0 check (attempts between 0 and 1000)
);
alter table public.receipt_storage_deletion_queue enable row level security;
revoke all on table public.receipt_storage_deletion_queue
  from public, anon, authenticated;

create or replace function public.enqueue_deleted_receipt_object()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.receipt_storage_deletion_queue (storage_path)
  values (old.storage_path)
  on conflict (storage_path) do update set
    queued_at = excluded.queued_at;
  return old;
end;
$$;

drop trigger if exists expense_attachments_queue_storage_delete
  on public.expense_attachments;
create trigger expense_attachments_queue_storage_delete
after delete on public.expense_attachments
for each row execute function public.enqueue_deleted_receipt_object();

revoke all on function public.enqueue_deleted_receipt_object()
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Personal recurring expenses. Generation is idempotent by template/due date.
-- ---------------------------------------------------------------------------

create table public.recurring_expense_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (length(btrim(title)) between 1 and 100),
  category text not null check (length(btrim(category)) between 1 and 100),
  original_amount numeric(20, 8) not null check (original_amount > 0),
  currency_code text not null check (currency_code ~ '^[A-Z0-9]{3,10}$'),
  base_amount numeric(20, 8) not null check (base_amount > 0),
  base_currency_code text not null default 'TRY'
    check (base_currency_code ~ '^[A-Z0-9]{3,10}$'),
  exchange_rate numeric(24, 12) not null check (exchange_rate > 0),
  rate_source text not null check (length(btrim(rate_source)) between 1 and 100),
  rate_locked_at timestamptz not null,
  frequency text not null check (frequency in ('weekly', 'monthly')),
  interval_count integer not null default 1 check (interval_count between 1 and 12),
  timezone text not null,
  next_run_at timestamptz not null,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint recurring_expenses_fx_math check (
    abs(base_amount - (original_amount * exchange_rate)) <= 0.01000000
  )
);

create table public.recurring_expense_runs (
  template_id uuid not null references public.recurring_expense_templates(id)
    on delete cascade,
  due_at timestamptz not null,
  transaction_id uuid references public.transactions(id) on delete set null,
  generated_at timestamptz not null default timezone('utc', now()),
  primary key (template_id, due_at)
);

alter table public.recurring_expense_templates enable row level security;
alter table public.recurring_expense_runs enable row level security;
revoke all on table public.recurring_expense_templates,
  public.recurring_expense_runs from public, anon;
grant select, insert, update, delete on public.recurring_expense_templates
  to authenticated;
grant select on public.recurring_expense_runs to authenticated;

create policy recurring_templates_select_own
on public.recurring_expense_templates for select to authenticated
using (user_id = (select auth.uid()));
create policy recurring_templates_insert_pro
on public.recurring_expense_templates for insert to authenticated
with check (user_id = (select auth.uid()) and public.splixa_actor_has_pro());
create policy recurring_templates_update_pro
on public.recurring_expense_templates for update to authenticated
using (user_id = (select auth.uid()) and public.splixa_actor_has_pro())
with check (user_id = (select auth.uid()) and public.splixa_actor_has_pro());
create policy recurring_templates_delete_pro
on public.recurring_expense_templates for delete to authenticated
using (user_id = (select auth.uid()) and public.splixa_actor_has_pro());
create policy recurring_runs_select_own
on public.recurring_expense_runs for select to authenticated
using (
  exists (
    select 1 from public.recurring_expense_templates r
    where r.id = recurring_expense_runs.template_id
      and r.user_id = (select auth.uid())
  )
);

create or replace function public.generate_due_recurring_expenses_v1(
  p_usd_per_try numeric default null,
  p_eur_per_try numeric default null,
  p_rate_locked_at timestamptz default null,
  p_rate_source text default 'scheduled_open_er_api',
  p_limit integer default 200
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_template public.recurring_expense_templates%rowtype;
  v_transaction_id uuid;
  v_generated integer := 0;
  v_next_local timestamp;
  v_next_at timestamptz;
  v_run_rate numeric;
  v_run_base_amount numeric;
  v_run_rate_source text;
  v_run_rate_locked_at timestamptz;
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

  -- Entitlement loss pauses rather than queues recurring writes. Reactivation
  -- schedules a new future occurrence in the client, so old months are never
  -- backfilled unexpectedly after a subscription is restored.
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
    v_run_base_amount := round(v_template.original_amount * v_run_rate, 2);

    insert into public.recurring_expense_runs (template_id, due_at)
    values (v_template.id, v_template.next_run_at)
    on conflict do nothing;

    if found then
      insert into public.transactions (
        user_id, group_id, amount, original_amount, currency_code,
        base_amount, base_currency_code, exchange_rate, rate_source,
        rate_locked_at, category, date, type
      ) values (
        v_template.user_id, null, v_run_base_amount,
        v_template.original_amount, v_template.currency_code,
        v_run_base_amount, v_template.base_currency_code,
        v_run_rate, v_run_rate_source,
        v_run_rate_locked_at,
        v_template.category,
        (v_template.next_run_at at time zone v_template.timezone)::date,
        'expense'
      ) returning id into v_transaction_id;

      update public.recurring_expense_runs
      set transaction_id = v_transaction_id
      where template_id = v_template.id
        and due_at = v_template.next_run_at;
      v_generated := v_generated + 1;
    end if;

    v_next_local := v_template.next_run_at at time zone v_template.timezone;
    v_next_local := case v_template.frequency
      when 'weekly' then v_next_local + make_interval(weeks => v_template.interval_count)
      else v_next_local + make_interval(months => v_template.interval_count)
    end;
    v_next_at := v_next_local at time zone v_template.timezone;

    update public.recurring_expense_templates
    set next_run_at = v_next_at, updated_at = timezone('utc', now())
    where id = v_template.id;
  end loop;

  return v_generated;
end;
$$;

revoke all on function public.generate_due_recurring_expenses_v1(
  numeric, numeric, timestamptz, text, integer
)
  from public, anon, authenticated;
grant execute on function public.generate_due_recurring_expenses_v1(
  numeric, numeric, timestamptz, text, integer
)
  to service_role;

-- ---------------------------------------------------------------------------
-- Consent-aware debt reminders and private device push tokens
-- ---------------------------------------------------------------------------

alter table public.profiles
  add column if not exists debt_reminders_enabled boolean not null default true;

create table public.push_tokens (
  token text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('android', 'ios')),
  language_code text not null default 'en'
    check (language_code in (
      'en', 'tr', 'es', 'pt', 'de', 'fr',
      'it', 'nl', 'ru', 'ar', 'hi', 'id'
    )),
  updated_at timestamptz not null default timezone('utc', now())
);
create index push_tokens_user_idx on public.push_tokens (user_id);
alter table public.push_tokens enable row level security;
revoke all on table public.push_tokens from public, anon;
grant select, delete on public.push_tokens to authenticated;
create policy push_tokens_own on public.push_tokens
for all to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

-- FCM/APNs may reuse the same installation token after sign-out. Transfer it
-- atomically to the current account so the previous account can never receive
-- the new account's reminders and an RLS upsert cannot fail on ownership.
create or replace function public.register_push_token_v1(
  p_token text,
  p_platform text,
  p_language_code text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_token text := btrim(p_token);
begin
  if v_actor_id is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if length(v_token) not between 16 and 4096 then
    raise exception 'INVALID_PUSH_TOKEN';
  end if;
  if p_platform not in ('android', 'ios') then
    raise exception 'INVALID_PUSH_PLATFORM';
  end if;
  if p_language_code not in (
    'en', 'tr', 'es', 'pt', 'de', 'fr',
    'it', 'nl', 'ru', 'ar', 'hi', 'id'
  ) then
    raise exception 'INVALID_LANGUAGE_CODE';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('splixa:push:' || v_token, 0)
  );
  delete from public.push_tokens
  where token = v_token and user_id <> v_actor_id;

  insert into public.push_tokens (
    token, user_id, platform, language_code, updated_at
  ) values (
    v_token, v_actor_id, p_platform, p_language_code, timezone('utc', now())
  )
  on conflict (token) do update set
    user_id = excluded.user_id,
    platform = excluded.platform,
    language_code = excluded.language_code,
    updated_at = excluded.updated_at;
end;
$$;

revoke all on function public.register_push_token_v1(text, text, text)
  from public, anon;
grant execute on function public.register_push_token_v1(text, text, text)
  to authenticated;

create table public.debt_reminders (
  id uuid primary key default gen_random_uuid(),
  expense_id uuid not null references public.expenses(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  constraint debt_reminders_parties_differ check (sender_id <> recipient_id)
);
create index debt_reminders_rate_idx
  on public.debt_reminders (sender_id, recipient_id, expense_id, created_at desc);
alter table public.debt_reminders enable row level security;
revoke all on table public.debt_reminders from public, anon, authenticated;
grant select on public.debt_reminders to authenticated;
create policy debt_reminders_participants_select
on public.debt_reminders for select to authenticated
using (
  sender_id = (select auth.uid()) or recipient_id = (select auth.uid())
);

alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type = any (array[
    'debt_request'::text,
    'payment_confirmation'::text,
    'debt_approved'::text,
    'debt_rejected'::text,
    'debt_settled'::text,
    'group_invite'::text,
    'group_activity'::text,
    'debt_reminder'::text
  ]));

create or replace function public.send_debt_reminder_v1(
  p_expense_id uuid,
  p_recipient_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_expense public.expenses%rowtype;
  v_reminder_id uuid;
begin
  if v_actor_id is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not public.splixa_actor_has_pro() then raise exception 'PRO_REQUIRED'; end if;

  select e.* into v_expense
  from public.expenses e
  where e.id = p_expense_id
  for update;
  if not found then raise exception 'EXPENSE_NOT_FOUND'; end if;
  if v_expense.payer_id <> v_actor_id then
    raise exception 'ONLY_CREDITOR_CAN_REMIND';
  end if;
  if not exists (
    select 1 from public.expense_shares es
    where es.expense_id = p_expense_id
      and es.participant_id = p_recipient_id
      and es.participant_id <> v_expense.payer_id
      and es.base_share_amount > 0
      and es.status in ('approved', 'payment_pending')
  ) then raise exception 'NO_REMINDABLE_DEBT'; end if;
  if not coalesce((
    select p.debt_reminders_enabled from public.profiles p
    where p.id = p_recipient_id
  ), true) then raise exception 'RECIPIENT_OPTED_OUT'; end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'splixa:reminder:' || v_actor_id::text || ':' || p_recipient_id::text,
      0
    )
  );
  if exists (
    select 1 from public.debt_reminders dr
    where dr.expense_id = p_expense_id
      and dr.sender_id = v_actor_id
      and dr.recipient_id = p_recipient_id
      and dr.created_at > now() - interval '24 hours'
  ) then raise exception 'REMINDER_RATE_LIMITED'; end if;
  if (
    select count(*) from public.debt_reminders dr
    where dr.sender_id = v_actor_id
      and dr.created_at > now() - interval '24 hours'
  ) >= 5 then raise exception 'REMINDER_DAILY_LIMIT_REACHED'; end if;

  insert into public.debt_reminders (expense_id, sender_id, recipient_id)
  values (p_expense_id, v_actor_id, p_recipient_id)
  returning id into v_reminder_id;

  insert into public.notifications (
    recipient_id, sender_id, group_id, expense_id, type, is_read
  ) values (
    p_recipient_id, v_actor_id, v_expense.group_id,
    p_expense_id, 'debt_reminder', false
  );

  return jsonb_build_object(
    'reminder_id', v_reminder_id,
    'recipient_id', p_recipient_id,
    'group_id', v_expense.group_id,
    'expense_id', p_expense_id,
    'description', v_expense.description
  );
end;
$$;

revoke all on function public.send_debt_reminder_v1(uuid, uuid)
  from public, anon;
grant execute on function public.send_debt_reminder_v1(uuid, uuid)
  to authenticated;

commit;
