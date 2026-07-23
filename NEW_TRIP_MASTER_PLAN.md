# Iter — Piano completo della scatola “Nuovo viaggio”

## Stato del documento

Questo è il documento canonico per la progettazione e l’implementazione progressiva della scatola **Nuovo viaggio**. Riunisce le decisioni approvate su workflow, UI/UX, raccolta delle preferenze, gestione delle date, risultati, confronto delle destinazioni e laboratorio Semplice.

Il documento descrive prima il prodotto definitivo e poi le fasi necessarie per
integrare progressivamente la sua presentazione. **Semplice** è l'unica
presentazione del Lab corrente; il rollout nel flusso reale resta successivo.

La prima iterazione a quattro layout è stata **testata ma rifiutata sul piano dell’interazione**: città casuali, opzioni a righe e doppio tap risposta/`Continua` non rappresentano la direzione del prodotto. La **Fase A2–A4 — Laboratorio UI v2** è stata implementata con localizzazione modificabile, otto domande, date flessibili corrette e percorso mock completo fino a risultati, shortlist, confronto e scelta. La riduzione qualitativa A5, descritta sotto come storia, ha conservato Focus e Rotta e introdotto Semplice. La successiva **Fase 1** ha selezionato Semplice come unica presentazione del Lab, senza alterare il controller o il contratto isolato.

Verifica corrente della Fase 1: QA nel Browser integrato completato su Home,
accesso diretto al Lab e modifica manuale dell'origine; due colonne a 390 dp,
una colonna a 360 dp, progresso dopo le opzioni, back e temi chiaro/scuro.
`flutter analyze`, la suite Flutter completa di 49 test, `flutter build web
--release` e APK debug Android sono completati. Lo snapshot A5 del 16 luglio
resta storico e precedente alla selezione finale di Semplice. Non integrare
persistenza o provider reali prima dei gate successivi documentati.

## Obiettivo del prodotto

“Nuovo viaggio” deve accompagnare una persona che non ha ancora scelto la meta verso una decisione informata. La destinazione non viene proposta prima di conoscere almeno i vincoli che incidono realmente sulla fattibilità e sul prezzo.

Il successo non coincide con il completamento di un questionario. Il flusso ha successo quando l’utente:

- capisce quanto manca alla fine e percepisce un impegno breve;
- può esprimere disponibilità precise, flessibili o completamente aperte;
- vede come le risposte costruiscono progressivamente la ricerca;
- riceve proposte con date, costi e compromessi confrontabili;
- conserva più alternative prima di scegliere;
- sceglie la proposta principale solo dopo avere avuto dati sufficienti;
- mantiene le alternative recuperabili se prezzi o preferenze cambiano.

## Principi UX approvati

- **Vincoli prima:** origine, date, durata, compagnia, trasporti e budget precedono la parte ispirazionale.
- **Percorso adattivo:** 6 domande essenziali, fino a 10 quando le risposte richiedono approfondimenti.
- **Una decisione alla volta:** niente form lungo e nessuna dashboard di parametri.
- **Niente chat persistente:** il testo libero appare inline tramite `Altro` o `Scrivilo tu` e in una nota finale opzionale.
- **Progresso onesto:** mostrare fase corrente, domande essenziali rimanenti e durata indicativa; le domande condizionali non devono sembrare un traguardo che si allontana.
- **Accumulo visibile:** una sintesi compatta aggiornata rende evidente che ogni risposta contribuisce alla ricerca.
- **Shortlist prima della scelta:** l’azione iniziale sui risultati è `Tieni per il confronto`, non `Scegli`.
- **Budget tutto incluso per persona:** trasporto, quota alloggio e spesa giornaliera stimata formano il numero principale.
- **Proposte come viaggi completi:** una proposta può essere una città oppure un percorso curato con più tappe.
- **Material 3 su Android:** “Apple style” significa precisione, spazio, gerarchia e motion; non comporta l’uso di controlli Cupertino incoerenti con la piattaforma.

## Workflow completo

```text
Home
→ Nuovo viaggio
→ Vincoli reali
→ Forma del viaggio
→ Riepilogo modificabile
→ Ricerca delle possibilità
→ Risultati già contestualizzati e prezzati
→ Shortlist di 2–4 proposte
→ Tabellone di confronto
→ Scelta della proposta principale
→ Alternative conservate
→ Curation dei luoghi
→ Scelta concreta del trasporto
→ Zona in cui dormire
→ Itinerario
```

