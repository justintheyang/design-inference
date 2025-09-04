# code/bash/s1_design_inference/gen_tasks.sh
#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
EXP="${EXP:-s1_design_inference}"
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/tasks.txt}"
SEEDS="${SEEDS:-20}"   # override: SEEDS=... code/bash/s1_design_inference/gen_tasks.sh

# Sherlock Python 3.9 + user site
module --force purge; module load python/3.9
export PATH="$HOME/.local/bin:$PATH"
PY_USER_SITE="$(python3 -c 'import site; print(site.getusersitepackages())')"
export PYTHONPATH="${PY_USER_SITE}:${PYTHONPATH-}"

export SDL_VIDEODRIVER=dummy
export MPLBACKEND=Agg

cd "$PROJECT_DIR"

ORCH="code/python/${EXP}/model_runs.py"
if [[ ! -f "$ORCH" ]]; then
  echo "ERROR: Orchestrator not found: $ORCH" >&2
  exit 1
fi

echo "[gen] building task list → $TASKS_FILE"
python3 "$ORCH" --seeds "$SEEDS" --jobs 1 --dry-run \
| awk '/^DRY-RUN:/{sub(/^DRY-RUN:[ ]*/,""); print}' \
| sed 's/^python[[:space:]]/python3 /' \
> "$TASKS_FILE"

NLINES=$(wc -l < "$TASKS_FILE")
echo "[gen] wrote $NLINES tasks to $TASKS_FILE"
head -3 "$TASKS_FILE" || true