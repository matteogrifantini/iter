#!/bin/bash
#
# opencode_loop.sh — mini-loop autonomo per opencode.
#
# Richiama `opencode run` in iterazioni successive (continuando la stessa
# sessione) finche' il task in TASK.md non viene dichiarato completo, oppure
# fino a max-loops / timeout / error / mancanza di progressi.
#
# Protocollo di completamento: l'agente deve terminare la risposta con una riga
# esattamente uguale a:
#   STATUS: DONE        -> il task e' completo, il loop esce con 0
#   STATUS: CONTINUE    -> serve altro lavoro, il loop continua
# Se STATUS manca, si assume CONTINUE ma si avverte.
#
# Uso:
#   tool/opencode_loop.sh --task TASK.md [opzioni]
#
# Opzioni:
#   --task <file>      file markdown con obiettivo e checklist (obbligatorio)
#   --work-dir <dir>   directory di lavoro (default: root del repo)
#   --model <m>        modello provider/model da passare a -m (default: config)
#   --max-loops N      iterazioni massime (default: 20)
#   --timeout-min N    timeout per singola chiamata in minuti (default: 20)
#   --no-auto          non approvare permessi automaticamente (default: --auto)
#   --log <file>       log delle iterazioni (default: tool/.opencode_loop.log)
#   --once             esegue una sola iterazione e termina
#   --dry-run          stampa solo il primo comando e termina

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TASK=""
WORK_DIR="$REPO_ROOT"
MODEL=""
MAX_LOOPS=20
TIMEOUT_MIN=20
AUTO=1
LOG=""
ONCE=0
DRY_RUN=0

usage() {
  sed -n '2,32p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task) TASK="$2"; shift 2 ;;
    --work-dir) WORK_DIR="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --max-loops) MAX_LOOPS="$2"; shift 2 ;;
    --timeout-min) TIMEOUT_MIN="$2"; shift 2 ;;
    --no-auto) AUTO=0; shift ;;
    --log) LOG="$2"; shift 2 ;;
    --once) ONCE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage ;;
    *) echo "Opzione sconosciuta: $1" >&2; usage ;;
  esac
done

if [[ -z "$TASK" ]]; then
  echo "Errore: --task <file> e' obbligatorio" >&2
  usage
fi

[[ "$TASK" == /* ]] || TASK="$WORK_DIR/$TASK"
if [[ "$DRY_RUN" -ne 1 && ! -f "$TASK" ]]; then
  echo "Errore: task non trovato: $TASK" >&2
  exit 2
fi

if [[ -z "$LOG" ]]; then
  LOG="$REPO_ROOT/tool/.opencode_loop.log"
fi
mkdir -p "$(dirname "$LOG")"

command -v opencode >/dev/null 2>&1 || { echo "Errore: opencode non trovato in PATH" >&2; exit 2; }
command -v gtimeout >/dev/null 2>&1 || { echo "Errore: gtimeout mancante (brew install coreutils)" >&2; exit 2; }

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

auto_flag=()
[[ "$AUTO" -eq 1 ]] && auto_flag=(--auto)

model_flag=()
[[ -n "$MODEL" ]] && model_flag=(--model "$MODEL")

working_tree_hash() {
  (cd "$WORK_DIR" && git status --porcelain | git hash-object --stdin 2>/dev/null) || echo "none"
}

PROMPT_BASE="Continua il lavoro sul task in $TASK (root repo: $WORK_DIR). Segui le istruzioni del task, lavora in autonomia e verifica con i comandi di lint/test del progetto quando possibile. NON fare commit a meno che il task non lo richieda esplicitamente. Termina la risposta con esattamente una riga: STATUS: DONE se l'intero task e' completo, altrimenti STATUS: CONTINUE."

run_once() {
  local continue_flag=()
  if [[ "$1" -eq 1 ]]; then
    continue_flag=(-c)
  fi
  local out
  out="$(gtimeout "${TIMEOUT_MIN}m" opencode run ${continue_flag[@]+"${continue_flag[@]}"} ${auto_flag[@]+"${auto_flag[@]}"} ${model_flag[@]+"${model_flag[@]}"} --dir "$WORK_DIR" --format default "$PROMPT_BASE" 2>&1)"
  echo "$out"
}

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "opencode run -c --auto --dir $WORK_DIR --format default \"$PROMPT_BASE\""
  exit 0
fi

echo "$(timestamp) [loop] start task=$TASK workdir=$WORK_DIR max_loops=$MAX_LOOPS" | tee -a "$LOG"

prev_hash=""
stall=0
for ((i = 1; i <= MAX_LOOPS; i++)); do
  echo "$(timestamp) [loop] iterazione $i/$MAX_LOOPS" | tee -a "$LOG"

  out="$(run_once "$i")"
  echo "$(timestamp) [loop] output iterazione $i:" >> "$LOG"
  echo "$out" >> "$LOG"

  if grep -q '^STATUS: DONE' <<<"$out"; then
    echo "$(timestamp) [loop] COMPLETATO (STATUS: DONE) dopo $i iterazioni" | tee -a "$LOG"
    exit 0
  fi
  if ! grep -q '^STATUS: CONTINUE' <<<"$out"; then
    echo "$(timestamp) [warn] nessun STATUS: CONTINUE|DONE nel primo 1k righe" >> "$LOG"
  fi

  if [[ "$ONCE" -eq 1 ]]; then
    echo "$(timestamp) [loop] --once: termino dopo la prima iterazione" | tee -a "$LOG"
    exit 0
  fi

  hash="$(working_tree_hash)"
  if [[ "$hash" == "$prev_hash" ]]; then
    stall=$((stall + 1))
    if [[ "$stall" -ge 3 ]]; then
      echo "$(timestamp) [loop] STUCK: nessuna modifica a git dopo 3 iterazioni; esco" | tee -a "$LOG"
      exit 5
    fi
  else
    stall=0
  fi
  prev_hash="$hash"
done

echo "$(timestamp) [loop] RAGGIUNTO max_loops=$MAX_LOOPS senza STATUS: DONE; esco" | tee -a "$LOG"
exit 3
