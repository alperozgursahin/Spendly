-- Safe account-deletion smoke test. It runs preparation against one eligible
-- production-shaped user and rolls back every mutation.

begin;

do $smoke$
declare
  v_user_id uuid;
  v_result jsonb;
  v_before_balances jsonb;
  v_after_balances jsonb;
  v_solo_group_ids uuid[] := array[]::uuid[];
begin
  select auth_user.id
  into v_user_id
  from auth.users auth_user
  where not exists (
    select 1
    from public.groups owned_group
    where owned_group.created_by = auth_user.id
      and exists (
        select 1
        from public.group_members other_member
        where other_member.group_id = owned_group.id
          and other_member.user_id <> auth_user.id
      )
  )
    and (
      exists (
        select 1 from public.expenses expense
        where expense.created_by = auth_user.id
           or expense.payer_id = auth_user.id
      )
      or exists (
        select 1 from public.expense_shares share
        where share.participant_id = auth_user.id
      )
      or exists (
        select 1 from public.settlements settlement
        where settlement.created_by = auth_user.id
           or settlement.paid_by = auth_user.id
           or settlement.received_by = auth_user.id
      )
    )
  order by auth_user.created_at
  limit 1;

  if not found then
    raise notice
      'ACCOUNT_DELETION_SMOKE_SKIPPED: no eligible user with ledger history';
    return;
  end if;

  select coalesce(array_agg(owned_group.id), array[]::uuid[])
  into v_solo_group_ids
  from public.groups owned_group
  where owned_group.created_by = v_user_id
    and not exists (
      select 1
      from public.group_members other_member
      where other_member.group_id = owned_group.id
        and other_member.user_id <> v_user_id
    );

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
  join auth.users remaining_user on remaining_user.id = balance.user_id
  where balance.user_id <> v_user_id
    and not (balance.group_id = any(v_solo_group_ids));

  v_result := public.prepare_account_deletion_v1(v_user_id);
  if not coalesce((v_result ->> 'prepared')::boolean, false) then
    raise exception 'Account deletion preparation did not succeed: %', v_result;
  end if;

  if exists (
    select 1 from public.expenses expense
    where expense.created_by = v_user_id or expense.payer_id = v_user_id
  ) or exists (
    select 1 from public.expense_shares share
    where share.participant_id = v_user_id
  ) or exists (
    select 1 from public.settlements settlement
    where settlement.created_by = v_user_id
       or settlement.paid_by = v_user_id
       or settlement.received_by = v_user_id
  ) or exists (
    select 1 from public.group_transactions legacy
    where legacy.payer_id = v_user_id
       or coalesce(legacy.split_data, '{}'::jsonb) ? v_user_id::text
  ) then
    raise exception 'Deleted Auth UUID remains in a financial actor field';
  end if;

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
  join auth.users remaining_user on remaining_user.id = balance.user_id
  where balance.user_id <> v_user_id
    and not (balance.group_id = any(v_solo_group_ids));

  if v_before_balances is distinct from v_after_balances then
    raise exception 'Remaining-user balances changed during deletion preparation';
  end if;

  if not exists (
    select 1
    from public.profiles profile
    where profile.id = v_user_id
      and profile.is_deleted
      and profile.email is null
      and profile.avatar_url is null
  ) then
    raise exception 'Profile was not anonymized';
  end if;

  raise notice
    'ACCOUNT_DELETION_SMOKE_PASSED for %; all changes will be rolled back',
    v_user_id;
end
$smoke$;

rollback;
