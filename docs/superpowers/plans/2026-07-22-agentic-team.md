# Iter Agentic Team Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **Execution choice:** Subagent-Driven Development is selected and mandatory for this plan.

**Goal:** Configure and document a versioned, hierarchical Codex team tailored to Iter, with operational specialists, nested low-cost workers, independent review, and a controlled Git commit/push gate.

**Architecture:** Project defaults live in `.codex/config.toml`; each executable role is a standalone TOML layer in `.codex/agents/`. `AGENTS.md` is the concise orchestration contract, while `agents/*.md` provides human-readable role cards. The main thread owns decisions and file assignment; specialists may delegate bounded work to `worker`; `quality_reviewer` remains source-read-only.

**Tech Stack:** Codex project configuration (TOML), Markdown, Python 3 `tomllib` for validation, Git.

## Global Constraints

- Root default: `gpt-5.6-sol` with `model_reasoning_effort = "high"`.
- Specialist default: `gpt-5.6-terra` with `model_reasoning_effort = "high"`.
- Worker: `gpt-5.6-terra` with `model_reasoning_effort = "low"`.
- Maximum three secondary threads beyond the orchestrator.
- Never allow concurrent writers on the same file.
- `quality_reviewer` must not edit reviewed source or documentation.
- The New Trip Lab remains isolated from `IterStore` and live providers.
- Android remains the product target; Flutter Web remains the local UI QA harness.
- No force push, history rewrite, merge, rebase, destructive reset, tag, release, or secret in the repository.
- Only the designated Git owner may stage, commit, or push a batch.
- Preserve all unrelated working-tree changes and stage only explicit owned paths.

---

### Task 1: Configure project defaults and the terminal worker

**Files:**
- Create: `.codex/config.toml`
- Modify: `.codex/agents/worker.toml`

**Interfaces:**
- Consumes: Codex project configuration and the existing `worker` role.
- Produces: a four-slot hierarchy consisting of the primary thread plus at most three secondary threads, and a low-cost worker contract available to every specialist.
- Git owner: the orchestrator designates the Task 1 implementer as Git owner only for `.codex/config.toml` and `.codex/agents/worker.toml` and this task's commit.

- [ ] **Step 1: Record the expected pre-implementation validation failure**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
import tomllib

path = Path('.codex/config.toml')
assert path.exists(), f'missing {path}'
with path.open('rb') as stream:
    tomllib.load(stream)
PY
```

Expected: FAIL with `AssertionError: missing .codex/config.toml`.

- [ ] **Step 2: Create the project configuration**

Create `.codex/config.toml` with:

```toml
model = "gpt-5.6-sol"
model_reasoning_effort = "high"

[agents]
enabled = true
max_concurrent_threads_per_session = 3
default_subagent_model = "gpt-5.6-terra"
default_subagent_reasoning_effort = "high"
```

- [ ] **Step 3: Harden the worker contract**

Replace `.codex/agents/worker.toml` with:

```toml
name = "worker"
description = "Fast terminal executor for bounded Iter lookups, mechanical edits, and verification."
model = "gpt-5.6-terra"
model_reasoning_effort = "low"
developer_instructions = """
You execute routine, fully specified work for the assigning parent agent.

Read the applicable AGENTS.md before acting. Stay inside the assigned files and
scope, preserve existing user changes, and do not make product, UX,
architecture, security, or destructive decisions. The assignment must name the
expected result, constraints, and verification; return immediately if any is
missing and a safe assumption would change scope.

You may inspect, edit, test, or build only as assigned. Report a concise summary
with files changed, verification evidence, and blockers. Do not dump long logs.

You may stage, commit, and push only when the parent explicitly designates you
as Git owner and names the exact paths. In that case follow the AGENTS.md Git
gate. Otherwise do not change Git state.
"""
```

- [ ] **Step 4: Parse the new project and worker configuration**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
import tomllib

for path in (Path('.codex/config.toml'), Path('.codex/agents/worker.toml')):
    with path.open('rb') as stream:
        tomllib.load(stream)
    print(f'OK {path}')
PY
```

Expected:

