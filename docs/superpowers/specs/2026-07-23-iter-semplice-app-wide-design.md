# Iter — specifica di design app-wide: Semplice

## Stato e decisione

Iter è un'app Flutter mobile per Android: una guida editoriale che aiuta una
persona a rendere possibile un viaggio, senza trasformarla in un agente di
viaggio né in un chatbot. Il Nuovo viaggio Lab ha confrontato Focus, Rotta e
Semplice sullo stesso flusso di preferenze, risultati deterministici,
shortlist e confronto.

La decisione di prodotto è di promuovere **Semplice** a unico linguaggio del
Nuovo viaggio e, progressivamente, dell'app. Focus e Rotta non restano come
modalità selezionabili nella superficie utente. Semplice non significa una UI
spoglia: significa una decisione leggibile per volta, testo breve ma
sufficiente, controlli direttamente modificabili e una conferma visibile
quando la scelta ha conseguenze.

La migrazione è incrementale. Il primo batch riguarda il Nuovo viaggio; Home,
Scopri, Viaggi, Profilo e gli altri flussi adottano il linguaggio solo dopo che
la sua forma è stabile nel Lab. Le integrazioni reali restano un programma
separato dal redesign.

## Obiettivi

- Rendere l'inizio di un viaggio caloroso, chiaro e poco formale: dalla
  disponibilità e dalle preferenze, non da una città preconfezionata.
- Usare Semplice come una sola esperienza coerente, non come un esperimento da
  scegliere nella Home.
- Conservare il contratto di fiducia: ogni vincolo importante è editabile, una
  proposta non salva né prenota, e prezzi/disponibilità mock restano dichiarati
  come stime.
- Ridurre il carico cognitivo nei risultati: prima capire se vale la pena
  tenere una proposta, poi confrontarne i trade-off, infine scegliere in modo
  esplicito.
- Trasferire nel tempo la stessa chiarezza ai flussi esistenti senza appiattire
  l'identità editoriale di Iter: atlante personale, route line, immagini e
  video usati come contenuto.
- Mantenere Material 3, tema chiaro/scuro, touch-first Android e accessibilità
  come vincoli di base, non come pass di rifinitura.

## Non-obiettivi

- Non cambiare nel primo batch il controller, i modelli di dominio, il
  proposal source, `IterStore`, i provider o la semantica delle date tipizzate.
- Non introdurre persistenza, autenticazione, ricerca reale, prenotazioni,
  pagamenti, mappe reali o scritture nello store attraverso il redesign.
- Non convertire Iter in una dashboard SaaS, in un form amministrativo o in
  un chatbot a schermo intero.
- Non creare una palette parallela, gradienti, superfici cream, glass panel,
  controlli proprietari o emoji usate come icone strutturali.
- Non applicare un restyling simultaneo a tutte le superfici: il linguaggio si
  afferma per batch verificabili.
- Non sostituire nel primo batch il percorso prodotto delle build senza Lab:
  finché dominio e store non sono integrati, soltanto la configurazione Lab
  apre direttamente Semplice.

## Principi visuali e di interazione

### Una decisione umana alla volta

Ogni schermata ha un titolo dominante, una domanda utile e un gruppo di
opzioni direttamente confrontabili. Il copy chiarisce le scelte che cambiano
il risultato, ma non narra il funzionamento dell'app. Quattro opzioni visibili
sono il limite preferito; gruppi più grandi usano categorie, una selezione
iniziale ristretta o disclosure progressiva.

Le opzioni Semplice combinano emoji e testo come contenuto espressivo del
viaggio, non come sostituto della semantica: il testo resta sempre visibile, i
controlli hanno ruoli e label accessibili e la navigazione usa icone Material
coerenti. Le selezioni singole complete avanzano dopo un breve feedback;
calendari, multi-selezioni, contatori, budget manuale e modifiche di vincoli
chiedono una conferma contestuale.

### Calma editoriale, nativa ad Android

Il brand vive nel ritmo, nella route line, in fotografie/video pertinenti e in
una tinta misurata; non in cornici decorative. Material 3 governa app bar,
bottom sheet, bottoni, chip, campi, snackbar e back. Il primario identifica
una scelta o impegno decisivo; i contenitori tonali spiegano una proposta o un
fit; errore e warning sono riservati ai casi reali. Una superficie non deve
sembrare una card se non rappresenta un viaggio, un luogo o un'area su cui si
agisce.

### Movimento che informa

La transizione tra domande, il feedback di una scelta e il passaggio a un
risultato spiegano un cambiamento di stato. Le transizioni durano normalmente
150–250 ms con easing calmo. Con riduzione movimento, ogni aggiornamento è
immediato o una crossfade semplice; non esistono animazioni decorative,
attese coreografate o layout che cambia dimensione al tap.

