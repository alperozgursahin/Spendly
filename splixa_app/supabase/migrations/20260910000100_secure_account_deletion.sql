-- Secure, idempotent preparation for hard account deletion.
--
-- The Edge Function verifies the caller and invokes this RPC with the service
-- role. Authenticated clients cannot invoke it directly. Financial facts are
-- retained, but the deleted user's auth UUID is replaced by an unlinked random
-- actor UUID. This preserves every other member's balance exactly while
-- severing the ledger's identity link to the deleted account.

begin;

alter table public.profiles
  add column if not exists is_deleted boolean not null default false,
  add column if not exists deleted_at timestamptz;

-- Legacy group transactions are financial history. A payer FK that cascades
-- from auth.users/profiles would also fire the compatibility delete trigger and
-- erase the normalized expense. Decouple this actor identifier just as the V1
-- expenses/settlements tables already do.
do $$
declare
  v_constraint record;
begin
  for v_constraint in
    select constraint_row.conname
    from pg_catalog.pg_constraint constraint_row
    join pg_catalog.pg_attribute attribute_row
      on attribute_row.attrelid = constraint_row.conrelid
     and attribute_row.attnum = any(constraint_row.conkey)
    where constraint_row.contype = 'f'
      and constraint_row.conrelid = 'public.group_transactions'::regclass
      and attribute_row.attname = 'payer_id'
  loop
    execute format(
      'alter table public.group_transactions drop constraint %I',
      v_constraint.conname
    );
  end loop;
end
$$;

comment on column public.group_transactions.payer_id is
  'Historical actor UUID; intentionally not foreign-keyed so account deletion cannot erase shared financial history.';

