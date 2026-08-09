# Iter — Home adattiva e identità Rotta viva

## Stato della decisione

Questa specifica registra la direzione approvata il 9 agosto 2026 per il
prototipo chat-first di Iter. Sostituisce, per la Home e come futura direzione
identitaria dell'app, la Home a catalogo basata su città, hero fotografici e
caroselli di ispirazioni.

Sono state approvate tre decisioni:

1. Iter resta un'app di viaggio guidata dall'AI; non diventa una chat a schermo
   intero.
2. La Home è adattiva: cambia priorità tra nessun viaggio, pianificazione
   aperta e viaggio in corso.
3. Il mondo visivo è **Rotta viva**, nella composizione **Manifesto + input**.

La specifica è pronta per la revisione utente. Non autorizza ancora modifiche
al codice, provider reali, persistenza o rollout app-wide.

## Problema osservato

La Home corrente espone in ordine un ingresso “Parlane con Iter”, una grande
proposta di città o percorso, viaggi da riprendere e altre città suggerite.
Questa gerarchia comunica un catalogo travel personalizzato. Non rende
credibile la promessa centrale di Iter: partire da un desiderio ancora vago,
capire i vincoli e scegliere una proposta completa per la persona.

Le destinazioni occupano il centro prima che l'utente abbia espresso un
bisogno. Percentuali come “Ti somiglia 89%” simulano personalizzazione senza
mostrare quali elementi l'AI abbia compreso. Saluto, card orizzontali, hero
fotografico e navigazione neutra rendono inoltre la Home intercambiabile con
molte app travel esistenti.

Il redesign deve rendere visibile il meccanismo specifico di Iter anche senza
foto, città o claim sull'AI:

> Un desiderio incompleto diventa una rotta leggibile, una domanda alla volta,
> fino a una proposta di viaggio confermabile.

## Obiettivi

- Dare a Iter un'identità riconoscibile attraverso composizione, tipografia,
  colore, icone, emoji e movimento coerenti.
- Rendere l'input libero il centro della Home quando non esiste un viaggio
  attivo.
- Mostrare ciò che Iter ha capito come indizi espliciti, non come un punteggio
  opaco.
- Portare in primo piano una sola azione utile quando una pianificazione o un
  viaggio sono già in corso.
- Mantenere l'AI come regia dentro un'app di viaggio navigabile e modificabile.
- Conservare Material 3, comportamento Android, accessibilità e conferma
  esplicita delle modifiche importanti.

## Non-obiettivi

- Non trasformare la Home in una inbox o nell'ultimo thread aperto.
- Non mostrare città, trend o itinerari prima che Iter abbia compreso il
  desiderio e i vincoli minimi.
- Non introdurre feed, carousel di destinazioni, classifiche o percentuali di
  compatibilità prive di spiegazione.
- Non ridisegnare nello stesso batch chat, curation, trasporto, alloggio,
  itinerario e Profilo.
- Non collegare provider, GPS, notifiche, booking, pagamenti o persistenza
  reale.
- Non modificare il contratto mock e isolato del prototipo chat-first.
- Non usare la route line, le emoji o i colori come decorazione senza una
  funzione nello stato corrente.

## Direzione visiva: Rotta viva

### Tesi

La Home è un manifesto operativo: una domanda umana, un input libero e una
rotta che prende forma dagli indizi. Rifiuta sia il catalogo fotografico delle
app travel sia il transcript permanente dei chatbot.

Rotta viva deriva la propria identità dalla cartografia affettiva e dai sistemi
di orientamento: un tratto collega punti che acquistano significato durante il
percorso. Il segno non rappresenta una destinazione già decisa. Rappresenta il
passaggio da desiderio a direzione.

### Composizione approvata: Manifesto + input

Nel primo viewport senza viaggio:

1. wordmark Iter e accesso discreto alle conversazioni;
2. domanda dominante: **Che viaggio ti farebbe bene adesso?**;
3. promessa breve: **Raccontami il momento. Alla destinazione penso io.**;
4. composer scuro come unico centro d'azione, con testo, foto e voce;
5. massimo tre indizi rapidi basati su desiderio, disponibilità o budget;
6. route line che attraversa la composizione e conduce verso il contenuto
   successivo;
