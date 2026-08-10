# Iter agentic team

Le configurazioni eseguibili sono in [`../.codex/agents`](../.codex/agents) e
i default di progetto in [`../.codex/config.toml`](../.codex/config.toml).
[`../AGENTS.md`](../AGENTS.md) è il contratto operativo autorevole; queste
schede aiutano a scegliere e revisionare i ruoli.

## Gerarchia

| Ruolo | Modello | Effort | Uso |
| --- | --- | --- | --- |
| Orchestrator | `gpt-5.6-sol` | `high` | Decisioni, assegnazione, integrazione |
| `worker` | `gpt-5.6-luna` | `medium` | Esecuzione predefinita delimitata |
| `worker-hard` | `gpt-5.6-luna` | `max` | Esecuzione complessa delimitata |
| `product_ux` | `gpt-5.6-luna` | `max` | Giudizio prodotto e UX |
| `flutter_engineer` | `gpt-5.6-luna` | `max` | Giudizio Dart e Flutter |
| `platform_engineer` | `gpt-5.6-luna` | `max` | Giudizio Android e native |
| `quality_reviewer` | `gpt-5.6-luna` | `max` | Review indipendente e QA |

La struttura è piatta: l'orchestratore assegna fino a tre agenti secondari,
mantiene un solo writer per file e nomina al massimo un Git owner per batch.
Gli agenti secondari non delegano.

## Routing rapido

- Lavoro delimitato ordinario: `worker`.
- Debugging difficile o refactor articolato: `worker-hard`.
- Giudizio di prodotto, Flutter o piattaforma: specialista relativo.
- Review indipendente, regressione, build o QA UI: `quality_reviewer`.

Esempi:

```text
Usa worker per implementare un widget già specificato e i test mirati.
Passa a worker-hard quando il difetto attraversa più componenti e la causa non è ovvia.
Usa product_ux quando serve decidere un criterio di accessibilità o un flusso ambiguo.
Usa quality_reviewer per revisionare il diff senza applicare correzioni.
```

Dopo aggiunte o modifiche agli agenti può essere necessario aprire una nuova
task Codex nel repository trusted per caricare le configurazioni.
