grant select, insert on table public.trip_versions to authenticated;

drop policy if exists "trip versions owner select" on public.trip_versions;
create policy "trip versions owner select"
on public.trip_versions for select to authenticated
using (exists (
  select 1 from public.trips t
  where t.id = trip_versions.trip_id
    and t.user_id = (select auth.uid())
));

drop policy if exists "trip versions owner insert" on public.trip_versions;
create policy "trip versions owner insert"
on public.trip_versions for insert to authenticated
with check (exists (
  select 1 from public.trips t
  where t.id = trip_versions.trip_id
    and t.user_id = (select auth.uid())
));

create or replace function public.save_trip_revision(
  p_conversation_id uuid,
  p_title text,
  p_status text,
  p_snapshot jsonb,
  p_summary jsonb,
  p_revision integer
)
returns boolean
language plpgsql
volatile
security invoker
set search_path = ''
as $$
declare
  v_trip_id uuid;
  v_latest_revision integer;
begin
  if p_revision <= 0 then
    raise exception 'Trip revision must be positive'
      using errcode = '22023';
  end if;

  select c.trip_id
  into v_trip_id
  from public.conversations as c
  where c.id = p_conversation_id
    and c.user_id = (select auth.uid())
  for update;

  if not found then
    raise exception 'Conversation not found'
      using errcode = 'P0002';
  end if;

  if v_trip_id is null then
    insert into public.trips (user_id, title, status, snapshot)
    values ((select auth.uid()), p_title, p_status, p_snapshot)
    returning id into v_trip_id;

    update public.conversations
    set trip_id = v_trip_id,
        updated_at = pg_catalog.now()
    where id = p_conversation_id;
  else
    perform t.id
    from public.trips as t
    where t.id = v_trip_id
      and t.user_id = (select auth.uid())
    for update;

    if not found then
      raise exception 'Trip not found'
        using errcode = 'P0002';
    end if;
  end if;

  select max(tv.version_number)
  into v_latest_revision
  from public.trip_versions as tv
  where tv.trip_id = v_trip_id;

  insert into public.trip_versions (trip_id, version_number, draft)
  values (v_trip_id, p_revision, p_snapshot)
  on conflict (trip_id, version_number) do nothing;

  if v_latest_revision is not null
     and p_revision <= v_latest_revision then
    return true;
  end if;

  update public.trips
  set title = p_title,
      status = p_status,
      snapshot = p_snapshot,
      updated_at = pg_catalog.now()
  where id = v_trip_id;

  update public.conversations
  set summary = p_summary,
      updated_at = pg_catalog.now()
  where id = p_conversation_id;

  return true;
end;
$$;

revoke execute on function public.save_trip_revision(
  uuid, text, text, jsonb, jsonb, integer
) from public, anon;
grant execute on function public.save_trip_revision(
  uuid, text, text, jsonb, jsonb, integer
) to authenticated;