7. navigazione Material a tre destinazioni: **Oggi**, **Viaggi**, **Tu**.

La domanda e il composer hanno più peso di qualunque elemento da riprendere.
La rotta è ampia abbastanza da essere riconoscibile, ma non riduce lo spazio
utile né ostacola testo e touch target.

### Elementi del north-star da non copiare letteralmente

- Il testo di esempio non è contenuto precompilato inviabile per errore: è un
  hint o un esempio semanticamente distinto.
- Status bar, icone e navigazione della comp non sono asset finali: la build usa
  componenti Android e icone Material coerenti.
- La route line non viene rasterizzata. È un elemento SVG/CustomPainter o un
  equivalente semantico, adattivo e disattivabile con movimento ridotto.
- La dimensione del titolo segue `TextTheme` e scala di sistema; non viene
  fissata per riprodurre un'immagine.
- Le ombre profonde della comp non sono una nuova grammatica app-wide. Il
  contrasto tra pannello scuro e canvas basta a stabilire il livello.
- La comp definisce gerarchia e ritmo, non coordinate da tracciare.

## Sistema identitario

### Strategia colore

Rotta viva usa una **full palette controllata**: cinque ruoli riconoscibili,
non una collezione di accenti intercambiabili.

| Ruolo | Light | Uso |
| --- | --- | --- |
| Ink | `#18204B` | testo principale, composer, superfici decisive |
| Rotta | `#2D63FF` | azione primaria, stato attivo, route line |
| Segnale | `#FF5C42` | freccia, attenzione, decisione da confermare |
| Possibilità | `#E7FF67` | indizio nuovo, opportunità, progresso positivo |
| Canvas | `#F9F7EF` | sfondo principale minerale, non crema editoriale |

Vincoli di contrasto light:

- Ink su Canvas: `14.53:1`;
- Rotta su Canvas: `4.51:1`;
- bianco su Rotta: `4.84:1`;
- Ink su Segnale: `5.09:1`;
- Ink su Possibilità: `14.03:1`.

Il corallo non porta testo bianco normale, perché quella combinazione non
raggiunge il contrasto AA. Usa Ink oppure funge da segnale grafico.

Il tema scuro mantiene gli stessi ruoli, non inverte meccanicamente il light:

- canvas `#0B1028`;
- superficie `#141C3B`;
- rotta `#7EA0FF`;
- segnale `#FF7A63`;
- possibilità `#E7FF67`;
- testo principale `#F9F7EF`.

I token definitivi vivono in `ColorScheme` e in `IterColorRoles`. I widget non
possiedono raw color. Il colore occupa un campo intero o comunica uno stato;
non appare come una serie di piccoli accenti decorativi.

### Tipografia

- **Bricolage Grotesque**: wordmark, display, headline e domande decisive.
- **Figtree**: body, label, controlli, chat, risultati e itinerari.

Bricolage fornisce il carattere riconoscibile della Home con forme morbide ma
non infantili. Figtree mantiene alta leggibilità nelle superfici operative e
nei testi italiani più lunghi. Entrambi sono font variabili distribuiti da
Google Fonts sotto OFL.

Regole:

- Bricolage non entra nei body o nelle liste dense.
- Figtree resta il fallback operativo per testo grande e contenuti lunghi.
- Il titolo usa peso forte, line-height compatta e tracking negativo solo nei
  ruoli display.
- Label, pulsanti e copy usano sentence case; niente maiuscole decorative
  estese.
- I font sono inclusi come asset dell'app: nessun caricamento remoto runtime.

### Wordmark e glifo proprietario

Il wordmark resta **iter** in minuscolo, composto in Bricolage, con un piccolo
punto corallo come segnale di presenza. Non serve un logo illustrato separato
per la Home.

Il glifo proprietario è una rotta composta da:

- tratto continuo arrotondato;
- punto o waypoint;
- freccia di direzione.

Il glifo identifica avvio, progresso e passaggio da indizio a proposta. Non
sostituisce le icone standard di home, chat, microfono, foto, profilo o back.

### Icone

Le azioni usano icone Material rounded/outlined con tratto visivo equivalente
a circa `1.8 dp`, target minimo `48 dp` e label o tooltip. Questo conserva
familiarità Android. Solo il glifo della rotta è proprietario.

