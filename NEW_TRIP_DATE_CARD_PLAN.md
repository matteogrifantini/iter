# Card “Quando puoi partire?”

> **Nota:** questo piano è stato integrato nel documento canonico
> [`NEW_TRIP_MASTER_PLAN.md`](NEW_TRIP_MASTER_PLAN.md). Il file corrente rimane
> disponibile come specifica focalizzata della card, aggiornata alla revisione
> Lab v2.

## Sintesi

La card è un mini-flusso che raccoglie una preferenza temporale completa senza mostrare insieme troppi controlli. Rimane una singola tappa del questionario e si conclude con una sintesi verificabile.

Vista iniziale:

- **Ho già le date** — partenza e ritorno precisi.
- **Ho più possibilità** — possibili giorni di partenza, anche separati.
- **Usa i miei giorni liberi** — attiva solo con disponibilità salvate.
- **Non lo so ancora** — ricerca indicativa nei prossimi mesi.

La transizione tra scelta e calendario usa uno scorrimento orizzontale Material; il campo chat non è presente.

## Comportamento delle modalità

### Date esatte

- Calendario inline per scegliere partenza e ritorno, anche tra mesi diversi.
- Mostrare immediatamente giorni e notti: `18–21 settembre · 3 notti`.
- Vietare solo date passate; il MVP assume almeno una notte.
- `Conferma date` completa la card.

### Più possibilità

- Copy: `In quali giorni potresti partire?`.
- Ogni giorno selezionato è una possibile partenza valida anche isolatamente; consentire date e intervalli disgiunti.
- Chiedere separatamente la durata con preset `1–2`, `3–4`, `5–7`, `8+`, `Indifferente` e intervallo personalizzato.
- Non raggruppare queste date in finestre consecutive e non imporre una durata predefinita.
- Mostrare il risultato prima della conferma: `5 partenze possibili · 3–5 giorni`.

### Giorni liberi salvati

- Senza giorni disponibili, la riga rimane grigia e semanticamente disabilitata, con testo: `Aggiungi almeno un giorno nella scatola Giorni liberi per sbloccare questa scelta`.
- Con disponibilità presenti, mostrare il calendario già evidenziato e le finestre consecutive ricavate.
- Permettere di escludere una finestra dal viaggio senza modificare i dati globali.
- Chiedere la durata desiderata come nella modalità flessibile.
- Alla conferma salvare nel viaggio una fotografia delle disponibilità usate; modifiche future ai giorni liberi non cambiano silenziosamente la ricerca. Un’azione esplicita permetterà di aggiornarla.

### Non lo so ancora

- L’orizzonte temporale è facoltativo: 3, 6 o 12 mesi.
- Senza selezione, usare e dichiarare i prossimi 12 mesi.
- Chiedere comunque una durata indicativa; consentire `Non so neanche questo`, equivalente a più durate standard.
- La card produce range mensili o stagionali, mai un prezzo puntuale presentato come certo.

## UI e stato prodotto

- In alto: progresso generale e indicazione `Quando`; eventuali sotto-passaggi mostrano `1 di 2`.
- Il tasto Indietro torna prima alla scelta delle quattro modalità e poi alla domanda precedente.
- Ogni interazione viene autosalvata nel draft; soltanto `Conferma` aggiorna la sintesi usata dalla ricerca.
- La barra “La tua ricerca” mostra:
  - `18–21 set · 3 notti`;
  - `5 partenze possibili · 3–5 giorni`;
  - `3 finestre dai giorni liberi`;
  - `Date aperte · entro 12 mesi`.
- Cambiare modalità è reversibile e non richiede dialoghi di conferma.
- Colore, tipografia, calendario e pulsanti seguono Material 3 e i ruoli semantici chiaro/scuro di Iter. Stato disabilitato ed errori non dipendono soltanto dal colore.

## Modello necessario

Sostituire la lista piatta `Trip.availableDates` con una preferenza tipizzata:

- modalità: esatta, disponibilità manuale, giorni liberi salvati, aperta;
- intervallo esatto opzionale;
- possibili date di partenza, separate dalle finestre di disponibilità;
- durata minima/massima opzionale;
- orizzonte di 3/6/12 mesi e indicazione se esplicito o predefinito;
- origine delle disponibilità e momento dello snapshot;
- stato incompleto/confermato.

I giorni liberi globali rimangono separati dal viaggio. Soltanto da questi si derivano finestre consecutive; le possibili partenze manuali restano date indipendenti e non vengono inserite come stringhe nelle risposte generiche.

## Verifica

- Selezione esatta nello stesso mese, tra mesi e tra anni.
- Date di partenza isolate e disgiunte valide senza requisiti di consecutività.
- Durata selezionata e modificata indipendentemente dalle possibili partenze.
- Durata incompatibile con le finestre consecutive dei giorni liberi.
- Giorni liberi assenti: riga grigia, testo esplicativo e semantica disabilitata.
- Giorni liberi presenti, esclusione di finestre e aggiornamento esplicito dello snapshot.
- `Non lo so` con orizzonte scelto e con default di 12 mesi.
- Ritorno indietro, cambio modalità, chiusura e ripresa del draft.
- Tema chiaro/scuro, font ingrandito, screen reader e Riduci movimento.

## Assunzioni

- La specifica è implementata nel laboratorio UI v2; la migrazione del dominio `Trip` resta successiva alla scelta della variante.
- Il MVP considera viaggi con almeno una notte.
- Il calendario accetta date fino a 12 mesi nel futuro.
- Prezzi precisi saranno mostrati soltanto per finestre concrete; senza date verranno usati range chiaramente etichettati.
