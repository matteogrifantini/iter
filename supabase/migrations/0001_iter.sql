-- Iter MVP. Apply with the Supabase CLI or SQL editor after creating iter-preview / iter-demo.
create extension if not exists "pgcrypto";

create table if not exists public.trips (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  city_id text not null,
  title text not null,
  brief jsonb not null,
  status text not null default 'draft' check (status in ('draft', 'saved', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.trip_versions (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  version_number integer not null check (version_number > 0),
  draft jsonb not null,
  created_at timestamptz not null default now(),
  unique (trip_id, version_number)
);

create table if not exists public.itinerary_items (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references public.trip_versions(id) on delete cascade,
  day_index integer not null check (day_index > 0),
  position integer not null check (position > 0),
  poi_id text not null,
  payload jsonb not null,
  locked boolean not null default false,
  created_at timestamptz not null default now(),
  unique (version_id, day_index, position)
);

create table if not exists public.source_cache (
  cache_key text primary key,
  provider text not null,
  payload jsonb not null,
  fetched_at timestamptz not null default now(),
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table if not exists public.ai_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_date date not null default current_date,
  generation_count integer not null default 0 check (generation_count >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, usage_date)
);

create table if not exists public.ai_global_usage (
  usage_date date primary key default current_date,
  generation_count integer not null default 0 check (generation_count >= 0),
  updated_at timestamptz not null default now()
);

create index if not exists trips_owner_updated_idx on public.trips(owner_id, updated_at desc);
create index if not exists trip_versions_trip_created_idx on public.trip_versions(trip_id, created_at desc);
create index if not exists source_cache_expires_idx on public.source_cache(expires_at);

alter table public.trips enable row level security;
alter table public.trip_versions enable row level security;
alter table public.itinerary_items enable row level security;
alter table public.source_cache enable row level security;
alter table public.ai_usage enable row level security;
alter table public.ai_global_usage enable row level security;

create policy "owners manage their trips" on public.trips
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy "owners read and create trip versions" on public.trip_versions
  for all using (
    exists (select 1 from public.trips where trips.id = trip_versions.trip_id and trips.owner_id = auth.uid())
  ) with check (
    exists (select 1 from public.trips where trips.id = trip_versions.trip_id and trips.owner_id = auth.uid())
  );

create policy "owners manage itinerary items" on public.itinerary_items
  for all using (
    exists (
      select 1
      from public.trip_versions
      join public.trips on trips.id = trip_versions.trip_id
      where trip_versions.id = itinerary_items.version_id and trips.owner_id = auth.uid()
    )
  ) with check (
    exists (
      select 1
      from public.trip_versions
      join public.trips on trips.id = trip_versions.trip_id
      where trip_versions.id = itinerary_items.version_id and trips.owner_id = auth.uid()
    )
  );

-- Cache is server-owned; browser clients receive source snapshots only through application routes.
create policy "users read own usage" on public.ai_usage
  for select using (user_id = auth.uid());

create or replace function public.consume_ai_credit(
  max_generations integer default 2,
  max_global_generations integer default 70
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  user_accepted boolean;
  global_accepted boolean;
begin
  if auth.uid() is null then
    return false;
  end if;

  insert into public.ai_global_usage (usage_date, generation_count)
  values (current_date, 1)
  on conflict (usage_date) do update
  set generation_count = public.ai_global_usage.generation_count + 1,
      updated_at = now()
  where public.ai_global_usage.generation_count < max_global_generations
  returning true into global_accepted;

  if not coalesce(global_accepted, false) then
    return false;
  end if;

  insert into public.ai_usage (user_id, usage_date, generation_count)
  values (auth.uid(), current_date, 1)
  on conflict (user_id, usage_date) do update
  set generation_count = public.ai_usage.generation_count + 1,
      updated_at = now()
  where public.ai_usage.generation_count < max_generations
  returning true into user_accepted;

  if not coalesce(user_accepted, false) then
    update public.ai_global_usage
    set generation_count = greatest(generation_count - 1, 0),
        updated_at = now()
    where usage_date = current_date;
  end if;

  return coalesce(user_accepted, false);
end;
$$;

revoke all on function public.consume_ai_credit(integer, integer) from public;
grant execute on function public.consume_ai_credit(integer, integer) to authenticated;