## Architettura e confini

Semplice sostituisce le varianti nella superficie di presentazione, senza
alterare la logica condivisa. Il primo batch conserva invariati:

- `NewTripPrototypeController`, i modelli e l'intento date tipizzato;
- `PrototypeProposalSource` deterministico, shortlist da due a quattro e
  confronto basato sui criteri già disponibili;
- isolamento del Lab da `IterStore`, provider reali e persistenza;
- origine approssimativa in primo piano con reverse geocoding, fallback
  manuale e possibilità di modifica;
- il contratto che una selezione finale nel Lab non crea né salva un viaggio.

La superficie Semplice può essere scomposta per responsabilità visive
(shell/intake, summary, lista risultati, shortlist, confronto, dettaglio,
empty state) affinché ogni componente abbia una sola grammatica. Questa
separazione non sposta né duplica la decisione di dominio nel layer widget.

Una volta che il primo batch ha scelto Semplice, il launcher di varianti e il
relativo switch non sono parte della Home. Con la configurazione Lab attiva,
“Inizia un viaggio” apre direttamente Semplice; senza Lab, il percorso prodotto
esistente resta invariato finché la Fase 5 non collega esplicitamente dominio,
draft e store. Qualsiasi meccanismo di comparazione interna resta separato
dalla navigazione di prodotto.

## Flusso: intake

### Entrata e origine

La Home offre una sola CTA primaria: **Inizia un viaggio**. Quando il Lab è
attivo, quella CTA apre direttamente Semplice; nelle altre build conserva il
percorso prodotto corrente fino all'integrazione reale. L'origine rilevata è
descritta come approssimativa e modificabile; se non è disponibile, la sheet
manuale spiega in italiano piano cosa serve e permette città, stazione o
aeroporto. Nessuna città casuale viene proposta come surrogato.

L'app bar ha un back/chiudi prevedibile e compatibile con il system Back. Dopo
la prima domanda, una pill modificabile riassume la partenza. Il suo stato è
annunciabile a screen reader e non richiede di ricordare un dato dalla schermata
precedente.

### Preferenze

L'ordine resta: origine, date/disponibilità e durata, compagnia, trasporti,
budget, stile, ritmo, cammino/accessibilità. Il progresso resta **sotto le
opzioni**, vicino al momento di decisione, ed espone sia il numero della
domanda sia il suo nome. Su schermi stretti o testo grande il contenuto scorre
sopra il footer e non viene nascosto dalla CTA.

La griglia ha due colonne solo quando larghezza e scala testo preservano
leggibilità e target da 48 dp; a 360 dp o sotto, e con testo grande, passa a
una colonna. Le opzioni con implicazioni non ovvie mantengono un breve
qualificatore visibile o una disclosure “come funziona”: le descrizioni non
vivono solo nel nome semantico. Stile di viaggio e trasporti, che possono
superare quattro alternative, offrono una selezione iniziale focalizzata e un
modo esplicito per vedere le opzioni restanti; il limite di priorità resta
visibile prima della selezione bloccata.

### Riepilogo e ricerca

Il riepilogo è una verifica editabile dei vincoli, non una pagina di marketing.
Confermare la ricerca rende esplicito che le destinazioni arrivano solo ora.
Lo stato di ricerca informa su date/durata, costi/collegamenti e trade-off,
senza simulare intelligenza artificiale o creare attese più lunghe del lavoro
effettivo.

## Flusso: risultati, shortlist e confronto

### Lista risultati

La lista propone dapprima due possibilità forti secondo l'ordinamento attivo,
con **Miglior equilibrio** come default e gli ordinamenti esistenti per prezzo,
tempo e compatibilità come controlli espliciti. Le altre restano disponibili
tramite un'espansione esplicita. Ogni riga/card di primo livello mostra
soltanto:

- destinazione o percorso e immagine che aiuta a immaginarlo;
- periodo/durata e prezzo stimato per persona;
- una ragione concreta di coerenza;
- una sola azione primaria: **Tieni per il confronto**.

Trasporto dettagliato, breakdown, attendibilità, alternative date e
compromesso si rivelano nel dettaglio. Il bookmark non duplica l'azione
primaria: la shortlist ha una singola metafora e uno stato chiaro. Lo stato
persistente in basso dice quanti elementi sono tenuti, quanti ne servono per il
confronto e rende abilitata la CTA solo da due elementi; non copre l'ultima
proposta nella lista.

### Dettaglio e trust

