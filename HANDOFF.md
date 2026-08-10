# Iter — Handoff di progetto

> Aggiornato il 6 agosto 2026. È il punto di ingresso consigliato per una
> nuova chat; le decisioni dettagliate sulla scatola “Nuovo viaggio” restano in
> `NEW_TRIP_MASTER_PLAN.md`.

## Contesto

Iter è un'app mobile Flutter AI-first per organizzare viaggi. Non è una web app e non deve sembrare un semplice chatbot: l'AI è la regia che aiuta a costruire il viaggio, mentre l'app resta sempre navigabile e modificabile anche manualmente.

Lingua di lancio: italiano. Stato: prototipo/demo personale, non commerciale.

## Prototipo chat-first (branch `codex/chat-first-prototype`)

Sperimentazione isolata, senza toccare l'app esistente. Su questo branch:

- Il prototipo si attiva in sostituzione totale al boot quando
  `ITER_CHAT_FIRST_PROTOTYPE` è on; in debug è on per default via `kDebugMode`,
  in release è off. La vecchia app resta compilabile e raggiungibile
  disattivando il define e ricompilando (`--dart-define=ITER_CHAT_FIRST_PROTOTYPE=false`).
- Home tipo Netflix: destinazioni trend in fasce orizzontali con video, anteprima
  immersiva (bottom sheet), CTA **Parlane con Iter** e uscita non impegnativa
  "Solo ispirazione".
- Chat stile WhatsApp: lista conversazioni, nuova chat, ultimo messaggio, non
  letti. Ogni viaggio è una conversazione; ogni conversazione possiede un
  `TripSnapshot` read-only apribile dall'icona del piano nella AppBar del thread
  (il titolo non è più tappabile).
- Thread multimodale e deterministico: testo, scelte cliccabili, immagini,
  video, vocali in arrivo e in uscita (mock), riepilogo viaggio e aggiornamento
  operativo. Composer con invio testo, mic (vocale demo) e allegati foto/video
  demo.
