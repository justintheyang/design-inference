#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
SEEDS="${SEEDS:-20}"
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/tasks.txt}"
CONCURRENCY="${CONCURRENCY:-200}"       # throttle: max concurrent array tasks

# 1) Build tasks
"$PROJECT_DIR/code/bash/gen_tasks.sh"

# 2) Submit the array
NLINES=$(wc -l < "$TASKS_FILE")
echo "[submit] tasks: $NLINES ; concurrency: $CONCURRENCY"
cd "$PROJECT_DIR"
mkdir -p logs
sbatch --array="1-${NLINES}%${CONCURRENCY}" code/bash/run_overcooked_array.slurm