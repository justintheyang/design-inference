#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
SEEDS="${SEEDS:-20}"                 # change or export SEEDS=... when calling
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/tasks.txt}"

# Sherlock Python 3.9 + user site
module purge; module load python/3.9
export PATH="$HOME/.local/bin:$PATH"
PY_USER_SITE="$(python3 -c 'import site; print(site.getusersitepackages())')"
export PYTHONPATH="$PY_USER_SITE:$PYTHONPATH"
export SDL_VIDEODRIVER=dummy
export MPLBACKEND=Agg

cd "$PROJECT_DIR"

echo "[gen] building task list → $TASKS_FILE"
python3 code/python/model_runs.py --seeds "$SEEDS" --jobs 1 --dry-run \
| awk '/^DRY-RUN:/{sub(/^DRY-RUN:[ ]*/,""); print}' \
| sed 's/^python[[:space:]]/python3 /' \
> "$TASKS_FILE"

NLINES=$(wc -l < "$TASKS_FILE")
echo "[gen] wrote $NLINES tasks to $TASKS_FILE"
head -3 "$TASKS_FILE" || true