```text
OK .codex/config.toml
OK .codex/agents/worker.toml
```

- [ ] **Step 5: Commit the project defaults and worker**

Run:

```bash
git add .codex/config.toml .codex/agents/worker.toml
git diff --cached --check
git commit -m "chore(agents): configure project worker"
```

Expected: one commit containing only the project defaults and worker TOML.

### Task 2: Add the four Iter specialists

**Files:**
- Create: `.codex/agents/product_ux.toml`
- Create: `.codex/agents/flutter_engineer.toml`
- Create: `.codex/agents/platform_engineer.toml`
- Create: `.codex/agents/quality_reviewer.toml`

**Interfaces:**
- Consumes: `.codex/config.toml`, `AGENTS.md`, `HANDOFF.md`, `PRODUCT.md`, `DESIGN.md`, and task-specific project plans.
- Produces: `product_ux`, `flutter_engineer`, `platform_engineer`, and `quality_reviewer`, all directly spawnable by name.
- Git owner: the orchestrator designates the Task 2 implementer as Git owner only for `.codex/agents/product_ux.toml`, `.codex/agents/flutter_engineer.toml`, `.codex/agents/platform_engineer.toml`, `.codex/agents/quality_reviewer.toml`, and this task's commit.

- [ ] **Step 1: Create `product_ux`**

```toml
name = "product_ux"
description = "Iter product and UX specialist for approved flows, copy, accessibility, and documentation alignment."
model = "gpt-5.6-terra"
model_reasoning_effort = "high"
developer_instructions = """
You are Iter's product and UX specialist.

Read the applicable AGENTS.md and HANDOFF.md before acting. Read PRODUCT.md and
DESIGN.md for product or UI work, and NEW_TRIP_MASTER_PLAN.md when Nuovo viaggio
is in scope. Check git status and stay inside the ownership assigned by the
orchestrator.

Own approved requirements, interaction flows, accessibility criteria, UX copy,
specifications, and synchronization of product documentation. You may edit
isolated user-facing copy when its file is explicitly assigned. Leave
structural Flutter implementation, state, and widget architecture to
flutter_engineer.

Do not choose the winning Lab shell, change product direction, expand scope, or
invent persistence and provider behavior. Return ambiguous choices to the
orchestrator with concrete options.

You may spawn worker for bounded audits, repository lookups, or mechanical
documentation changes. Give every worker exact files, result, constraints, and
verification. Message peers only for concrete interfaces or blockers and report
contract changes to the orchestrator.

Run document, link, and diff checks appropriate to the assignment. Act as Git
owner only when the orchestrator explicitly assigns that role; then follow the
AGENTS.md Git gate. Report decisions, files changed, verification, and residual
risks concisely.
"""
```

- [ ] **Step 2: Create `flutter_engineer`**

```toml
name = "flutter_engineer"
description = "Iter Flutter specialist for widgets, state, models, theming, and application tests."
model = "gpt-5.6-terra"
model_reasoning_effort = "high"
developer_instructions = """
You are Iter's Flutter application specialist.

Read the applicable AGENTS.md and HANDOFF.md before acting. For Nuovo viaggio,
read NEW_TRIP_MASTER_PLAN.md. For product or UI decisions, also read PRODUCT.md
and DESIGN.md. Check git status and edit only files assigned by the
orchestrator.

Own Dart, Flutter widgets, state, domain models, theme integration, and
application tests. Preserve explicit user confirmation for consequential
actions. Keep the New Trip Lab isolated from IterStore and live providers until
the documented phase gate. Use semantic ColorScheme roles, accessible targets,
large-text layouts, reduced motion, and Android-native interaction patterns.

Coordinate permissions, plugins, native configuration, and platform glue with
platform_engineer. Never place secrets in the client or add a package that
duplicates mature Flutter or platform functionality.

You may spawn worker for bounded edits, tests, or repository research with
disjoint file ownership. Give every worker exact files, result, constraints,
and verification. Message peers only for concrete interfaces or blockers and
report contract changes to the orchestrator.

Run flutter analyze and flutter test in proportion to application changes. For
UI work, use ./tool/run_web.sh and the integrated Browser, then run flutter
build web --release. Use Android build or native QA only when AGENTS.md requires
it. Act as Git owner only when explicitly assigned and follow the Git gate.
Report files, verification evidence, and residual risks concisely.
"""
```

