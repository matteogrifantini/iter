# Iter Agentic Team Design

## Stato

Design approvato e poi esteso nella conversazione del 22 luglio 2026. Il
documento definisce la squadra di agenti Codex versionata nel repository; non
modifica il prodotto Flutter. Commit e push diventano azioni delegabili solo
attraverso il gate Git descritto sotto.

## Obiettivo

Creare un team gerarchico e operativo nel quale l'orchestratore conserva il
contesto complessivo, assegna aree e file, coordina specialisti capaci di
implementare e usa worker economici per lavoro routinario completamente
specificato.

La configurazione deve:

- vivere nella codebase e poter essere sottoposta a versionamento;
- riflettere i confini reali del progetto Iter;
- permettere comunicazione e delega annidata quando gli strumenti Codex della
  sessione la supportano;
- evitare scritture concorrenti sugli stessi file;
- mantenere indipendente la review finale;
- preservare le decisioni correnti su Flutter, Android e Nuovo viaggio.

## Non obiettivi

- Non creare un agente per ogni cartella o feature corrente.
- Non legare permanentemente il team alle tre shell temporanee del Lab.
- Non consentire ai worker di prendere decisioni di prodotto o architettura.
- Non introdurre dipendenze nell'app, servizi esterni o segreti.
- Non autorizzare force push, riscrittura della cronologia, merge, rebase, tag,
  release o pubblicazioni esterne attraverso il gate Git ordinario.
- Non garantire che un override scelto nella UI di Codex non prevalga sui
  default del repository.

## Architettura scelta

```text
orchestrator — gpt-5.6-sol / high
├── product_ux — gpt-5.6-terra / high
├── flutter_engineer — gpt-5.6-terra / high
├── platform_engineer — gpt-5.6-terra / high
├── quality_reviewer — gpt-5.6-terra / high / sorgenti read-only
└── worker — gpt-5.6-terra / low
```

`gpt-5.6-luna` non viene usato perché non è un identificatore disponibile
nell'ambiente Codex corrente. `gpt-5.6-terra` con effort `low` è il fallback
approvato per i worker terminali.

Il repository imposta i modelli come default. Le selezioni esplicite della
sessione e gli override runtime di Codex possono avere precedenza.

## Ruoli

### Orchestrator

Il thread principale usa idealmente `gpt-5.6-sol` con effort `high`. È l'unico
ruolo che:

- interpreta requisiti ambigui e prende decisioni trasversali;
- scompone il lavoro e sceglie fra profondità e parallelismo;
- assegna la proprietà temporanea di aree e file;
- risolve conflitti tra specialisti;
- integra i risultati e decide il gate finale;
- comunica all'utente esito, verifiche e rischi residui.

Prima della delega definisce per ogni incarico:

```text
owner -> file/area -> risultato -> dipendenze -> verifica -> worker disponibili
```

### product_ux

Specialista operativo di prodotto e UX. Possiede requisiti, flussi, UX copy,
accessibilità e sincronizzazione documentale. Legge `PRODUCT.md`, `DESIGN.md`
e, quando pertinente, `NEW_TRIP_MASTER_PLAN.md`.

Può modificare documentazione, specifiche, copy isolato e criteri di
accettazione assegnati. Non sceglie autonomamente la direzione visuale, la
shell vincitrice o un ampliamento dello scope. Le modifiche strutturali ai
widget appartengono a `flutter_engineer`.

### flutter_engineer

Specialista operativo Dart e Flutter. Possiede widget, stato, modelli, tema,
logica applicativa e test Flutter. Protegge in particolare i contratti tra:

- Lab temporaneo e store di produzione;
- controller condiviso e shell visuali;
- interazioni visibili e conferme esplicite dell'utente;
- UI mobile Android e harness Web usato per il QA.

Non modifica autonomamente permessi, configurazione Android, dipendenze native
o provider esterni: quando servono, concorda il contratto con
`platform_engineer` tramite l'orchestratore.

### platform_engineer

Specialista operativo di piattaforma. Possiede Android, manifest, permessi,
plugin, dipendenze, script di sviluppo, media, localizzazione e integrazioni
native. Mantiene Android come target prodotto e il Web come solo harness QA.

