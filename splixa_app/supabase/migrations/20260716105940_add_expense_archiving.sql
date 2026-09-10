alter table public.group_transactions
  add column if not exists archived_at timestamptz null;

create or replace function public.archive_group_transaction(p_transaction_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_actor_id uuid := auth.uid();
  v_payer_id uuid;
  v_split_data jsonb;
  v_participant_id text;
  v_status text;
begin
  if v_actor_id is null then
    raise exception 'Not authenticated';
  end if;

  select payer_id, split_data
    into v_payer_id, v_split_data
  from public.group_transactions
  where id = p_transaction_id
  for update;

  if not found then
    raise exception 'Transaction not found';
  end if;

  if v_actor_id <> v_payer_id then
    raise exception 'Only the creditor can archive this expense';
  end if;

  for v_participant_id, v_status in
    select key, lower(coalesce(value ->> 'status', 'approved'))
    from jsonb_each(coalesce(v_split_data, '{}'::jsonb))
  loop
    if v_participant_id <> v_payer_id::text and v_status <> 'settled' then
      raise exception 'All participants must be settled before archiving';
    end if;
  end loop;

  update public.group_transactions
  set archived_at = timezone('utc'::text, now())
  where id = p_transaction_id
    and archived_at is null;
end;
$function$;;
