#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
GEN="${GEN:-$PROJECT_DIR/code/bash/s1_design_inference/gen_tasks.sh}"
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/code/bash/s1_design_inference/tasks.txt}"
SLURM_FILE="${SLURM_FILE:-$PROJECT_DIR/code/bash/s1_design_inference/run_overcooked_array.slurm}"

# chunking + throttle (override via env)
CHUNK="${CHUNK:-900}"          # max indices per array (stay under site cap)
CONCURRENCY="${CONCURRENCY:-200}"  # % throttle per array

# 1) (Re)generate tasks
"$GEN"

# 2) Submit in chunks
NLINES=$(wc -l < "$TASKS_FILE")
if [[ "$NLINES" -le 0 ]]; then
  echo "No tasks found in $TASKS_FILE"; exit 2
fi

echo "Submitting $NLINES tasks in chunks of $CHUNK (concurrency=$CONCURRENCY)"
i=0
while (( i * CHUNK < NLINES )); do
  OFFSET=$(( i * CHUNK ))
  REMAIN=$(( NLINES - OFFSET ))
  SPAN=$(( REMAIN < CHUNK ? REMAIN : CHUNK ))
  ARR_SPEC="1-${SPAN}%${CONCURRENCY}"

  echo "Chunk $((i+1)): lines $((OFFSET+1))..$((OFFSET+SPAN))  OFFSET=$OFFSET  ARRAY=$ARR_SPEC"
  sbatch --export=OFFSET="$OFFSET" --array="$ARR_SPEC" "$SLURM_FILE"
  (( i++ ))
done