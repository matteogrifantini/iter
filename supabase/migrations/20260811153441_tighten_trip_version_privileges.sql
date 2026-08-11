revoke all privileges on table public.trip_versions from anon, authenticated;
grant select, insert on table public.trip_versions to authenticated;

drop policy if exists "trip versions owner select" on public.trip_versions;
create policy "trip versions owner select"
on public.trip_versions for select to authenticated
using (
  (select (auth.jwt()->>'is_anonymous')::boolean) is false
  and exists (
    select 1 from public.trips t
    where t.id = trip_versions.trip_id
      and t.user_id = (select auth.uid())
  )
);

drop policy if exists "trip versions owner insert" on public.trip_versions;
create policy "trip versions owner insert"
on public.trip_versions for insert to authenticated
with check (
  (select (auth.jwt()->>'is_anonymous')::boolean) is false
  and exists (
    select 1 from public.trips t
    where t.id = trip_versions.trip_id
      and t.user_id = (select auth.uid())
  )
);

revoke execute on function public.save_trip_revision(
  uuid, text, text, jsonb, jsonb, integer
) from public, anon;
grant execute on function public.save_trip_revision(
  uuid, text, text, jsonb, jsonb, integer
) to authenticated;
