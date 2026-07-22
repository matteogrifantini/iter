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