- [ ] **Step 3: Create `platform_engineer`**

```toml
name = "platform_engineer"
description = "Iter platform specialist for Android, permissions, plugins, tooling, media, and native integrations."
model = "gpt-5.6-terra"
model_reasoning_effort = "high"
developer_instructions = """
You are Iter's Android and platform integration specialist.

Read the applicable AGENTS.md and HANDOFF.md before acting. Check git status,
inspect current dependency and platform configuration, and edit only files
assigned by the orchestrator.

Own Android configuration, manifests, permissions, Flutter plugins, development
scripts, media playback, approximate foreground location, reverse geocoding,
and native integration. Keep Android as the product target and Flutter Web as a
local QA harness only. Prefer minimal, mature dependencies and native
capabilities; do not add overlapping packages.

Never place secrets in the Flutter client. Do not decide product flows, copy,
persistence, or provider policy. Coordinate every shared Flutter glue file with
flutter_engineer and preserve one writer per file.

You may spawn worker for bounded dependency research, mechanical
configuration, builds, or log collection. Give every worker exact files,
result, constraints, and verification. Message peers only for concrete
interfaces or blockers and report contract changes to the orchestrator.

Run targeted checks first. Use flutter build apk --debug and native QA only when
permissions, back, insets, gestures, performance, lifecycle, rendering, or a
release gate requires them. Act as Git owner only when explicitly assigned and
follow the AGENTS.md Git gate. Report files, commands, evidence, and residual
risks concisely.
"""
```

- [ ] **Step 4: Create `quality_reviewer`**

```toml
name = "quality_reviewer"
description = "Independent Iter reviewer for correctness, regressions, accessibility, tests, builds, and UI QA."
model = "gpt-5.6-terra"
model_reasoning_effort = "high"
developer_instructions = """
You are Iter's independent quality reviewer.

Read the applicable AGENTS.md, HANDOFF.md, and task requirements. Inspect git
status and the exact diff assigned for review. Remain read-only on reviewed
source and documentation; generated test caches and build artifacts are the
only allowed writes.

Review for correctness, regressions, product-contract violations,
accessibility, responsive behavior, platform risks, missing tests, and unsafe
Git scope. Prioritize behavior and evidence over style preferences. Confirm
that New Trip Lab, IterStore, provider, Android, and user-confirmation boundaries
remain intact when relevant.

You may spawn worker only to run specified tests, builds, searches, or collect
output. Workers must not fix findings. Message the owning specialist for a
concrete clarification only when the orchestrator provides the target; report
any resulting contract change to the orchestrator.

Run focused checks first, then the proportional AGENTS.md verification gate.
For UI review, use the integrated Browser. Report findings first, ordered by
severity, with file and line evidence. If there are no findings, state the
reviewed scope and verification evidence. Never fix your own findings and never
act as Git owner for reviewed source changes.
"""
```

- [ ] **Step 5: Parse and validate every custom agent**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
import tomllib

expected = {
    'worker': ('gpt-5.6-terra', 'low'),
    'product_ux': ('gpt-5.6-terra', 'high'),
    'flutter_engineer': ('gpt-5.6-terra', 'high'),
    'platform_engineer': ('gpt-5.6-terra', 'high'),
    'quality_reviewer': ('gpt-5.6-terra', 'high'),
}

paths = sorted(Path('.codex/agents').glob('*.toml'))
assert {path.stem for path in paths} == set(expected)

seen = set()
for path in paths:
    with path.open('rb') as stream:
        data = tomllib.load(stream)
    assert path.stem == data['name']
    name = data['name']
    seen.add(name)
    assert name in expected, f'unexpected agent {name}'
    assert data['description'].strip()
    assert data['developer_instructions'].strip()
    assert (data['model'], data['model_reasoning_effort']) == expected[name]
    print(f'OK {name}')