Le icone non vivono in tile decorative, non cambiano famiglia tra superfici e
non usano emoji al posto dei controlli strutturali.

### Emoji

Le emoji sono indizi emotivi e contestuali, sempre accompagnati da testo:

- `🌊 Voglio respirare`;
- `📅 Ho pochi giorni`;
- `💶 Ho 500 €`;
- `🐢 Voglio rallentare`.

Vivono in una superficie colorata coerente con il ruolo. Sono escluse dalla
semantica quando il testo adiacente esprime già il significato. Non compaiono
nel bottom navigation, nei pulsanti icon-only o come decorazione di titoli.

## Home adattiva

La Home deriva il proprio contenuto da uno stato di prodotto, non da una
preferenza visuale selezionabile.

### Stato 1 — Nessun viaggio

Obiettivo: iniziare da un desiderio.

- Il manifesto e il composer dominano il primo viewport.
- L'utente può inviare testo, voce o una foto mock.
- Gli indizi rapidi parlano di tempo, sensazione e budget.
- Non compaiono destinazioni o percentuali di affinità.
- Un contenuto recente può apparire sotto la prima piega, ma non compete con il
  composer.

### Stato 2 — Pianificazione aperta

Obiettivo: riprendere senza ricostruire il contesto.

- La Home mostra una sola decisione mancante, ad esempio **Quanto vuoi
  muoverti?**.
- Tre indizi sintetici ricordano ciò che Iter ha già compreso.
- **Continua il viaggio** è l'azione primaria.
- **Inizia un altro viaggio** resta disponibile come azione quieta.
- Non esiste un carousel di conversazioni: l'archivio completo è in Viaggi.

### Stato 3 — Viaggio in corso

Obiettivo: capire cosa serve oggi.

- La Home mostra viaggio, giorno e prossime tappe in una timeline breve.
- Un aggiornamento operativo può proporre un'alternativa, ma non applicarla.
- **Apri il piano di oggi** è l'azione primaria.
- Chat e composer restano raggiungibili senza sostituire la timeline.
- Nuovo viaggio e archivio sono secondari.

### Priorità quando esistono più elementi

1. viaggio attivo oggi;
2. pianificazione modificata o con decisione in sospeso;
3. bozza più recente;
4. ingresso a nuovo viaggio.

La Home non mostra più di un elemento da riprendere. Gli altri vivono in
**Viaggi**.

## Flusso dell'input AI

```text
Racconto libero
→ indizi compresi e modificabili
→ una domanda sul vincolo mancante
→ riepilogo esplicito
→ proposta completa
→ conferma utente
```

### Composer

Il composer accetta:

- testo libero;
- voce demo;
- foto/video demo secondo il contratto mock esistente.

Gli indizi rapidi precompilano o aggiungono contenuto al composer. Non avviano
una destinazione né creano una conversazione al semplice tap. Il primo invio
esplicito crea/apre il thread FreeTalk.

Il composer ha stati empty, focused, composing, submitting, failed e restored.
Durante submitting conserva il testo localmente e disabilita soltanto invii
duplicati. Foto e voce hanno sempre label accessibili e feedback visibile.

### Indizi compresi

Dopo il primo invio, Iter rende visibile ciò che ha compreso, ad esempio:

- `4 giorni`;
- `fine settembre`;
- `ritmo lento`;
- `cibo`;
- `500 €`.

Ogni indizio è modificabile o rimovibile. L'utente non deve dedurre quali
assunzioni abbiano guidato la proposta. Gli indizi sostituiscono punteggi di
affinità opachi.

### Domande e proposta

Iter chiede una sola informazione mancante alla volta e riusa lo script intake
esistente. Non mostra destinazioni prima di avere abbastanza contesto e prima
del riepilogo modificabile.

La proposta finale include una ragione concreta di compatibilità e un
compromesso. Scegliere o modificare una proposta richiede conferma esplicita.

## Componenti e responsabilità

