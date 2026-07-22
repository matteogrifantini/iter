# Iter — Worker-first agent team

**Data:** 2026-07-23
**Stato:** approvato per la specifica; implementazione dopo revisione utente

## Obiettivo

Ridurre il consumo del thread orchestratore `gpt-5.6-sol` senza perdere il
controllo sulle decisioni. Il flusso ordinario diventa piatto:

```text
orchestratore (Sol/high)
  ├─ worker (Terra/low)
  ├─ worker (Terra/low)
  └─ worker (Terra/low)
```

Il limite configurato di tre subthread esclude il thread principale: possono
quindi lavorare al massimo tre worker alla volta, soltanto su attività
indipendenti e con file disgiunti.

## Decisioni

### Orchestratore

L'orchestratore conserva contesto di prodotto, decisioni ambigue, definizione
di scope, assegnazione dei file, integrazione, review finale e Git gate. Non
esegue normalmente ricerca di repository, modifiche, test, build o
sincronizzazione documentale quando il lavoro è sufficientemente specifico da
assegnare a un worker.

Il lavoro diretto resta ammesso soltanto per:

- letture minime necessarie a inquadrare l'incarico;
- decisioni di prodotto, UX, architettura o sicurezza;
- integrazione e verifica finale;
- operazioni così piccole da non compensare il costo di avvio di un worker.

Prima di agire, l'orchestratore decide esplicitamente se il task è delegabile.
Per ogni task delegato indica file o area, risultato, vincoli, dipendenze,
verifica e Git owner.

### Worker pool

`worker` è il percorso predefinito per:

- ricerca puntuale nel repository;
- modifica meccanica e completamente specificata;
- test, build, raccolta log o verifica;
- aggiornamento documentale senza nuove decisioni;
- implementazione già progettata con percorsi e criteri espliciti.

Il worker usa `gpt-5.6-terra` con reasoning effort `low`. Il valore di default
dei subagent deve essere lo stesso, così anche gli spawn generici non riportano
il costo su `high`.

I worker non prendono decisioni di prodotto, UX, architettura, sicurezza o Git
scope. Non creano altri agenti. Rientrano con sintesi breve: file, verifica,
blocco o rischio residuo. Caveman può essere usato per comprimere un handoff,
ma non è obbligatorio.

### Specialisti conservati come fallback

Restano disponibili ed eseguibili `product_ux`, `flutter_engineer`,
`platform_engineer` e `quality_reviewer`, con le rispettive configurazioni
attuali. Non sono il routing predefinito e non vengono chiamati per lavori
routinari.

L'orchestratore li usa solo quando:

- l'utente richiede esplicitamente quel ruolo;
- un worker è bloccato da un'ambiguità che richiede giudizio specialistico;
- una review indipendente ad alto rischio è proporzionata allo scope.

Uno specialista fallback lavora direttamente sul proprio incarico e non può
creare worker: la gerarchia resta piatta e ogni slot resta visibile
all'orchestratore.

### Skill workflow

Superpowers non è una dipendenza del flusso ordinario né un requisito in
`AGENTS.md`. Può essere usato solo se l'utente lo richiede o se un task
richiede concretamente una delle sue procedure. Le skill restano istruzioni
del runtime, non routing permanente del repository.

I documenti storici dell'implementazione agentic-team saranno marcati
esplicitamente come superati per evitare che il loro requisito Superpowers
venga interpretato come istruzione corrente.

### Git e sicurezza

L'orchestratore è Git owner predefinito. Un worker può diventarlo solo con
assegnazione esplicita di percorsi e dopo il gate Git esistente. Gli
specialisti fallback seguono lo stesso gate quando nominati Git owner;
`quality_reviewer` resta read-only sui sorgenti revisionati.

## Modifiche previste

1. Aggiornare `.codex/config.toml`: subagent default Terra/low e tre worker
   concorrenti oltre all'orchestratore.
2. Riscrivere `AGENTS.md` con routing worker-first, trigger di delega chiari,
   fallback specialistico e skill opzionali.
3. Aggiornare `agents/README.md`, la scheda worker e le schede specialistiche
   per riflettere la gerarchia piatta.
4. Aggiornare le istruzioni TOML degli specialisti per vietare spawn annidati.
5. Marcare piano e specifica agentic-team del 2026-07-22 come storici e
   superati, senza cancellarli.

## Verifica

- parsing TOML e controllo dell'esatto set di ruoli;
- controllo che default e worker siano `gpt-5.6-terra`/`low`;
- controllo riferimenti e assenza di obblighi Superpowers nel contratto
  operativo;
- `git diff --check`;
- smoke test in un task Codex nuovo: tre worker `worker` avviati in parallelo,
  con ID child non vuoti e completamento osservato.

Non sono necessari build Flutter per sole modifiche a configurazione e
documentazione degli agenti.
