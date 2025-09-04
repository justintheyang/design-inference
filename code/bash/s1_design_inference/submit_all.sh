#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
GEN="${GEN:-$PROJECT_DIR/code/bash/s1_design_inference/gen_tasks.sh}"
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/code/bash/s1_design_inference/tasks.txt}"
SLURM_FILE="${SLURM_FILE:-$PROJECT_DIR/code/bash/s1_design_inference/run_overcooked_array.slurm}"

# tuneables
CHUNK="${CHUNK:-900}"            # tasks per array (≤ site array cap)
CONCURRENCY="${CONCURRENCY:-200}"# tasks running per array
SEEDS="${SEEDS:-20}"             # pass through to generator

# 1) (re)generate tasks
SEEDS="$SEEDS" "$GEN"

NLINES=$(wc -l < "$TASKS_FILE")
(( NLINES > 0 )) || { echo "No tasks in $TASKS_FILE"; exit 2; }

# 2) compute chunk count and submit all
CHUNKS=$(( (NLINES + CHUNK - 1) / CHUNK ))
echo "Submitting $NLINES tasks in $CHUNKS chunk(s) of up to $CHUNK (%$CONCURRENCY)"

for ((i=0; i<CHUNKS; i++)); do
  OFFSET=$(( i * CHUNK ))
  SPAN=$(( NLINES - OFFSET ))
  (( SPAN > CHUNK )) && SPAN=$CHUNK
  ARR_SPEC="1-${SPAN}%${CONCURRENCY}"
  echo "Chunk $((i+1))/$CHUNKS: lines $((OFFSET+1))..$((OFFSET+SPAN)), OFFSET=$OFFSET, ARRAY=$ARR_SPEC"
  sbatch --export=OFFSET="$OFFSET" --array="$ARR_SPEC" "$SLURM_FILE"
done

echo "All chunks submitted."