| Componente | Responsabilità | Dipendenze |
| --- | --- | --- |
| `IterWordmark` | wordmark, punto segnale e variante light/dark | tema |
| `RouteGlyph` | marchio statico della rotta | colori semantici |
| `RouteTrace` | tratto adattivo che collega indizi/stati | reduced motion |
| `IntentComposer` | testo, voce, media, invio e recupero errore | controller FreeTalk |
| `IntentSeed` | aggiunge un indizio testuale al composer | nessuna destinazione |
| `UnderstoodSignal` | mostra e modifica un fatto compreso | intake controller |
| `NextDecisionPanel` | riprende una pianificazione dal prossimo vincolo | thread summary |
| `TodayRoute` | prossime tappe e contesto operativo | `TripSnapshot` read-only |
| `ProactiveUpdate` | proposta locale da accettare o rifiutare | `PlanProposal` |
| `HomeStateResolver` | sceglie stato e priorità della Home | thread e snapshot mock |

Ogni componente espone contenuto e azioni, non decide il dominio. Lo stato
della Home appartiene al controller/shell; colori e tipografia al tema.

## Dati e integrazione

Il primo batch opera sul branch e feature flag del prototipo chat-first:

- conserva `ITER_CHAT_FIRST_PROTOTYPE`;
- riusa `ChatFirstPrototypeController`, thread FreeTalk e intake condiviso;
- legge conversazioni e `TripSnapshot` senza scrivere in `IterStore`;
- usa media, messaggi e proposte deterministici/mock;
- non aggiunge provider o permessi reali.

La sequenza FreeTalk attuale va però corretta nel primo batch. Dopo l'eco del
desiderio non deve più offrire immediatamente le mete trend. Deve estrarre e
mostrare gli indizi compresi, chiedere il prossimo vincolo mancante e
convergere sull'intake condiviso. La destinazione arriva dopo il riepilogo e
nella proposta completa. Questa modifica riguarda controller, script/dati mock
e relativi test; non è un redesign completo del thread.

La shell conserva tre destinazioni e le route esistenti, ma ne riallinea la
presentazione al prodotto approvato:

- `Oggi` apre la Home adattiva;
- `Viaggi` apre l'attuale lista di conversazioni/viaggi;
- `Tu` apre il Profilo.

Non viene introdotto un nuovo router. L'icona conversazioni nella Home può
aprire la stessa lista di `Viaggi` come scorciatoia contestuale.

Lo stato adattivo minimo può essere derivato da:

```text
active trip today?       → viaggio in corso
pending planning thread? → pianificazione aperta
otherwise                → nessun viaggio
```

La logica di priorità deve essere una funzione pura e testabile. I widget non
filtrano o ordinano direttamente thread e viaggi.

## Fiducia, errori e stati vuoti

### Errore AI o rete

- Il testo rimane nel composer.
- L'errore appare vicino all'azione che lo ha prodotto.
- **Riprova** riusa lo stesso input senza creare un secondo thread.
- **Modifica** riapre l'input.
- La Home non sostituisce l'errore con destinazioni di fallback.

### Media non disponibile

Il composer mantiene testo e altri allegati validi. Spiega quale allegato non è
stato accettato e permette di rimuoverlo. Nessun permesso reale viene richiesto
nel prototipo mock.

### Dati incompleti o incoerenti

Iter evidenzia l'indizio interessato e formula una sola domanda di recupero.
Non corregge date, budget o compagnia silenziosamente.

### Viaggio attivo senza aggiornamenti

La Home mostra comunque la timeline essenziale e **Apri il piano di oggi**.
Non inventa alert, meteo o notifiche per riempire lo spazio.

## Motion

La route line comunica progresso:

- dopo il primo invio compare il primo waypoint;
- un nuovo indizio estende il tratto;
- la proposta completa conclude il tratto con la freccia.

Durata ordinaria: `180–260 ms`, ease-out, una sola trasformazione principale.
Non esistono loop, glow, typing fake o loader “AI”. Con
`disableAnimations/reduced motion`, il tratto appare nello stato finale tramite
crossfade o aggiornamento immediato.

## Responsive e accessibilità

- Target interattivi minimi `48×48 dp`, distanza minima `8 dp`.
- Layout verificato a `360 dp`, `390 dp` e larghezza Android compatta minima.
- Con testo grande, titolo, composer e indizi passano in flusso verticale; la
  route line non impone un'altezza fissa.
- La tastiera non copre input, errore o azione di invio.
- Semantics segue: contesto, domanda, composer, indizi, azione primaria,
  contenuto secondario, navigazione.
