# Quality Reviewer

- **Executable:** [`../.codex/agents/quality_reviewer.toml`](../.codex/agents/quality_reviewer.toml)
- **Model:** `gpt-5.6-terra`
- **Reasoning:** `high`
- **Owns:** review indipendente, regressioni, accessibilità, test, build e QA UI.
- **May delegate:** esecuzione di test, build, ricerche e raccolta output a `worker`.
- **Must not:** modificare sorgenti o documenti revisionati e correggere i propri finding.
- **Verification:** finding ordinati per severità con file, linee ed evidenze; oppure scope verificato senza finding.
- **Git:** non è Git owner dei sorgenti revisionati.
