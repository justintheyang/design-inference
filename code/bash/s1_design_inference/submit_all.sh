#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   submit_all.sh [overwrite] [regen]
# or via env:
#   OVERWRITE=1 REGEN=1 CHUNK=900 CONCURRENCY=300 SEEDS=20 ./submit_all.sh

PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
GEN="${GEN:-$PROJECT_DIR/code/bash/s1_design_inference/gen_tasks.sh}"
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/code/bash/s1_design_inference/tasks.txt}"
SLURM_FILE="${SLURM_FILE:-$PROJECT_DIR/code/bash/s1_design_inference/run_overcooked_array.slurm}"

# tuneables
CHUNK="${CHUNK:-900}"                # tasks per array (≤ site array cap)
CONCURRENCY="${CONCURRENCY:-300}"    # tasks running per array
SEEDS="${SEEDS:-20}"                 # passed to gen
OVERWRITE="${OVERWRITE:-0}"          # 1 = re-run even if pickle exists
REGEN="${REGEN:-0}"                  # 1 = force re-generate tasks.txt

# Positional shorthands
case "${1-}" in
  overwrite) OVERWRITE=1 ;;
esac
case "${2-}" in
  regen) REGEN=1 ;;
esac

# 1) (re)generate tasks.txt?
if [[ ! -f "$TASKS_FILE" || "$REGEN" == "1" ]]; then
  echo "[gen] building task list → $TASKS_FILE"
  SEEDS="$SEEDS" "$GEN"
else
  echo "[gen] using existing $TASKS_FILE (REGEN=0)"
fi

NLINES=$(wc -l < "$TASKS_FILE")
(( NLINES > 0 )) || { echo "No tasks in $TASKS_FILE"; exit 2; }

# 2) compute chunk count and submit all
CHUNKS=$(( (NLINES + CHUNK - 1) / CHUNK ))
echo "Submitting $NLINES tasks in $CHUNKS chunk(s) of up to $CHUNK (%$CONCURRENCY)"
echo "OVERWRITE=${OVERWRITE} (1 = do not skip existing pickles)"

for ((i=0; i<CHUNKS; i++)); do
  OFFSET=$(( i * CHUNK ))
  SPAN=$(( NLINES - OFFSET ))
  (( SPAN > CHUNK )) && SPAN=$CHUNK
  ARR_SPEC="1-${SPAN}%${CONCURRENCY}"
  echo "Chunk $((i+1))/$CHUNKS: lines $((OFFSET+1))..$((OFFSET+SPAN)), OFFSET=$OFFSET, ARRAY=$ARR_SPEC"
  sbatch --export=OFFSET="$OFFSET",OVERWRITE_RESULTS="$OVERWRITE" --array="$ARR_SPEC" "$SLURM_FILE"
done

echo "All chunks submitted."