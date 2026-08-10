# Agent Workflow Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configurare Iter con orchestratore Sol High, worker Luna Medium, worker-hard Luna Max e specialisti Luna Max.

**Architecture:** Il team resta piatto e worker-first. L'orchestratore mantiene decisioni e integrazione; i file TOML definiscono il runtime, mentre AGENTS, HANDOFF e le schede in `agents/` mantengono il contratto leggibile e coerente.

**Tech Stack:** Codex TOML, Markdown, Python `tomllib`, catalogo modelli locale Codex.

## Global Constraints

- Orchestratore: `gpt-5.6-sol`, effort `high`.
- Worker: `gpt-5.6-luna`, effort `medium`.
- Worker-hard e specialisti: `gpt-5.6-luna`, effort `max`.
- Massimo tre agenti secondari; struttura piatta; un solo writer per file.
- Gate Git, sicurezza, QA e ownership esistenti restano invariati.
- Non modificare Flutter o la configurazione opencode.

---

### Task 1: Configurazione eseguibile Codex

**Files:**
- Modify: `.codex/config.toml`
- Modify: `.codex/agents/worker.toml`
- Create: `.codex/agents/worker-hard.toml`
- Modify: `.codex/agents/product_ux.toml`
- Modify: `.codex/agents/flutter_engineer.toml`
- Modify: `.codex/agents/platform_engineer.toml`
- Modify: `.codex/agents/quality_reviewer.toml`

**Interfaces:**
- Consumes: catalogo locale `/Users/matteo/.codex/models_cache.json`.
- Produces: configurazione Codex worker-first con routing documentato nelle descrizioni degli agenti.

- [x] **Step 1: Impostare i default dei subagent**

In `.codex/config.toml` impostare:

```toml
default_subagent_model = "gpt-5.6-luna"
default_subagent_reasoning_effort = "medium"
```

- [x] **Step 2: Configurare worker e worker-hard**

Impostare `worker` su Luna Medium. Creare `worker-hard.toml` su Luna Max con
istruzioni equivalenti al worker, aggiungendo ownership di debugging difficile,
refactor articolati e cambi coordinati, senza autorita su scope o architettura.

- [x] **Step 3: Configurare gli specialisti**

In tutti e quattro i TOML specialistici impostare:

```toml
model = "gpt-5.6-luna"
model_reasoning_effort = "max"
```

Rimuovere dalle istruzioni la possibilita di creare worker, mantenendo la
struttura piatta governata dall'orchestratore.

- [x] **Step 4: Verificare il parsing TOML**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
import tomllib
for path in sorted(Path('.codex').rglob('*.toml')):
    with path.open('rb') as handle:
        tomllib.load(handle)
    print(path)
PY
```

Expected: ogni file TOML viene elencato senza eccezioni.

### Task 2: Contratto operativo leggibile

**Files:**
- Modify: `AGENTS.md`
- Modify: `HANDOFF.md`
- Modify: `agents/README.md`
- Modify: `agents/worker.md`
- Create: `agents/worker-hard.md`
- Modify: `agents/product_ux.md`
- Modify: `agents/flutter_engineer.md`
- Modify: `agents/platform_engineer.md`
- Modify: `agents/quality_reviewer.md`

**Interfaces:**
- Consumes: configurazioni prodotte dal Task 1.
- Produces: documentazione coerente del routing, escalation e modello di ogni ruolo.

- [x] **Step 1: Riscrivere routing e orchestrazione in AGENTS**

Definire `worker` come default, `worker-hard` come escalation per complessita e
gli specialisti come escalation per competenza di dominio. Vietare deleghe
annidate e conservare massimo tre agenti secondari.

- [x] **Step 2: Allineare HANDOFF**

Sostituire la sezione operativa Terra/Low con la tabella Sol High, Luna Medium e
Luna Max, includendo il criterio di escalation.

- [x] **Step 3: Allineare le schede ruolo**

Aggiornare modelli ed effort nelle schede esistenti e aggiungere
`agents/worker-hard.md` collegato al TOML eseguibile.

- [x] **Step 4: Controllare riferimenti obsoleti**

Run:

```bash
rtk rg -n "gpt-5\\.6-terra|model_reasoning_effort = \\"low\\"|worker-hard" AGENTS.md HANDOFF.md agents .codex
```

Expected: nessun riferimento operativo Terra/Low; `worker-hard` compare in
configurazione e documentazione.

### Task 3: Gate finale e commit

**Files:**
- Verify: tutti i file dei Task 1 e 2
- Verify: `docs/superpowers/specs/2026-08-11-agent-workflow-redesign.md`
- Verify: `docs/superpowers/plans/2026-08-11-agent-workflow-redesign.md`

**Interfaces:**
- Consumes: configurazione e documentazione complete.
- Produces: batch revisionato e committato senza push.

- [x] **Step 1: Validare i modelli contro il catalogo locale**

Run uno script Python che estragga tutti i campi `model` dai TOML e verifichi
che ogni slug esista in `/Users/matteo/.codex/models_cache.json`.

- [x] **Step 2: Verificare diff e whitespace**

Run:

```bash
rtk git diff --check
rtk git diff --stat
rtk git diff
```

Expected: nessun errore whitespace e diff limitato ai file dichiarati.

- [x] **Step 3: Validare e committare il batch**

Eseguire il Gate Git di `AGENTS.md`, fare staging dei soli percorsi dichiarati,
controllare `git diff --cached --check`, quindi creare un commit Conventional
Commits senza push.
