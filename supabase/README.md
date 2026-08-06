# Supabase setup — guida

Iter usa Supabase (Postgres + Auth) come backend. In debug/test l'app gira sul
mock locale; Supabase è il percorso reale, attivato da `--dart-define=ITER_SUPABASE_ON=true`
o in release.

## 1. Crea il progetto

1. Vai su https://supabase.com e accedi.
2. "New project": scegli una regione vicina (es. `eu-central-1`), password DB
   (salvala), **non** partire dal template (vuoto).
3. Copia da **Project Settings → API**:
   - **Project URL** (es. `https://abcd1234.supabase.co`) → `SUPABASE_URL`
   - **anon public key** → `SUPABASE_ANON_KEY`
   - **service_role key** (segreta, solo per seed/CLI) → `SUPABASE_SERVICE_KEY`

Le chiavi **non** vanno mai nel client in repo: `SUPABASE_ANON_KEY` può stare
nel client, la `service_role` solo server-side/CLI.

## 2. Applica schema e seed

Opzione A — **SQL Editor** (semplice, senza CLI):

1. In Dashboard → **SQL Editor** apri `supabase/schema.sql`, esegui.
2. Poi apri `supabase/seed.sql`, esegui.

Opzione B — **Supabase CLI** (riproducibile):

```bash
npm install -g supabase
supabase login
supabase init          # crea supabase/ (se assente)
supabase link --project-ref <ref>   # ref = parte del Project URL
# incolla schema e seed come migration
supabase db push
```

Verifica: nella Dashboard → **Table Editor** vedi `destinations` (11 righe:
8 città + 3 percorsi) e `pois` (5 righe).

## 3. Configura il client Flutter

Crea `.env` locale nella root (mai committare):

```bash
SUPABASE_URL="https://abcd1234.supabase.co"
SUPABASE_ANON_KEY="eyJ..."
```

L'app legge queste variabili in build (vedi F0) e richiede
`--dart-define=ITER_SUPABASE_ON=true` per usare il percorso reale.

## 4. Auth anonima

La tabella `profiles` e i dati utente usano `auth.uid()`. In F0 l'app chiama
`supabase.auth.signInAnonymously()` al primo avvio: Supabase crea un utente
anonimo e la RLS lo lega alle sue righe. Il magic link (fase successiva) farà
l'upgrade della stessa identità.

## 5. RLS

Schema applicato con policy:

- `destinations`, `pois`: lettura pubblica (catalogo).
- `profiles`, `trips`, `conversations`, `messages`: solo proprietario
  (`auth.uid()`).

Se un'anonym sign-in non basta, attiva in Dashboard → **Authentication →
Providers → Email** il "Anonymous" provider (in alcuni piani va abilitato
esplicitamente).
