# Iter — Product brief

## Stato canonico

Questo checkout descrive la versione nuova e unica di Iter. L'app parte da
`lib/main.dart`, costruisce `ChatFirstPrototypeApp` e non sceglie più tra una
vecchia app e un prototipo tramite feature flag. I documenti storici del Lab e
della vecchia UI restano consultabili solo come archivio.

Branch di lavoro: `codex/iter-new-only`.

## Scopo

Iter è un'app Flutter per persone italiane che vogliono costruire un viaggio dal
telefono, anche partendo solo da una sensazione o da pochi giorni liberi. L'AI
fa da regia e da editor: propone, spiega e prepara modifiche concrete; la
persona può sempre controllare e cambiare il piano senza passare dalla chat.

Iter non è un questionario tecnico e non è un chatbot isolato.

## Principi di prodotto

- Una decisione importante alla volta, con copy breve e comprensibile.
- Il piano è un oggetto visibile e modificabile, non il risultato nascosto di
  una conversazione.
- Nessuna modifica materiale, acquisto o prenotazione avviene senza conferma.
- I dati demo sono dichiarati; un link esterno non equivale a un acquisto.
- Il tono è calmo, curioso e concreto: meno card, meno duplicazioni, più spazio
  a immagini, timeline e scelte.

## Architettura dell'esperienza

La navigazione principale è sempre una pillola flottante in basso con tre voci:

- **Oggi** — home adattiva e accesso rapido al desiderio di un nuovo viaggio;
- **Viaggi** — conversazioni e piani già creati, con **Nuova chat** in basso a
  destra;
- **Tu** — profilo leggero, disponibilità, statistiche e impostazioni.

Non esistono due percorsi separati per “piano” e “chat”. Il piano si apre dalla
conversazione quando serve, mentre le azioni principali del piano stanno nella
barra flottante inferiore.

## Flussi

### Home

La home mostra una domanda umana, un composer e segnali brevi. La superficie è
neutra e usa i ruoli del tema; il blocco principale non è una card blu estranea
al resto dell'app. Un invio esplicito crea o riapre una chat.

Quando esiste un viaggio in corso, la home mostra solo il giorno corrente, una
timeline breve e l'eventuale modifica in attesa. Il riepilogo è rapido: mostra
la modifica rilevante e usa **Vedi il piano completo** per il dettaglio.

### Chat

La chat mantiene una grammatica familiare, simile a WhatsApp, ma conserva
l'identità di Iter. Il thread mock può contenere:

- proposte di destinazione e luoghi con immagini;
- schede luogo con categoria, motivo, momento migliore e azioni;
- confronto di volo e hotel dentro la conversazione;
- riepilogo operativo e proposte **Accetta / Annulla**;
- testo, vocale, foto e video demo;
- composer ampio, multi-riga, con allegato a sinistra e invio/microfono a
  destra.

Il riepilogo di una modifica non duplica il piano: comunica cosa cambia e porta
al piano completo.

### Piano operativo

Il piano non usa una mappa in cima. Usa una hero fotografica/video, fatti
essenziali, chip dei giorni e una timeline continua. Ogni tappa apribile mostra
una scheda con foto, eventuale reel, dettagli, **Indicazioni** (Google Maps o
launcher esterno) e **Chiedi a Iter**.

La barra inferiore contiene:

- **Aggiungi luogo** — catalogo locale e inserimento manuale;
- **Chiedi** — ritorno alla conversazione;
- **Costi** — riepilogo e conferma demo.

Le azioni rare stanno nel menu overflow, inclusa **Importa ispirazione**. Ogni
aggiunta, spostamento, cambio orario, blocco o rimozione genera prima una
preview. Solo **Applica** crea una revisione; la snackbar offre **Annulla**.

### Costi e conferma

Il foglio costi è lineare e ha tre sezioni:

1. **Da acquistare** — volo e hotel selezionati;
2. **Stime non acquistate** — ingressi, pasti e trasporto locale;
3. **Totali** — costo esterno, stime sul posto e totale previsto.

**Conferma acquisti demo** apre un dialog esplicito. Dopo la conferma il piano
mostra **Scelte confermate**. Il percorso è locale e non raccoglie carta, PNR o
denaro: il copy **Demo: nessun pagamento reale** è sempre visibile. I link a
provider allowlistati restano opzionali e separati dal CTA demo.

### Profilo

Il profilo usa poche sezioni, non una pila di card:

- header essenziale e qualche preferenza appresa in chip;
- tre statistiche semplici: viaggi, luoghi, chilometri stimati;
- tema Chiaro/Scuro/Sistema;
- disponibilità con giorno, stato **Libero/Turno**, fascia e nota;
- collegamenti a FAQ, Privacy e conversazioni.

La disponibilità è un input mock locale: serve a proporre viaggi nel tempo
libero, non importa calendari o documenti.

### Ispirazioni da Reel/TikTok

Da chat o overflow del piano si può incollare un link Reel/TikTok. Il mock
parser usa solo fixture locali approvate:

- Instagram Porto → Livraria Lello;
- TikTok Roma → Foro Romano.

Il flusso è: estrai → scegli il viaggio → salva in **Ispirazioni salvate** →
**Proponi integrazione**. Il salvataggio non tocca il piano. La proposta arriva
in chat e modifica la timeline solo dopo **Accetta**. Non è ancora una Share
Target Android e non fa scraping o rete.

## Fiducia e confini

- La modalità predefinita è mock, deterministica e locale.
- Supabase è un seam opzionale per profilo, conversazioni e revisioni; non
  cambia il contratto UI e non espone segreti nel client.
- Nessun provider di viaggio, pagamento, GPS, calendario o AI remoto è
  necessario per provare questi flussi.
- Le selezioni e le revisioni restano osservabili nel controller.
- I luoghi bloccati e le scelte acquistate non vengono alterati in silenzio.
- Il testo deve restare comprensibile con tema scuro, testo grande, moto ridotto
  e larghezze compatte.

## Fuori scope di questo branch

Checkout reale, prenotazioni in-app, prezzi live, disponibilità live, GPS in
background, import automatico di turni, Share Target Android, scraping social,
collaborazione e feed social. Sono estensioni future, non promesse del mock.

## Verifica di accettazione

Ogni modifica applicativa deve mantenere:

```bash
flutter analyze
flutter test
```

Per UI/responsive:

```bash
flutter build web --release
python3 -m http.server 7357 --directory build/web --bind 127.0.0.1
```

Provare almeno 320/360/390 dp, tema chiaro/scuro, testo 1.5 e riduzione del
movimento. Il piano deve restare usabile senza aprire la chat.
