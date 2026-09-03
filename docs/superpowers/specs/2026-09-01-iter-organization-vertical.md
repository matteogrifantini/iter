# Iter — Specifica del primo verticale di organizzazione

> Documento di direzione approvata. Descrive il verticale da costruire; non autorizza ancora modifiche al codice applicativo, integrazioni remote o commit.

**Data:** 1 settembre 2026
**Ambito:** organizzazione di un viaggio, dal desiderio iniziale al piano con volo e soggiorno confermati
**Fuori ambito:** viaggio live, radar personale, acquisti dentro Iter, conferma automatica e GPS in background

## Obiettivo

Una persona deve poter entrare con un desiderio incompleto e arrivare a un viaggio concreto senza compilare un questionario tecnico e senza cercare separatamente partenza, mezzo, volo, zona e hotel.

Il risultato da validare è:

```text
desiderio libero
→ domande mirate
→ partenza, mezzo, destinazione e date convenienti
→ confronto voli reali
→ acquisto sul partner esterno
→ conferma del volo
→ interessi e modo di vivere il viaggio
→ zone coerenti
→ confronto hotel reali
→ conferma del soggiorno
→ primo piano modificabile
```

Il valore distintivo non è mostrare più offerte. È fare emergere la soluzione più adatta attraverso profilo, disponibilità reale, vincoli e compromessi spiegati.

## Decisioni di prodotto

- L’AI è la regista del flusso e dell’ordine delle domande.
- L’utente può scrivere, parlare oppure navigare le schede; tutti i percorsi modificano lo stesso viaggio in costruzione.
- La Home mantiene una struttura stabile: CTA, carosello dei viaggi, opportunità eventuali e navigazione fissa.
- La CTA principale è `Organizza un viaggio`; non esistono tre modalità separate come `Organizza`, `Scegli` e `Sono in viaggio`.
- Il viaggio live futuro si attiverà automaticamente in base a date e luogo, con conferma contestuale; non fa parte di questo verticale.
- Iter pone 3–4 domande essenziali e al massimo 2 domande adattive. Il limite vale per la raccolta esplicita; le schede contestuali possono comunque proporre luoghi o attività da esplorare.
- La domanda successiva viene mostrata soltanto se può cambiare concretamente ricerca, prezzo, fattibilità o compatibilità.
- Iter può proporre da dove partire, come partire e dove andare. Origine, mezzo e destinazione non sono campi obbligatori da compilare in anticipo.
- Le date possono essere precise, flessibili, ricavate da disponibilità salvate oppure aperte entro un orizzonte dichiarato.
- Il volo acquistato e confermato è il primo vincolo reale del viaggio.
- L’hotel non viene cercato soltanto per città e date: prima vengono proposte zone motivate da profilo, luoghi, eventi, collegamenti, aeroporto e prezzo.
- L’utente può scegliere una proposta, modificarla o ignorare il suggerimento di Iter senza essere bloccato.
- Prezzi, disponibilità e fonti devono essere distinguibili da stime e contenuti editoriali.
- Un link aperto verso un partner non equivale a un acquisto. Acquisti e prenotazioni richiedono conferma esplicita, salvo una futura fonte verificabile.

## Home: struttura stabile

La Home è un contenitore prevedibile. Cambiano i dati nelle sezioni, non la gerarchia della pagina.

```text
Oggi

[ Organizza un viaggio ]

I tuoi viaggi
[ In costruzione ] [ In arrivo ] [ Live ]  →

Opportunità per te                         →
[ solo proposta realmente pertinente ]

Oggi · Viaggi · Tu
```

Regole:

- `Organizza un viaggio` resta nella stessa posizione e apre una nuova conversazione.
- Se esiste un draft, il carosello mostra l’ultima azione: `Continua: scegli il volo`, `Conferma il soggiorno` o equivalente.
- Un viaggio live viene automaticamente portato in evidenza quando sarà supportato; l’utente non sceglie quale viaggio è attivo.
- Il carosello dei viaggi è manuale e non scorre automaticamente.
- `Opportunità per te` è uno slot separato. Nel primo verticale resta vuoto o assente se non esiste una proposta pertinente; non viene riempito con città generiche.
- La navigazione inferiore resta sempre `Oggi / Viaggi / Tu`.