### Fase 1 — Vincoli reali

La sequenza di base è:

1. **Da dove puoi partire?**
2. **Quando puoi partire?**
3. **Quanto può durare?** se non è già determinato dalle date esatte.
4. **Con chi parti?**
5. **Quali mezzi e spostamenti accetti?**
6. **Quanto vuoi spendere?**

### Fase 2 — Forma del viaggio

La domanda essenziale è:

7. **Che tipo di viaggio cerchi?**

Può essere seguita soltanto dagli approfondimenti pertinenti:

- ritmo desiderato;
- disponibilità a camminare e requisiti di accessibilità;
- una base oppure più tappe;
- clima o stagione da evitare;
- cambi, voli notturni o spostamenti non accettabili;
- desideri irrinunciabili e cose da evitare.

### Fase 3 — Riepilogo

Prima della ricerca mostrare **Il viaggio che stiamo cercando**, con righe modificabili per origine, date, durata, compagnia, trasporti, budget e preferenze.

Il pulsante `Cerca le possibilità` è l’unico elemento che avvia la ricerca. Non mostrare destinazioni prima di questa conferma.

### Fase 4 — Risultati e scelta

La prima schermata presenta 6–10 proposte complete. L’utente ne conserva 2–4 e apre quindi il confronto. Soltanto dal confronto o dal dettaglio informato può scegliere la proposta principale.

## Sistema di interazione del questionario

### Cornice condivisa

- App bar con chiusura, titolo `Nuovo viaggio` e fase corrente.
- Indicatore orizzontale della progressione; eliminare l’attuale linea verticale sovradimensionata.
- Indicazione contestuale come `Le basi · 2 di 6`.
- Sintesi compatta, ad esempio `Firenze · 3–5 giorni · 500 € p.p.`, usando sempre la partenza rilevata o inserita dalla persona.
- Contenuto centrale dedicato alla domanda corrente.
- Nessun `Continua` generico: le scelte singole complete avanzano dopo circa 200 ms; multi-selezioni, calendari e contatori espongono soltanto azioni contestuali come `Fatto (n)` o `Usa queste date`.
- Indietro preserva le risposte e consente la modifica.
- `Non lo so` o `Non importa` sono risposte esplicite soltanto dove hanno significato; non esiste uno skip generico.

### Comportamento delle risposte

- Scelta singola semplice: selezione, feedback di stato, avanzamento dopo 150–220 ms.
- Scelta multipla: nessun avanzamento automatico; usare `Fatto (n)`.
- Valore numerico: preset leggibili più campo manuale.
- Testo libero: campo inline dentro la domanda, non composer globale.
- Domanda condizionale: appare soltanto se migliora concretamente ricerca o confronto.
- Riduci movimento: sostituire slide e trasformazioni con crossfade o aggiornamento immediato.

## Specifica delle domande

### Partenza

- All’apertura richiedere nel contesto soltanto la posizione approssimativa mentre l’app è in uso; mai posizione precisa o in background.
- Convertire la posizione in città e mostrarla come pillola persistente `Parti da Firenze · Modifica`.
- Se servizio, permesso o reverse geocoding non sono disponibili, aprire la ricerca manuale senza bloccare il flusso.
- Il campo manuale accetta città, aeroporto o stazione e non mostra località casuali.
- Quando rilevata automaticamente, la partenza non conta come domanda; resta sempre modificabile.
- Approfondimento condizionale: disponibilità a raggiungere aeroporti o stazioni alternativi, espressa in tempo di viaggio anziché soltanto in chilometri.

### Compagnia

- Scelte iniziali: Solo, Coppia, Amici, Famiglia.
- Se non è Solo, mostrare il numero di viaggiatori.
- Per Famiglia chiedere il numero di bambini e le informazioni necessarie ai prezzi soltanto quando il provider le richiederà.
- Il budget principale resta per persona; il totale del gruppo è secondario.

### Mezzi

- Selezione multipla: volo, treno, bus, auto.
- `Qualsiasi, se conviene` seleziona tutte le modalità.
- Approfondimenti eventuali: numero massimo di cambi, voli notturni, aeroporti alternativi, disponibilità a noleggio o guida.

