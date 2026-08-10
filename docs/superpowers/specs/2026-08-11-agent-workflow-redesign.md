# Iter Agent Workflow Redesign

## Obiettivo

Rendere il team Codex worker-first, con un orchestratore stabile e una scala di
esecuzione semplice: worker per il lavoro ordinario, worker-hard per il lavoro
complesso e specialisti soltanto quando serve giudizio di dominio.

## Modelli

| Ruolo | Modello | Effort |
| --- | --- | --- |
| Orchestratore | `gpt-5.6-sol` | `high` |
| `worker` | `gpt-5.6-luna` | `medium` |
| `worker-hard` | `gpt-5.6-luna` | `max` |
| `product_ux` | `gpt-5.6-luna` | `max` |
| `flutter_engineer` | `gpt-5.6-luna` | `max` |
| `platform_engineer` | `gpt-5.6-luna` | `max` |
| `quality_reviewer` | `gpt-5.6-luna` | `max` |

`gpt-5.6-luna` e gli effort `medium` e `max` risultano presenti nel catalogo
modelli locale di Codex.

## Routing operativo

L'orchestratore conserva contesto, decisioni prodotto e architetturali,
priorita, dipendenze, ownership dei file, integrazione e Git.

`worker` e la scelta predefinita per implementazioni circoscritte, test,
documentazione, ricerche e verifiche. Puo usare giudizio tecnico entro lo scope
assegnato, ma non puo cambiare requisiti, architettura, sicurezza o confini del
lavoro.

`worker-hard` riceve debugging non ovvio, refactor articolati, cambi coordinati
su piu file e incarichi che richiedono ragionamento profondo. Ha gli stessi
limiti decisionali del worker: la maggiore capacita non gli trasferisce
l'autorita dell'orchestratore.

Gli specialisti entrano soltanto quando serve giudizio di dominio:

- `product_ux`: requisiti, flussi, copy, accessibilita e documenti prodotto;
- `flutter_engineer`: Dart, widget, stato, modelli, tema e test applicativi;
- `platform_engineer`: Android, permessi, plugin, media e integrazioni native;
- `quality_reviewer`: review indipendente, regressioni, accessibilita e QA.

## Escalation

Ogni incarico parte da `worker`, salvo complessita o necessita specialistica
gia evidenti. Se il worker trova un limite, restituisce evidenze e rischio
all'orchestratore. Solo l'orchestratore decide se assegnare il seguito a
`worker-hard` o a uno specialista.

La struttura e piatta: gli agenti secondari non creano altri agenti. Restano
massimo tre agenti secondari concorrenti, con file disgiunti e un solo writer
per file.

## Contratto di assegnazione

Ogni incarico specifica:

1. owner e ruolo;
2. file o area posseduta;
3. risultato osservabile;
4. vincoli e dipendenze;
5. verifica richiesta;
6. Git owner, se necessario.

Ogni rientro contiene sintesi, file cambiati, evidenze di verifica, rischi e
blocchi in forma concisa.

## Git e verifica

Il gate Git esistente resta invariato. `quality_reviewer` resta read-only sullo
scope revisionato. Worker, worker-hard e specialisti agiscono come Git owner
solo quando nominati esplicitamente dall'orchestratore.

Per questo intervento, limitato a configurazione e documentazione agenti, il
gate e:

- parsing di tutti i file `.codex/**/*.toml` con Python `tomllib`;
- controllo che i modelli configurati esistano nel catalogo locale Codex;
- controllo riferimenti a modelli, effort e `worker-hard`;
- `git diff --check` e review del diff.

## Fuori scope

- modifica del codice Flutter o del prodotto;
- modifica del numero massimo di tre agenti secondari;
- modifica dei gate Git, QA o sicurezza;
- configurazione del runtime opencode, che resta un'integrazione separata.

## Criteri di accettazione

- il default dei subagent e Luna Medium;
- `worker` e Luna Medium;
- `worker-hard` esiste come agente eseguibile ed e Luna Max;
- tutti gli specialisti sono Luna Max;
- AGENTS, HANDOFF e schede leggibili descrivono lo stesso routing worker-first;
- nessun riferimento operativo Codex continua a prescrivere Terra.