## Flusso canonico

### 1. Avvio e desiderio

La CTA apre una conversazione nuova. L’utente può scrivere o parlare, ad esempio:

> “Vorrei staccare qualche giorno a novembre, spendendo poco, ma con buon cibo e un posto vivo.”

La voce non invia automaticamente: la trascrizione appare nel composer, può essere corretta e viene inviata soltanto dopo conferma.

Iter crea un `TripIntent` provvisorio e riassume ciò che ha capito senza presentare ancora destinazioni casuali.

### 2. Domande essenziali e adattive

Iter raccoglie soltanto le informazioni mancanti che cambiano il risultato. L’ordine può variare in base alla richiesta e al profilo.

Le aree possibili sono:

- origine o raggio di partenza;
- finestra temporale e durata;
- compagnia e numero di viaggiatori;
- mezzi accettati e cambi tollerati;
- budget tutto incluso per persona;
- forma del viaggio, ritmo e priorità;
- disponibilità a raggiungere aeroporti o stazioni alternativi.

Il profilo dei viaggi passati può precompilare segnali già confermati. Non deve diventare un questionario nascosto: Iter mostra perché una preferenza viene usata e consente di correggerla.

Le risposte possono essere chip, calendario, contatore, testo inline o voce. Sono sempre presenti `Non lo so` e `Decidi tu` dove hanno un significato reale.

Mentre l’utente risponde, Iter può preparare ricerche parziali. Non deve ricominciare da zero dopo ogni risposta: aggiorna l’intento e invalida soltanto i risultati incompatibili.

### 3. Proposte di partenza, mezzo e destinazione

Quando il minimo contesto è sufficiente, Iter costruisce un piano di ricerca:

- aeroporti o stazioni di partenza plausibili;
- mezzi compatibili;
- destinazioni o percorsi possibili;
- date e durate da confrontare;
- hard constraints e preferenze morbide;
- copertura dei provider e livello di attendibilità.

La persona può accettare il piano di ricerca, modificarlo con filtri oppure scrivere una correzione. Non deve compilare una form separata per origine, destinazione e mezzo.

### 4. Confronto dei voli

La prima ricerca concreta è quella del trasporto. Mostrare una lista verticale completa, con filtri e ordinamenti; non un unico vincitore deciso in modo opaco.

Ogni scheda volo mostra almeno:

- partenza e arrivo;
- aeroporto o stazione;
- durata e scali;
- bagaglio e condizioni rilevanti;
- prezzo e valuta;
- eventuale flessibilità della data;
- fonte e orario di verifica;
- scadenza o avvertenza sulla volatilità;
- compromesso principale.

Ordinamenti leggibili:

- miglior equilibrio;
- prezzo più basso;
- meno tempo di viaggio;
- meno cambi;
- più coerente con i criteri dichiarati.

Iter può raccomandare una scheda, ma deve mostrare anche le alternative e spiegare il motivo della raccomandazione. `Migliore` significa migliore tra le fonti e i criteri effettivamente consultati, non miglior prezzo assoluto del mercato.

### 5. Acquisto e conferma del volo

Il percorso è esterno a Iter:

```text
proposta live
→ pronta per l’acquisto
→ partner aperto
→ in attesa di conferma
→ confermato dall’utente o da una fonte verificabile
```

Iter non raccoglie carta e non interpreta l’apertura del link come acquisto. La scheda di ritorno offre `Ho acquistato questo volo`; un codice di prenotazione può essere facoltativo e non è un requisito del primo verticale.

Il volo confermato congela date, aeroporti, orari, durata, bagaglio e budget già impegnato. Se l’utente lo modifica, le ricerche hotel collegate vengono marcate obsolete e ricalcolate soltanto dopo la nuova conferma.

### 6. Modo di vivere la destinazione

Dopo la conferma del volo, Iter apre una conversazione breve e contestuale. Usa le domande adattive residue e schede esplorative, non un secondo questionario.

Può mostrare:

- ritmo: intensivo, equilibrato o lento;
- cibo, cultura, natura, mare, riposo, vita locale o sera;
- luoghi ed eventi disponibili nelle date fissate;
- una base unica oppure più spostamenti;
- tolleranza a camminate, trasporti e cambi di zona.