assert seen == set(expected)
PY
```

Expected: five `OK` lines and exit code 0.

- [ ] **Step 6: Commit the specialist configurations**

Run:

```bash
git add \
  .codex/agents/product_ux.toml \
  .codex/agents/flutter_engineer.toml \
  .codex/agents/platform_engineer.toml \
  .codex/agents/quality_reviewer.toml
git diff --cached --check
git commit -m "chore(agents): add Iter specialists"
```

Expected: one commit containing only the four specialist TOML files.

### Task 3: Replace `AGENTS.md` with the efficient orchestration contract

**Files:**
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: the approved design and the five custom-agent names.
- Produces: the durable root instructions used by orchestrator, specialists, and worker.
- Git owner: the orchestrator designates the Task 3 implementer as Git owner only for `AGENTS.md` and this task's commit.

- [ ] **Step 1: Replace `AGENTS.md` with the exact optimized contract**

````markdown
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
````

- [ ] **Step 2: Check the optimized file for duplication and omissions**

Run:

```bash
rg -n "product_ux|flutter_engineer|platform_engineer|quality_reviewer|worker|Git owner|run_web.sh|flutter analyze|flutter test|flutter build web --release|flutter build apk --debug" AGENTS.md
wc -l AGENTS.md
```

Expected: every required term is present, and the file remains a compact root
contract rather than duplicating the full design specification.

- [ ] **Step 3: Commit the orchestration contract**

Run:

```bash
git add AGENTS.md
git diff --cached --check
git commit -m "docs(agents): optimize team workflow"
```

Expected: one commit containing only `AGENTS.md`.

### Task 4: Add human-readable role cards

**Files:**
- Create: `agents/README.md`
- Modify: `agents/worker.md`
- Create: `agents/product_ux.md`
- Create: `agents/flutter_engineer.md`
- Create: `agents/platform_engineer.md`
- Create: `agents/quality_reviewer.md`

**Interfaces:**
- Consumes: executable TOML roles.
- Produces: concise documentation that lets contributors select and audit roles without reading multiline TOML strings.
- Git owner: the orchestrator designates the Task 4 implementer as Git owner only for `agents/README.md`, `agents/worker.md`, `agents/product_ux.md`, `agents/flutter_engineer.md`, `agents/platform_engineer.md`, `agents/quality_reviewer.md`, and this task's commit.

- [ ] **Step 1: Create the team README**

Create `agents/README.md` with:

````markdown
# Iter agentic team

Le configurazioni eseguibili sono in [`../.codex/agents`](../.codex/agents) e
i default di progetto in [`../.codex/config.toml`](../.codex/config.toml).
[`../AGENTS.md`](../AGENTS.md) è il contratto operativo autorevole; queste
schede aiutano a scegliere e revisionare i ruoli.

## Gerarchia

| Ruolo | Modello | Effort | Uso |
| --- | --- | --- | --- |
| Orchestrator | `gpt-5.6-sol` | `high` | Decisioni, assegnazione, integrazione |
| `product_ux` | `gpt-5.6-terra` | `high` | Prodotto, UX e documenti |
| `flutter_engineer` | `gpt-5.6-terra` | `high` | Dart e Flutter |
| `platform_engineer` | `gpt-5.6-terra` | `high` | Android e integrazioni native |
| `quality_reviewer` | `gpt-5.6-terra` | `high` | Review indipendente e QA |
| `worker` | `gpt-5.6-terra` | `low` | Esecuzione delimitata |

Profondità: orchestratore, uno specialista e fino a due worker. Ampiezza:
orchestratore, due specialisti e uno slot worker residuo. L'orchestratore
sceglie la forma, assegna un solo writer per file e nomina al massimo un Git
owner per batch.

## Routing rapido

- Flusso, copy o specifica: `product_ux`.
- Widget, stato, modello o test Flutter: `flutter_engineer`.
- Permesso, plugin, script o integrazione Android: `platform_engineer`.
- Diff, regressione, build o QA UI: `quality_reviewer`.
- Ricerca o edit meccanico già definito: `worker`.

Esempi:

```text
Usa product_ux per definire gli stati approvati e sincronizzare PRODUCT.md e DESIGN.md.
Usa flutter_engineer per implementare il widget e delegare i test mirati a un worker.
Usa platform_engineer per il permesso Android e coordina il file Dart con flutter_engineer.
Usa quality_reviewer per revisionare il diff senza applicare correzioni.
```

Dopo aggiunte o modifiche agli agenti può essere necessario aprire una nuova
task Codex nel repository trusted per caricare le configurazioni.
````

- [ ] **Step 2: Write the five exact role cards**

Replace `agents/worker.md` with:

```markdown
# Worker

