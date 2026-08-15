# Iter — Design system

## Direzione

Iter usa **Rotta viva**: un sistema di orientamento affettivo per costruire un
viaggio. La nuova UI rebuild rende questa idea visibile già nel primo viewport:
una scena della destinazione, una rotta leggibile e un composer che resta pronto
alla modifica. Non è una dashboard e non è una raccolta di card.

La modalità di lavoro è **Operate**: l'utente deve capire rapidamente cosa può
fare, cosa è solo una proposta e cosa è stato confermato.

## Superfici e navigazione

- Canvas semantico dal tema Iter, mai colori raw nei widget.
- Material 3 e safe area native.
- Contenuto centrato con larghezza massima 760 dp sulle finestre ampie.
- Bottom navigation flottante e compatta: **Oggi / Viaggi / Tu**.
- Una sola barra di azioni principali nel piano, ancorata in basso.
- Menu overflow solo per azioni rare.
- Sheet e dialog per attività brevi che richiedono focus protetto.

La navigazione non deve sembrare un sito ridotto su mobile e non deve offrire
percorsi duplicati per la stessa azione.

## Palette semantica

I token vivono in `lib/app/iter_theme.dart` e nei ruoli `ColorScheme` /
`IterColorRoles`.

| Ruolo | Light | Dark | Uso |
| --- | --- | --- | --- |
| Ink | `#18204B` | `#F9F7EF` | testo principale |
| Canvas | `#F9F7EF` | `#0B1028` | sfondo |
| Surface | `#FFFFFF` | `#141C3B` | contenuto |
| Raised | `#F0EEE6` | `#1D2750` | superfici secondarie |
| Rotta | `#2D63FF` | `#7EA0FF` | azione e stato attivo |
| Segnale | `#FF5C42` | `#FF7A63` | attenzione e decisione |
| Possibilità | `#E7FF67` | `#E7FF67` | nuovo segnale positivo |

La Home attiva usa una scena fotografica della destinazione come primo ancoraggio,
poi una timeline lineare e un composer flottante. La Home vuota usa il composer
come oggetto principale, non come campo dentro una card. Niente box blu imposto
fuori gerarchia, griglie di card, gradienti o ombre decorative.

Le superfici traslucide sono ammesse solo per chrome flottante e sheet, dove
separano un'azione dal canvas. Devono avere fallback opaco con trasparenza ridotta
e non possono essere impilate una sopra l'altra.

## Tipografia

- **Bricolage Grotesque** per wordmark, display e titoli decisivi.
- **Figtree** per corpo, controlli, chat e timeline.
- Copy in frase normale, senza maiuscole decorative.
- Body leggibile, line-height generosa e testi lunghi sempre scrollabili.
- Il testo di stato deve dire cosa succede: `Proposta pronta`, `Scelte
  confermate`, `Dati demo`.

## Piano operativo

La composizione è verticale:

1. hero immagine/video della destinazione;
2. fatti brevi;
3. chip dei giorni;
4. timeline fotografica/operativa;
5. contenuto `Da sistemare`;
6. barra flottante delle azioni.

Non mettere una mappa sopra il piano. La mappa o il link di navigazione è una
azione contestuale della scheda luogo. La scheda mostra immagine, reel, dettagli,
indicazioni e domanda a Iter senza perdere il contesto del piano.

Una tappa ha un'azione accessibile equivalente al drag: sposta, orario,
blocca/sblocca e rimuovi. La modifica passa sempre da preview → conferma →
revisione → snackbar Annulla.

## Chat

La bolla segue una grammatica familiare: ingresso a sinistra, risposta della
persona a destra, card solo quando rappresenta un contenuto azionabile reale.
Le schede di volo/hotel e i luoghi restano nel thread, non aprono una pagina
esterna per mostrare i dati mock.

Il composer è una bolla ampia multi-riga, simile a WhatsApp:

- allegato a sinistra;
- campo con almeno due righe visuali;
- invio o microfono a destra;
- safe area rispettata;
- feedback pressed e tooltip/semantics su ogni icona.

## Home e profilo

La home ha un solo invito principale. Un aggiornamento operativo è una riga
breve con una modifica concreta e **Vedi il piano completo**; non è un testo
lungo da confermare direttamente in poco spazio.

Il profilo evita la griglia di card ripetute. Usa titoli con icona vettoriale,
separatori hairline, statistiche compatte, chip per la memoria e `ListTile` per
FAQ/Privacy/conversazioni. Le emoji possono accompagnare un significato
editoriale, mai sostituire un'icona di navigazione o controllo.

## Ispirazioni

Il foglio Reel/TikTok è una progressione a tre stati:

1. incolla o usa un link demo;
2. guarda ciò che Iter ha estratto e scegli il viaggio;
3. salva, poi chiedi una proposta di integrazione.

La miniatura e i dati estratti sono locali. Lo stato `salvata` è distinto da
`applicata`: la timeline cambia solo dopo l'accettazione della `PlanProposal`.

## Costi

Il foglio costi è un documento lineare, non una schermata di checkout. Le tre
sezioni sono sempre leggibili con testo grande. Il CTA demo apre un dialog con
totale e disclaimer `Demo: nessun pagamento reale`; il successo diventa
`Scelte confermate`.

## Motion e stati

- 150–300 ms, ease-out, nessuna animazione infinita decorativa.
- Con moto ridotto: stato immediato o crossfade.
- Tutti i controlli hanno stato normale, pressed, disabled e feedback di errore.
- Le sheet scrollano; nessun testo o CTA è nascosto dietro la barra inferiore.
- Nessun loading finto o ragionamento AI simulato.

## Accessibilità e responsive

- Target interattivi minimi 48 dp e almeno 8 dp di spazio.
- Semantics per immagini, azioni, luoghi, stato di acquisto e aggiornamenti.
- Contrasto corpo almeno 4.5:1 in entrambi i temi.
- Test obbligatori a 320, 360 e 390 dp, text scale 1.5, dark mode e
  `disableAnimations`.
- Il piano mantiene sempre una rappresentazione testuale della timeline.
- Il back chiude prima tastiera, sheet o dialog e non perde il testo composto.

## File visuali principali

```text
lib/app/iter_theme.dart
lib/features/chat_first_prototype/chat_first_shell.dart
lib/features/chat_first_prototype/iter_ui_primitives.dart
lib/features/chat_first_prototype/chat_first_home_screen.dart
lib/features/chat_first_prototype/chat_first_thread_screen.dart
lib/features/chat_first_prototype/trip_snapshot_screen.dart
lib/features/chat_first_prototype/chat_first_profile_screen.dart
lib/features/chat_first_prototype/plan_cost_sheet.dart
```
