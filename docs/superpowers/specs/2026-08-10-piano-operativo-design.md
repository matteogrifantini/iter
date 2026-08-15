# Iter — Piano operativo modificabile

**Stato:** design approvato il 10 agosto 2026

**Branch di riferimento:** `codex/chat-first-prototype`

**Target:** Flutter mobile, Android prodotto; Web solo harness QA

**Modalità dati:** mock deterministico con persistenza best effort già disponibile

## 1. Obiettivo

Trasformare l'attuale `TripSnapshot` read-only in un Piano operativo che la
persona può consultare e modificare sia direttamente sia tramite la chat. Il
Piano resta la fonte canonica delle decisioni: luoghi, ordine, orari, volo,
hotel, alternative, costi e stato degli acquisti non possono vivere soltanto
come istruzioni temporanee nella conversazione.

Il risultato deve consentire di:

- capire rapidamente la giornata attraverso media e timeline;
- aprire una scheda informativa per ogni luogo senza lasciare il Piano;
- vedere un reel del luogo e avviare indicazioni esterne;
- aggiungere, riordinare e rimuovere tappe senza usare la chat;
- chiedere a Iter informazioni sul luogo con il contesto già collegato;
- confrontare in chat opzioni di volo e hotel prima della selezione;
- conservare scelta e alternative nel Piano;
- vedere un riepilogo costi con scorciatoie di acquisto esterne;
- aggiornare esplicitamente lo stato dopo il ritorno dal provider.

## 2. Decomposizione del programma più ampio

La richiesta complessiva riguarda quattro sottoprogetti distinti:

1. **Piano operativo** — questa specifica.
2. **Chat ricca iniziale** — proposte di mete, luoghi, hotel e voli dentro la
   conversazione, usando i modelli tipizzati definiti qui.
3. **Shell, Viaggi e Profilo** — navigazione flottante, nuova chat, profilo
   distillato, disponibilità e statistiche.
4. **Condividi con Iter** — Android share target reale per Reel/TikTok,
   associazione al viaggio ed estrazione mock dei contenuti.

Questa specifica include soltanto i moduli di chat necessari a scegliere o
modificare volo e hotel di un viaggio già in costruzione. Non ridisegna ancora
l'intera conversazione iniziale, la sezione Viaggi, il Profilo o l'ingresso
Android da app social.

## 3. Decisioni di prodotto approvate

### 3.1 Integrazione ibrida Android

- Le indicazioni usano un collegamento esterno reale compatibile con Google
  Maps e browser.
- I collegamenti di acquisto di voli e hotel aprono provider esterni reali o
  URL demo configurate; Iter non esegue il checkout.
- Inventario, prezzi, estrazione dei contenuti e suggerimenti restano mock
  deterministici e vengono dichiarati come tali.
- Nessun pagamento proprietario, dato bancario, PNR, ricevuta o documento viene
  raccolto.
- L'implementazione riusa `url_launcher` e `video_player`, già presenti nel
  progetto. Non introduce SDK Google Maps, checkout, booking o media aggiuntivi.

### 3.2 Piano visuale

È approvata la direzione **Racconto + timeline**:

1. app bar con titolo del viaggio e azioni rare nel menu overflow;
2. hero fotografico o video breve della destinazione;
3. chip dei giorni;
4. timeline continua con fotografie delle tappe;
5. barra azioni flottante in basso con **Aggiungi luogo**, **Chiedi** e
   **Costi**.

La barra è una superficie Material flottante sopra il `SafeArea`, non una copia
di componenti Cupertino. I comandi globali restano in basso; tap, drag handle e
azioni contestuali del luogo rimangono accanto all'oggetto a cui appartengono.

La mappa decorativa iniziale viene rimossa. Il Piano privilegia foto e video;
la geografia operativa è disponibile tramite distanze testuali e indicazioni
esterne.

### 3.3 Alternative valutate

- **Diario immersivo:** scartato come struttura primaria perché rende ordine e
  orari meno confrontabili.
- **Agenda intelligente:** scartata come struttura primaria perché troppo
  operativa e meno identitaria; le sue qualità di scansione restano nella
  timeline scelta.
