-- Safe remote Phase 4 guard test. Uses one existing non-Pro account, creates
-- only rollback-scoped rows, and proves direct RPC/database calls cannot skip
-- the free limits or paid ledger gates.

begin;

do $smoke$
declare
  v_user_id uuid;
  v_count integer;
  v_rejected boolean;
begin
  select u.id
  into v_user_id
  from auth.users u
  join public.profiles p on p.id = u.id
  where not public.has_active_pro_entitlement(u.id)
  order by u.created_at
  limit 1;

  if not found then
    raise notice 'PHASE4_PRO_GUARDS_SKIPPED: no non-Pro fixture account';
    return;
  end if;

  perform set_config('request.jwt.claim.sub', v_user_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub', v_user_id::text,
      'role', 'authenticated',
      'app_metadata', '{}'::jsonb
    )::text,
    true
  );

  -- Bring the rollback-scoped current-month count exactly to the free ceiling.
  v_count := public.splixa_personal_expense_count(v_user_id);
  while v_count < 50 loop
    perform public.create_personal_transaction_v1(
      1, 'TRY', 1, 'TRY', 1, 'identity', now(),
      'Market', current_date, 'expense'
    );
    v_count := v_count + 1;
  end loop;

  v_rejected := false;
  begin
    perform public.create_personal_transaction_v1(
      1, 'TRY', 1, 'TRY', 1, 'identity', now(),
      'Market', current_date, 'expense'
    );
  exception when others then
    v_rejected := sqlerrm like '%FREE_PERSONAL_EXPENSE_LIMIT_REACHED%';
  end;
  if not v_rejected then
    raise exception 'Personal expense RPC bypassed the 50/month server limit';
  end if;

  -- Income avoids the expense quota and isolates the two paid feature gates.
  v_rejected := false;
  begin
    perform public.create_personal_transaction_v1(
      1, 'TRY', 1, 'TRY', 1, 'identity', now(),
      'ROLLBACK_CUSTOM_CATEGORY', current_date, 'income'
    );
  exception when others then
    v_rejected := sqlerrm like '%PRO_REQUIRED_CUSTOM_CATEGORY%';
  end;
  if not v_rejected then
    raise exception 'Direct ledger write bypassed the custom-category Pro gate';
  end if;

  v_rejected := false;
  begin
    perform public.create_personal_transaction_v1(
      1, 'TRY', 1, 'TRY', 1, 'manual_user_locked', now(),
      'Market', current_date, 'income'
    );
  exception when others then
    v_rejected := sqlerrm like '%PRO_REQUIRED_CUSTOM_EXCHANGE_RATE%';
  end;
  if not v_rejected then
    raise exception 'Direct ledger write bypassed the custom-FX Pro gate';
  end if;

  while public.splixa_group_count(v_user_id) < 2 loop
    perform public.create_group_v1(
      'ROLLBACK_ONLY_PHASE4_LIMIT_' || public.splixa_group_count(v_user_id)
    );
  end loop;

  v_rejected := false;
  begin
    perform public.create_group_v1('ROLLBACK_ONLY_PHASE4_THIRD_GROUP');
  exception when others then
    v_rejected := sqlerrm like '%FREE_GROUP_LIMIT_REACHED%';
  end;
  if not v_rejected then
    raise exception 'Group RPC bypassed the two-group server limit';
  end if;

  raise notice
    'PHASE4_PRO_GUARDS_PASSED limits/custom-category/custom-FX; all writes roll back';
end
$smoke$;

rollback;