### Budget

- Il valore rappresenta il limite tutto incluso per persona.
- Comprende trasporto intercity, quota alloggio e stima giornaliera per pasti, trasporto locale e attività tipiche.
- Non comprende shopping, assicurazioni o esperienze premium opzionali.
- Usare importi espliciti, non categorie vaghe come `economico` o `comodo`.
- Consentire un valore manuale e una tolleranza modificabile.

### Tipo di viaggio

- Selezione multipla breve, con massimo consigliato di tre priorità.
- Categorie iniziali: cultura, cibo, natura, mare, riposo, vita locale, energia/notte.
- Ultima opzione `Altro`, con testo libero inline.

## Card “Quando puoi partire?”

La card è un mini-flusso con un solo obiettivo. Il progresso generale non avanza finché la preferenza temporale non viene confermata.

Vista iniziale:

- **Ho già le date** — partenza e ritorno precisi.
- **Ho più possibilità** — giorni disponibili anche separati.
- **Usa i miei giorni liberi** — attiva soltanto con disponibilità salvate.
- **Non lo so ancora** — ricerca indicativa nei prossimi mesi.

Copy di supporto:

> Più possibilità ci dai, più facilmente possiamo trovare la combinazione conveniente.

### Date esatte

- Calendario inline per scegliere partenza e ritorno, anche tra mesi o anni diversi.
- Date passate disabilitate; il MVP considera viaggi di almeno una notte.
- Mostrare immediatamente `18–21 settembre · 3 notti`.
- `Conferma date` completa la card.

### Più possibilità

- Copy: `In quali giorni potresti partire?`.
- Ogni giorno selezionato è una possibile partenza valida anche da solo; date e intervalli disgiunti sono ammessi.
- La durata è separata, con preset `1–2`, `3–4`, `5–7`, `8+`, `Indifferente` e intervallo personalizzato.
- Non raggruppare queste date in finestre consecutive e non imporre una durata predefinita di tre giorni.
- Mostrare un riepilogo come `5 partenze possibili · 3–5 giorni`.
- Il raggruppamento consecutivo resta esclusivo dei giorni liberi globali, che descrivono vere giornate disponibili a stare via.

### Giorni liberi salvati

- Senza dati, la riga rimane grigia e semanticamente disabilitata.
- Testo: `Aggiungi almeno un giorno nella scatola Giorni liberi per sbloccare questa scelta`.
- Con dati disponibili, mostrare il calendario evidenziato e le finestre consecutive ricavate.
- Consentire di escludere finestre per il viaggio senza modificare i giorni liberi globali.
- Alla conferma salvare uno snapshot; cambi globali successivi non modificano silenziosamente il viaggio.
- Un’azione esplicita permette di aggiornare lo snapshot.

### Non lo so ancora

- Orizzonte facoltativo di 3, 6 o 12 mesi.
- Senza scelta esplicita, usare i prossimi 12 mesi e dichiararlo.
- Chiedere una durata indicativa oppure consentire `Non so neanche questo`.
- Ricercare più durate standard quando anche la durata è aperta.
- Nei risultati mostrare range mensili o stagionali, mai prezzi puntuali presentati come certi.

### Sintesi della card

La barra della ricerca mostra uno dei formati:

- `18–21 set · 3 notti`;
- `4 finestre · 3–5 giorni`;
- `3 finestre dai giorni liberi`;
- `Date aperte · entro 12 mesi`.

## Risultati

### Lista delle proposte

Mostrare una lista verticale di proposte visuali, non un reel che nasconde i dati. Ogni proposta include:

- immagine o breve contenuto editoriale;
- città singola oppure percorso multi-tappa;
- migliore finestra trovata;
- durata;
- costo stimato tutto incluso per persona;
- totale del gruppo come dato secondario;
- suddivisione trasporto, alloggio e spesa locale;
- tempo di viaggio e numero di cambi;
- breve motivo di compatibilità;
- freschezza e livello di attendibilità del prezzo;
- compromesso principale.

Ordinamenti iniziali:

- miglior equilibrio;
- prezzo più basso;
- meno tempo negli spostamenti;
- maggiore compatibilità.

Azioni:

- `Dettagli`;
- `Tieni per il confronto`.

