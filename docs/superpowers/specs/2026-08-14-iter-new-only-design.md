# Iter new-only — Specifica prodotto e UI

## Stato

Specifica approvata il 14 agosto 2026 per il branch `codex/iter-new-only`.
Il branch mantiene dati e provider mock deterministici. Non introduce pagamenti
reali, account di pagamento, Android Share Target o provider live.

## Obiettivo

Trasformare il prototipo chat-first nella sola applicazione avviata da Iter,
rimuovendo il percorso legacy e il codice che lo rende ancora raggiungibile.
La nuova app deve restare leggibile come prodotto di viaggio, non come chatbot:
la chat propone e spiega, mentre Home, Viaggi, Piano e Profilo restano superfici
autonome e modificabili.

## Principi vincolanti

- **Mock esplicito:** mete, voli, hotel, costi, disponibilità, statistiche,
  importazioni e conferme sono fixture locali; la UI dichiara quando un dato è
  dimostrativo.
- **Conferma delle conseguenze:** modifiche al piano e conferma costi mostrano
  prima l'effetto materiale e non applicano decisioni importanti in silenzio.
- **Una sola grammatica di azioni:** il CTA pieno è riservato alla decisione
  principale; alternative usano pulsanti tonali, outline o testo.
- **Material 3 e Rotta viva:** usare i ruoli del `ColorScheme`, la palette e la
  tipografia già definite in `DESIGN.md`; niente nuova palette parallela,
  gradienti, glassmorphism o ombre decorative.
- **Accessibilità:** target minimi di 48 dp, label semantiche in italiano,
  ordine leggibile, temi chiaro/scuro, testo grande, reduced motion e azioni
  equivalenti al gesto.
- **Isolamento dati:** il nuovo controller usa la propria sorgente mock e non
  scrive in `IterStore`. Un eventuale backend Supabase resta opzionale e non
  cambia il percorso mock predefinito.

## Architettura new-only

### Avvio

`lib/main.dart` avvia direttamente `ChatFirstPrototypeApp`. `AppConfig` conserva
soltanto le impostazioni necessarie al backend dati (`ITER_BACKEND`, URL e chiave
publishable Supabase); `ITER_CHAT_FIRST_PROTOTYPE` e `ITER_NEW_TRIP_LAB` non sono
più necessari per scegliere quale app avviare.

Il refactor deve rimuovere, dopo una verifica dell'import graph, il vecchio
percorso `IterApp`, `IterStore`, il suo shell a quattro tab, le vecchie schermate
di discovery/curation/trasporto/hotel/itinerario/profilo e i test dedicati solo
a quel percorso. Va preservato ogni asset, tema o modello ancora importato dal
nuovo prototipo. Il compat layer `TripSnapshotScreen(snapshot: ...)` viene
rimosso: il Piano riceve sempre controller e `conversationId`.

Il JSON storico dei piani rimane leggibile soltanto dove serve alla persistenza
del nuovo modello; la compatibilità dati non deve mantenere una seconda UI o un
secondo controller.

### Navigazione

La shell espone esattamente tre destinazioni:

- `Oggi`: Home adattiva;
- `Viaggi`: elenco delle conversazioni e dei piani;
- `Tu`: profilo e impostazioni leggere.

Su telefono la barra è una pillola flottante sopra la safe area. Su larghezze
ampie può diventare una rail Material, ma mantiene gli stessi tre elementi.
Non esistono tab separati per Piano e Chat: il Piano si apre dal thread e il
thread resta raggiungibile dal viaggio.

## Home e chat iniziale

### Home

La Home mantiene i tre stati adattivi esistenti: nessun viaggio, pianificazione
aperta e viaggio in corso. Il vecchio box blu viene sostituito da una superficie
neutra coerente con `surfaceContainerHighest` e con il tracciato Rotta viva.
Resta una sola azione dominante per stato; i collegamenti a Viaggi e Profilo
non vengono duplicati dentro card secondarie.

### Conversazione

La nuova chat iniziale mostra fixture rich dentro il flusso, senza navigare a
schermate estranee:

- proposta di una destinazione con immagini e motivazione;
- luoghi da visitare, con salvataggio/passaggio;
- confronto volo con durata, cambi e costo demo;
- confronto hotel con zona, notti e compromesso;
- proposta coordinata del piano, accettabile o annullabile.

