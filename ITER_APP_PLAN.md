# Iter — Piano: l'app comincia a funzionare

> Aggiornato il 6 agosto 2026. Documento canonico per portare Iter da
> prototipo mock a prototipo funzionante con dati reali. Questo piano ragiona
> **sulla nuova idea di app (chat-first)**, non sul flusso del masterplan
> legacy; `NEW_TRIP_MASTER_PLAN.md` resta riferimento per contenuti e vincoli,
> `PRODUCT.md` per la visione, `DESIGN.md` per la direzione visiva.

## La nuova idea di app

Iter non è un questionario che porta a un piano. **Il viaggio è una
conversazione**: la chat è il foglio dove il viaggio si forma e si modifica, e
il piano è l'oggetto vivo che ne resta fuori, sempre visibile e persistente.

Da questo derivano principi che cambiano il design rispetto al masterplan:

1. **Niente flusso di schermate lineare.** Il masterplan era una sequenza
   (intake → curation → trasporto → zona → itinerario). Qui non esistono "step":
   esistono superfici che sono viste della conversazione/viaggio, e il progresso
   vive nello stato della conversazione.
2. **L'intake è una conversazione, non un Lab separato.** Le domande Semplice
   (una alla volta, conferme contestuali) si esprimono **nel thread** come
   scelte/messaggi, non in schermate Lab a parte. Il Lab resta come intelligenza
   di raccolta, non come UI.
3. **Il piano è versionato.** Accettare/annullare una proposta crea una nuova
   versione del piano (log append-only). Revert e trasparenza sono possibili.
4. **Le fasi del masterplan diventano moduli conversazionali.** Curation,
   trasporto, zona, itinerario entrano nella chat come card, scelte e contesti;
   il piano si aggiorna. Nessuna superficie drag/undo in questa iterazione.
5. **La memoria attraversa i viaggi.** `profiles.memory_tags` fa sì che Iter
   ricordi stile, ritmo e gusti tra un viaggio e l'altro.
6. **Non è un chatbot puro.** La chat propone; il piano resta ispezionabile e
   ogni modifica importante richiede conferma esplicita (accept/reject).
7. **Proattività.** Un viaggio attivo invia aggiornamenti (badge non letti),
   come nel prototipo Roma.

### Lifecycle di un viaggio

```text
idea        conversazione che scopre e raccoglie vincoli (intake inline)
plan        piano bozza con proposte accettate/annullate (versioni)
active      viaggio in corso: aggiornamenti proattivi, modifiche via chat
done        archivio in Viaggi
```

Ogni fase è una conversazione con stato; il piano è l'artefatto che le unisce.

## Architettura

```text
Flutter app (shell chat-first)
  │
  ├─ DataSource (interfaccia)
  │    ├─ MockDataSource      → demo deterministiche + test (debug default)
  │    └─ SupabaseDataSource  → Supabase Postgres (define/release)
  │
  ├─ supabase_flutter (auth anon + client)
  ├─ MCP Supabase (strumento per questo progetto: schema/seed/query)
  ├─ Edge Function AI proxy (fase F4; chiavi mai nel client)
  └─ assets/ locali (media con riferimenti in DB)
```

- Il controller chat-first parla con `DataSource`, mai col DB direttamente.
- `IterStore` e provider legacy restano intoccati dal percorso chat-first.

## Modello dati (Supabase Postgres)

RLS: catalogo in lettura pubblica; righe utente per `auth.uid()`.

- `destinations` — città o percorso (`type city|route`); nome, paese, slug,
  descrizione, emoji, `poster_asset`, `video_assets[]`, `stops[]`, `mode`,
  `season`, `duration_label`, `match_score`, `why_it_fits`,
  `destination_ids[]`, tag.
- `pois` — id, `destination_id`, nome, categoria, emoji, coordinate, durata,
  momento migliore, `why_fits`, media ref.
- `profiles` — `id = auth.uid()`, `theme_mode`, `memory_tags[]`, preferenze.
- `trips` — id, `user_id`, titolo, `destination_id`, stato
  (`draft|active|done`), `snapshot` (jsonb, piano corrente), `created_at`,
  `updated_at`.
- `trip_versions` — id, `trip_id`, `version`, `snapshot` (jsonb), `reason`
  (testo della proposta applicata), `created_at`. Log append-only per revert.
- `conversations` — id, `user_id`, `trip_id`, titolo, `avatar_asset`, `unread`,
  `summary` (jsonb), `created_at`, `updated_at`.
- `messages` — id, `conversation_id`, `role`, `kind` (`text|choice|image|video|
  audio|system|operational|tripSummary|planProposal`), testo, `audio_duration`,
  `proposal` (jsonb), `content` (jsonb per media/scelte), `sent_at`.