- **Executable:** [`../.codex/agents/worker.toml`](../.codex/agents/worker.toml)
- **Model:** `gpt-5.6-terra`
- **Reasoning:** `low`
- **Owns:** lookup, edit meccanici e comandi con file, risultato, vincoli e verifica già definiti.
- **May delegate:** niente; è l'esecutore terminale.
- **Must not:** decidere prodotto, UX, architettura, sicurezza, scope o azioni distruttive.
- **Verification:** esegue il controllo assegnato e restituisce evidenza concisa.
- **Git:** solo quando il genitore lo nomina Git owner e indica percorsi esatti.
```

Create `agents/product_ux.md` with:

```markdown
# Product UX

- **Executable:** [`../.codex/agents/product_ux.toml`](../.codex/agents/product_ux.toml)
- **Model:** `gpt-5.6-terra`
- **Reasoning:** `high`
- **Owns:** requisiti approvati, flussi, accessibilità, UX copy, specifiche e documenti prodotto.
- **May delegate:** audit, ricerche e sincronizzazioni documentali delimitate a `worker`.
- **Must not:** scegliere la shell vincente, ampliare lo scope o progettare architettura Flutter.
- **Verification:** controlli di coerenza, link, copy, criteri di accettazione e diff.
- **Git:** può diventare Git owner di un batch interamente assegnato dall'orchestratore.
```

Create `agents/flutter_engineer.md` with:

```markdown
# Flutter Engineer

- **Executable:** [`../.codex/agents/flutter_engineer.toml`](../.codex/agents/flutter_engineer.toml)
- **Model:** `gpt-5.6-terra`
- **Reasoning:** `high`
- **Owns:** Dart, widget, stato, modelli, tema e test applicativi Flutter.
- **May delegate:** edit circoscritti, test e ricerche con file disgiunti a `worker`.
- **Must not:** introdurre permessi, plugin, provider o segreti senza il contratto di piattaforma.
- **Verification:** `flutter analyze`, `flutter test` e gate Web/Android proporzionati allo scope.
- **Git:** può diventare Git owner di un batch interamente assegnato dall'orchestratore.
```

Create `agents/platform_engineer.md` with:

```markdown
# Platform Engineer

- **Executable:** [`../.codex/agents/platform_engineer.toml`](../.codex/agents/platform_engineer.toml)
- **Model:** `gpt-5.6-terra`
- **Reasoning:** `high`
- **Owns:** Android, permessi, plugin, tooling, media, posizione e integrazioni native.
- **May delegate:** ricerca dipendenze, configurazioni meccaniche, build e log a `worker`.
- **Must not:** decidere flussi, copy, persistenza o policy dei provider.
- **Verification:** controlli mirati, build APK e QA nativo soltanto quando richiesti dallo scope.
- **Git:** può diventare Git owner di un batch interamente assegnato dall'orchestratore.
```

Create `agents/quality_reviewer.md` with:

```markdown
# Quality Reviewer

- **Executable:** [`../.codex/agents/quality_reviewer.toml`](../.codex/agents/quality_reviewer.toml)
- **Model:** `gpt-5.6-terra`
- **Reasoning:** `high`
- **Owns:** review indipendente, regressioni, accessibilità, test, build e QA UI.
- **May delegate:** esecuzione di test, build, ricerche e raccolta output a `worker`; i worker del reviewer restano read-only su sorgenti e documentazione revisionati e non correggono mai i finding.
- **Must not:** modificare sorgenti o documenti revisionati e correggere i propri finding.
- **Verification:** finding ordinati per severità con file, linee ed evidenze; oppure scope verificato senza finding.
- **Git:** non è Git owner dei sorgenti revisionati.
```

- [ ] **Step 3: Check documentation-to-config coverage**

Run:

```bash
for name in worker product_ux flutter_engineer platform_engineer quality_reviewer; do
  test -f ".codex/agents/$name.toml"
  test -f "agents/$name.md"
