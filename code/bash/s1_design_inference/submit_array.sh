#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/tasks.txt}"
SEEDS="${SEEDS:-20}"
CONCURRENCY="${CONCURRENCY:-200}"     # max concurrent tasks

# 1) Build tasks
"$PROJECT_DIR/code/bash/s1_design_inference/gen_tasks.sh"

# 2) Submit array
NLINES=$(wc -l < "$TASKS_FILE")
echo "[submit] tasks: $NLINES ; concurrency: $CONCURRENCY"
cd "$PROJECT_DIR"
mkdir -p logs
sbatch --array="1-${NLINES}%${CONCURRENCY}" code/bash/s1_design_inference/run_overcooked_array.slurm