- Emoji decorative sono escluse; label e stato non dipendono dal colore.
- Il focus screen reader torna al nuovo indizio o alla domanda successiva dopo
  un aggiornamento.
- Tema chiaro e scuro sono entrambi first-class.
- System Back chiude media sheet/tastiera prima di uscire dal flusso e non
  perde il testo composto.

## Criteri di accettazione

### Identità

- La Home è riconoscibile come Rotta viva anche senza foto o destinazioni.
- Bricolage e Figtree sono asset locali e mappati tramite `TextTheme`.
- I cinque colori rispettano ruoli semantici e contrasto light/dark.
- Il glifo proprietario non sostituisce icone Android note.
- Emoji compaiono solo con una label testuale.

### Prodotto

- Senza viaggio, il composer è l'unica azione dominante.
- Nessuna città appare prima dell'input e del riepilogo.
- Con bozza o viaggio attivo, la Home mostra un solo prossimo passo.
- Non compaiono carousel di città o percentuali di affinità.
- Il primo invio converge sul FreeTalk e sull'intake condiviso.
- Il FreeTalk non propone mete trend prima del riepilogo confermato.
- Nessun tap su un indizio rapido crea da solo un viaggio o un thread.
- Proposte e modifiche importanti richiedono conferma.

### Resilienza

- Input e allegati validi sopravvivono a errore e retry.
- Retry non duplica thread o messaggi.
- Gli stati senza aggiornamenti non inventano contenuto.
- Reduced motion, testo grande, tema scuro, back e tastiera preservano il flusso.

### Verifica tecnica futura

Per il batch applicativo:

```bash
flutter analyze
flutter test
./tool/run_web.sh
flutter build web --release
```

Il Browser integrato verifica almeno:

- tre stati adattivi;
- primo invio FreeTalk e indizi compresi;
- `360 dp` e `390 dp`;
- testo grande;
- chiaro/scuro;
- reduced motion;
- errore con input preservato;
- ordine semantico e target;
- back e tastiera.

Il gate Android aggiunge `flutter build apk --debug` e QA mirata per system
Back, inset, IME, gesture e rendering dei font.

## Scope del primo batch

Il primo batch futuro comprende:

- aggiornamento di `PRODUCT.md` e sostituzione della direzione corrente in
  `DESIGN.md` con Rotta viva;
- font asset e tema;
- Home chat-first adattiva;
- componenti visuali necessari alla Home;
- correzione della sequenza FreeTalk e collegamento all'intake mock esistente;
- riallineamento delle tre label della shell a Oggi, Viaggi e Tu senza nuovo
  router;
- test widget/controller e QA UI descritti sopra.

Restano fuori:

- redesign completo del thread;
- rollout di Rotta viva su curation, trasporto, stay e itinerario;
- provider, store reale e persistenza;
- nuova gerarchia di navigazione o router app-wide;
- produzione di un feed Scopri sostitutivo.

## Rischi e mitigazioni

| Rischio | Mitigazione |
| --- | --- |
| Il titolo espressivo occupa troppo spazio | scala Material, max linee controllato, test testo grande |
| La route line diventa decorazione | ogni waypoint corrisponde a un indizio/stato reale |
| Palette percepita infantile | Ink dominante, lime limitato a possibilità, nessun arcobaleno di peer |
| Emoji incoerenti tra device | testo sempre presente, uso secondario, nessuna funzione icon-only |
| Home troppo simile a una chat | composer senza transcript, stato e piano restano superfici app |
| Stato adattivo imprevedibile | priorità pura, un solo elemento primario, test exhaustivo |
| Nuova identità resta isolata alla Home | `DESIGN.md` aggiornato prima del codice e rollout per batch successivi |

## Handoff verso il piano

Dopo l'approvazione di questa specifica, il piano di implementazione deve:

1. mappare le modifiche su tema, asset, Home, shell/controller e test;
2. preservare la modifica preesistente a `HANDOFF.md`;
3. assegnare un solo writer per file;
4. aggiornare documentazione e codice nello stesso batch;
5. richiedere review indipendente prima del commit applicativo;
6. fermarsi prima di provider, persistenza o rollout non approvati.