Una barra inferiore mostra il numero di proposte conservate e abilita `Confronta` da due elementi in su. La shortlist contiene al massimo quattro proposte.

### Dettaglio della proposta

Il dettaglio mostra:

- alternative di data;
- andamento o range del prezzo;
- assunzioni usate per trasporto e alloggio;
- struttura indicativa dei giorni;
- motivi di compatibilità;
- compromessi e fattori che possono cambiare il costo.

Il confronto è consigliato ma non obbligatorio: dal dettaglio è possibile scegliere direttamente una proposta quando l’utente è già convinto.

## Tabellone di confronto

Il confronto è verticale e organizzato per criterio, non una matrice laterale troppo densa.

Sezioni:

1. **Costo:** totale per persona, totale gruppo e differenza dal budget.
2. **Quando:** finestre migliori e livello di flessibilità.
3. **Come arrivare:** durata, cambi e aeroporto/stazione di partenza.
4. **Cosa ottieni:** notti, tappe e forma del viaggio.
5. **Compatibilità:** punti di forza e compromessi.

Ogni sezione confronta le proposte con valori e barre leggibili. Evitare un punteggio complessivo opaco; usare segnali comprensibili come `Miglior prezzo`, `Meno spostamenti` o `Più coerente con i tuoi interessi`.

Quando l’utente sceglie:

- la proposta selezionata diventa il viaggio principale;
- le altre 1–3 proposte restano disponibili come alternative;
- mostrare un riepilogo di date, costo e attendibilità;
- dichiarare che il prezzo non è bloccato;
- proseguire verso la curation dei luoghi e poi verso la scelta concreta del trasporto.

## Snapshot storico — Laboratorio a tre UI antecedente alla Fase 1

Prima della Fase 1, le tre anteprime — Focus, Rotta e Semplice — usavano lo
stesso controller, le stesse otto domande e lo stesso percorso successivo alle
domande. Cambiavano composizione, presenter delle opzioni, progresso e motion;
dati, regole e isolamento da store/provider restavano identici. Questo non è un
contratto operativo: Semplice è ora la sola presentazione del Lab.

Sequenza condivisa:

1. Partenza soltanto se non rilevata.
2. Quando.
3. Compagnia.
4. Mezzi.
5. Budget.
6. Tipo di viaggio, massimo tre priorità.
7. Ritmo.
8. Camminate e accessibilità.
9. Riepilogo modificabile.
10. Ricerca, sei proposte, shortlist, confronto e scelta.

Le anteprime non chiamavano `IterStore.beginNewTrip()`, non creavano viaggi,
ripartivano da zero a ogni apertura e usavano soltanto dati mock deterministici.
La Home di sviluppo mostrava una galleria responsive di tre tile visivamente
riconoscibili; nelle build senza laboratorio rimaneva il CTA normale.

### Regole visuali condivise storiche

- Niente elenchi con divisori come presenter principale.
- Ogni opzione combina icona Material, label, eventuale microtesto e stato selezionato.
- Usare presenter coerenti con la shell, con target minimo di 48 dp.
- L’ordine semantico resta logico anche quando la disposizione è decorativa.
- Con testo grande o larghezza ridotta, i presenter tornano a una griglia o a
  una colonna leggibile senza diventare righe nude.
- Movimento ridotto sostituisce le slide con crossfade o aggiornamento immediato.

### Varianti storiche

- **Focus:** tipografia grande, spazio ampio e bolle illustrate centrate.
- **Rotta:** domande come tappe verticali; risposte completate compatte e modificabili.
- **Semplice:** UI moderna e sobria, con sfondo caldo derivato dai ruoli
  semantici del tema (nessuna crema o palette parallela), titolo dominante e
  copy ridotto. Le opzioni emoji più testo sono su due colonne in condizioni
  normali, con fallback a una colonna per schermi stretti o testo grande; il
  progresso è sotto le opzioni.

### Snapshot storico — sette varianti prima della riduzione A5

Prima del feedback qualitativo il laboratorio includeva anche Mazzo, Canvas,
Costellazione, Passaporto e Compasso, oltre a Focus e Rotta. Quelle cinque
shell sono state eliminate durante A5 e non sono candidate al gate corrente.

### Riferimenti visuali