Non decide flussi, copy, persistenza o comportamento prodotto. Le modifiche al
codice Flutter di collegamento sono concordate con `flutter_engineer` e hanno
un solo proprietario di file alla volta.

### quality_reviewer

Specialista indipendente di review e verifica. Analizza diff, regressioni,
copertura, accessibilità e comportamento Flutter/Android. Può eseguire o
delegare:

- test mirati;
- `flutter analyze` e `flutter test`;
- build Web o Android proporzionate allo scope;
- QA interattivo nel Browser integrato;
- raccolta concisa di evidenze.

È read-only sui sorgenti e sulla documentazione revisionata. Può generare solo
cache e artefatti necessari ai test o alle build. Restituisce finding
prioritizzati all'orchestratore; le correzioni tornano allo specialista
proprietario.

### worker

Esecutore terminale su `gpt-5.6-terra` con effort `low`. Può essere creato
dall'orchestratore o da uno specialista per:

- ricerche puntuali nel repository;
- modifiche meccaniche di uno o pochi file;
- test, build e raccolta di output;
- sincronizzazioni documentali già determinate.

Ogni incarico deve specificare area o file, risultato atteso, vincoli e
verifica. Il worker non decide architettura, UX, prodotto, scope o azioni
distruttive e rientra appena completato con un resoconto breve.

## Topologia dinamica

Il limite scelto è tre thread secondari contemporanei oltre al principale.
L'orchestratore usa due forme:

### Profondità

```text
orchestrator + 1 specialista + fino a 2 worker
```

È la forma preferita per un incarico complesso concentrato in un dominio.

### Ampiezza

```text
orchestrator + 2 specialisti + 1 slot worker disponibile
```

È adatta a sottoproblemi indipendenti con aree di scrittura disgiunte. Lo slot
worker viene usato da un solo ramo alla volta.

L'orchestratore sceglie dinamicamente. Non avvia parallelismo quando esistono
dipendenze sequenziali o file condivisi.

## Routing del lavoro

| Tipo di lavoro | Proprietario | Supporto consentito |
| --- | --- | --- |
| Requisiti, flussi, copy, accessibilità, documenti prodotto | `product_ux` | Worker per audit e sincronizzazioni definite |
| Widget, stato, modelli, tema, test Dart/Flutter | `flutter_engineer` | Worker per edit circoscritti e test |
| Android, permessi, plugin, script, media, localizzazione nativa | `platform_engineer` | Worker per ricerca, configurazione e build |
| Review, regressioni, test, build e QA | `quality_reviewer` | Worker per esecuzione e raccolta evidenze |

Per un'attività trasversale, l'orchestratore definisce prima i contratti e poi
assegna sottotask indipendenti. Un esempio con permesso Android usa
`product_ux` per comportamento e stati, `platform_engineer` per il permesso,
`flutter_engineer` per UI e stato, quindi `quality_reviewer` per il gate.

## Comunicazione

- L'orchestratore resta il registro delle decisioni e della proprietà dei file.
- Gli specialisti possono comunicare direttamente quando la sessione espone i
  relativi strumenti e il destinatario è noto.
- La comunicazione diretta serve solo a chiarire contratti, dipendenze,
  sequenza di integrazione o blocchi concreti.
- Una decisione ambigua torna sempre all'orchestratore.
- Ogni decisione fra pari che cambia un contratto viene riportata anche
  all'orchestratore.
- Ogni agente restituisce sintesi, file cambiati, verifiche eseguite, finding e
  rischi residui; non riversa log estesi nel thread principale.

## Proprietà e conflitti

- Un file ha un solo agente in scrittura alla volta.
- Un'attività che richiede lo stesso file di un'altra viene serializzata.
- Un agente non sovrascrive modifiche preesistenti non assegnate.
- Se scopre lavoro fuori area, lo segnala senza includerlo automaticamente.
- Un worker bloccato torna al proprio specialista e non coinvolge da solo altri
  domini.
- Un finding di review torna allo specialista che possiede la correzione.

## File di progetto

```text
.codex/
├── config.toml
└── agents/
    ├── worker.toml
    ├── product_ux.toml
    ├── flutter_engineer.toml
    ├── platform_engineer.toml
    └── quality_reviewer.toml

agents/
├── README.md
├── worker.md
├── product_ux.md
├── flutter_engineer.md
├── platform_engineer.md
└── quality_reviewer.md
```