Il dettaglio è una Material bottom sheet o pagina temporanea, non una card
annidata. Presenta la migliore combinazione, alternative, assunzioni di costo,
ragioni, compromesso e attendibilità con linguaggio normale. Prezzi, durata e
collegamenti mock sono dichiarati come stime; nessun controllo suggerisce che
sia avvenuta una prenotazione. La scelta diretta di una proposta è permessa
soltanto dopo che la persona ha visto abbastanza contesto o ha lasciato
volontariamente il confronto.

### Confronto

Il confronto conserva da due a quattro alternative. In alto, una strip
compatta e nominata mantiene le candidate riconoscibili. Il primo blocco
rispecchia l'ordinamento attivo nella lista; costo, date, arrivo, contenuto e
compromessi seguono come sezioni richiudibili. Ogni sezione mostra un valore
per proposta, evidenzia con testo oltre che colore il miglior valore e non
ripete descrizioni lunghe quando il dettaglio le contiene già.

La CTA **Scegli [proposta]** arriva dopo il confronto ma il back ritorna allo
stesso confronto e la scelta è ancora una bozza. La conferma finale chiarisce
che non salva un viaggio nel Lab, conserva le alternative e permette di
chiudere senza effetto persistente.

## Design system e rollout app-wide

Il design system mantiene **Atlante personale**: canvas daylight freddo,
superfici bianche, testo grafite e azioni petrolio in chiaro; near-black petrol
con ruoli distinti in scuro. Vermilion segnala una decisione impegnativa o la
route line, mint un esito positivo. I colori arrivano da `ColorScheme` e dalla
theme extension esistente: `primary`, `surface`, contenitori, `outline`,
`secondaryContainer`, `tertiary` e `error`. Componenti non usano raw hex,
black/white ad hoc o ombre non semantiche.

La scala adotta ruoli `TextTheme` Material: display/headline per la domanda,
title per sezioni e destinazioni, body per evidenza, label per controlli. Il
layout usa griglia da 4/8 dp, corner radius fino a 14 dp per superfici primarie
e target di 48 dp. La stessa grammatica bottoni resta ovunque: filled per un
impegno significativo, tonal/outlined per alternative, text per azioni a basso
rischio.

Dopo il primo batch Nuovo viaggio, l'adozione procede per superfici:

1. **Home:** una CTA di ingresso, un viaggio in corso e disponibilità senza
   wall di dashboard; il launcher dell'esperimento non è utente-facing.
2. **Scopri e curation:** media verticale come contenuto, controlli laterali
   etichettati e alternative tap equivalenti allo swipe.
3. **Viaggi:** archivio personale editoriale con stato leggibile, non lista
   tecnica.
4. **Profilo e disponibilità:** preferenze correggibili, tema esplicito
   Chiaro/Scuro e spiegazioni di privacy/permessi contestuali.
5. **Trasporto, soggiorno, itinerario:** una scelta primaria alla volta,
   stime oneste, mappa supplementare a una lista/timeline completa e patch AI
   visibili, reversibili e locali.

Ogni superficie adotta il sistema solo quando i suoi contenuti e i suoi stati
sono pronti; non viene ridisegnata per somigliare artificialmente al Lab.

## Accessibilità, responsive e motion

- Tutti i target interattivi misurano almeno 48×48 dp, con 8 dp minimi tra
  controlli adiacenti; i controlli icon-only hanno tooltip e label descrittiva.
- L'ordine Semantics segue domanda, scelta, stato e CTA; aggiornamenti di
  progresso, validazione, shortlist e ricerca sono annunciati senza duplicare
  il contenuto visivo.
- Emoji e immagini decorative sono escluse dalla semantica; immagini
  informative hanno una descrizione utile. Stato, selezione, attendibilità e
  miglior valore non dipendono dal solo colore.
- Il layout è provato a 360 dp, 390 dp, 320×640 con testo 1.5, device grande e
  testo di sistema massimo. Footer fissi rispettano safe area, tastiera e
  scroll inset; nessun contenuto termina dietro la CTA.
- Chiaro e scuro sono schemi progettati separatamente con contrasto AA: testo
  principale almeno 4.5:1, testo secondario almeno 3:1 e bordi/stati
  distinguibili in entrambi.
- `disableAnimations` e preferenze di riduzione movimento governano tutte le
  transizioni, incluse sheet, cambio di domanda, feedback selezione e loader.

## Errori, empty state e trust

L'errore non cancella il lavoro della persona. Fallimento dell'origine apre
subito l'inserimento manuale e spiega come riprovare; campi e date evidenziano
il vincolo vicino alla sua fonte. I limiti della selezione (es. massimo tre
priorità o quattro proposte) sono dichiarati prima che l'azione sia bloccata.

Quando nessuna combinazione è abbastanza buona, Iter propone una sola modifica
reversibile alla volta, spiega quale vincolo cambia e permette di esplorare
l'alternativa successiva. Non presenta una pagina vuota, non modifica i
vincoli silenziosamente e non attribuisce decisioni a un modello opaco.