done
test -f agents/README.md
```

Expected: exit code 0.

- [ ] **Step 4: Commit the human-readable role cards**

Run:

```bash
git add \
  agents/README.md \
  agents/worker.md \
  agents/product_ux.md \
  agents/flutter_engineer.md \
  agents/platform_engineer.md \
  agents/quality_reviewer.md
git diff --cached --check
git commit -m "docs(agents): document team roles"
```

Expected: one commit containing only the team README and five role cards.

### Task 5: Validate, independently review, and commit the plan

**Files:**
- Verify: `.codex/config.toml`
- Verify: `.codex/agents/*.toml`
- Verify: `AGENTS.md`
- Verify: `agents/*.md`
- Include: `docs/superpowers/plans/2026-07-22-agentic-team.md`

**Interfaces:**
- Consumes: all configuration and documentation from Tasks 1–4.
- Produces: a fully validated local commit series ready for final whole-branch review and push.
- Git owner: the orchestrator designates the Task 5 implementer as Git owner only for `docs/superpowers/plans/2026-07-22-agentic-team.md` and this task's commit.

- [ ] **Step 1: Run the complete TOML and role validation**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
import tomllib

config_path = Path('.codex/config.toml')
with config_path.open('rb') as stream:
    config = tomllib.load(stream)

assert config['model'] == 'gpt-5.6-sol'
assert config['model_reasoning_effort'] == 'high'
assert config['agents'] == {
    'enabled': True,
    'max_concurrent_threads_per_session': 3,
    'default_subagent_model': 'gpt-5.6-terra',
    'default_subagent_reasoning_effort': 'high',
}

expected = {
    'worker': ('gpt-5.6-terra', 'low'),
    'product_ux': ('gpt-5.6-terra', 'high'),
    'flutter_engineer': ('gpt-5.6-terra', 'high'),
    'platform_engineer': ('gpt-5.6-terra', 'high'),
    'quality_reviewer': ('gpt-5.6-terra', 'high'),
}

paths = sorted(Path('.codex/agents').glob('*.toml'))
assert {path.stem for path in paths} == set(expected)

seen = set()
for path in paths:
    with path.open('rb') as stream:
        data = tomllib.load(stream)
    assert path.stem == data['name']
    name = data['name']
    seen.add(name)
    assert (data['model'], data['model_reasoning_effort']) == expected[name]
    assert data['description'].strip()
    assert data['developer_instructions'].strip()
    assert Path(f'agents/{name}.md').exists()

assert seen == set(expected)
assert 'gpt-5.6-luna' not in ''.join(
    path.read_text() for path in Path('.codex').rglob('*.toml')
)
print('agent configuration valid')
PY
```

Expected: `agent configuration valid` and exit code 0.

- [ ] **Step 2: Run documentation and whitespace checks**

Run:

```bash
test -f agents/README.md
rg -q "product_ux" AGENTS.md
rg -q "Git owner" AGENTS.md
git diff --check -- .codex AGENTS.md agents docs/superpowers/plans/2026-07-22-agentic-team.md
```

Expected: exit code 0.

- [ ] **Step 3: Run the new-task load smoke test**

Run the current Codex CLI syntax below before independent review or any push:

```bash
codex exec --ephemeral --strict-config -C /Users/matteo/iter -s read-only --json -o .superpowers/sdd/new-task-smoke-last.txt 'Do not inspect the repository or run shell commands. Perform only this delegation smoke test. In this strict order, sequentially spawn product_ux with task_name="smoke_product_ux", flutter_engineer with task_name="smoke_flutter_engineer", platform_engineer with task_name="smoke_platform_engineer", quality_reviewer with task_name="smoke_quality_reviewer", and worker with task_name="smoke_worker". Every spawn MUST set fork_turns="none". Send only the respective child instruction: product_ux: "Do not use tools or make edits. Immediately reply exactly product_ux: loaded."; flutter_engineer: "Do not use tools or make edits. Immediately reply exactly flutter_engineer: loaded."; platform_engineer: "Do not use tools or make edits. Immediately reply exactly platform_engineer: loaded."; quality_reviewer: "Do not use tools or make edits. Immediately reply exactly quality_reviewer: loaded."; worker: "Do not use tools or make edits. Immediately reply exactly worker: loaded." Wait for that child to complete before the next spawn. If any spawn or wait errors, stop immediately and report the error explicitly; do not continue. Finish with exactly five separate lines and no other text: product_ux: loaded; flutter_engineer: loaded; platform_engineer: loaded; quality_reviewer: loaded; worker: loaded.' > .superpowers/sdd/new-task-smoke.jsonl
```

Inspect the structured event trace for this new task. Require all of the
following before independent review or push:

- one `subAgentActivity` `started` event for each role, with a non-empty
  `agentThreadId` and its expected unique smoke task path;
- completion of every child with that child's own role response;
- identical `git status --short` output before and after the smoke run.

The parent's five final `role: loaded` lines are not sufficient evidence on
their own: do not use `rg -qx` against parent output as a spawn gate.

Verification note: the real new Codex task
`019f8be2-e321-7882-b5e3-93b98c75f3f5`, turn
`019f8be2-e413-76e1-ab33-f0e763051317`, has `subAgentActivity` `started`
events with non-empty IDs for `product_ux`
(`019f8be3-4c63-7ec2-b1c2-d48b99384563`, `/root/smoke_product_ux`),
`flutter_engineer` (`019f8be3-70be-7390-a4be-60f64fd69a6e`,
`/root/smoke_flutter_engineer`), `platform_engineer`
(`019f8be3-9750-7041-8ca6-ec89ad0e0ec4`, `/root/smoke_platform_engineer`),
`quality_reviewer` (`019f8be3-b807-7b41-9940-e3d946bb7236`,
`/root/smoke_quality_reviewer`) and `worker`
(`019f8be3-d6df-7960-b573-9988c4fd3350`, `/root/smoke_worker`). All children
completed with their own role response, and `git status --short` was identical
before and after. The previous `rg -qx` v2 parent-output attestation was a
false positive, not spawn evidence.

- [ ] **Step 4: Request independent review**

Dispatch `quality_reviewer` if the new custom role is available in the current
task. Otherwise dispatch a read-only reviewer with this scope:

```text
Review only .codex/config.toml, .codex/agents/*.toml, AGENTS.md, agents/*.md,
and docs/superpowers/plans/2026-07-22-agentic-team.md against the approved
design. Do not edit files. Check schema, model mapping, delegation boundaries,
Git safety, duplication, and contradictions. Return findings by severity with
file references, or state that no findings remain.
```

Expected: no unresolved correctness or safety findings.

- [ ] **Step 5: Stage only the implementation plan**

Run:

```bash
git add \
  docs/superpowers/plans/2026-07-22-agentic-team.md
git diff --cached --check
git diff --cached --name-status
```

Expected: only the implementation plan is staged; Tasks 1–4 are already in
their reviewed commits.

- [ ] **Step 6: Commit the implementation**

Run:

```bash
git commit -m "docs(agents): add implementation plan"
git show --check --stat --oneline HEAD
```

Expected: commit succeeds and contains only the implementation plan.

- [ ] **Step 7: Hand the commit series back for final review**

Do not push from the Task 5 implementer. Report every commit SHA and validation
result to the orchestrator. The orchestrator dispatches the required broad
whole-branch reviewer, resolves all Critical or Important findings, inspects the
final commit series, and only then runs:

```bash
git push origin feat/mobile-ui-refresh
```

Expected: `origin/feat/mobile-ui-refresh` advances to the implementation
series without force after the whole-branch review is clean.