- `scripts` (opzionale in F4) — script conversazionali per destinazione
  (derivati da `ChatFirstDemoData`), così le demo Roma/Porto diventano dati.

Seed: 8 città, 3 percorsi, POI, nessuna conversazione (nasce per utente).

## Guida setup Supabase

Vedi `supabase/README.md`. Il progetto ref è `ijefngmutwigfmpfwsrc` (MCP
configurato in `~/.config/opencode/opencode.json`, auth OAuth in corso). Le
chiavi non vanno mai in repo; service_role solo CLI/server.

## Fasi

### F0 — Fondazione
Scope: progetto Supabase (ref `ijefngmutwigfmpfwsrc`) + schema + RLS + seed via
MCP/CLI; `supabase_flutter`; interfaccia `DataSource` con `MockDataSource`
(riusa `ChatFirstDemoData`) e `SupabaseDataSource` (stub catalogo); anon
sign-in; define `ITER_SUPABASE_ON`.
Verifica: schema applicato, seed presente (11 destinazioni + POI),
`flutter analyze` + test 71, mock invariato, Supabase che carica catalogo.
Review: funzionale (quality_reviewer) + minima grafica.

### F1 — Catalogo live
Scope: Home "Ispirazioni per te" + preview sheet da `destinations`/`pois` via
`SupabaseDataSource`; mock invariato.
Verifica: con Supabase on, home/preview mostrano dati DB.
Review: grafica (product_ux, impeccable, ui-ux-pro-max) + funzionale + QA :7357.

### F2 — Conversazioni e piani persistiti
Scope: `conversations`/`messages`/`trips`/`trip_versions`; controller async;
invio → insert; proposta accettata → nuova `trip_versions` + upsert `trips` +
messaggio conferma; annullata → messaggio, nessuna versione; badge non letti;
snapshot da DB; riavvio → tutto ancora lì.
Verifica: chiudi/riapri, accetta modifica, revert verificabile su
`trip_versions`.
Review: grafica + funzionale + QA.

### F3 — Profilo e memoria persistiti
Scope: `profiles`; `theme_mode` e `memory_tags` letti/scritti; tema applicato al
riavvio; memoria mostrata come tag (non interattivi, come ora).
Verifica: cambio tema/tag → riavvio → applicati.
Review: grafica + funzionale + QA.

### F4 — Nuovo viaggio reale
Scope: intake Semplice **inline nel thread** (domande una alla volta via
scelte/messaggi); proposte; scelta → creazione `trips` + `conversations` +
primo messaggio; Edge Function AI proxy (mock server-side default, Gemini free
solo demo manuali). Chiavi solo server-side.
Verifica: Home → nuovo viaggio → domande nel thread → piano → conversazione
persistita.
Review: grafica + funzionale + QA.

### F5 — Moduli conversazionali
Scope: curation luoghi, trasporto, zona, itinerario **dentro la chat**: card
video/choices per luoghi (skip/salva/must), confronto trasporto, contesto zona
con mappa demo, itinerario = TripSnapshot visivo + edit via chat. Modifica del
piano sempre via chat (nessuna superficie drag/undo ora).
Verifica: percorso curation→trasporto→zona→itinerario dal piano, tutto
persistito.
Review: grafica + funzionale + QA, gate Android mirato se rendering nativo.

## Workflow di review (ogni feature)

1. Implementazione: `flutter_engineer` (o orchestratore per pezzi piccoli).
2. Review grafica: `product_ux` + skill `impeccable` + `ui-ux-pro-max`
   (chiaro/scuro, testo grande, ordine semantico, riduci movimento).
3. Review funzionale: `quality_reviewer` (read-only, findings allo specialista).
4. Verifica: `flutter analyze`, `flutter test`, `flutter build web --release`,
   QA :7357. APK debug solo se serve (back, inset, gesture, rendering nativo).
5. Un file = un solo writer; serializzare file condivisi.

## Loop sotto controllo

- `tool/opencode_loop.sh --task TASK.md --max-loops N` itera finché
  `STATUS: DONE`. Ogni iterazione aggiorna `TASK.md` e logga in
  `tool/.opencode_loop.log`. L'utente segue e interrompe da terminale.
- Il loop non committa a meno che il task non lo richieda esplicitamente.

## Fuori scope in questa iterazione

- Magic link / auth completa (dopo F5).
- Supabase Storage per media (restano locali).
- Superficie itinerario drag/undo (fase successiva).
- AI reale non-mock, mappe reali, prenotazioni, prezzi live, GPS, offline,
  social, collaborazione.
