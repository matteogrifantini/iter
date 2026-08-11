grant select, insert on table public.trip_versions to authenticated;

create policy "trip versions owner select"
on public.trip_versions for select to authenticated
using (exists (
  select 1 from public.trips t
  where t.id = trip_versions.trip_id
    and t.user_id = (select auth.uid())
));

create policy "trip versions owner insert"
on public.trip_versions for insert to authenticated
with check (exists (
  select 1 from public.trips t
  where t.id = trip_versions.trip_id
    and t.user_id = (select auth.uid())
));
