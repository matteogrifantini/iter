-- Iter — schema Supabase (Postgres)
-- Applicare in ordine: schema.sql, seed.sql

-- Estensioni
create extension if not exists "pgcrypto";

-- Catalogo destinazioni (città o percorsi)
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

-- Punti d'interesse
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

-- Profili utente (id = auth.uid())
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  theme_mode text not null default 'system' check (theme_mode in ('light', 'dark', 'system')),
  memory_tags text[] not null default '{}',
  updated_at timestamptz not null default now()
);

-- Viaggi (piano persistito)
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

-- Versioni del piano: ogni proposta accettata appende una riga, così il revert
-- e la cronologia restano verificabili (unique per trip + version_number).
create table if not exists public.trip_versions (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id) on delete cascade,
  version_number integer not null check (version_number > 0),
  draft jsonb not null,
  created_at timestamptz not null default now(),
  unique (trip_id, version_number)
);

-- Conversazioni
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

-- Messaggi
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

-- Indici
create index if not exists idx_pois_destination on public.pois (destination_id);
create index if not exists idx_trips_user on public.trips (user_id);
create index if not exists idx_trip_versions_trip on public.trip_versions (trip_id, created_at desc);
create index if not exists idx_conversations_user on public.conversations (user_id, updated_at desc);
create index if not exists idx_messages_conversation on public.messages (conversation_id, sent_at);

-- Row Level Security
alter table public.destinations enable row level security;
alter table public.pois enable row level security;
alter table public.profiles enable row level security;
alter table public.trips enable row level security;
alter table public.trip_versions enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;

-- Catalogo: lettura pubblica (anon + auth)
create policy "destinations public read"
  on public.destinations for select using (true);
create policy "pois public read"
  on public.pois for select using (true);

-- Profili: solo il proprietario
create policy "profiles owner select"
  on public.profiles for select using (auth.uid() = id);
create policy "profiles owner insert"
  on public.profiles for insert with check (auth.uid() = id);
create policy "profiles owner update"
  on public.profiles for update using (auth.uid() = id);

-- Trips: solo il proprietario
create policy "trips owner all"
  on public.trips for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Trip versions: append-only, via il trip del proprietario
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

-- Conversazioni: solo il proprietario
create policy "conversations owner all"
  on public.conversations for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Messaggi: via conversazione del proprietario
create policy "messages owner select"
  on public.messages for select using (
    exists (select 1 from public.conversations c
            where c.id = messages.conversation_id and c.user_id = auth.uid())
  );
create policy "messages owner insert"
  on public.messages for insert with check (
    exists (select 1 from public.conversations c
            where c.id = messages.conversation_id and c.user_id = auth.uid())
  );