Le schede di luogo o evento hanno foto/video quando aiutano a decidere, breve motivo di compatibilità, momento migliore, tempi di spostamento e azioni chiare. Salvare un luogo come interesse non lo inserisce automaticamente nel piano.

### 7. Zone prima degli hotel

Iter propone 2–3 ipotesi di zona. Ogni ipotesi deve rendere visibile il ragionamento:

- luoghi ed eventi raggiungibili;
- tempo e semplicità dall’aeroporto;
- collegamenti verso le attività selezionate;
- atmosfera e ritmo;
- disponibilità e fascia di prezzo;
- compromesso principale.

Non usare un punteggio unico artificiale. Usare frasi come:

> “Questa zona è più adatta perché ti permette di raggiungere a piedi i ristoranti che ti interessano, resta collegata all’aeroporto e offre più soluzioni nel budget.”

La zona è modificabile. Se l’utente sceglie una zona diversa, Iter ricalcola gli hotel e spiega cosa cambia.

### 8. Confronto degli hotel

La ricerca usa zona, coordinate o collegamenti, non soltanto `città + date`.

Ogni scheda hotel mostra almeno:

- foto e servizi;
- prezzo totale e condizioni;
- cancellazione e trattamento;
- distanza o tempo verso i luoghi rilevanti;
- tempo e complessità dall’aeroporto;
- fonte, disponibilità e orario di verifica;
- link esterno per prenotare;
- motivo di compatibilità e compromesso.

L’utente può filtrare o chiedere in chat, ad esempio `più economico`, `più centrale`, `senza usare la metro` o `con colazione`. La ricerca si aggiorna nella stessa scheda/sessione.

La prenotazione segue la stessa regola del volo: link esterno, stato di attesa e conferma esplicita. Solo dopo la conferma del soggiorno si genera il piano completo.

### 9. Primo piano modificabile

Il piano nasce con:

- volo e soggiorno confermati;
- arrivo e partenza;
- attività coerenti con profilo, luoghi ed eventi;
- tempi realistici di spostamento;
- spazi liberi;
- alternative non ancora accettate;
- costi e disponibilità quando verificabili.

Ogni attività ha stato `proposta`, `accettata`, `prenotata` o `completata`. L’utente può riordinare, spostare, bloccare, rimuovere o chiedere modifiche in chat. Le modifiche importanti passano da anteprima a conferma; Iter non riscrive silenziosamente tutto il piano.

## Grammatica delle schede

La chat resta la timeline canonica. Le schede sono contenuti azionabili inline, non pagine parallele.

Tipi iniziali:

```text
IntentSummaryCard
QuestionCard
SearchStatusCard
FlightComparisonCard
ExternalPurchaseCard
FlightConfirmationCard
ExperienceCard
ZoneProposalCard
StayComparisonCard
StayConfirmationCard
PlanProposalCard
```

Ogni scheda ha una forma comune:

```text
id
tripId
kind
state
payload
actions
source?
verifiedAt?
expiresAt?
```

Stati comuni:

```text
collecting
searching
partial
ready
selected
awaitingConfirmation
confirmed
stale
unavailable
```

Regole visuali:

- testo breve di Iter sopra o accanto all’azione;
- una decisione principale alla volta;
- dati numerici confrontabili prima dell’editoriale;
- media solo quando aiuta la scelta;
- fonte, aggiornamento e stato sempre leggibili;
- aggiornamento nella stessa scheda senza perdere la selezione;
- alternativa accessibile a ogni swipe, drag o animazione.

## Eventi e aggiornamenti progressivi

L’orchestratore produce eventi strutturati che il client converte in messaggi e schede:

```text
intent.created
question.requested
user.answer.confirmed
search.started
search.progressed
search.partialResults
search.completed
flight.selected
external.purchaseOpened
flight.confirmationRequested
flight.confirmed
experience.contextRequested
zone.proposed
stay.searchStarted
stay.partialResults
stay.selected
stay.confirmed
plan.proposed
provider.degraded
offer.expired
```