- [Onboarding Interests Selection](https://dribbble.com/shots/2800173-Onboarding-Interests-Selection)
- [Travel Planner Mobile App UI/UX](https://dribbble.com/shots/27167323-Travel-Planner-Mobile-App-UI-UX-Design)
- [Apple — Entering data](https://developer.apple.com/design/human-interface-guidelines/entering-data)
- [Android — Location permissions](https://developer.android.com/develop/sensors-and-location/location/permissions)

Usare i riferimenti per gerarchia, progressione e ritmo. Non copiare glassmorphism, radius eccessivi o controlli iOS incoerenti con Android.

## Architettura Flutter del laboratorio

### Configurazione

Estendere `AppConfig` con `newTripLab`:

- in debug è attivo di default tramite `kDebugMode`;
- `--dart-define=ITER_NEW_TRIP_LAB=false` lo disattiva esplicitamente e
  conserva il percorso prodotto esistente;
- nelle build release è disattivato di default;
- iniettabile nei widget test.

### Tipi condivisi

```text
NewTripPrototypeStep
  origin
  dates
  company
  transport
  budget
  travelStyle
  pace
  walking

NewTripFlowStage
  questions
  summary
  searching
  results
  compare
  selected

PrototypeDateMode
  exact
  manualAvailability
  savedAvailability
  open
```

`NewTripPrototypeController` conserva lo stato temporaneo e viene creato per
ogni route. La sola shell Semplice riceve il controller e implementa layout,
presenter delle risposte, progresso e motion. Dopo il riepilogo confluisce nel
flusso risultati esistente, che la Fase 1 non ridisegna.

Lo stato comprende:

- step corrente;
- stato dell’origine e relativa fonte dispositivo/manuale;
- preferenza temporale tipizzata;
- composizione del gruppo;
- mezzi accettati;
- budget per persona;
- stile, ritmo e preferenza di camminata/accessibilità;
- validità e sintesi di ogni passaggio.
- proposte mock, ordinamento, shortlist e scelta finale.

`OriginResolver` è iniettabile: l’implementazione reale usa posizione approssimativa e reverse geocoding; widget test e anteprime possono usare un resolver deterministico. `PrototypeProposalSource` è a sua volta iniettabile per coprire risultati e stato vuoto senza chiamate live. La sorgente deterministica fa incidere origine, mezzi accettati, orizzonte temporale e preferenza di camminata su costi, tempi, mese proposto, compatibilità e compromessi: i dati restano mock, ma le risposte non sono decorative.

Durante il laboratorio non sostituire ancora `Trip.availableDates`: il tipo sperimentale riproduce il contratto futuro senza migrare lo store di produzione. I giorni liberi sono quindi una dipendenza read-only iniettabile nel prototipo; il launcher reale non inventa fixture se il dominio globale non esiste ancora. Il collegamento persistente della scatola Giorni liberi appartiene alla Fase 3.

### Dipendenze approvate

- [`calendar_date_picker2 ^3.0.0`](https://pub.dev/packages/calendar_date_picker2) per range e selezioni multiple. È basato sul date picker Flutter, supporta Material 3 ed è compatibile con Flutter 3.44.
- [`geolocator ^14.0.3`](https://pub.dev/packages/geolocator) per il solo permesso foreground e la posizione approssimativa.
- [`geocoding ^5.0.0`](https://pub.dev/packages/geocoding) per trasformare le coordinate in città tramite i servizi nativi della piattaforma.
- `flutter_localizations` dall'SDK Flutter per calendario, semantica e formattazione italiane.
- `AnimatedSwitcher`, `AnimatedContainer`, `Wrap`, `Stack` e componenti Material nativi per motion e layout.

Non aggiungere `permission_handler`, SDK di mappe, package di motion, onboarding o design system: duplicano funzionalità già coperte da Flutter e dai due plugin di localizzazione.

## Modello dati definitivo

Nella Fase 3, sostituire la lista piatta `Trip.availableDates` con una
preferenza temporale tipizzata contenente:

- modalità;
- intervallo esatto opzionale;
- giorni o intervalli disponibili;
- durata minima e massima;
- orizzonte temporale;
- indicazione di valore esplicito o predefinito;
- origine manuale o da giorni liberi;
- timestamp dello snapshot;
- stato incompleto o confermato.

I giorni liberi globali rimangono separati dal viaggio. Le finestre ricercabili vengono derivate e non archiviate come stringhe dentro `discoveryAnswers`.

Anche origine, compagnia, trasporti, budget e preferenze devono passare progressivamente da `Map<String, String>` a tipi espliciti prima dell’integrazione con provider reali.

## Piano di implementazione

### Fase A2–A4 — Laboratorio UI v2 — implementata

1. Localizzazione approssimativa con origine persistente e modifica manuale.
2. Auto-avanzamento protetto per le scelte singole e azioni contestuali per le altre.
3. Date flessibili come possibili partenze, con durata separata.
4. Presenter illustrato condiviso e art direction sperimentali.
5. Ricerca mock deterministica su sei `JourneyRoute` esistenti.
6. Risultati, ordinamenti, shortlist 2–4, confronto verticale, stato vuoto e conferma.
7. Prezzi a range anche nel totale gruppo quando le date sono aperte; modo di arrivo coerente con i mezzi selezionati.
8. Verifica automatica dello stesso percorso sulle varianti allora disponibili,
   inclusi testo grande, schermi stretti, movimento ridotto e fallback manuale
   dell’origine.

### Fase A5 — Riduzione qualitativa a tre shell — implementata (storico)

1. Dopo il feedback qualitativo, eliminare Mazzo, Canvas, Costellazione,
   Passaporto e Compasso dalla galleria e dalle candidate al gate.
2. Conservare Focus e Rotta e aggiungere Semplice con la direzione sobria,
   semantica e responsiva definita sopra.
3. Mantenere controller, otto domande, riepilogo, ricerca mock, shortlist,
   confronto, selezione e isolamento da store/provider invariati.
4. Preparare il confronto qualitativo fra Focus, Rotta e Semplice; questa era
   la base storica della selezione successiva.

### Fase 1 — Intake Semplice del Lab — implementata

1. Rendere Semplice l'unica presentazione del Lab; Focus e Rotta non sono più
   selezionabili.
2. In debug, `kDebugMode` apre direttamente Semplice da **Inizia un viaggio**;
   `--dart-define=ITER_NEW_TRIP_LAB=false` lo disattiva esplicitamente e
   mantiene invariato il percorso prodotto esistente. In release il Lab è
   disattivato per default.
3. Limitare lo scope a presentazione e intake: mantenere invariati controller,
   date tipizzate, sorgente di proposte mock deterministica, riepilogo,
   risultati esistenti e contratto senza persistenza/provider.
4. Usare due colonne solo oltre 360 dp con testo normale; usare una colonna a
   360 dp o meno e con testo grande. Posizionare il progresso dopo le opzioni e
   indicare domanda corrente e domande residue.
5. Il QA nel Browser integrato è completato su Home, accesso diretto al Lab e
   modifica manuale dell'origine, con i breakpoints 390/360 dp, progresso dopo
   le opzioni, back e temi chiaro/scuro. Non dichiarare provider live,
   persistenza o pubblicazione/rilascio.

### Fase 2 — Risultati, shortlist e confronto — pianificata

1. Ridisegnare risultati, shortlist e confronto senza modificare il contratto
   dei dati validato nel Lab.
2. Validare il redesign separatamente prima di estendere l'intake nel prodotto
   intero.

### Fase 3 — Flusso reale — pianificata

1. Introdurre i modelli tipizzati nel dominio del viaggio.
2. Collegare la shell vincente a `IterStore` e alla ripresa dei draft.
3. Introdurre la sorgente globale e persistente dei giorni liberi, separata da `Trip.availableDates`, e passarla read-only al nuovo viaggio.
4. Portare nel dominio i modelli tipizzati validati nel laboratorio.
5. Collegare la scelta al flusso esistente di curation, trasporto, zona e itinerario.

### Fase 4 — Provider reali — pianificata

Soltanto dopo la validazione del flusso mock:

- definire provider di prezzi e disponibilità;
- usare backend autenticato per chiavi e chiamate esterne;
- distinguere sempre prezzo rilevato, stima e range storico/stagionale;
- gestire risultati parziali e fonti non disponibili;
- non introdurre checkout o prenotazioni interne.

## Test e criteri di accettazione

### Laboratorio

- Con laboratorio attivo, **Inizia un viaggio** nella Home apre direttamente
  Semplice; con laboratorio disattivato, il CTA normale resta invariato.
- Semplice completa domande, riepilogo, risultati, shortlist, confronto e
  scelta finale. La Fase 1 non ridisegna le ultime tre superfici.
- La partenza rilevata viene preselezionata e può essere modificata; permesso negato, servizi disattivati e lookup fallito ricadono sul campo manuale.
- Una scelta singola avanza una sola volta senza `Continua`; multi-selezioni e calendari aspettano l’azione contestuale.
- Indietro modifica la risposta senza perdere gli altri valori.
- Chiudere e riaprire riparte da zero.
- Aprire o completare un’anteprima non cambia il numero di viaggi nello store.
- Swipe e drag hanno sempre un’alternativa tramite controlli espliciti.
- La sorgente mock produce sei proposte con breakdown coerente; lo stato senza risultati è iniettabile e testabile.
- Shortlist minima due, massima quattro; riordinare i risultati non perde la selezione.

### Date

- Intervallo nello stesso mese, tra mesi e tra anni.
- Possibili partenze singole e disgiunte valide senza consecutività.
- Durata selezionata indipendentemente dalle possibili partenze.
- Raggruppamento consecutivo applicato soltanto ai giorni liberi salvati.
- Durata incompatibile con i giorni liberi.
- Giorni liberi assenti e stato semanticamente disabilitato.
- Giorni liberi presenti tramite fixture di test.
- Orizzonte scelto e default di 12 mesi.
- Cambio modalità e ripristino corretto della sintesi.

### UI e accessibilità

- Target di almeno 48 dp.
- Ordine screen reader coerente con quello visuale.
- Contrasto adeguato in tutte le art direction.
- Tema chiaro e scuro.
- Font ingrandito senza overflow.
- Riduci movimento senza trasformazioni decorative.
- Semplice passa a una colonna a 360 dp o meno e con testo grande, mantenendo
  ordine semantico e target di interazione.
- Back Android e inset di sistema corretti.
- Layout compatto e comportamento su schermi più larghi.

### Verifica tecnica

```bash
flutter analyze
flutter test
flutter build web --release
```

Per la prova UI ordinaria, avviare:

```bash
./tool/run_web.sh
```

Aprire `http://127.0.0.1:7357` nel Browser integrato Codex e provare il solo
intake Semplice in modo interattivo, senza emulatore né screenshot/video
obbligatori. Il QA integrato è completato su Home, accesso diretto al Lab e
modifica manuale dell'origine, con due colonne a 390 dp, una a 360 dp,
progresso dopo le opzioni, back e temi chiaro/scuro. Screenshot o video restano
artefatti facoltativi, da usare solo quando richiesti o utili.

Il web è esclusivamente un harness QA locale e non cambia il target mobile o
la distribuzione Android. Al gate Android eseguire inoltre:

```bash
flutter build apk --debug
```

e una prova mirata sull’emulatore per back, inset di sistema, permessi,
gesture, prestazioni, lifecycle e comportamento/rendering nativo coinvolto
dalla modifica.

## Fuori scope iniziale

- prezzi e disponibilità live;
- autenticazione necessaria alla generazione remota;
- salvataggio dei prototipi nell’archivio;
- rollout app-wide dell'intake Semplice prima del relativo piano;
- import automatico di calendari o file dei turni;
- prenotazioni, pagamenti o checkout;
- multi-city costruito liberamente dall’utente;
- aggiornamento definitivo di `PRODUCT.md` e `DESIGN.md` prima della scelta visuale.

## Decisioni già chiuse

- Percorso adattivo da 6–10 domande.
- Vincoli mostrati per primi.
- Budget tutto incluso per persona.
- Proposte come viaggi completi.
- Shortlist seguita da confronto.
- Tabellone di confronto verticale per criterio.
- Alternative conservate dopo la scelta.
- Quattro modalità per la disponibilità temporale.
- Le date di `Ho più possibilità` sono partenze possibili, non giornate consecutive di vacanza.
- Semplice come unica presentazione corrente del laboratorio; Focus e Rotta
  restano storia della Fase A5.
- Otto domande più riepilogo e percorso mock completo.
- Localizzazione approssimativa automatica, sempre modificabile e senza background.
- Anteprime isolate e azzerate a ogni apertura.
- QA Browser della Fase 1 completato; rollout app-wide ancora da completare.