Per costi, itinerari e collegamenti, la UI dice cosa è stima, quando un dato
può cambiare e quale scelta resta in mano alla persona. Il Lab ribadisce al
termine che la bozza non è stata salvata. Provider, booking, pagamento e
scritture nello store richiedono una successiva integrazione con consenso
esplicito e un proprio design/trust review.

## Migrazione per fasi

### Fase 1 — Nuovo viaggio Semplice

Rimuovere le shell concorrenti dalla superficie Lab, rendere Semplice
l'ingresso diretto quando il Lab è attivo e allineare intake, responsive
policy, progresso e semantica. Conservare il contratto di
controller/modelli/proposal source, l'isolamento del Lab e il percorso delle
build senza Lab.

### Fase 2 — Risultati e confronto Semplice

Ridurre la densità della lista, eliminare azioni duplicate, introdurre
shortlist-first e confronto gerarchico. Mantenere tutti i dati attuali, ma
spostarli al livello di disclosure appropriato e confermare il ritorno/back
dopo la selezione.

### Fase 3 — Consolidamento design system

Estrarre e applicare in modo coerente ruoli colore, tipografia, spacing,
forme, bottoni, pill informative, empty/error panels e motion policy. Le
superfici non definiscono palette o vocabolari di componenti propri.

### Fase 4 — Rollout delle superfici esistenti

Applicare il linguaggio Semplice per batch a Home, Scopri/curation, Viaggi,
Profilo/disponibilità e ai flussi di trasporto, soggiorno e itinerario. Ogni
batch preserva i comportamenti fuori scope e viene verificato prima del batch
successivo.

### Fase 5 — Integrazioni reali separate

Solo dopo che il linguaggio UI e i confini del Lab sono stabili, progettare il
passaggio a store, persistenza e provider reali. Questo lavoro stabilisce
contratti, consenso, error handling, privacy e stati di caricamento propri;
non è una conseguenza automatica della migrazione visiva.

## Ownership team

| Area | Owner | Responsabilità |
| --- | --- | --- |
| Direzione, requisiti, copy, flussi, accessibilità e questa specifica | `product_ux` | Mantiene il contratto Semplice e blocca espansioni di scope. |
| Widget Flutter, tema, controller binding, modelli e test | `flutter_engineer` | Implementa le superfici senza alterare il dominio nel primo batch. |
| Android, permessi, system back, inset e plugin | `platform_engineer` | Verifica le garanzie native quando il batch le tocca. |
| Review indipendente, browser QA, build e regressione | `quality_reviewer` | Restituisce finding senza correggere i file del proprietario. |
| Comandi o edit meccanici completamente specificati | `worker` | Opera su percorsi disgiunti e non sceglie direzione prodotto. |

L'orchestratore conserva la decisione tra batch, l'integrazione e ogni
ambiguità trasversale. Un file ha un solo writer attivo; documentazione e codice
cambiano insieme quando una decisione modifica il prodotto.

## Acceptance criteria e verification

La migrazione è accettabile quando:

- con il Lab attivo la Home apre direttamente Semplice e non espone Focus/Rotta;
  senza Lab il percorso prodotto resta invariato fino all'integrazione reale;
- l'intake mantiene una domanda per volta, date tipizzate, origine editabile,
  conferme contestuali, progresso sotto le opzioni e fallback a una colonna a
  360 dp o testo grande;
- risultati, shortlist e confronto rendono visibili prezzo, periodo, ragione,
  trade-off e stato di scelta senza una card wall, azioni duplicate o un
  confronto che richiede memoria di schermate precedenti;
- nessuna scelta nel Lab scrive in `IterStore`, prenota, paga o chiama provider
  reale;
- light/dark, semantics, system back, target 48 dp, safe area, testo grande e
  riduzione movimento soddisfano i criteri descritti in questa specifica;
- il no-result e gli errori origine/dati spiegano il problema, preservano le
  scelte e offrono una via di recupero concreta;
- copy e stati comunicano sempre che prezzi e proposte sono stime e che la
  selezione finale Lab non salva un viaggio.

Per ogni batch UI, la verifica minima include `flutter analyze`, `flutter test`,
Browser integrato su `http://127.0.0.1:7357` con controllo di chiaro/scuro,
360 dp, testo grande, ordine semantico e reduced motion, poi `flutter build web
--release`. Il gate Android aggiunge `flutter build apk --debug` e QA nativa
mirata quando il batch interessa back, inset, permessi, gesture, lifecycle o
rendering. Ogni diff passa `git diff --check`; nessuna build Web finale compete
con il server del harness attivo.