`SearchStatusCard` può mostrare attività reale, per esempio provider interrogati, combinazioni analizzate o verifiche in corso. Non deve mostrare percentuali inventate, ragionamenti simulati o un caricamento infinito.

Se arrivano risultati parziali, la scheda può crescere progressivamente. Un’offerta cambiata diventa `stale` con l’ora dell’ultima verifica; non viene rimossa senza spiegazione.

## Modello concettuale

Il primo verticale deve tenere separati questi oggetti:

### `TripIntent`

Desiderio corrente e criteri ancora modificabili:

- testo iniziale;
- origine e alternative;
- destinazione o percorso candidato;
- mezzi accettati;
- modalità temporale e durata;
- viaggiatori;
- budget e tolleranza;
- ritmo, interessi e vincoli;
- segnali di profilo usati;
- stato di completezza.

### `SearchSession`

Ricerca concreta con query, provider, timestamp, risultati parziali, errori e scadenza. Una nuova risposta aggiorna la sessione o ne apre una versione correlata; non cancella la storia delle decisioni.

### `ProviderOffer`

Offerta normalizzata con identificativo provider, tipo, origine, destinazione, date, prezzo, condizioni, media, link esterno, `fetchedAt`, `expiresAt` e stato.

### `UserDecision`

Scelta esplicita con oggetto scelto, momento, origine dell’azione, stato di conferma e possibilità di revisione. Aprire un link non crea una decisione confermata.

### `ProfileSignal`

Preferenza stabile derivata soltanto da una scelta confermata o da un dato modificato dall’utente. Il profilo stabile, l’intento corrente e le offerte live restano separati.

### `TripPlan`

Timeline derivata da volo e soggiorno confermati, con revisioni, attività e stato di ogni elemento.

Il radar personale non entra in questi contratti iniziali; sarà un oggetto separato con consenso, durata e pausa espliciti.

## Ruolo dell’AI

L’AI riceve lo stato corrente, i segnali di profilo consentiti e i risultati strutturati dei provider. Può produrre:

- la prossima domanda motivata;
- il piano di ricerca;
- l’ordinamento delle alternative;
- la spiegazione dei compromessi;
- la proposta di zona;
- la bozza di piano;
- la richiesta di conferma.

Non può:

- inventare prezzi, disponibilità, foto o condizioni;
- dichiarare acquistato un elemento senza conferma;
- modificare una scelta confermata senza richiesta;
- usare una preferenza inferita come fatto stabile senza renderla correggibile;
- chiamare provider o custodire chiavi dal client Flutter.

La logica deterministica applica i vincoli duri. L’AI interpreta, ordina e spiega le preferenze morbide sulla base dei risultati realmente disponibili.

## Provider e costi

### Voli