- Due scenari demo: pianificazione (Porto/Douro) e viaggio attivo (Roma) con
  aggiornamenti proattivi e non letti. La modifica del piano avviene dalla chat:
  Iter propone una modifica concreta (`PlanProposal`), l'utente può
  Accetta/Annulla; accettare aggiorna lo snapshot del thread (es. "mattina più
  lenta" a Roma).
- **Nuovo viaggio parlando (FreeTalk)**: la Home ha l'entry **Parlane con
  Iter** che apre un thread senza destinazione imposta; il desiderio libero non
  pinna la meta, viene echeggiato, poi la conversazione offre le mete trend
  (inclusa "Consigliami tu"). Appena la destinazione è sciolta, il thread
  converge sullo stesso intake guidato (stessa `restIntakeScript`, stessa
  proposta finale e stessi moduli F5). `IntakeThread` ora mantiene `journey`
  opzionale/mutabile così il FreeTalk lo aggancia a metà conversazione.
- Profilo: tema Sistema/Chiaro/Scuro con persistenza locale, memoria appresa dal
  contesto (niente sondaggi o profili iniziali), privacy descritta.
- Tutto mock e isolato: nessuna scrittura in `IterStore`, nessun provider, GPS,
  permesso, notifica o motivatore reale.
- Codice: `lib/features/chat_first_prototype/` (models, data, controller, app,
  shell, home, preview, list, thread, snapshot, profile). Verifica: analyze
  pulito, 71 test totali (22 del prototipo chat-first), build web release
  riuscite.
- Audit UX completato (skill ui-ux-pro-max/impeccable) e miglioramento UI
  applicato: Home decluttered a tre sezioni (saluto, hero con CTA unica,
  Riprendi/"Ispirazioni per te" senza duplicati), niente gradienti/ombre, badge
  petrol, radii normalizzati, pausa video in preview, stato positivo in mint.
- Orchestrazione opencode: `opencode.json` + subagent in `.opencode/agent/`
  (worker, flutter_engineer, product_ux, quality_reviewer, …); il runtime usa
  come fallback il modello `opencode/*` di default perché il provider Copilot
  non risolve.
- Dopo il post-viaggio/portfolio (non in scope) verrà definita la sezione
  successiva.

## Stato corrente in breve

- Il **Nuovo viaggio Lab v2** usa **Semplice** come unica presentazione.
  Focus e Rotta restano soltanto nella storia esplicitamente etichettata della
  riduzione A5; non sono modalità selezionabili.
- In debug il Lab è attivo per default tramite `kDebugMode`: **Inizia un
  viaggio** nella Home apre direttamente Semplice. Il define
  `--dart-define=ITER_NEW_TRIP_LAB=false` lo disattiva esplicitamente e
  conserva il percorso prodotto esistente; in release il Lab è disattivato per
  default.
- La Fase 1 cambia soltanto presentazione e raccolta iniziale: controller,
  otto domande, date tipizzate, sorgente mock deterministica, riepilogo e
  contratto senza persistenza restano invariati. Il Lab non interroga provider
  reali e non scrive in `IterStore`.
- Semplice usa una UI moderna e sobria: sfondo caldo dai ruoli semantici del
  tema, titolo dominante, opzioni emoji più testo su due colonne solo con spazio
  sufficiente e testo normale, una colonna a 360 dp o meno e con testo grande,
  copy ridotto e progresso dopo le opzioni. Il progresso indica domanda corrente
  e domande residue.
- La partenza usa posizione approssimativa in primo piano, reverse geocoding e
  fallback manuale; resta sempre modificabile.
- Le scelte singole avanzano automaticamente. Multi-selezioni, calendari e
  valori manuali usano soltanto conferme contestuali.
- “Ho più possibilità” raccoglie possibili date di partenza anche isolate; la
  durata è separata. Solo i giorni liberi salvati formano finestre consecutive.
- Risultati, shortlist e confronto esistenti non vengono ridisegnati in Fase 1;
  il loro redesign e il rollout dell'intake Semplice nel prodotto intero sono
  piani successivi.
- Il QA nel Browser integrato della Fase 1 è completato: Home, accesso diretto
  al Lab e modifica manuale dell'origine; due colonne a 390 dp, una colonna a
  360 dp, progresso dopo le opzioni, back e temi chiaro/scuro.
- Verifica corrente: `flutter analyze` pulito, suite Flutter completa di 71
  test, `flutter build web --release` riuscita.
- Lo snapshot A5 del 16 luglio resta storico, precedente alla selezione finale
  di Semplice.

Il QA Browser dell'intake Semplice è chiuso. Il redesign di
risultati/shortlist/confronto, il rollout nel flusso prodotto, persistenza,
store e provider reali restano fasi successive.

## Repository e ambiente

- Repository locale: `/Users/matteo/iter`
- Branch: `codex/chat-first-prototype` (prototipo chat-first); `feat/mobile-ui-refresh` resta storicamente per il flusso prodotto esistente.
- Commit più recente: `96feb3a feat(ui): refresh mobile travel flows`
- Remote: `https://github.com/matteogrifantini/itertravel`
- Stack: Flutter, Dart, asset video locali e dati mock.

Versioni note:

- Flutter `3.44.6`, canale stable
- Dart `3.12.2`
- Emulatore Android: `emulator-5554`, AVD `iter_android`

### QA UI rapido nel Browser integrato Codex

```bash
cd /Users/matteo/iter
./tool/run_web.sh
```

Aprire quindi `http://127.0.0.1:7357` nel Browser integrato di Codex e
percorrere l'app direttamente con mouse/tastiera. Questo è il percorso
predefinito per provare il flusso Semplice, tema e responsive UI: non richiede un
emulatore Android, né screenshot o video come prova ordinaria. Lasciare il
processo dello script attivo durante l'ispezione; usa il device Flutter
`web-server`, la porta locale `7357` e abilita il Nuovo viaggio Lab.

Il browser web è soltanto un harness QA locale. Non cambia il target mobile di
Iter, la distribuzione Android né le decisioni di piattaforma.

### Loop autonomo opencode

`tool/opencode_loop.sh` esegue `opencode run` in iterazioni successive finché il
task non viene dichiarato completo (protocollo `STATUS: DONE|CONTINUE`). Si usa
dal terminale dell'utente, non da dentro una sessione agente:

```bash
tool/opencode_loop.sh --task TASK.md --max-loops 15
```

Template di task: `tool/TASK.example.md`. Il loop logga in
`tool/.opencode_loop.log` e non fa commit a meno che il task non lo richieda.

### Gate Android mirato

Usare l'emulatore Android soltanto quando la modifica o il gate finale richiede
verifiche native: back, inset di sistema, permessi, gesture, prestazioni,
comportamento del lifecycle o rendering specifico della piattaforma.

Se necessario, avviarlo così:

```bash
export ANDROID_SDK_ROOT="/Users/matteo/Library/Android/sdk"
export PATH="$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"
emulator -avd iter_android
```

Poi, in un secondo terminale:

```bash
cd /Users/matteo/iter
flutter run -d emulator-5554
```

`flutter emulators --launch iter_android` in passato non ha sempre reso visibile il device; l'avvio diretto con `emulator -avd iter_android` è più affidabile.

Verifiche da eseguire dopo modifiche:

```bash
flutter analyze
flutter test
flutter build web --release
```

Al gate Android aggiungere `flutter build apk --debug` e la prova nativa
mirata descritta sopra.

Nota ambiente: il checkout Flutter SDK contiene uno stash chiamato `before-flutter-upgrade-local-pubspec-lock`; non riguarda questa repository.

## Visione del prodotto

Iter accompagna una persona dall'ispirazione alla bozza di viaggio completa. Non parte con parametri freddi o un questionario tecnico: l'utente può iniziare da una frase libera, una disponibilità o un desiderio.

Esempio:

> Ho quattro giorni a fine settembre, voglio staccare, mangiare bene e vedere posti belli senza correre.

Iter interpreta il desiderio, pone una domanda alla volta e propone possibilità esplorabili visivamente. L'AI deve sembrare una guida editoriale intelligente, non un modulo amministrativo.

L'utente può iniziare un nuovo viaggio, riprendere viaggi precedenti, vedere ricordi, scoprire tendenze, ricevere proposte personalizzate e modificare il piano tramite azioni dirette o chat AI. L'AI può proporre e spiegare, ma non deve salvare, prenotare, rimuovere vincoli bloccati o modificare scelte importanti senza approvazione esplicita.

## Flusso principale

```text
Ispirazione
→ scelta o conferma della meta
→ curation dei luoghi
→ scelta del trasporto
→ scelta della zona in cui dormire
→ itinerario per giorni
→ collegamenti esterni per prenotare
```

### Home

La home non deve essere caotica, piena di testo o sembrare una dashboard SaaS. Deve avere personalità e far sentire che Iter conosce l'utente.

Privilegiare:

- invito immediato a iniziare un nuovo viaggio;
- viaggi in corso;
- idee e trend coerenti con i gusti;
- memoria di viaggi passati;
- presenza AI utile ma non invasiva.

L'utente non deve vedere subito una lista di città preconfezionate. Deve poter partire da un momento, un desiderio, un budget o una disponibilità.

Esempi di input:

- “Vorrei un weekend al mare ma con cose da vedere.”
- “Ho voglia di un viaggio lento in autunno.”
- “Vorrei partire quando finisco questi turni.”
- “Ho 500 euro e quattro giorni liberi.”

### Esplorazione della meta

La scoperta non deve essere limitata alle città. Iter può proporre una città singola, due città vicine, un itinerario ferroviario, borghi, una costa, un road trip o un tema di viaggio.

La UI usa sequenze di video verticali, tipo reel/editorial travel feed, non un elenco turistico di card statiche.

Ogni proposta deve avere:

- video verticale;
- titolo breve;
- tag: città, percorso, ispirazione o itinerario;
- frase evocativa breve;
- pulsante Info;
- scelta esplicita dell'utente.

Il pulsante Info apre un bottom sheet leggero con: perché può piacere, tappe principali, durata ideale, periodo consigliato, ritmo, budget indicativo, tipo di esperienza e note utili.

Demo attuale:

- Roma;
- Parigi;
- Barcellona;
- Lisbona;
- Porto;
- percorso ferroviario/costa atlantica.

### Scelta dei luoghi

Dopo la meta, l'utente costruisce prima il proprio gusto tramite monumenti, piazze, musei, quartieri, locali, mercati, panorami o eventi. Non riceve subito un itinerario rigido.

L'interazione deve essere visiva e rapida:

- video verticale a schermo pieno;
- pochi elementi testuali;
- una scelta alla volta;
- controlli verticali a destra, ispirati alle azioni TikTok;
- swipe possibile ma non obbligatorio.

Azioni laterali: Info, Passa, Salva e Must/irrinunciabile.

Info deve spiegare: cosa rende interessante il luogo, categoria, durata, momento migliore, coerenza con i gusti dell'utente ed eventuali note.

La demo ha volutamente quattro luoghi: deve dimostrare il meccanismo, non creare una lista infinita. Nel prodotto reale, le proposte dovrebbero combinare preferenze esplicite, luoghi scelti/rifiutati, viaggi precedenti, ritmo, interessi, compagni di viaggio, disponibilità e budget.

### Come arrivare

Tutte le opzioni sono nella stessa schermata, senza tab inutili:

- volo;
- treno;
- bus;
- auto/noleggio.

Ogni opzione mostra logo della compagnia, orario/fascia, durata, cambi, prezzo, stato di selezione e link esterno. I dati sono demo; provider mostrati: Ryanair, Trenitalia, FlixBus ed Europcar.

In futuro i dati possono provenire da servizi esterni. Non costruire ancora checkout o prenotazione interna.

### Dove dormire

Questa fase parte da una mappa, non da una lista di hotel. Mostra luoghi selezionati, quartieri colorati, atmosfera della zona, tempi a piedi e coerenza con il viaggio. Offre un link esterno configurabile per cercare alloggi.

Il copy deve essere umano, ad esempio: “Qui sei vicino a quello che hai salvato” oppure “È una zona più tranquilla, utile se vuoi rallentare”. Non promettere disponibilità o prezzi reali.

### Itinerario

L'itinerario deve essere editoriale e visivo, non una tabella fitta di testo.

Elementi principali:

- hero visuale/video della meta;
- giorni navigabili con chip semplici;
- timeline verticale pulita;
- immagini dei luoghi;
- titolo, categoria, durata e stato del vincolo;
- trasporto e zona scelti;
- presenza AI discreta.

La chat/composer AI può ricevere richieste come “Spostiamo il museo a domani”, “Vorrei una mattina più lenta”, “Aggiungi un aperitivo vicino al tramonto” o “Piove sabato, cambia il piano”. L'AI non deve limitarsi a rispondere: propone una modifica concreta che l'utente può accettare o annullare.

Vincoli bloccati: luoghi Must, prenotazioni future, appuntamenti, limiti temporali o preferenze esplicite importanti. Non devono essere spostati o rimossi automaticamente.

### Viaggi e profilo

La schermata Viaggi deve sembrare un archivio personale: card visuali, viaggi in corso, ricordi, immagini, route/stops e stato. Non una semplice lista.

Il profilo deve supportare la personalizzazione: stile di viaggio, budget, interessi, ritmo, preferenze alimentari, alloggio, mezzi, città già viste, luoghi amati/rifiutati, tema e disponibilità da turni di lavoro.

## Tema e design

Tema di default: chiaro. L'utente può scegliere Sistema, Chiaro o Scuro. Il tema scuro non è una semplice inversione: le superfici usano ruoli semantici distinti.

Direzione visuale (mondo "Neutro System Blue", vedi DESIGN.md):

- neutrali system e superfici chiare, non tenute calde;
- un solo accento System Blue per azioni e selezione;
- separatori hairline invece di ombre;
- immagini e mappe come materia principale;
- molto spazio e gerarchia chiara;
- motion fluido e funzionale;
- niente estetica SaaS generica;
- niente eccesso di badge, card, bordi, testo descrittivo o gradienti casuali;
- evitare una UI che sembri generata dall'AI.

Per modifiche UI usare la skill Impeccable:

```text
/Users/matteo/iter/.agents/skills/impeccable/SKILL.md
```

Leggerla integralmente prima di fare refactor visivi. Preservare la direzione attuale, senza reintrodurre la vecchia UI.

## Asset e contenuti demo

```text
assets/videos/vertical/
assets/images/travel/
assets/logos/
assets/videos/SOURCES.md
```

I video sono reel verticali ottimizzati e concatenati per evitare loader finti e ridurre problemi del decoder Android. I loghi demo dei trasporti sono in `assets/logos/`. Le fonti/licenze sono in `assets/videos/SOURCES.md`.

Non eliminare o sostituire asset senza aggiornare `pubspec.yaml` e il file delle fonti.

## File rilevanti

```text
lib/app/iter_app.dart
lib/data/mock_data.dart
lib/models/trip_models.dart
lib/state/iter_store.dart

lib/screens/destination_discovery_screen.dart
lib/screens/discover_tab.dart
lib/screens/place_curation_screen.dart
lib/screens/transport_selection_screen.dart
lib/screens/stay_selection_screen.dart
lib/screens/itinerary_screen.dart
lib/screens/trips_screen.dart

lib/widgets/journey_media.dart
lib/widgets/trip_card.dart

lib/features/new_trip_lab/new_trip_lab_models.dart
lib/features/new_trip_lab/new_trip_lab_controller.dart
lib/features/new_trip_lab/new_trip_origin_resolver.dart
lib/features/new_trip_lab/new_trip_lab_steps.dart
lib/features/new_trip_lab/new_trip_lab_shells.dart
lib/features/new_trip_lab/new_trip_lab_proposals.dart
lib/features/new_trip_lab/new_trip_lab_results.dart
lib/features/new_trip_lab/new_trip_lab_screen.dart

AGENTS.md
agents/worker.md
.codex/agents/worker.toml
NEW_TRIP_MASTER_PLAN.md
NEW_TRIP_DATE_CARD_PLAN.md
ITER_APP_PLAN.md
supabase/README.md
PRODUCT.md
DESIGN.md
README.md
```

Quando cambia la direzione del prodotto, aggiornare documentazione e codice insieme.

## Architettura attuale e roadmap tecnica

L'app è oggi una demo Flutter locale basata su mock data e asset locali. Nel
solo laboratorio “Nuovo viaggio” sono attivi geolocalizzazione approssimativa
in primo piano e reverse geocoding del dispositivo. Non sono ancora attivi
autenticazione, Supabase runtime, backend, AI reale, mappe reali, routing,
disponibilità/prezzi reali o provider di prenotazione.

Direzione tecnica prevista quando il prototipo evolverà:

- Flutter per iOS/Android;
- Supabase Free per Auth, Postgres e RLS;
- magic link prima della prima generazione AI;
- backend/Route Handlers per tenere segrete le chiavi;
- Gemini Flash free tier solo per test manuali;
- mock AI come default per preview/test;
- Ollama opzionale in locale;
- MapLibre/OpenFreeMap per mappe di prototipo;
- openrouteservice con cache per routing;
- Nominatim solo server-side, su invio esplicito e con cache;
- cataloghi POI versionati e con fonti attribuite.

Se viene implementata AI reale: output strutturato validato, nessun ragionamento grezzo esposto, streaming con eventi UI allowlisted, una generazione attiva per utente, massimo due al giorno, cap di quota, timeout e nessun fallback automatico a provider a pagamento. Gemini free tier non deve ricevere dati personali, indirizzi privati, prenotazioni o documenti.

## Turni di lavoro — requisito futuro

L'utente dovrebbe poter importare o inserire turni/disponibilità. Iter deve capire quando può partire, per quanti giorni, quali mete hanno senso e quali mezzi sono coerenti. Non implementare ancora import complessi da calendari o documenti senza definire privacy, permessi e formato dati.

## Fuori scope del MVP/demo

- multi-city illimitato;
- trasporto pubblico live;
- aperture/eventi live;
- prezzi hotel live;
- recensioni;
- GPS e offline;
- album/social;
- collaborazione;
- checkout, pagamenti e prenotazioni interne;
- upload di documenti o storage di dati sensibili;
- import automatico di turni;
- integrazioni dirette Booking, Skyscanner o altri provider.

Per ora usare link esterni configurabili e dichiarare sempre chiaramente quando un dato è demo.

## Regole di lavoro

- Non trasformare Iter in un chatbot puro.
- Non reintrodurre questionari tecnici, form lunghi o parametri freddi.
- Ridurre il testo: una frase buona vale più di cinque spiegazioni.
- Privilegiare video, immagini, mappe e scelte progressive.
- L'utente mantiene sempre il controllo.
- Non inserire API key nel client.
- Non fare commit o push senza richiesta esplicita.
- Prima di modifiche importanti, controllare `git status`.
- Dopo modifiche: almeno `flutter analyze` e `flutter test`.
- Per modifiche UI: usare prima il Browser integrato Codex, tema chiaro/scuro e
  Riduci movimento; richiedere l'emulatore Android solo per il gate nativo
  mirato (back, inset, permessi, gesture, prestazioni o rendering piattaforma).
- Aggiornare `PRODUCT.md` e `DESIGN.md` quando serve.

## Orchestrazione Codex

`AGENTS.md` contiene le istruzioni persistenti per le nuove chat. Il thread
principale è l'orchestratore, mantiene requisiti e decisioni e usa un routing
worker-first con struttura piatta e massimo tre agenti secondari.

Configurazione operativa:

| Ruolo | Modello | Effort | Uso |
| --- | --- | --- | --- |
| Orchestratore | `gpt-5.6-sol` | `high` | Decisioni, ownership e integrazione |
| `worker` | `gpt-5.6-luna` | `medium` | Esecuzione predefinita delimitata |
| `worker-hard` | `gpt-5.6-luna` | `max` | Escalation per complessità |
| Specialisti | `gpt-5.6-luna` | `max` | Escalation per giudizio di dominio |

L'orchestratore assegna prima a `worker`, salvo complessità o competenza
specialistica già evidenti. Solo l'orchestratore può passare il lavoro a
`worker-hard`, `product_ux`, `flutter_engineer`, `platform_engineer` o
`quality_reviewer`. Gli agenti secondari non delegano.

In questo runtime opencode la configurazione è `opencode.json` con i subagent
in `.opencode/agent/`; il provider Copilot non risolve, quindi come fallback si
usa il modello `opencode/*` di default.

Le schede leggibili sono in `agents/`; le configurazioni eseguibili in
`.codex/agents/`. Ogni agente riferisce con un riepilogo breve; l'orchestratore
verifica diff e test e conserva nel thread principale soltanto le decisioni
importanti.

## Prossimo passo

Il QA del solo intake Semplice nel Browser integrato Codex è completato. Il
miglioramento UI del prototipo chat-first è applicato e verificato (analyze
pulito, 71 test, build web OK); resta il QA visuale del prototipo su
`http://127.0.0.1:7357` (scrim hero, "Ispirazioni per te" senza duplicati, pausa
video in preview, badge in scuro) e l'eventuale commit del branch
`codex/chat-first-prototype`. Il redesign di risultati, shortlist e confronto,
quindi il rollout app-wide, richiederanno un piano successivo. Eseguire il QA
Android mirato soltanto prima di un gate nativo pertinente o del pre-release.
