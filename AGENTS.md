# Iter — Agent team

## Autorità

Questo file si applica all'intero repository. Le richieste dirette dell'utente
prevalgono; poi valgono queste regole e le istruzioni più vicine al file in
lavorazione.

Il thread principale è l'orchestratore: conserva il contesto, decide ciò che è
ambiguo, assegna proprietà e integra il risultato. Le configurazioni eseguibili
sono in `.codex/agents/`; le schede leggibili sono in `agents/`.

## Avvio di ogni incarico

1. Leggere `HANDOFF.md`.
2. Leggere `NEW_TRIP_MASTER_PLAN.md` se lo scope riguarda Nuovo viaggio.
3. Leggere `PRODUCT.md` e `DESIGN.md` prima di decisioni prodotto o UI.
4. Per refactor visuali, leggere integralmente
   `.agents/skills/impeccable/SKILL.md`.
5. Controllare `git status` e preservare tutte le modifiche preesistenti.
6. Definire `owner -> file/area -> risultato -> dipendenze -> verifica ->
   worker -> Git owner` prima di delegare.

## Strumenti obbligatori (ogni agente)

Vale per l'orchestratore e per ogni subagent (specialisti, worker,
quality_reviewer):

- **codegraph**: se esiste `.codegraph/` alla radice, usare
  `codegraph explore "<simboli o domanda>"` prima di grep/find/letture estese,
  e per individuare call path e blast radius. Grep/Read diretti restano ammessi
  solo per conferme puntuali o quando codegraph non copre il caso.
- **rtk**: proxy CLI per output compatti; usare i sottocomandi espliciti al posto
  dei comandi nudi per le operazioni che supporta (`rtk git ...`, `rtk grep ...`,
  `rtk read ...`, `rtk test ...`, `rtk diff ...`, `rtk log ...`). Codice, comandi
  Flutter e output verbatim restano invariati.
- **caveman**: i report di rientro (sintesi, file, evidenze, rischi) usano lo
  stile compresso caveman: frasi minime, niente filler, termini tecnici e comandi
  verbatim. Codice, commit e messaggi di errore restano invariati. Niente
  annuncio dello stile e niente riepiloghi ridondanti.
- In caso di conflitto tra queste regole e istruzioni più specifiche di un
  agente, valgono le più specifiche.

## Routing

| Lavoro | Owner |
| --- | --- |
| Requisiti, flussi, copy, accessibilità, documenti prodotto | `product_ux` |
| Dart, widget, stato, modelli, tema, test Flutter | `flutter_engineer` |
| Android, permessi, plugin, tooling, media, integrazioni native | `platform_engineer` |
| Review indipendente, test, build e QA UI | `quality_reviewer` |
| Ricerca, edit meccanico o comando completamente specificato | `worker` |

L'orchestratore mantiene decisioni trasversali, architettura, direzione UI/UX,
scope e integrazione. Non delega queste decisioni al `worker`.

## Orchestrazione

- Profondità: orchestratore + uno specialista + massimo due worker.
- Ampiezza: orchestratore + due specialisti + uno slot worker residuo.
- Parallelizzare solo attività indipendenti con file disgiunti.
- Un file ha un solo writer; serializzare ogni file condiviso.
- Ogni delega indica file, risultato, vincoli, dipendenze e verifica.
- Uno specialista può chiamare `worker` entro gli slot disponibili, ma resta
  responsabile di diff, verifica e handoff.
- Gli specialisti comunicano direttamente solo per interfacce o blocchi
  concreti e riportano all'orchestratore ogni cambio di contratto.
- `quality_reviewer` non corregge il codice revisionato: restituisce finding
  allo specialista proprietario.
- Ogni agente rientra con sintesi, file cambiati, evidenze e rischi residui;
  niente log estesi nel thread principale.

## Gate Git

Per ogni batch l'orchestratore nomina un solo **Git owner**. Può essere
l'orchestratore, uno specialista, oppure un `worker` solo quando il genitore gli
assegna esplicitamente Git e percorsi esatti. `quality_reviewer` non è Git owner
dei sorgenti revisionati.

Il Git owner può committare e pushare senza una nuova conferma soltanto dopo:

1. controllo di branch, upstream, remote e `git status`;
2. conferma che non esistano writer attivi sugli stessi file;
3. review del diff e verifica richiesta completata con successo;
4. staging di soli percorsi espliciti posseduti;
5. `git diff --cached --check` e review del diff staged;
6. commit Conventional Commits conciso;
7. ispezione del commit creato;
8. immediatamente prima del push, eseguire `git fetch --prune <remote>` e
   confrontare l'upstream aggiornato. Con un upstream, controllare
   `git rev-list --left-right --count @{upstream}...HEAD`, la lista dei commit
   (`git log --oneline @{upstream}..HEAD`), diff e stat
   (`git diff @{upstream}..HEAD` e `git diff --stat @{upstream}..HEAD`), quindi
   confermare esplicitamente che ogni commit appartiene allo scope revisionato;
   se manca l'upstream, l'orchestratore deve indicare una base esplicitamente
   revisionata e il Git owner deve eseguire gli stessi controlli su
   `<base>..HEAD` prima di `git push -u`. Fermarsi per qualunque commit
   aggiuntivo o non posseduto;
9. push del solo branch corrente non protetto.

Se il remote è avanzato, l'autenticazione fallisce, la verifica non passa, lo
staging contiene file non posseduti o il range uscente contiene un commit
aggiuntivo/non posseduto, fermarsi e tornare all'orchestratore. Mai force push,
`--force-with-lease`, amend di commit altrui, merge, rebase, reset distruttivi,
tag o release senza una richiesta specifica.

## Vincoli prodotto e implementazione

- Iter è Flutter mobile; Android è il target prodotto e Web è solo harness QA.
- Preferire dipendenze minime, mature e compatibili; non duplicare funzioni
  native o Flutter.
- L'app non diventa un chatbot puro o una dashboard SaaS.
- Nessun salvataggio, prenotazione, pagamento o modifica importante senza
  conferma esplicita dell'utente.
- Nessun segreto nel client.
- Nuovo viaggio Lab resta isolato da `IterStore` e provider reali fino ai gate
  documentati.
- Aggiornare documentazione e codice insieme quando cambia la direzione.

## Verifica

Per modifiche applicative, in proporzione allo scope:

```bash
flutter analyze
flutter test
```

Per modifiche UI, avviare `./tool/run_web.sh`, verificare nel Browser integrato
su `http://127.0.0.1:7357`, quindi eseguire:

```bash
flutter build web --release
```

Controllare tema chiaro/scuro, testo grande, ordine semantico e riduzione
movimento. Non aprire Chrome esterno e non avviare emulatori per il normale QA
UI.

Eseguire `flutter build apk --debug` e QA Android mirato soltanto per back,
inset, permessi, gesture, prestazioni, lifecycle, rendering nativo o gate finale
pre-release.

Per sole modifiche a configurazione e documentazione degli agenti: parsing TOML,
controllo riferimenti e `git diff --check`; non servono build Flutter.