Il primo adapter candidato è [`fast-flights`](https://github.com/AWeirdDev/flights), eseguito fuori dal client Flutter e isolato dietro un contratto Iter. Poiché il progetto è uno scraper, l’adapter deve prevedere blocchi, cambiamenti di formato, risultati parziali e sostituzione futura.

### Hotel

Serve un adapter partner con ricerca per luogo/coordinate, disponibilità, prezzi, immagini e link esterno. Vio è un candidato da verificare sul piano commerciale e tecnico tramite la sua [Partner API](https://developers.vio.com/docs/getting-started.html). Trivago non è il baseline per una ricerca libera nel client: il suo [FastConnect](https://developer.trivago.com/fastconnect/fast-connect-overview.html) va trattato come integrazione partner distinta.

### Regola economica

- Iter non raccoglie pagamenti.
- L’utente acquista o prenota sul partner esterno.
- Le chiavi restano sul backend/orchestratore.
- Il modello desiderato è senza costi fissi per Iter, con eventuale revenue share; ogni provider va verificato prima dell’integrazione.
- In assenza di accesso a un provider reale, l’ambiente di sviluppo può usare un adapter deterministico. In produzione l’assenza del provider deve essere dichiarata, non mascherata con dati demo.

## Stati degradati e fiducia

Il verticale deve avere stati progettati per:

- provider lento o parzialmente disponibile;
- nessun risultato compatibile;
- prezzo cambiato o offerta scaduta;
- link esterno non disponibile;
- permesso voce negato o trascrizione fallita;
- media assente;
- zona scelta dall’utente ma con pochi hotel;
- viaggio modificato dopo la conferma del volo.

Ogni stato comunica cosa è successo e quale azione è possibile. Non presentare una stima come disponibilità live e non trasformare un errore del provider in una raccomandazione generica.

## Accessibilità e motion

Il verticale eredita i vincoli di `DESIGN.md`:

- target minimi 48 dp;
- composer vocale con testo modificabile;
- ordine semantico coerente tra chat e schede;
- testo leggibile a scala 1.5;
- tema chiaro e scuro;
- layout usabile a 320, 360 e 390 dp;
- stato testuale equivalente per ogni animazione;
- con movimento ridotto, aggiornamento immediato o crossfade;
- tastiera, sheet e dialog chiudibili senza perdere il testo composto.

## Criteri di accettazione del verticale

Il verticale è valido quando una prova manuale e automatizzata dimostra che:

1. La Home mantiene CTA, carosello e navigazione in posizioni prevedibili.
2. La CTA apre una conversazione senza chiedere una modalità.
3. L’utente può partire da testo o voce; la trascrizione vocale richiede conferma.
4. Iter pone 3–4 domande essenziali e non supera 2 domande adattive.
5. Iter può proporre origine, mezzo, destinazione e date flessibili.
6. La lista voli mostra alternative, filtri, fonte, freschezza e compromessi.
7. Il link esterno non viene trattato come acquisto.
8. Solo la conferma del volo apre la fase contestuale per zone e hotel.
9. Le zone sono visibili, motivate e modificabili.
10. Gli hotel sono cercati in base alla zona e al profilo, non solo città/date.
11. Il piano completo appare soltanto dopo la conferma del soggiorno.
12. Chat, filtri e schede mantengono lo stesso `tripId` e lo stesso stato.
13. Offerte scadute, provider non disponibili e risultati vuoti hanno stati onesti.
14. Nessuna scelta confermata viene modificata in silenzio.
15. Il mock resta confinato allo sviluppo e non maschera un provider assente in produzione.

## Confini rispetto al checkout attuale

Questo documento descrive il target del nuovo verticale e non autorizza a collegare provider reali al Nuovo viaggio Lab esistente. Il Lab resta isolato, deterministico e senza persistenza/provider finché non viene approvato il relativo piano di migrazione.

La successiva implementazione dovrà essere divisa in piani testabili per responsabilità:

1. contratti di dominio, stato ed eventi;
2. orchestrazione e schede della ricerca volo;
3. conferma del volo, contesto della destinazione e proposte di zona;
4. adapter hotel, confronto e conferma del soggiorno;
5. generazione e modifica del piano;
6. voce, media e stati degradati in modo trasversale.

Radar personale, attivazione live automatica, importazioni e conferme automatiche restano piani successivi.

## Appendice A — Registro completo delle decisioni emerse

Questa appendice conserva il ragionamento che ha portato alla specifica, così una nuova AI non deve ricostruire il contesto da risposte brevi o da scelte multiple isolate.

### Visione generale

L’utente vuole che Iter copra tutti i momenti del viaggio:

1. nasce il desiderio;
2. il desiderio diventa un viaggio organizzato;
3. vengono confrontate e confermate le scelte concrete;
4. il viaggio diventa live quando arrivano le date e il luogo giusti.

La priorità attuale non è il viaggio live ma l’organizzazione. Il live deve essere una trasformazione automatica dello stesso viaggio, non un prodotto separato e non una scelta iniziale nella Home.

Il punto di partenza non deve essere necessariamente una destinazione già nota. L’utente può dire soltanto che vuole staccare, spendere poco, mangiare bene, partire in un certo periodo o sfruttare alcuni giorni liberi. Iter deve aiutarlo a capire anche **dove**, **da quale punto di partenza** e **con quale mezzo** conviene partire.

### Accesso e comportamento della Home

In una prima fase era stata considerata una Home che chiedesse di scegliere tra organizzare, scegliere o usare il viaggio live. Questa direzione è stata rifiutata: introduce una decisione artificiale e mette l’utente davanti a modalità che Iter dovrebbe gestire automaticamente.

La decisione finale è una Home ibrida:

- struttura stabile e riconoscibile;
- CTA fissa per iniziare;
- carosello dei viaggi in costruzione, in arrivo o live;
- eventuale spazio per opportunità personali;
- contenuti adattivi soltanto dentro spazi prevedibili.

La Home non deve essere né completamente statica né completamente dinamica. Non deve sembrare confusionaria, un catalogo di città o una dashboard piena di widget. La CTA `Organizza un viaggio` è utile e deve rimanere visibile; non è una modalità, è l’ingresso chiaro alla conversazione.

### Viaggio live e unicità del viaggio attivo

L’utente non sceglie il viaggio attivo. Un viaggio diventa candidato al live quando:

- la data corrente rientra nelle date del viaggio;
- la posizione dell’utente è coerente con la destinazione;
- l’app può chiedere una conferma contestuale del tipo `Sei in viaggio?`.

La conferma serve come protezione dell’utente, ma non deve diventare una schermata o una modalità principale della Home.

Non possono esistere più viaggi live contemporaneamente: l’utente non può trovarsi in più luoghi nello stesso momento. Possono esistere più viaggi futuri o in costruzione, ma non si devono creare duplicati per lo stesso viaggio. Se una nuova richiesta sembra riferirsi a un viaggio già in costruzione, Iter deve riaprire o aggiornare quel contesto e chiedere chiarimento soltanto se l’ambiguità è reale.

### Ritmo della conversazione

La direzione approvata è ibrida:

- Iter non deve fare subito un questionario;
- Iter non deve nemmeno proporre una lista generica dopo una sola frase;
- deve fare poche domande decisive e iniziare a cercare appena ha abbastanza contesto;
- le ricerche e le risposte successive restringono il campo progressivamente.

Il limite approvato è di 3–4 domande essenziali e massimo 2 domande adattive. Le domande non devono essere tutte uguali: possono essere chip, calendario, contatore, testo libero inline o voce. `Non lo so` e `Decidi tu` sono risposte ammesse quando rappresentano davvero un’opzione.

Le domande devono essere concrete e legate a una decisione. Esempi approvati:

- `Preferisci una base comoda o cambiare zona ogni giorno?`
- `Quanto conta per te mangiare bene rispetto a vedere molti monumenti?`
- `In questo viaggio vuoi vedere molti luoghi o avere più tempo libero?`

Iter può conoscere meglio l’utente, ma senza questionario noioso e senza proposte generiche. Deve alternare domanda, ricerca e proposta. Una risposta già confermata in passato può ridurre le domande; una preferenza soltanto inferita non deve diventare un fatto stabile senza essere mostrata e correggibile.

### AI e personalizzazione

L’AI deve essere centrale. Non deve limitarsi a rispondere a un modulo rigido e non deve lasciare all’utente il compito di conoscere in anticipo aeroporti, stazioni, comparatori, quartieri e percorsi.

Iter deve unire:

- desiderio espresso adesso;
- viaggi e scelte passate confermate;
- disponibilità e vincoli correnti;
- offerte realmente disponibili;
- costi, tempi e compromessi.

L’AI decide cosa chiedere, quali strumenti chiamare, come ordinare i risultati e come spiegare la proposta. I provider forniscono i dati concreti. L’AI non deve inventare il prezzo migliore, la disponibilità o una motivazione non collegata ai dati.

Il risultato non deve essere una lista di `Roma, Parigi o Budapest` perché sono mete famose. Deve essere una soluzione specifica, motivata da profilo e disponibilità: partenza plausibile, date, mezzo, destinazione, costo e compromesso.

### Trasporto: decisioni esplicite

La ricerca del trasporto viene prima dell’hotel. L’utente può navigare la lista oppure scrivere direttamente in chat.

La ricerca deve:

- considerare date esatte o flessibili;
- confrontare più combinazioni di partenza, aeroporto, stazione, destinazione e mezzo;
- mostrare la lista completa con filtri;
- non imporre un unico vincitore opaco;
- spiegare perché una combinazione è interessante;
- permettere di cambiare criterio senza ricominciare da capo.

La prima fonte candidata per i voli è il repository [`AWeirdDev/flights`](https://github.com/AWeirdDev/flights). È stato scelto come primo adapter accettando il rischio che sia uno scraper e possa subire blocchi o cambiamenti. Deve quindi essere isolato e sostituibile.

L’utente può acquistare il volo sul partner esterno. Iter non deve gestire il pagamento e non deve interpretare il semplice click come acquisto.

### Hotel e zona

Dopo l’acquisto e la conferma del volo, Iter deve fissare il volo e cambiare registro. Non deve aprire una ricerca generica `Budapest, 4–6 dicembre`.

Deve capire:

- come l’utente vuole passare quei giorni;
- quali monumenti, eventi, ristoranti e luoghi lo interessano;
- quanto vuole camminare o usare i trasporti;
- se preferisce una base centrale, locale, tranquilla, serale o ben collegata.

Prima dell’hotel propone le zone. L’hotel è una conseguenza della zona, dei luoghi scelti, dell’aeroporto, dei collegamenti e del profilo.

Vio è stato considerato un possibile partner per la ricerca hotel, ma l’accesso e il modello commerciale devono essere verificati prima dell’integrazione. Trivago è stato considerato, ma la sua integrazione partner non va assunta come una API pubblica generica. È stato valutato anche Duffel per i voli: non è il baseline desiderato perché “nessun costo iniziale” non significa assenza di costi per ordine o altri costi commerciali.

La regola economica desiderata è: Iter non deve richiedere pagamenti all’utente dentro l’app e il modello per Iter deve evitare costi fissi, preferibilmente con revenue share. Questa è una condizione da verificare con ogni partner, non una promessa da codificare senza contratto.

### Multimodalità

La richiesta dell’utente non è una chat di solo testo. Iter deve usare:

- schede dinamiche;
- immagini e video pertinenti;
- scelte interattive;
- ricerca progressiva;
- voce come input;
- risposta principalmente visiva.

La voce funziona così: registrazione, trascrizione nel composer, correzione o conferma dell’utente, invio. Non è stata scelta una modalità full voice con risposte audio obbligatorie.

Immagini e video non devono essere decorativi. Devono aiutare a decidere una destinazione, una zona, un luogo, un evento o un hotel. Se non esiste una fonte attendibile, la scheda può restare testuale.

Le animazioni devono far capire che il motore sta davvero lavorando, ma soltanto rappresentando lavoro reale: fonti interrogate, combinazioni confrontate, risultati parziali, verifica del prezzo. Non devono simulare pensieri dell’AI, percentuali inventate o caricamenti infiniti.

### Profilo e apprendimento

Il profilo non deve essere un questionario permanente. Iter impara in modo progressivo e usa come segnali stabili soltanto:

- scelte confermate;
- viaggi completati o confermati;
- preferenze modificate esplicitamente;
- dati che l’utente può vedere, correggere e cancellare.

Vanno tenuti separati:

1. profilo stabile;
2. intenzione del viaggio corrente;
3. ricerca live;
4. eventuale radar salvato.

Una ricerca corrente non deve diventare automaticamente una preferenza permanente. Una proposta rifiutata non deve essere interpretata come una preferenza negativa stabile senza evidenza sufficiente.

### Radar personale e ciclo batch

Il radar è una funzione successiva, non parte del primo verticale. Deve controllare un’intenzione personale, non scansionare genericamente tutte le offerte per tutti gli utenti.

Dopo aver raccolto i criteri, Iter può chiedere:

> `Vuoi che controlli se compare una combinazione davvero interessante?`

Solo con consenso il radar si attiva. Deve avere criteri visibili, scadenza, pausa e cancellazione.

Il controllo non deve essere un batch quotidiano rumoroso. Deve privilegiare:

- verifica live quando l’utente riapre l’app;
- controlli poco frequenti per intenzioni ancora attive;
- eventi o variazioni significative;
- deduplicazione e cache;
- AI coinvolta soprattutto quando è cambiato qualcosa di rilevante.

Esempi di variazione significativa: calo sostanziale del prezzo, nuove date molto più convenienti, collegamento più semplice o hotel molto più affine nella zona.

Le variazioni normali restano nella Home. Le opportunità importanti possono generare una push, secondo impostazioni dell’utente. Il radar non deve riempire la Home con offerte generiche.

## Appendice B — Contesto verificato del repository

Questa sezione descrive lo stato visto durante la sessione del 1 settembre 2026. Non va confusa con il target prodotto descritto sopra.

### Branch e worktree

- Checkout: `/Users/matteo/iter`.
- Branch corrente: `feat/real-iter-app`.
- `feat/real-iter-app` e `codex/iter-ui-rebuild` puntano allo stesso commit `9007e49`.
- Non è stato trovato un branch più recente; non è stato effettuato alcuno switch perché il worktree era già sporco.
- Il worktree contiene modifiche tracked e molti file untracked precedenti a questa specifica. Non usare reset, checkout distruttivi o pulizie ampie.
- Non sono stati fatti commit, push o modifiche remote.

Prima di qualsiasi lavoro futuro eseguire:

```bash
cd /Users/matteo/iter
git status --short --branch
```

Considerare le modifiche già presenti come appartenenti all’utente finché non vengono esaminate esplicitamente.

### Architettura presente

L’app parte da `lib/main.dart`, costruisce `ChatFirstPrototypeApp` tramite `buildIterApp()` e usa `ChatFirstPrototypeController`. La shell espone `Oggi`, `Viaggi` e `Tu`.

La sorgente dati è dietro `IterDataSource`: il mock è deterministico e la sorgente Supabase è opzionale. Esistono già servizi e moduli per mappa, luoghi, voli, soggiorni, cibo, meteo, spese, traduttore, checklist, preferenze, Gemini, piano ed esportazione. La loro presenza nel checkout non significa che il nuovo verticale sia già conforme al flusso approvato.

Il checkout attuale contiene anche un Nuovo viaggio Lab isolato con `NewTripPlannerSheet` e relative fixture. Il Lab ha contratti storici e non deve essere collegato direttamente a provider reali o a `IterStore` senza un piano di migrazione approvato.

### Documenti da leggere in una nuova sessione

Ordine consigliato:

1. `/Users/matteo/iter/AGENTS.md`;
2. `/Users/matteo/iter/HANDOFF.md`;
3. `/Users/matteo/iter/PRODUCT.md`;
4. `/Users/matteo/iter/DESIGN.md`;
5. `/Users/matteo/iter/NEW_TRIP_MASTER_PLAN.md` per il Lab;
6. questo documento;
7. `/Users/matteo/iter/docs/superpowers/specs/2026-09-01-iter-organization-vertical.md` se il percorso è stato rinominato o linkato da un handoff più recente.

Le fonti di prodotto e il codice attuale possono contenere livelli diversi di maturità. Distinguere sempre:

- implementato e verificato;
- presente ma mock/demo;
- target approvato;
- idea futura o non ancora confermata.

## Appendice C — Istruzioni operative per una nuova AI

Se una nuova AI riprende questo lavoro:

1. non partire dal codice e non assumere che le funzioni elencate nell’handoff siano già live o economicamente sostenibili;
2. leggere prima i documenti indicati e verificare branch/worktree;
3. trattare questo documento come direzione target del primo verticale;
4. non modificare il Nuovo viaggio Lab per accelerare la nuova esperienza;
5. non aggiungere provider, chiavi o servizi remoti nel client Flutter;
6. mantenere la conferma esplicita per acquisti, prenotazioni e modifiche importanti;
7. non trasformare Iter in un chatbot puro, un questionario o un comparatore generico;
8. mantenere una sola fonte di verità per il viaggio e un solo `tripId` tra chat, schede, filtri e piano;
9. non nascondere un errore provider dietro dati demo in produzione;
10. prima del codice, dividere l’implementazione in piani testabili per dominio/eventi, voli, zone/hotel, piano e cross-cutting multimodale;
11. eseguire test proporzionati alle modifiche e non dichiarare “live”, “gratuito” o “verificato” senza evidenza;
12. non fare commit o push senza richiesta esplicita dell’utente.

Il primo obiettivo di implementazione resta una prova end-to-end dell’organizzazione: desiderio, domande, combinazioni di viaggio, volo esterno, conferma, zona, hotel e piano. Live automatico, radar, importazioni e conferme automatiche vengono dopo.
