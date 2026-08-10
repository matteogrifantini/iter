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
   agente -> Git owner` prima di delegare.

## Strumenti obbligatori (ogni agente)

Vale per l'orchestratore e per ogni subagent (specialisti, worker,
quality_reviewer):

- **codegraph**: se esiste `.codegraph/` alla radice, usare
  `codegraph explore "<simboli o domanda>"` prima di grep/find/letture estese,
  e per individuare call path e blast radius. Grep/Read diretti restano ammessi
  solo per conferme puntuali o quando codegraph non copre il caso.
- **rtk**: proxy CLI per output compatti; usare i sottocomandi espliciti al posto
  dei comandi nudi per ogni operazione che supporta. Rilevanti qui:
  - Git: `rtk git status`, `rtk git log`, `rtk git diff`, `rtk git show`,
    `rtk git stash list`;
  - File/ricerca: `rtk ls`, `rtk find`, `rtk tree`, `rtk grep`, `rtk rg`,
    `rtk read <file>` (al posto di `cat`/`head`/`tail`), `rtk wc`, `rtk diff`,
    `rtk smart <file>` (riassunto firme);
  - Test/build/lint: `rtk test`, `rtk err`, `rtk summary` (per runner supportati:
    jest, vitest, pytest, go test, cargo test, tsc, ruff, eslint, dotnet);
  - Altri proxy disponibili quando servono: `gh`, `docker`, `kubectl`, `psql`,
    `curl`, `aws`, `wc`, `pnpm`.
  Flag utili: `--ultra-compact`, `-v`/`-vv`/`-vvv`. Codice, comandi Flutter,
  `flutter analyze`/`flutter test`/`flutter build ...` e output verbatim restano
  invariati.
- **caveman**: i report di rientro (sintesi, file, evidenze, rischi) usano lo
  stile compresso caveman: frasi minime, niente filler, termini tecnici e comandi
  verbatim. Codice, commit e messaggi di errore restano invariati. Niente
  annuncio dello stile e niente riepiloghi ridondanti.
- In caso di conflitto tra queste regole e istruzioni più specifiche di un
  agente, valgono le più specifiche.

## Routing

| Lavoro | Owner |
| --- | --- |
| Implementazione, test, documentazione, ricerca o verifica delimitata | `worker` |
| Debugging difficile, refactor articolato o implementazione complessa delimitata | `worker-hard` |
| Giudizio su requisiti, flussi, copy, accessibilità o documenti prodotto | `product_ux` |
| Giudizio su Dart, widget, stato, modelli, tema o test Flutter | `flutter_engineer` |
| Giudizio su Android, permessi, plugin, tooling, media o integrazioni native | `platform_engineer` |
| Review indipendente, regressioni, build e QA UI | `quality_reviewer` |

Il routing è worker-first: ogni incarico parte da `worker`, salvo complessità o
necessità specialistica già evidenti. Solo l'orchestratore può passare il lavoro
a `worker-hard` o a uno specialista. L'orchestratore mantiene decisioni
trasversali, architettura, direzione UI/UX, scope e integrazione; nessun agente
secondario riceve questa autorità.

## Orchestrazione

- Struttura piatta: soltanto l'orchestratore crea e assegna agenti secondari.
- Massimo tre agenti secondari concorrenti, scelti fra worker, worker-hard e
  specialisti.
- `worker` è il default; `worker-hard` è l'escalation per complessità; gli
  specialisti sono l'escalation per giudizio di dominio.
- Gli agenti secondari non creano altri agenti e restituiscono all'orchestratore
  evidenze, rischi e blocchi quando serve un'escalation.
- Parallelizzare solo attività indipendenti con file disgiunti.
- Un file ha un solo writer; serializzare ogni file condiviso.
- Ogni delega indica file, risultato, vincoli, dipendenze e verifica.
- Gli specialisti comunicano direttamente solo per interfacce o blocchi
  concreti e riportano all'orchestratore ogni cambio di contratto.
- `quality_reviewer` non corregge il codice revisionato: restituisce finding
  all'agente proprietario.
- Ogni agente rientra con sintesi, file cambiati, evidenze e rischi residui;
  niente log estesi nel thread principale.

## Gate Git

Per ogni batch l'orchestratore nomina un solo **Git owner**. Può essere
l'orchestratore, uno specialista, `worker` o `worker-hard` solo quando riceve
esplicitamente Git e percorsi esatti. `quality_reviewer` non è Git owner dei
sorgenti revisionati.

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