create or replace function public.check_account_deletion_v1(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owned_groups jsonb;
begin
  if p_user_id is null then
    return jsonb_build_object(
      'allowed', false,
      'code', 'INVALID_USER',
      'message', 'A user id is required.'
    );
  end if;

  -- Splixa currently models the group creator as its only administrator.
  -- A creator must transfer/delete a group that still has another member;
  -- otherwise auth deletion could leave a group without an administrator.
  select coalesce(
    jsonb_agg(
      jsonb_build_object('id', g.id, 'name', g.name)
      order by g.created_at, g.id
    ),
    '[]'::jsonb
  )
  into v_owned_groups
  from public.groups g
  where g.created_by = p_user_id
    and exists (
      select 1
      from public.group_members gm
      where gm.group_id = g.id
        and gm.user_id <> p_user_id
    );

  if jsonb_array_length(v_owned_groups) > 0 then
    return jsonb_build_object(
      'allowed', false,
      'code', 'GROUP_OWNERSHIP_REQUIRED',
      'message',
        'Transfer ownership or delete the listed groups before deleting your account.',
      'groups', v_owned_groups
    );
  end if;

  return jsonb_build_object('allowed', true);
end;
$$;

revoke all on function public.check_account_deletion_v1(uuid)
  from public, anon, authenticated;
grant execute on function public.check_account_deletion_v1(uuid)
  to service_role;

create or replace function public.prepare_account_deletion_v1(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_check jsonb;
  v_deleted_actor_id uuid := pg_catalog.gen_random_uuid();
  v_solo_group_ids uuid[] := array[]::uuid[];
  v_before_balances jsonb;
  v_after_balances jsonb;
begin
  if p_user_id is null then
    return jsonb_build_object(
      'allowed', false,
      'code', 'INVALID_USER',
      'message', 'A user id is required.'
    );
  end if;

  -- Serialize deletion preparation for the same account. The second call is
  -- intentionally safe if Auth deletion or the network failed after phase one.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_user_id::text, 0)
  );

  v_check := public.check_account_deletion_v1(p_user_id);
  if not coalesce((v_check ->> 'allowed')::boolean, false) then
    return v_check;
  end if;

  select coalesce(array_agg(g.id order by g.id), array[]::uuid[])
  into v_solo_group_ids
  from public.groups g
  where g.created_by = p_user_id
    and not exists (
      select 1
      from public.group_members gm
      where gm.group_id = g.id
        and gm.user_id <> p_user_id
    );

  -- Snapshot every balance except the departing actor and groups with no
  -- remaining members. Exact equality is rechecked before this transaction can
  -- commit; any unexpected delta rolls the whole preparation back.
  select coalesce(
    jsonb_agg(
      jsonb_build_array(
        balance.group_id::text,
        balance.user_id::text,
        balance.currency_code,
        balance.balance::text
      )
      order by balance.group_id, balance.user_id, balance.currency_code
    ),
    '[]'::jsonb
  )
  into v_before_balances
  from public.group_balances_v1 balance
  where balance.user_id <> p_user_id
    and not (balance.group_id = any(v_solo_group_ids));

  -- A group with no other member has no third-party history to preserve.
  -- Group-owned rows, including normalized financial rows, cascade safely.
  delete from public.groups
  where id = any(v_solo_group_ids);

  -- De-identify the compatibility ledger too. Its trigger mirrors these new
  -- actor keys into normalized legacy rows, preventing a later legacy update
  -- from reintroducing the deleted Auth UUID.
  update public.group_transactions transaction_row
  set payer_id = case
        when transaction_row.payer_id = p_user_id
          then v_deleted_actor_id
        else transaction_row.payer_id
      end,
      split_data = coalesce(
        (
          select jsonb_object_agg(
            case
              when split_entry.key = p_user_id::text
                then v_deleted_actor_id::text
              else split_entry.key
            end,
            split_entry.value
          )
          from jsonb_each(coalesce(transaction_row.split_data, '{}'::jsonb))
            split_entry
        ),
        '{}'::jsonb
      )
  where transaction_row.payer_id = p_user_id
     or coalesce(transaction_row.split_data, '{}'::jsonb) ? p_user_id::text;

  -- Retain immutable financial facts while removing the auth identity. The
  -- random replacement is not stored alongside the old UUID, so there is no
  -- application-level lookup back to the deleted account.
  update public.expenses
  set created_by = case
        when created_by = p_user_id then v_deleted_actor_id
        else created_by
      end,
      payer_id = case
        when payer_id = p_user_id then v_deleted_actor_id
        else payer_id
      end
  where created_by = p_user_id or payer_id = p_user_id;

  update public.expense_shares
  set participant_id = v_deleted_actor_id
  where participant_id = p_user_id;

  update public.settlements
  set created_by = case
        when created_by = p_user_id then v_deleted_actor_id
        else created_by
      end,
      paid_by = case
        when paid_by = p_user_id then v_deleted_actor_id
        else paid_by
      end,
      received_by = case
        when received_by = p_user_id then v_deleted_actor_id
        else received_by
      end,
      legacy_migration_key = case
        when legacy_migration_key is not null
          then replace(
            legacy_migration_key,
            p_user_id::text,
            v_deleted_actor_id::text
          )
        else null
      end
  where created_by = p_user_id
     or paid_by = p_user_id
     or received_by = p_user_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_array(
        balance.group_id::text,
        balance.user_id::text,
        balance.currency_code,
        balance.balance::text
      )
      order by balance.group_id, balance.user_id, balance.currency_code
    ),
    '[]'::jsonb
  )
  into v_after_balances
  from public.group_balances_v1 balance
  where balance.user_id <> v_deleted_actor_id
    and not (balance.group_id = any(v_solo_group_ids));

  if v_before_balances is distinct from v_after_balances then
    raise exception using
      errcode = 'P0001',
      message = 'ACCOUNT_DELETION_BALANCE_GUARD_FAILED';
  end if;

  -- Private/non-financial data is erased. Shared financial descriptions and
  -- facts remain because other group members have a legitimate history need.
  delete from public.group_chat_reads where user_id = p_user_id;
  delete from public.group_messages where sender_id = p_user_id;
  delete from public.direct_messages
    where sender_id = p_user_id or receiver_id = p_user_id;
  delete from public.friendships
    where user_id1 = p_user_id or user_id2 = p_user_id;
  delete from public.notifications
    where recipient_id = p_user_id or sender_id = p_user_id;
  delete from public.transactions where user_id = p_user_id;
  delete from public.group_members where user_id = p_user_id;

  -- If profiles has ON DELETE CASCADE this tombstone is removed by Auth. If it
  -- does not, it remains non-identifying and prevents stale PII from leaking.
  update public.profiles
  set username = 'deleted_' || left(replace(v_deleted_actor_id::text, '-', ''), 12),
      email = null,
      avatar_url = null,
      bio = null,
      is_deleted = true,
      deleted_at = timezone('utc', now())
  where id = p_user_id;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'full_name'
  ) then
    execute 'update public.profiles set full_name = null where id = $1'
      using p_user_id;
  end if;

  return jsonb_build_object(
    'allowed', true,
    'prepared', true,
    'deleted_solo_group_count', cardinality(v_solo_group_ids),
    'deleted_solo_group_ids', to_jsonb(v_solo_group_ids)
  );
end;
$$;

revoke all on function public.prepare_account_deletion_v1(uuid)
  from public, anon, authenticated;
grant execute on function public.prepare_account_deletion_v1(uuid)
  to service_role;

comment on function public.prepare_account_deletion_v1(uuid) is
  'Service-role-only transactional preparation for hard Auth account deletion.';

commit;
