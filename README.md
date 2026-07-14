# Iter

Iter è un'app Flutter nativa per Android che costruisce un viaggio insieme alla persona, anche quando la meta non è ancora nota. Parte da sensazioni e tempo disponibile, propone percorsi coerenti anche tra più città o borghi, raccoglie luoghi da vivere, suggerisce dove dormire e rende visibile un itinerario che l'AI può aiutare a modificare.

Non è un questionario tecnico e non è un chatbot isolato. L'itinerario resta sempre consultabile e modificabile anche senza conversare con l'AI.

## Cosa copre questo MVP

- Home minimale con **Inizia un viaggio**, un solo viaggio in corso e disponibilità opzionale.
- Scoperta in cinque domande progressive, senza città mostrate in anticipo, con campo conversazionale sempre disponibile.
- Proposte di viaggio complete e video-led: città, borghi e tratte possono convivere nello stesso percorso.
- Tab **Scopri**, **Viaggi** e **Profilo** con tendenze, archivio, preferenze apprese e selezione Chiaro/Scuro.
- Curation di luoghi lungo tutte le tappe con swipe opzionale e pulsanti accessibili: non fa per me, mi incuriosisce, irrinunciabile.
- Confronto compatto tra volo, treno, bus e auto con prezzi mock dichiarati come stime, senza acquisto o falsa disponibilità live.
- Zone consigliate dove dormire, con soli link esterni configurabili.
- Giorni, tappe e modifiche conversazionali visibili; l'AI propone una bozza o una modifica locale, la persona decide se accettarla.
- Un segnale di disponibilità/turni per idee future, senza import di file o calendario nel MVP.
- Catalogo locale iniziale per Roma, Parigi, Barcellona, Lisbona, Porto, Amsterdam, Berlino e Praga.

Restano fuori dal primo rilascio: costruzione multi-city libera, prezzi e disponibilità live, trasporti pubblici live, recensioni, GPS, offline, condivisione, pagamenti e prenotazioni in-app. I percorsi multi-tappa presenti sono contenuti dimostrativi curati localmente.

I tre brevi video dimostrativi sono inclusi in `assets/videos/`; provenienza e link originali sono elencati in `assets/videos/SOURCES.md`. Il playback usa il plugin Flutter ufficiale `video_player` e degrada a una visualizzazione del percorso se il video non è disponibile.

## Architettura

```text
Flutter (Android)
  ├─ mock locale per sviluppo e test
  └─ Supabase Auth + Postgres + RLS
       └─ Edge Function /plan
            ├─ quota atomica in Postgres
            ├─ catalogo/cache sorgenti
            ├─ routing opzionale lato server
            └─ Gemini solo lato server
```

Vercel non ospita più l'app dopo il pivot mobile. Può eventualmente servire una pagina di supporto in futuro, ma la distribuzione del prodotto avviene tramite App Store e Google Play.

## Avvio locale

È richiesto Flutter stable con Android SDK configurato.

```bash
flutter pub get
flutter run
```

Senza configurazione esterna, Iter usa `ITER_BACKEND=mock`: nessuna chiamata a Gemini o a un provider di routing e nessun dato lascia il dispositivo.

Per collegare un progetto Supabase, passa soltanto valori pubblici al client:

```bash
flutter run \
  --dart-define=ITER_BACKEND=supabase \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<publishable-key>
```

La publishable/anon key è ammessa nel client solo con RLS attiva. Non passare mai `GEMINI_API_KEY`, `ORS_API_KEY`, una service-role key o altri segreti tramite `--dart-define`.

## Supabase e contratto di pianificazione

Usa due progetti Supabase Free riproducibili: `iter-preview` e `iter-demo`. Applica `supabase/migrations/0001_iter.sql` a entrambi. La migration conserva viaggi, versioni, tappe bloccabili, cache server-owned e quote giornaliere; RLS limita ogni viaggio al relativo proprietario.

Il prototipo in questo repository usa il planner `mock`. Prima di attivare la prima generazione remota va collegata la schermata magic link a Supabase Auth; l'Edge Function autenticata `POST /functions/v1/plan` resta l'unico confine tra Flutter e Gemini/routing provider. Il contratto completo, incluso il formato SSE allowlisted, è in [supabase/functions/plan/README.md](supabase/functions/plan/README.md).

La funzione deve validare il token utente, invocare `consume_ai_credit` con il JWT dell'utente, imporre un timeout di 45 secondi e restituire una bozza parziale con gli avvisi quando una fonte non risponde. Non deve salvare un itinerario: l'integrazione live dovrà creare una nuova `trip_versions` solo dopo un'azione esplicita di accettazione.

## AI e privacy

- `mock` è il provider predefinito per sviluppo, preview automatiche e test.
- Gemini Free è consentito solo per demo manuali e contenuti di pianificazione minimizzati; la disponibilità e le quote del free tier possono cambiare.
- Le chiavi `GEMINI_API_KEY`, `GEMINI_MODEL` e `ORS_API_KEY` vivono esclusivamente nei Supabase Edge Function secrets.
- Non inviare a Gemini email, indirizzi privati, documenti, PNR, dati di pagamento, file di turni o altri dati sensibili.
- Non esiste fallback automatico verso un provider a pagamento.

## Sviluppo e verifica

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Prima di pubblicare, prova i flussi Android su emulatori e dispositivi: discovery, swipe con controlli alternativi, modifica e annullamento dell'itinerario, accettazione di una versione, font-size elevato, dark mode e riduzione movimento.

Per il rilascio serviranno account e firme che non sono nel repository:

```bash
flutter build appbundle --release
```

Prima di uso commerciale, sostituisci le dipendenze free-tier con un piano di backend/AI adatto, backup verificati, monitoraggio e una policy privacy pubblicata.

## Design workflow

Impeccable rimane uno strumento locale di sviluppo: `PRODUCT.md` e `DESIGN.md` descrivono la UX mobile, non vengono distribuiti nell'app. Per reinstallarlo in un nuovo clone:

```bash
npx impeccable install --providers=codex --scope=project --no-hooks
```

Caveman resta globale e fuori dal repository: ottimizza il flusso di sviluppo, non il copy dell'interfaccia né i token dell'AI.
