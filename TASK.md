# Task: F5 — Moduli conversazionali (curation luoghi, trasporto, zona, itinerario in chat)

## Contesto

F0–F4 completati e pushati su `codex/chat-first-prototype` (HEAD `a79b805`).
Il prototipo chat-first ha: thread deterministici (ChatThread + ScriptedBeat +
PlanProposal), intake inline (IntakeThread, 5 domande, proposta finale),
persistenza conversazioni/messaggi/piani/profilo su Supabase, Edge Function
`plan` (mock server-side).

F4 ha chiuso il flusso **Home → Inizia un viaggio → intake (domande) →
proposta finale → accettazione → conversazione persistita**. Il piano resta
una bozza: `TripSnapshot` con pochi luoghi, trasporto e zona "da definire".

Scope F5 (ITER_APP_PLAN riga 139-146): portare curation luoghi, trasporto,
zona e itinerario **dentro la chat**, continuando il percorso dall'intake.
Principi HANDOFF/PRODUCT: card video/choices per i luoghi (skip/salva/must),
confronto trasporto, contesto zona con mappa demo, itinerario = TripSnapshot
visivo + edit via chat. **Modifica del piano solo via chat** (nessuna
superficie drag/undo ora).

## Obiettivo F5 (questo batch)

Proseguire il thread del viaggio, dopo la proposta accettata dall'intake, con
quattro moduli conversazionali sequenziali. Ogni modulo propone, l'utente
decide con scelte/conferme, il `TripSnapshot` del thread si aggiorna e alla
fine si persiste una nuova versione (trip_versions) con la conferma esplicita
dell'utente.

1. **Curation luoghi** — dopo l'intake, Iter mostra i luoghi del catalogo
   della meta uno alla volta come messaggi con scelte (passa / salva /
   irrinunciabile). I luoghi salvati/must entrano nello snapshot. Mock
   esistente: `MockData.places` e `topPlacesFor` già disponibili.
2. **Trasporto** — confronto dentro la chat: opzioni demo (aereo / treno /
   auto) con prezzo e durata fittizi, scelta singola che aggiorna lo snapshot.
3. **Zona** — contesto zona con mappa demo: messaggio che descrive la zona
   consigliata (da `stayZones`/`preferredStayFor`), atmosfera e tempi a piedi,
   senza mappa reale (nessuna nuova dipendenza). Scelta che aggiorna lo
   snapshot.
4. **Itinerario** — riepilogo visivo (TripSnapshot già esistente) + edit via
   chat: Iter propone modifiche concrete (`PlanProposal`) che l'utente
   Accetta/Annulla; accettare aggiorna lo snapshot e persiste.

## Vincoli

- NON committare (il Git owner decide a fine loop).
- Tutto resta nel prototipo chat-first (`lib/features/chat_first_prototype/`);
  nessuna scrittura in IterStore/provider reali.
- Un solo writer per file; serializzare i file condivisi.
- Il mock demo esistente (Porto/Roma, intake) resta byte-identico per i test
  esistenti: nuove feature = aggiunte, non modifiche distruttive.
- Nessuna nuova dipendenza (niente mappa reale, niente provider esterni).
- Copy in italiano, coerente con l'esistente (tutte le superfici di chat).
- Ogni modifica importante del piano richiede conferma esplicita dell'utente.
- Termina con `STATUS: DONE` quando la checklist è completa e la verifica
  passa, altrimenti `STATUS: CONTINUE`.

## Checklist F5

- [x] **Modelli**: nuovi tipi di messaggio/card per curation luoghi, confronto
      trasporto, contesto zona (estendere `ChatMessageKind` e/o `ChatChoice` in
      modo retrocompatibile).
- [x] **Script F5**: percorso curation→trasporto→zona→itinerario agganciato
      dopo l'accettazione della proposta intake (nuova estensione thread o
      script in `chat_first_data.dart`), deterministico.
- [x] **Controller**: logica dei moduli (risposte→snapshot, proposta
      accettata→persistenza via `saveTripVersion`, guardie contro decisioni
      doppie).
- [x] **Thread widget**: rendering delle nuove card (luoghi, trasporto, zona)
      coerente con lo stile esistente (bolle, scelte, PlanProposal).
- [x] **Test**: nuovi test controller+widget per il percorso F5; test esistenti
      aggiornati al nuovo comportamento (auto-advance).
- [x] Persistenza: la versione aggiornata del piano salvata dopo la conferma.

## Fix post-review

Applicati integralmente i 7 finding (product_ux + quality_reviewer):
1. CHECK `messages.kind` esteso in `supabase/schema.sql` (`placeCard`,
   `transport`, `stayZone`).
2. Auto-advance: dopo l'accettazione intake il thread consuma da solo i beat di
   transizione e atterra sulla prima card luogo; si ferma esattamente su una
   decisione (choices/proposta), mai oltre una proposta.
3. Chips passate non cliccabili (UI) + guardia `acceptsChoiceFrom` nel
   controller: un tap stale su una card già risolta non applica due volte.
4. Trasporto: nessuno stile "selezionato"; la raccomandata ha solo un badge
   "Consigliato".
5. Media nella PlaceCard via `DemoMedia.postersForDestination` (nuovo campo
   `PlaceCard.imageAsset`, retrocompatibile).
6. Restanti: clarifica free-text su card luogo (non avanza), fallback
   "Consigliami tu" quando non ci sono zone, ack demo trasporto, label zona
   "dalle tappe", rimozione riepilogo ridondante (la proposta porta il
   preview), righe trasporto overflow-safe a testo grande.

## QA

- [x] `flutter analyze` 0 issue.
- [x] `flutter test` 115/115 (inclusi i nuovi test F5 e i fix).
- [x] `flutter build web --release` ok.
- [ ] QA live :7357 non eseguibile da qui (no browser); dichiararlo in evidenze.
- [x] Review: product_ux (grafica, read-only) + quality_reviewer (funzionale,
      read-only) con finding applicati e re-review di conferma passata.
- [ ] QA live :7357 (no browser in sessione): da eseguire in una sessione con
      browser — look chip disabilitate (scuro+testo grande), immagine card
      luogo, mappa demo, overflow righe trasporto.

## Evidenze

- `flutter analyze` 0; `flutter test` 115/115; `flutter build web --release` ok.
- `git diff --check` pulito.
- Subagent: flutter_engineer (F5 + fix), file disgiunti; nessun commit eseguito.
- Re-review: quality_reviewer gate ok (1 ALTO + 3 MEDIO + bassi risolti);
  product_ux grafica e UX PASSA. QA live :7357 non eseguito (no browser).

## Rischi residui

- `acceptsChoiceFrom` non copre "proposta pendente" come ultimo messaggio: un
  tap stale programmatico su una card precedente avanzerebbe oltre la proposta.
  Protetto a livello UI (chip disabilitate); hardening suggerito in futuro.
- Secondo free-text dopo una clarifica la bypassa (avanza senza registrare):
  caso limite accettabile per il demo.
- Free-text non riconosciuto su transport/stay finisce grezzo nello snapshot
  (comportamento demo).
- Persistenza live non provata a runtime (mock/spy nei test); CHECK `messages.kind`
  allineato in `schema.sql`, da applicare su `iter` insieme a migrazioni note.

## STATUS: DONE