- **Dettaglio luogo full-screen:** scartato; interrompe il contesto del Piano.
- **Checkout Iter:** scartato per la prima versione; acquisti esterni e
  conferma leggera sono il contratto approvato.

## 4. Scheda luogo sovrapposta

### 4.1 Apertura e struttura

Il tap su una tappa apre un pannello sovrapposto e trascinabile. Il Piano resta
riconoscibile dietro lo scrim. Il pannello:

- parte a circa tre quarti dell'altezza utile;
- può espandersi quasi a schermo intero;
- può essere trascinato verso il basso per chiudersi;
- contiene uno scroll indipendente;
- conserva posizione e scroll dopo il ritorno da reel o chat;
- con testo grande può aprirsi direttamente nello stato esteso.

L'implementazione usa `DraggableScrollableSheet` o primitive Flutter native,
senza nuova dipendenza di layout.

### 4.2 Contenuto approvato

Ordine:

1. fotografia reale del luogo;
2. pillola **Vedi reel** sovrapposta alla fotografia;
3. nome, categoria e quartiere;
4. segnali con emoji: durata, costo indicativo e momento consigliato;
5. un solo riquadro **Perché Iter te la consiglia**;
6. descrizione breve, neutra e fattuale in stile enciclopedia;
7. azioni discrete **Indicazioni** e **Chiedi a Iter**;
8. informazioni pratiche con emoji: posizione nel Piano, distanza, ingresso e
   accessibilità.

Non compaiono gallery, taskbar interna, una seconda nota di Iter o testo che
spieghi ovvietà come il comportamento del pulsante chat.

### 4.3 Fotografia e reel demo

Il riferimento approvato per Livraria Lello è:

- file: `Porto - Livraria Lello.jpg`;
- autore: JaimeMSilva;
- origine: Wikimedia Commons;
- licenza: CC BY-SA 4.0;
- URL: `https://commons.wikimedia.org/wiki/File:Porto_-_Livraria_Lello.jpg`.

L'implementazione scarica il file negli asset, lo ottimizza senza rimuovere
l'attribuzione e lo registra nel file delle fonti media. Nessuna risorsa remota
viene caricata a runtime per il mock.

**Vedi reel** apre un visualizzatore verticale dedicato al luogo con:

- chiusura esplicita e Back Android;
- pausa/ripresa;
- audio disattivato inizialmente e controllo esplicito;
- fonte visibile;
- fallback fotografico se il video non parte;
- nessun autoplay in loop quando è attivo Riduci movimento.

### 4.4 Indicazioni

Ogni luogo possiede coordinate tipizzate e un nome destinazione. Il comando
costruisce un URI HTTPS di Google Maps Directions senza API key client. Il
sistema apre l'app compatibile quando disponibile e ricade sul browser.

Se coordinate o URI non sono validi, il comando resta disabilitato con testo
utile; non apre destinazioni parziali o non validate.

### 4.5 Chiedi a Iter

Il pulsante apre il thread del viaggio con un contesto visibile del luogo sopra
il composer. Non invia automaticamente un messaggio e non modifica il Piano.
Il contesto viene consumato dal successivo invio dell'utente e può essere
rimosso prima di scrivere.

## 5. Modifica manuale del Piano

### 5.1 Aggiunta di un luogo

**Aggiungi luogo** apre un pannello di ricerca e suggerimenti sul catalogo mock
della destinazione. La persona può:

- cercare per nome o categoria;
- aprire la scheda luogo;
- selezionare un luogo;
- vedere la proposta di Iter per giorno e orario;
- confermare oppure scegliere un altro punto.

Iter propone il punto migliore usando durata, distanza mock, orari, ritmo e
vincoli. Il Piano non cambia prima di una conferma esplicita. Quando non esiste
uno spazio coerente, il luogo entra soltanto nella raccolta **Da sistemare** e
non in una giornata arbitraria.

### 5.2 Riordino

Ogni tappa modificabile espone un drag handle con alternativa accessibile
**Sposta**. Durante il drag il Piano mostra un'anteprima. Dopo il drop compare
una conferma compatta con i soli effetti materiali, per esempio:

```text
Livraria Lello → 15:00
Ribeira slitta di 45 min

Applica · Annulla
```

