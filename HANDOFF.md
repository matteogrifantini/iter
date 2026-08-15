# Iter — Handoff

Aggiornato il 15 agosto 2026. Questo è il punto di ingresso per riprendere il
lavoro sul branch `codex/iter-ui-rebuild`.

## Stato

La vecchia app e il vecchio Lab non sono più il percorso di avvio. `main.dart`
chiama `buildIterApp()` e monta solo `ChatFirstPrototypeApp`. Sono stati rimossi
il routing con feature flag, `IterStore` e le schermate legacy che non servono
alla nuova esperienza. Non sono stati fatti commit o push.

Il branch è nato pulito da `codex/iter-new-only` (`0e4453e`), lasciando il
precedente pass visuale su `codex/iter-design-polish` come archivio confrontabile.
Prima di toccare altro controllare sempre:

```bash
git status --short --branch
```

## Chiusura post-audit UI

Il passaggio post-audit ha chiuso i gap funzionali più visibili senza introdurre
provider o dati live:

- Home mantiene il solo percorso **Viaggi** nella shell inferiore; il pulsante
  duplicato nella testata è stato rimosso.
- Il picker del Piano consente anche un **luogo personalizzato**, che entra
  nella stessa pipeline preview → conferma delle tappe catalogate.
- Le proposte in chat mostrano la sola modifica in evidenza e il CTA
  **Vedi il piano completo**; il riepilogo dettagliato resta nel Piano.
- La hero del Piano apre un foglio con immagini e reel demo della destinazione;
  le **Ispirazioni salvate** restano visibili nel Piano con stato da integrare o
  integrata.
- Costi e conferme espongono sempre il carattere demo. Se il piano non ha
  volo/hotel, non viene mostrato un CTA inattivo.
- Il percorso Share Target Android, scraping social e pagamento reale restano
  fuori scope come dichiarato in `PRODUCT.md`.

Verifica eseguita dopo queste modifiche: `flutter analyze` senza issue, `flutter
test` con 243 test superati, `flutter build web --release` riuscito e
`git diff --check` pulito. Il rebuild visuale è stato verificato nel Browser
integrato su `http://127.0.0.1:7359/?v=iter-ui-rebuild-final`: Home, Chat,
Piano, Viaggi, Tu e tema scuro. Il worktree resta non committato.

## Rebuild visuale 15 agosto

Il branch `codex/iter-ui-rebuild` rende esplicito il nuovo mondo visivo:

- frame centrato da 760 dp e dock inferiore flottante da 360 dp;
- Home attiva con scena fotografica, timeline lineare e composer pronto alla
  modifica;
- Viaggi senza FAB ambiguo: nuova chat esplicita nella testata;
- Chat con composer grande in una superficie flottante tipo WhatsApp;
- Piano con hero/media, timeline editabile e isola azioni riservata sotto il
  contenuto;
- Profilo lineare con statistiche, emoji, disponibilità, tema e collegamenti,
  senza griglia di card.

La vecchia implementazione resta fuori dal percorso di avvio e non è stata
riattivata per ottenere questo risultato.

## Contratto prodotto

Le fonti operative sono:

- `PRODUCT.md` — cosa deve fare Iter;
- `DESIGN.md` — gerarchia, colori, interazioni e accessibilità;
- `docs/superpowers/specs/2026-08-14-iter-new-only-design.md` — decisioni
  approvate del nuovo perimetro;
- `docs/superpowers/specs/2026-08-15-iter-ui-rebuild-design.md` — contratto
  visuale del rebuild corrente;
- `docs/superpowers/plans/2026-08-14-iter-new-only-implementation.md` — piano
  esecutivo e gate.

I documenti `NEW_TRIP_MASTER_PLAN.md` e alcune spec precedenti sono storici: non
reintrodurre il loro routing o le loro feature flag solo perché compaiono in una
pagina d'archivio.

## Architettura corrente

```text
lib/main.dart
  -> lib/app/app_entry.dart
     -> ChatFirstPrototypeApp
        -> ChatFirstShell
           -> Oggi / Viaggi / Tu
```

Il controller è `ChatFirstPrototypeController`. Il mock è deterministico e
isolato da `IterStore`:

- `chat_first_data.dart` — thread, fixture Porto/Roma, luoghi, voli, hotel;
- `chat_first_models.dart` — messaggi, conversazioni, proposte;
- `plan_models.dart` — snapshot, giorni, tappe, selezioni e revisioni;
- `plan_editor.dart` — preview e applicazione delle modifiche;
- `data_source.dart` + `mock_data_source.dart` — seam di persistenza;
- `supabase_data_source.dart` — integrazione opzionale, senza segreti nel client.

I modelli nuovi sono:

- `profile_models.dart` — disponibilità e statistiche;
- `inspiration_models.dart` — draft e ispirazioni salvate;
- `inspiration_importer.dart` — parser locale delle due fixture approvate.

## Flussi da preservare

### Piano

Il piano non mostra una mappa sopra. La hero e la timeline sono il contenuto
principale. La barra inferiore offre **Aggiungi luogo**, **Chiedi** e **Costi**;
il menu overflow offre **Importa ispirazione**. Le azioni sulle tappe passano da
preview e conferma.

### Ispirazione

`parseMockInspiration()` non fa rete. Il link Instagram Porto estrae Livraria
Lello; il link TikTok Roma estrae Foro Romano. `saveInspiration()` salva senza
mutare lo snapshot. `proposeInspiration()` aggiunge una `PlanProposal` e solo
`acceptProposal()` cambia la timeline e marca l'ispirazione come applicata.

### Acquisti demo

`confirmMockPurchases()` segna volo e hotel come `purchased` in una sola
revisione con label `Conferma acquisti demo`. Il CTA non chiama `url_launcher` e
non raccoglie dati di pagamento. I link esterni esistenti sono separati e
allowlistati.

### Profilo

Il profilo è volutamente leggero: statistiche, memoria, tema, disponibilità,
FAQ, Privacy e conversazioni. `ProfileAvailabilitySheet` restituisce un modello
normalizzato a mezzanotte; il controller assegna l'id e notifica il shell.

## Verifica locale

Per il controllo rapido:

```bash
dart format lib test
git diff --check
flutter analyze
flutter test
```

Per UI/responsive usare il build release, perché sul device web-server DDC di
questa macchina il caricamento può restare bianco o non montare il widget
Flutter:

```bash
flutter build web --release
python3 -m http.server 7359 --directory build/web --bind 127.0.0.1
```

Poi aprire `http://127.0.0.1:7359` nel Browser integrato. Percorrere almeno:

1. Oggi → nuova chat → composer e allegato;
2. Viaggi → Porto → piano → scheda luogo/indicazioni;
3. piano → Costi → Conferma acquisti demo;
4. piano → overflow → import demo Porto → salva → proponi → accetta in chat;
5. Tu → disponibilità → aggiungi/rimuovi e cambio tema.

Ripetere il controllo a 320/360/390 dp, testo 1.5, light/dark e moto ridotto.
Il Browser è un harness QA locale, non un target di distribuzione.

## Regole di manutenzione

- Non reintrodurre i vecchi define di routing o il vecchio Lab.
- Non ricreare `IterStore` o schermate legacy solo per compatibilità visiva.
- Non aggiungere provider reali al mock e non mettere chiavi nel client.
- Preservare modifiche dirty non pertinenti.
- Non fare commit, merge o push senza richiesta esplicita.
- Se si cambia un flusso UI, aggiungere prima un test widget/contratto e poi
  aggiornare `PRODUCT.md` o `DESIGN.md` se cambia la decisione.
