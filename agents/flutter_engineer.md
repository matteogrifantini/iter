# Flutter Engineer

- **Executable:** [`../.codex/agents/flutter_engineer.toml`](../.codex/agents/flutter_engineer.toml)
- **Model:** `gpt-5.6-terra`
- **Reasoning:** `high`
- **Owns:** Dart, widget, stato, modelli, tema e test applicativi Flutter.
- **May delegate:** edit circoscritti, test e ricerche con file disgiunti a `worker`.
- **Must not:** introdurre permessi, plugin, provider o segreti senza il contratto di piattaforma.
- **Verification:** `flutter analyze`, `flutter test` e gate Web/Android proporzionati allo scope.
- **Git:** può diventare Git owner di un batch interamente assegnato dall'orchestratore.