Il drag non salva silenziosamente. `Annulla` ripristina ordine e orari. Luoghi
bloccati o collegati a una scelta acquistata non vengono spostati senza una
conferma rafforzata e una spiegazione dell'impatto.

### 5.3 Rimozione e modifica orario

Le azioni rare vivono nel menu contestuale della tappa o in **Sposta**; non
creano una fila permanente di pulsanti. Rimuovere un luogo non bloccato richiede
conferma quando cambia costi o prenotazioni. Cambiare orario usa lo stesso
contratto di anteprima e applicazione del riordino.

### 5.4 Versioni e annullamento

Ogni modifica accettata produce una revisione con:

- identificatore;
- timestamp;
- origine `manuale`, `chat` o in futuro `condivisione`;
- etichetta breve;
- stato precedente e stato risultante.

Il controller conserva una cronologia limitata e consente almeno l'annullamento
dell'ultima modifica. La revisione corrente del Piano è sempre persistita nel
riepilogo della conversazione; non dipende dalla presenza del messaggio che ha
originato il cambiamento.

### Note di implementazione (12 agosto 2026)

- Editing manuale realizzato con anteprima, conferma e annullamento:
  `place_picker_sheet.dart` (cerca → scheda → posizionamento, con esito
  **Da sistemare** quando non c'è uno slot coerente), `plan_patch_sheet.dart`
  (anteprima degli effetti con **Applica/Annulla**) e menu della tappa per
  **Sposta** (drag o menu), **Cambia orario**, **Blocca/Sblocca** e **Rimuovi**
  (`plan_timeline.dart`, `trip_snapshot_screen.dart`).
- Ogni comando produce una `PlanPatchPreview`; una conferma stale viene
  ricalcolata sulla revisione corrente (rebase) e resta in attesa di una
  conferma esplicita. La cronologia tiene al massimo 10 revisioni e
  `undoLastPlanRevision` ripristina l'ultima modifica, esposta anche come
  snackbar **Annulla** dopo la conferma.
- Copertura: `plan_models_test.dart`, `plan_editor_test.dart`,
  `trip_snapshot_screen_test.dart`.

## 6. Volo e hotel guidati dalla chat

### 6.1 Principio

Iter raccomanda, ma non nasconde il resto dell'inventario disponibile nella
sorgente corrente. Nel mock, **tutte le opzioni** significa tutte le opzioni
della fixture deterministica, non il mercato reale.

### 6.2 Volo

La conversazione deve mostrare una raccomandazione principale e consentire di
aprire l'elenco completo. Ogni opzione espone almeno:

- aeroporti di partenza e arrivo;
- date e orari;
- durata e scali;
- bagaglio incluso;
- prezzo e freschezza della stima;
- provider e URL esterno;
- compromesso principale.

Iter deve proporre alternative utili come:

- partire un giorno prima o dopo per risparmiare un importo esplicito;
- tornare un giorno prima o dopo;
- usare un aeroporto vicino dichiarando tempo e costo di avvicinamento;
- accettare uno scalo in cambio di un risparmio;
- mantenere l'opzione iniziale.

La selezione è esplicita. Opzione scelta e alternative viste vengono salvate
nel Piano.

### 6.3 Hotel

La conversazione guida la scelta mantenendo accessibile l'elenco completo della
fixture. Ogni opzione espone almeno:

- nome e zona;
- date e numero di notti;
- prezzo totale e condizioni demo;
- distanza media dalle tappe;
- atmosfera e compromesso;
- provider e URL esterno.

Iter può proporre una notte in più o in meno soltanto collegandola alle date di
viaggio e mostrando il nuovo totale. La scelta non modifica silenziosamente
volo o Piano: produce una proposta coordinata da confermare.

### Note di implementazione (12 agosto 2026)

- In chat i moduli `FlightCompare` e `StayCompare`
  (`chat_first_thread_screen.dart`, dati da `ChatFirstDemoData`) mostrano tutte
  le opzioni della fixture con la raccomandazione in evidenza; la selezione è
  esplicita e salva scelta e alternative nel Piano
  (`selectTravelOption`/`selectStayOption`).
- Per l'hotel il widget include uno stepper delle notti che produce una proposta
  coordinata (`PlanProposal` "Soggiorno ricalcolato") da confermare, senza
  modificare volo o Piano; la tariffa notturna è derivata deterministicamente
  dal prezzo totale (`stayNightlyPriceCents`).
- Le voci demo sono dichiarate: "Dati demo · prezzi e disponibilità non in
  tempo reale".

## 7. Riepilogo costi e acquisti esterni

### 7.1 Struttura

Il comando **Costi** apre un riepilogo lineare, senza checkout proprietario e
senza una pila di card. Le sezioni sono:

1. **Da acquistare:** volo e hotel selezionati;
2. **Stime non acquistate:** ingressi, pasti e trasporto locale;
3. **Totali:** da acquistare fuori da Iter, stime sul posto e totale previsto.

Ogni voce mostra origine del dato e stato `stima`, `selezionato`, `acquisto
aperto` o `acquistato`. Volo e hotel espongono **Cambia scelta** e
**Acquista ↗**. Le alternative viste in chat restano recuperabili.

### 7.2 Acquisto esterno

**Acquista ↗** apre soltanto un URI HTTPS allowlisted e configurato. Iter non
trasmette dati sensibili, non compila form e non dichiara di avere bloccato
prezzo o disponibilità.

Prima dell'apertura, il controller registra un ritorno atteso con
`conversationId`, tipo di scelta e identificatore dell'opzione. La domanda di
conferma appare una sola volta quando l'app torna in foreground dopo un link
avviato da Iter; non appare dopo normali resume o cold start. Se il processo è
stato terminato, la voce resta `acquisto aperto` e può essere aggiornata
manualmente dal Piano.

Al ritorno nell'app compare una conferma leggera:

```text
Hai acquistato questo volo?

Sì, aggiorna il Piano · Non ancora
```

Con **Sì** vengono salvati soltanto provider, opzione, prezzo mostrato,
timestamp e stato `acquistato`. Non vengono richiesti PNR, ricevute, documenti,
numero carta o indirizzo. **Non ancora** mantiene lo stato precedente.

### Note di implementazione (12 agosto 2026)

- Cost sheet lineare a tre sezioni come da vincolo (`plan_cost_sheet.dart`):
  **Da acquistare** / **Stime non acquistate** / **Totali**, con stato per voce
  (`stima`, `selezionato`, `acquisto aperto`, `acquistato`) e **Cambia scelta**
  / **Acquista ↗** su volo e hotel.
- **Acquista ↗** apre soltanto URI HTTPS il cui host è nell'allowlist di
  `PlanExternalLauncher.allowedHosts`; altrimenti l'azione è disabilitata e non
  tenta aperture permissive.
- `ChatFirstPrototypeApp` osserva `WidgetsBinding` e traduce `resumed` in una
  domanda di conferma solo se il launch è riuscito nella sessione; la shell
  consuma il prompt una volta prima di mostrarlo. **Sì, aggiorna** salva
  soltanto provider, opzione, prezzo, timestamp e stato; **Non ancora**
  ripristina `selezionato`; se il processo è stato terminato la voce resta
  `acquisto aperto` (i flag di launch sono stato di sessione, nessun prompt a
  cold start).
- Copertura: `trip_snapshot_screen_test.dart`,
  `chat_first_prototype_controller_test.dart`,
  `chat_first_prototype_widget_test.dart`.

## 8. Modello e flusso dati

### 8.1 Evoluzione compatibile

`TripSnapshot` resta un valore immutabile serializzabile e diventa la fonte
canonica corrente. Non viene trasformato in un oggetto mutabile: ogni comando
produce un nuovo snapshot, facilitando anteprima, versioni e annullamento.

Il JSON attuale continua a essere leggibile con default compatibili. I nuovi
campi sono opzionali in deserializzazione e completi nelle fixture nuove.

Tipi previsti:

```text
TripSnapshot
  revision
  destination media
  days: List<TripDaySnapshot>
  travelSelection: TravelPlanSelection?
  staySelection: StayPlanSelection?
  costSummary: PlanCostSummary

TripDaySnapshot
  id
  date
  label
  theme
  items: List<TripItemSnapshot>

TripItemSnapshot
  id
  place: PlanPlaceDetails?
  title
  category
  startTime
  durationMinutes
  locked
  source

PlanPlaceDetails
  placeId
  neighborhood
  description
  whyIterRecommends
  estimatedCost
  bestMoment
  accessibilityNote
  latitude
  longitude
  imageAsset
  reelAsset
  mediaAttribution

TravelPlanSelection / StayPlanSelection
  selectedOption
  alternatives
  providerPurchaseUri
  quotedPrice
  quotedAt
  purchaseState

PlanCostSummary
  externalPending
  purchased
  activitiesEstimate
  onTripEstimate
  projectedTotal
```

### 8.2 Comandi

Widget e chat non modificano liste direttamente. Chiamano comandi del
controller, per esempio:

```text
previewAddPlace
confirmPlanPatch
cancelPlanPatch
previewMoveStop
previewRemoveStop
selectTravelOption
selectStayOption
openExternalPurchase
confirmExternalPurchase
undoLastPlanRevision
```

Ogni comando è legato a `conversationId` e snapshot revision. Una conferma
stale viene rifiutata e il Piano viene ricalcolato sulla revisione corrente.

### 8.3 Persistenza

La sostituzione dello snapshot aggiorna immediatamente il thread in memoria e
usa la persistenza best effort già esistente. Una modifica accettata genera un
evento allowlisted con snapshot risultante, così chat e ripristino convergono
sullo stesso stato.

Un errore di persistenza non perde l'anteprima o l'input: la UI conserva la
modifica, segnala **Non salvato** e offre **Riprova**. La navigazione non finge
successo mentre la conferma è ancora in corso. Per questo slice, il risultato
delle scritture del Piano diventa osservabile dal controller invece di essere
sempre assorbito internamente dalla sorgente dati.

### Note di implementazione (12 agosto 2026)

- `TripSnapshot` resta un valore immutabile serializzabile; implementati anche
  `PlanRevisionMetadata` (id, numero, timestamp, origine, etichetta),
  `PlanChangeOrigin` (`manuale|chat|share`) e `PlanItemSource`
  (`iter|manual|chat|share`). Nel mock `PlanPlaceDetails` è ridotto a
  id/titolo/descrizione: coordinate, media e attribuzione vivono nella fixture
  operativa (`OperationalPlaceFixture`/`PlanMedia`).
- Comandi realizzati: `previewAddPlace`, `previewMoveStop`, `previewRemoveStop`,
  `previewChangeTime`, `previewToggleLock`, `confirmPlanPatch`,
  `cancelPlanPatch`, `selectTravelOption`, `selectStayOption`,
  `openExternalPurchase`, `confirmExternalPurchase`, `undoLastPlanRevision`.
  Le conferme stale vengono ricalcolate (rebase) sulla revisione corrente.
- La persistenza è osservabile dal controller (`PlanPersistenceState`:
  `idle|saving|saved|failed`) con `retryPlanPersistence`; `saveTripVersion`
  usa l'RPC `save_trip_revision` oppure il no-op del mock. `trip_versions` ha
  RLS con policy owner per select/insert e privilegi ristretti a
  `authenticated`
  (`supabase/migrations/20260811153441_tighten_trip_version_privileges.sql`).

## 9. Stati ed errori

- **Caricamento media:** spazio riservato e fallback fotografico, nessun layout
  shift.
- **Reel assente:** il pulsante non appare; la scheda resta completa.
- **Maps non disponibile:** apertura HTTPS nel browser.
- **Coordinate mancanti:** Indicazioni disabilitate con spiegazione.
- **URL provider mancante o non HTTPS:** Acquista disabilitato; nessun tentativo
  permissivo.
- **Nessuna alternativa:** la scelta corrente resta visibile senza promesse.
- **Conflitto di orario:** anteprima con tappe coinvolte; nessuna applicazione.
- **Revisione stale:** ricalcolo e nuova conferma.
- **Persistenza fallita:** stato locale conservato, indicatore e retry.
- **Ritorno provider non acquistato:** nessun cambio di stato.
- **Testo lungo o 1.5×:** pannello esteso e contenuto scrollabile.

## 10. Accessibilità e comportamento Android

- target minimi `48×48 dp`;
- alternativa tramite menu **Sposta** al drag;
- descrizione semantica completa per orario, stato, costo e vincolo;
- la timeline testuale resta completa senza immagini o video;
- focus screen reader sul pannello appena aperto e sul cambiamento confermato;
- Back chiude prima reel, pannello, tastiera o anteprima, poi la route;
- `SafeArea` e IME inset proteggono barra flottante e composer;
- temi chiaro e scuro;
- larghezze `320`, `360`, `390 dp` e testo `1.5`;
- Riduci movimento elimina trasformazioni del pannello e autoplay;
- nessuno stato dipende soltanto dal colore.

## 11. Verifica

### 11.1 Test di modello e controller

- compatibilità JSON dei vecchi snapshot;
- serializzazione di luoghi, selezioni, costi e stato acquisto;
- aggiunta con anteprima, conferma e annullamento;
- gestione **Da sistemare**;
- riordino con ricalcolo degli orari;
- blocchi e conflitti;
- revisione stale;
- undo ultima modifica;
- selezione volo/hotel e alternative persistenti;
- conferma al ritorno dal provider;
- URL Maps/provider validi e non validi;
- errore e retry di persistenza.

### 11.2 Widget test

- Piano senza mappa iniziale;
- hero media, giorni e timeline;
- scheda sovrapposta scrollabile;
- nota Iter unica e descrizione distinta;
- Vedi reel e fallback;
- Indicazioni e Chiedi a Iter;
- aggiunta, drag e alternativa accessibile;
- conferma compatta degli orari;
- riepilogo costi con acquisti esterni;
- domanda al ritorno dal provider;
- layout e semantica a `320/360/390 dp`, testo `1.5`, chiaro/scuro e Riduci
  movimento.

### 11.3 Gate

```bash
flutter analyze
flutter test
./tool/run_web.sh
flutter build web --release
```

Il Browser integrato verifica chiaro/scuro, pannello e scroll, reel/fallback,
aggiunta, riordino, costi e ritorno provider. Poiché indicazioni e collegamenti
esterni coinvolgono il comportamento Android, il gate include inoltre:

```bash
flutter build apk --debug
```

e QA Android mirato per Back, intent esterni, ritorno nell'app, inset e stato
del lifecycle.

## 12. Fuori scope

- inventario live completo di voli o hotel;
- pagamento, checkout, blocco prezzo o prenotazione dentro Iter;
- raccolta di PNR, ricevute, carte o documenti;
- mappa live o navigazione turn-by-turn interna;
- apertura orari, traffico o trasporto pubblico live;
- importazione automatica dell'esito di acquisto;
- intero mockup della nuova chat iniziale;
- redesign di Viaggi, navigazione e Profilo;
- disponibilità/turni di lavoro;
- statistiche personali;
- Android share target per Reel/TikTok.

## 13. Criteri di accettazione

Il Piano operativo è accettato quando:

1. ogni modifica diretta e ogni scelta fatta in chat convergono sullo stesso
   snapshot tipizzato;
2. nessuna tappa, alternativa, scelta di volo/hotel o stato acquisto esiste
   soltanto nel testo della chat;
3. la persona può consultare luoghi, reel e indicazioni senza una mappa iniziale;
4. aggiunta e riordino mostrano l'impatto prima di cambiare il Piano;
5. volo e hotel espongono tutte le opzioni della fixture e alternative di
   data/aeroporto utili;
6. il riepilogo distingue acquisti esterni e stime;
7. il ritorno dal provider aggiorna il Piano soltanto dopo conferma;
8. temi, accessibilità, responsive e gate Flutter/Android passano;
9. documentazione prodotto e design vengono aggiornate insieme al codice.

### Note di implementazione — stato (12 agosto 2026)

I task 1–9 del piano operativo sono implementati e verificati sul branch
`codex/chat-first-prototype`: 261 test PASS (210 sui moduli
chat-first/piano operativo), `flutter analyze` pulito. I fix emersi dal QA
Browser sono applicati: la nuova chat libera converge subito su Porto
(disclosure "Dati demo"), rimossa la selezione "Con chi vuoi parlare?" e la
card della Home con pianificazione aperta è neutra
(`surfaceContainerLow` + bordo). I gate finali del task 10 (QA Browser
integrato, `flutter build web --release`, `flutter build apk --debug`,
verifica Supabase e commit) restano da eseguire. Nessuna decisione approvata in
questa spec è stata modificata.
