# Task: F1 — Catalogo live (Home + preview da DB)

## Contesto

F0 completato e committato (`383aeba feat(f0)`): seam `IterDataSource`
(`lib/features/chat_first_prototype/data_source.dart`) con `MockDataSource`
(default debug/test) e `SupabaseDataSource` (definisce `ITER_BACKEND=supabase`).
Il fetch di `destinations` (città + route) già funziona: Home e preview card
mostrano i dati DB quando Supabase è on.

Schema già applicato sul progetto `iter`: tabella `public.destinations`
(`slug`, `name`, `description`, `poster_asset`, `video_assets[]`, `stops[]`,
`travel_mode`, `season`, `duration_label`, `match_score`, `why_it_fits`,
`destination_ids[]`) e tabella `public.pois` (`id uuid`, `destination_id uuid
-> destinations(id)`, `name`, `category`, `emoji`, `lat`, `lng`,
`duration_min`, `best_moment`, `why_fits`, `media_asset`).

Media: restano in asset locali (`DemoMedia`), il DB tiene solo riferimenti.
Niente Storage Supabase in questa fase.

## Obiettivo F1

Il preview sheet (e l'esperienza Home) usa anche i **POI** reali del DB per la
destinazione selezionata, quando la sorgente è Supabase. Il percorso mock deve
restare identico a oggi (stessi dati, stessi test verdi).

## Checklist

- [x] Estendere `IterDataSource` con un metodo per i POI di una destinazione,
      es. `Future<List<DestinationPoint>> fetchPois(String destinationSlug)`.
      Definire un modello leggero `DestinationPoint` (id, name, category,
      emoji, whyFits) riusando quanto più possibile i modelli esistenti —
      NON toccare `lib/models/trip_models.dart` se non strettamente necessario.
- [x] `MockDataSource`: ritorna POI deterministici coerenti con la demo
      (riusa i dati esistenti di `ChatFirstDemoData` se compatibili; altrimenti
      un piccolo set locale stabile per i test).
- [x] `SupabaseDataSource.fetchPois`: legge `public.pois` per la destinazione.
      La join è su `destination_id uuid`: risolvere prima lo `slug` in `id`
      (select `id` da `destinations` dove `slug = ...`) oppure query con
      `destinations!inner(...)`; scegliere il modo più robusto. Su errore o
      vuoto ritorna lista vuota, mai crash.
- [x] Cablare il preview: `ChatPreviewSheet` mostra i POI della destinazione
      (es. sezione "Da non perdere" / "Vicino a te") caricandoli in modo
      asincrono dal controller/dataSource. Il mock deve mostrare gli stessi POI
      di oggi.
- [x] NON modificare file legacy (`lib/screens/`, `lib/app/iter_app.dart`,
      `lib/app/iter_store.dart`).
- [x] Verifica: `flutter analyze` → 0 issue; `flutter test` → 75 verdi (mock
      invariato + test nuovi per il modello POI); `flutter build web
      --release` → ok.
- [~] QA web su `http://127.0.0.1:7357` (via `./tool/run_web.sh`):
      con backend default i POI mock appaiono; con `ITER_BACKEND=supabase` i
      POI del DB appaiono. Non eseguito qui (loop autonomo); build release ok.

## Vincoli

- NON fare commit o push.
- Nessuna chiave nel codice; solo `AppConfig`/dart-define e `.env` locale.
- Se l'API `supabase_flutter` v2 richiede qualcosa di diverso, adeguati alla
  versione reale e annota la differenza nel report.
- Un file = un solo writer; serializzare `data_source.dart` e
  `supabase_data_source.dart` se toccati in più punti.
- Termina la risposta con `STATUS: DONE` quando l'intera checklist è
  completata e la verifica passa, altrimenti `STATUS: CONTINUE`.
