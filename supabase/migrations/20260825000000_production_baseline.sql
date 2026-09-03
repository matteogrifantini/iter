-- Iter — Baseline di produzione Supabase
-- Raccoglie la struttura completa per l'architettura Chat-First

create extension if not exists "pgcrypto";

-- 1. Catalogo destinazioni
create table if not exists public.destinations (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('city', 'route')),
  name text not null,
  country text,
  slug text unique not null,
  description text,
  emoji text,
  poster_asset text not null,
  video_assets text[] not null default '{}',
  stops text[] not null default '{}',
  travel_mode text,
  season text,
  duration_label text,
  match_score integer not null default 0,
  why_it_fits text,
  destination_ids text[] not null default '{}',
  tags text[] not null default '{}',
  created_at timestamptz not null default now()
);

-- 2. Punti d'interesse
create table if not exists public.pois (
  id uuid primary key default gen_random_uuid(),
  destination_id uuid not null references public.destinations (id) on delete cascade,
  name text not null,
  category text not null,
  emoji text,
  lat double precision,
  lng double precision,
  duration_min integer,
  best_moment text,
  why_fits text,
  media_asset text,
  created_at timestamptz not null default now()
);

-- 3. Profili utente
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  theme_mode text not null default 'system' check (theme_mode in ('light', 'dark', 'system')),
  memory_tags text[] not null default '{}',
  updated_at timestamptz not null default now()
);

-- 4. Viaggi
create table if not exists public.trips (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  destination_id uuid references public.destinations (id) on delete set null,
  status text not null default 'draft' check (status in ('draft', 'active', 'done')),
  snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 5. Versioni del piano
create table if not exists public.trip_versions (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id) on delete cascade,
  version_number integer not null check (version_number > 0),
  draft jsonb not null,
  created_at timestamptz not null default now(),
  unique (trip_id, version_number)
);

-- 6. Conversazioni
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  trip_id uuid references public.trips (id) on delete set null,
  title text not null,
  avatar_asset text,
  unread integer not null default 0,
  summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 7. Messaggi
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  kind text not null default 'text'
    check (kind in ('text', 'choice', 'image', 'video', 'audio', 'system',
                    'operational', 'tripSummary', 'planProposal',
                    'placeCard', 'transport', 'stayZone')),
  text text,
  audio_duration integer,
  proposal jsonb,
  content jsonb not null default '{}'::jsonb,
  sent_at timestamptz not null default now()
);

-- 8. Quota Guard AI (Free Tier Protection)
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

-- 9. Indici prestazionali
create index if not exists idx_destinations_match_score on public.destinations (match_score desc);
create index if not exists idx_pois_destination on public.pois (destination_id);
create index if not exists idx_trips_user on public.trips (user_id);
create index if not exists idx_trip_versions_trip on public.trip_versions (trip_id, created_at desc);
create index if not exists idx_conversations_user on public.conversations (user_id, updated_at desc);
create index if not exists idx_messages_conversation on public.messages (conversation_id, sent_at);

-- 10. Row Level Security
alter table public.destinations enable row level security;
alter table public.pois enable row level security;
alter table public.profiles enable row level security;
alter table public.trips enable row level security;
alter table public.trip_versions enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.ai_usage enable row level security;
alter table public.ai_global_usage enable row level security;

-- Policy Lettura pubblica per catalogo
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'destinations' and policyname = 'destinations public read') then
    create policy "destinations public read" on public.destinations for select using (true);
  end if;
  if not exists (select 1 from pg_policies where tablename = 'pois' and policyname = 'pois public read') then
    create policy "pois public read" on public.pois for select using (true);
  end if;
end $$;

-- Policy Profili
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'profiles' and policyname = 'profiles owner select') then
    create policy "profiles owner select" on public.profiles for select using (auth.uid() = id);
  end if;
  if not exists (select 1 from pg_policies where tablename = 'profiles' and policyname = 'profiles owner insert') then
    create policy "profiles owner insert" on public.profiles for insert with check (auth.uid() = id);
  end if;
  if not exists (select 1 from pg_policies where tablename = 'profiles' and policyname = 'profiles owner update') then
    create policy "profiles owner update" on public.profiles for update using (auth.uid() = id);
  end if;
end $$;

-- Policy Trips
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'trips' and policyname = 'trips owner all') then
    create policy "trips owner all" on public.trips for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
  end if;
end $$;

-- Policy Trip versions
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

-- Policy Conversazioni
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'conversations' and policyname = 'conversations owner all') then
    create policy "conversations owner all" on public.conversations for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
  end if;
end $$;

-- Policy Messaggi
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'messages' and policyname = 'messages owner select') then
    create policy "messages owner select" on public.messages for select using (
      exists (select 1 from public.conversations c where c.id = messages.conversation_id and c.user_id = auth.uid())
    );
  end if;
  if not exists (select 1 from pg_policies where tablename = 'messages' and policyname = 'messages owner insert') then
    create policy "messages owner insert" on public.messages for insert with check (
      exists (select 1 from public.conversations c where c.id = messages.conversation_id and c.user_id = auth.uid())
    );
  end if;
end $$;

-- Policy AI Usage
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'ai_usage' and policyname = 'users read own usage') then
    create policy "users read own usage" on public.ai_usage for select using (user_id = auth.uid());
  end if;
end $$;

-- 11. RPC Quota Guard
create or replace function public.consume_ai_credit(
  max_generations integer default 5,
  max_global_generations integer default 1500
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

-- 12. RPC di salvataggio atomico revisioni del piano
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
