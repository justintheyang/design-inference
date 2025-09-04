#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
EXP="${EXP:-s1_design_inference}"
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/code/bash/${EXP}/tasks.txt}"
SEEDS="${SEEDS:-20}"   # override via: SEEDS=50 code/bash/s1_design_inference/gen_tasks.sh
OUTDIR="${OUTDIR:-$SCRATCH/design-inference/${EXP}}"   # <- write results to SCRATCH

# --- Lmod / Python module (robust) ---
source /share/software/user/open/lmod/lmod/init/bash
module --ignore_cache purge
module --ignore_cache load python/3.9.0 || module --ignore_cache load python/3.12.1

# User-site visibility
export PATH="$HOME/.local/bin:$PATH"
PY_USER_SITE="$(python3 -c 'import site; print(site.getusersitepackages())')"
export PYTHONPATH="${PY_USER_SITE}:${PYTHONPATH-}"

# Headless graphics
export SDL_VIDEODRIVER=dummy
export MPLBACKEND=Agg

cd "$PROJECT_DIR"

ORCH="code/python/${EXP}/model_runs.py"
if [[ ! -f "$ORCH" ]]; then
  echo "ERROR: Orchestrator not found: $ORCH" >&2
  exit 1
fi

mkdir -p "$(dirname "$TASKS_FILE")" "$OUTDIR"

echo "[gen] building task list → $TASKS_FILE"
python3 "$ORCH" --seeds "$SEEDS" --jobs 1 --dry-run \
| awk '/^DRY-RUN:/{sub(/^DRY-RUN:[ ]*/,""); print}' \
| sed 's/^python[[:space:]]/python3 /' \
| awk -v outdir="$OUTDIR" '
  # replace the value that follows --output-dir with our SCRATCH path
  {
    for (i=1; i<=NF; i++) {
      if ($i=="--output-dir" && (i+1)<=NF) { $(i+1)=outdir }
    }
    print
  }
' > "$TASKS_FILE"

NLINES=$(wc -l < "$TASKS_FILE" || echo 0)
echo "[gen] wrote $NLINES tasks to $TASKS_FILE"
head -3 "$TASKS_FILE" 2>/dev/null || true