  -- Harden mutable financial/social rows, lock down helper RPCs, and provide an
  -- atomic server-side rate limiter for the public login Edge Function.

  -- PostgreSQL combines permissive policies with OR. Remove every UPDATE/DELETE
  -- policy that could keep broader legacy access alive before adding replacements.
  do $$
  declare
    policy_row record;
  begin
    for policy_row in
      select schemaname, tablename, policyname
      from pg_policies
      where schemaname = 'public'
        and (
          (tablename = 'transactions' and cmd in ('UPDATE', 'DELETE', 'ALL'))
          or (tablename in ('friendships', 'direct_messages') and cmd in ('UPDATE', 'ALL'))
        )
    loop
      execute format(
        'drop policy if exists %I on %I.%I',
        policy_row.policyname,
        policy_row.schemaname,
        policy_row.tablename
      );
    end loop;
  end
  $$;

  -- A transaction can only be changed or removed by its owner/creator.
  grant update, delete on table public.transactions to authenticated;

  create policy transactions_update_owner_only
  on public.transactions
  for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

  create policy transactions_delete_owner_only
  on public.transactions
  for delete
  to authenticated
  using (user_id = (select auth.uid()));

  -- The requester cannot accept their own friendship request. Only the receiver
  -- may transition a pending request to accepted, and only `status` is writable.
  revoke update on table public.friendships from authenticated;
  grant update (status) on table public.friendships to authenticated;

  create policy friendships_accept_by_receiver_only
  on public.friendships
  for update
  to authenticated
  using (
    user_id2 = (select auth.uid())
    and status = 'pending'
  )
  with check (
    user_id2 = (select auth.uid())
    and status = 'accepted'
  );

  -- A direct-message receiver may only update read_status. Column privileges
  -- prevent edits to sender_id, receiver_id, message content, or timestamps.
  revoke update on table public.direct_messages from authenticated;
  grant update (read_status) on table public.direct_messages to authenticated;

  create policy direct_messages_update_read_status_by_receiver
  on public.direct_messages
  for update
  to authenticated
  using (receiver_id = (select auth.uid()))
  with check (receiver_id = (select auth.uid()));

  revoke all on table public.transactions, public.friendships, public.direct_messages from anon;

  -- Remove PUBLIC/anon execution inherited from PostgreSQL's default function ACL.
  do $$
  begin
    if to_regprocedure('public.check_username_exists(text)') is not null then
      execute 'revoke all on function public.check_username_exists(text) from public, anon, authenticated';
      execute 'grant execute on function public.check_username_exists(text) to authenticated, service_role';
    end if;

    if to_regprocedure('public.is_group_member(uuid,uuid)') is not null then
      execute 'revoke all on function public.is_group_member(uuid, uuid) from public, anon, authenticated';
      execute 'grant execute on function public.is_group_member(uuid, uuid) to authenticated, service_role';
    end if;
  end
  $$;

  -- The table is API-visible only so the Edge Function can use Supabase RPC.
  -- RLS plus revoked privileges keep all client roles out; bucket keys are hashes.
  create table if not exists public.auth_login_rate_limits (
    bucket_key text primary key,
    window_started_at timestamptz not null default timezone('utc', now()),
    attempt_count integer not null default 1 check (attempt_count > 0),
    updated_at timestamptz not null default timezone('utc', now())
  );

  alter table public.auth_login_rate_limits enable row level security;
  revoke all on table public.auth_login_rate_limits from public, anon, authenticated;
  grant select, insert, update, delete on table public.auth_login_rate_limits to service_role;

  create or replace function public.consume_login_rate_limit(
    p_bucket_key text,
    p_max_attempts integer,
    p_window_seconds integer
  )
  returns table (allowed boolean, retry_after_seconds integer)
  language plpgsql
  security definer
  set search_path = ''
  as $$
  declare
    v_now timestamptz := timezone('utc', now());
    v_window_started timestamptz;
    v_attempts integer;
    v_window_size interval;
  begin
    if p_bucket_key is null or length(p_bucket_key) < 16 or length(p_bucket_key) > 160 then
      raise exception 'Invalid rate-limit bucket';
    end if;
    if p_max_attempts < 1 or p_max_attempts > 1000 then
      raise exception 'Invalid rate-limit maximum';
    end if;
    if p_window_seconds < 60 or p_window_seconds > 86400 then
      raise exception 'Invalid rate-limit window';
    end if;

    v_window_size := make_interval(secs => p_window_seconds);

    insert into public.auth_login_rate_limits as limits (
      bucket_key,
      window_started_at,
      attempt_count,
      updated_at
    )
    values (p_bucket_key, v_now, 1, v_now)
    on conflict (bucket_key) do update
    set
      window_started_at = case
        when limits.window_started_at <= v_now - v_window_size then v_now
        else limits.window_started_at
      end,
      attempt_count = case
        when limits.window_started_at <= v_now - v_window_size then 1
        else limits.attempt_count + 1
      end,
      updated_at = v_now
    returning limits.window_started_at, limits.attempt_count
    into v_window_started, v_attempts;

    allowed := v_attempts <= p_max_attempts;
    retry_after_seconds := case
      when allowed then 0
      else greatest(
        1,
        ceil(extract(epoch from (v_window_started + v_window_size - v_now)))::integer
      )
    end;

    return next;

    -- Opportunistic cleanup bounds table growth without a scheduled job.
    if random() < 0.01 then
      delete from public.auth_login_rate_limits
      where updated_at < v_now - interval '2 days';
    end if;
  end;
  $$;

  revoke all on function public.consume_login_rate_limit(text, integer, integer)
  from public, anon, authenticated;
  grant execute on function public.consume_login_rate_limit(text, integer, integer)
  to service_role;