`.codex/config.toml` contiene i default dell'orchestratore, abilita gli agenti,
limita a tre i thread secondari e assegna ai subagent non specializzati il
default `gpt-5.6-terra` con effort `high`. Ogni file specialista fissa
esplicitamente `gpt-5.6-terra` e `high`; `worker.toml` fissa `low`.

`AGENTS.md` viene aggiornato con la matrice di routing, le regole di proprietà,
la delega annidata e l'indipendenza del reviewer. Le schede in `agents/` sono
la documentazione leggibile delle configurazioni eseguibili.

## Gate Git delegabile

Commit e push sono operazioni ammesse per il team dopo un controllo finale,
senza richiedere una nuova conferma per ogni incarico già compreso nello scope
assegnato. L'autorizzazione non è implicita per ogni agente attivo: per ciascun
batch l'orchestratore designa un solo **Git owner**, così i rami concorrenti non
creano commit sovrapposti.

Possono essere Git owner:

- l'orchestratore, per integrazioni o cambi trasversali;
- uno specialista, per un batch interamente dentro la sua area;
- un worker, soltanto quando il prompt del genitore gli assegna esplicitamente
  anche la proprietà Git e il genitore ha già definito file e verifica.

`quality_reviewer` non committa correzioni o sorgenti revisionati. Può fornire
il controllo finale che sblocca il Git owner.

Prima di creare il commit, il Git owner deve:

1. verificare branch, upstream, remote e `git status`;
2. controllare che nessun altro agente stia scrivendo sugli stessi file;
3. esaminare il diff e separare tutte le modifiche non possedute;
4. eseguire la verifica richiesta dallo scope e leggerne l'esito completo;
5. aggiungere allo staging soltanto percorsi espliciti di cui è proprietario;
6. eseguire `git diff --cached --check` e revisionare il diff staged;
7. usare un messaggio Conventional Commits conciso e coerente col repository;
8. immediatamente prima del push, eseguire `git fetch --prune <remote>` e
   confrontare l'upstream aggiornato. Con un upstream, controllare
   `git rev-list --left-right --count @{upstream}...HEAD`, la lista dei commit
   (`git log --oneline @{upstream}..HEAD`), diff e stat
   (`git diff @{upstream}..HEAD` e `git diff --stat @{upstream}..HEAD`), quindi
   confermare esplicitamente che ogni commit appartiene allo scope revisionato.
   Senza upstream, l'orchestratore deve fornire una base esplicitamente
   revisionata e il Git owner deve eseguire gli stessi controlli su
   `<base>..HEAD` prima di `git push -u`. Qualunque commit aggiuntivo o non
   posseduto blocca il push.

Il push è consentito sul branch corrente soltanto quando l'intero range
controllato è in scope e il branch non è `main` o un altro branch protetto. Se
manca l'upstream, il Git owner può impostarlo sul remote già configurato usando
lo stesso nome del branch corrente soltanto dopo il controllo della base
esplicitamente revisionata. Non può eseguire force push, `--force-with-lease`,
amend di commit altrui, merge, rebase, reset distruttivi, tag o release senza
una richiesta specifica ulteriore.

Se il branch remoto è avanzato, l'autenticazione fallisce, lo staging include
file non posseduti, la verifica non passa o il range uscente contiene un commit
aggiuntivo/non posseduto, il Git owner non forza la procedura: restituisce il
controllo all'orchestratore con l'evidenza del blocco.

## Gestione degli errori

- Configurazione non caricata: verificare che il repository sia trusted e
  aprire una nuova task Codex.
- Modello non disponibile: fermare la delega e riportare l'identificatore; non
  sostituirlo silenziosamente.
- Slot esauriti: attendere un agente esistente o ridurre il parallelismo.
- Diff sovrapposto: interrompere il secondo writer e riassegnare dopo
  l'integrazione del primo.
- Verifica fallita: riportare comando, prima causa utile e proprietario della
  correzione.
- Requisito ambiguo: proporre opzioni all'orchestratore senza implementare per
  ipotesi.

## Verifica della configurazione

L'implementazione viene verificata con:

1. parsing TOML di `.codex/config.toml` e di ogni agente;
2. controllo dei campi obbligatori `name`, `description` e
   `developer_instructions`;
3. controllo dei modelli e degli effort approvati;
4. confronto di coerenza tra TOML e schede `agents/*.md`;
5. controllo dei link e riferimenti in `AGENTS.md` e `agents/README.md`;
6. revisione del diff per escludere modifiche applicative;
7. smoke test eseguibile di caricamento in una nuova task Codex, con spawn e
   attesa sequenziali di tutti i ruoli.

Lo smoke test usa la sintassi CLI corrente:

```bash
codex exec --ephemeral --strict-config -C /Users/matteo/iter -s read-only --json -o .superpowers/sdd/new-task-smoke-last.txt 'Do not inspect the repository or run shell commands. Perform only this delegation smoke test. In this strict order, sequentially spawn product_ux with task_name="smoke_product_ux", flutter_engineer with task_name="smoke_flutter_engineer", platform_engineer with task_name="smoke_platform_engineer", quality_reviewer with task_name="smoke_quality_reviewer", and worker with task_name="smoke_worker". Every spawn MUST set fork_turns="none". Send only the respective child instruction: product_ux: "Do not use tools or make edits. Immediately reply exactly product_ux: loaded."; flutter_engineer: "Do not use tools or make edits. Immediately reply exactly flutter_engineer: loaded."; platform_engineer: "Do not use tools or make edits. Immediately reply exactly platform_engineer: loaded."; quality_reviewer: "Do not use tools or make edits. Immediately reply exactly quality_reviewer: loaded."; worker: "Do not use tools or make edits. Immediately reply exactly worker: loaded." Wait for that child to complete before the next spawn. If any spawn or wait errors, stop immediately and report the error explicitly; do not continue. Finish with exactly five separate lines and no other text: product_ux: loaded; flutter_engineer: loaded; platform_engineer: loaded; quality_reviewer: loaded; worker: loaded.' > .superpowers/sdd/new-task-smoke.jsonl
```

Il gate passa solo dopo l'ispezione della traccia strutturata della task: per
ogni ruolo deve esistere un evento `subAgentActivity` `started` con
`agentThreadId` non vuoto, ogni child deve completare con la propria risposta e
`git status --short` deve essere identico prima e dopo. Le cinque righe finali
del parent sono un riepilogo utile, ma non sono prova di spawn e non possono da
sole superare il gate.

Prova reale: la nuova task Codex
`019f8be2-e321-7882-b5e3-93b98c75f3f5`, turn
`019f8be2-e413-76e1-ab33-f0e763051317`, ha prodotto eventi `started` con ID
non vuoti per `product_ux` (`019f8be3-4c63-7ec2-b1c2-d48b99384563`),
`flutter_engineer` (`019f8be3-70be-7390-a4be-60f64fd69a6e`),
`platform_engineer` (`019f8be3-9750-7041-8ca6-ec89ad0e0ec4`),
`quality_reviewer` (`019f8be3-b807-7b41-9940-e3d946bb7236`) e `worker`
(`019f8be3-d6df-7960-b573-9988c4fd3350`). Tutti hanno completato con la
risposta del proprio ruolo e `git status --short` era identico prima e dopo.
La precedente attestazione basata solo sui cinque `rg -qx` dell'output v2 era
un falso positivo e non è evidenza di caricamento.

Non sono richiesti `flutter analyze`, test o build quando cambiano soltanto
configurazione e documentazione degli agenti.

## Criteri di accettazione

- Tutti e cinque gli agenti sono configurati e documentati nel repository.
- I default dei modelli corrispondono alla gerarchia approvata.
- Ogni specialista ha confini, divieti, output e regole di delega espliciti.
- Il reviewer non può correggere direttamente il codice revisionato.
- La topologia supporta profondità e ampiezza entro tre thread secondari.
- `AGENTS.md` rende obbligatori proprietà esclusiva dei file e handoff concisi.
- Commit e push rispettano il gate Git e non includono modifiche non possedute.
- Lo smoke test di una nuova task carica sequenzialmente tutti e cinque i ruoli
  senza superare la capacità configurata.
- La configurazione è TOML valido e pronta a essere caricata da una nuova task
  in un repository trusted.