Il riepilogo di una modifica mostra soltanto cosa cambia, quando e l'impatto
principale, con CTA `Vedi il piano completo`. Il composer del thread è
multilinea, alto come un composer di messaggistica mobile, con allegato a
sinistra e invio/microfono a destra.

## Piano operativo

Il Piano è la superficie canonica per leggere e modificare il viaggio anche
senza chat.

- Nessuna mappa in alto: hero fotografico/video della destinazione e timeline
  continua per giorno.
- Una tappa apre una scheda overlay con foto, reel, categoria, durata, nota di
  Iter, `Indicazioni` e `Chiedi a Iter`.
- `Indicazioni` costruisce il link Google Maps già previsto, senza SDK o chiavi
  nel client; il resto dei dati resta mock.
- `Aggiungi luogo` apre un picker con luoghi fixture e un inserimento manuale
  locale. L'utente sceglie giorno/orario oppure `Da sistemare`.
- Riordino tramite drag e tramite menu accessibile. Spostamento, orario,
  blocco/sblocco e rimozione passano da anteprima, conferma e snackbar `Annulla`.
- La barra inferiore flottante contiene solo `Aggiungi luogo`, `Chiedi` e
  `Costi`; azioni rare restano nell'overflow.
- Il Piano contiene una sezione `Ispirazioni salvate`, distinta dalle tappe
  confermate, con origine, estratto mock e azione per proporre l'integrazione.

## Costi e conferma mock

Il foglio costi usa tre sezioni lineari:

1. `Da acquistare`: volo e hotel selezionati;
2. `Stime non acquistate`: trasporti locali, ingressi e spese giornaliere;
3. `Totali`: totale selezionato e totale previsto.

La CTA `Conferma acquisti demo` apre un riepilogo finale delle scelte e, dopo
una conferma esplicita, marca il piano come `confermato` solo nella sessione
mock. Mostra sempre `Demo: nessun pagamento reale`. Non vengono raccolti carta,
PNR, ricevute o dati personali. Gli eventuali link esterni ai provider restano
facoltativi e non sono parte della conferma mock.

## Profilo, disponibilità e statistiche

Il Profilo viene distillato a una pagina ariosa composta da:

- intestazione breve e poche emoji/preferenze apprese;
- collegamenti semplici a `Aspetto`, `Disponibilità`, `FAQ` e `Privacy`;
- editor mock per aggiungere finestre libere o turni con giorno, fascia e nota;
- riepilogo statistiche: viaggi completati, luoghi visitati e chilometri
  stimati, calcolati dalle fixture locali.

Non si introducono import automatici da calendario, documenti o turni reali.
Le disponibilità servono a mostrare come Iter potrebbe proporre viaggi nel
tempo libero e restano modificabili e cancellabili.

## Importazione Reel/TikTok mock

Poiché il branch non integra Android Share Target, l'ingresso demo è un'azione
`Importa ispirazione` disponibile dalla chat e dal Piano. Un foglio consente di
incollare un URL o scegliere uno dei link demo Instagram/TikTok. Iter:

1. riconosce il tipo di contenuto tramite parser deterministico;
2. mostra titolo, luogo, momento e dati estratti mock;
3. chiede a quale viaggio associarlo;
4. salva il contenuto in `Ispirazioni salvate`;
5. propone in chat un cambiamento o un nuovo punto da inserire nel Piano.

Il contenuto non modifica il Piano finché l'utente non conferma la proposta.

## Documentazione e verifiche

La direzione implementata deve essere riflessa in `PRODUCT.md`, `DESIGN.md`,
`HANDOFF.md` e `README.md`; i riferimenti a flag e vecchia app devono sparire
dalla documentazione operativa. La verifica finale comprende:

- test unitari per modelli, stato mock, conferme, disponibilità e import;
- test widget per avvio new-only, navigazione a tre tab, chat, Piano, Profilo,
  costi e importazione;
- `flutter analyze`;
- `flutter test`;
- `flutter build web --release`;
- QA Browser su 320/360/390 dp, chiaro/scuro, testo 1.5 e reduced motion.

## Fuori scope

- pagamento reale o checkout interno;
- prezzi, disponibilità, recensioni o orari live;
- Android Share Target reale;
- import calendario/documenti;
- GPS, notifiche e provider AI reali;
- redesign del post-viaggio oltre le statistiche mock;
- modifiche a servizi o container esterni.
