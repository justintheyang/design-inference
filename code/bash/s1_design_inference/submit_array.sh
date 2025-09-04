#!/usr/bin/env bash
set -euo pipefail

# Config (override via env or flags)
PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/code/bash/s1_design_inference/tasks.txt}"
SLURM_FILE="${SLURM_FILE:-$PROJECT_DIR/code/bash/s1_design_inference/run_overcooked_array.slurm}"

# Reasonable defaults: many clusters cap arrays at ~1000; keep us under that.
CHUNK="${CHUNK:-900}"           # max indices per submitted array
CONCURRENCY="${CONCURRENCY:-200}" # throttle per array (1-N%CONCURRENCY)
DRY_RUN="${DRY_RUN:-0}"         # set to 1 to print sbatch cmds without running

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [--chunk N] [--concurrency M] [--dry-run]
Env overrides:
  PROJECT_DIR=$PROJECT_DIR
  TASKS_FILE=$TASKS_FILE
  SLURM_FILE=$SLURM_FILE
  CHUNK=$CHUNK   CONCURRENCY=$CONCURRENCY  DRY_RUN=$DRY_RUN
EOF
  exit 1
}

# Simple flag parser
while [[ $# -gt 0 ]]; do
  case "$1" in
    --chunk) CHUNK="${2:?}"; shift 2 ;;
    --concurrency) CONCURRENCY="${2:?}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  case
done

[[ -f "$TASKS_FILE" ]] || { echo "Missing tasks file: $TASKS_FILE" >&2; exit 2; }
[[ -f "$SLURM_FILE" ]] || { echo "Missing slurm file: $SLURM_FILE" >&2; exit 2; }

NLINES=$(wc -l < "$TASKS_FILE")
[[ "$NLINES" -gt 0 ]] || { echo "No tasks in $TASKS_FILE" >&2; exit 3; }

echo "Submitting $NLINES tasks in chunks of $CHUNK (concurrency=$CONCURRENCY)"
echo "  tasks: $TASKS_FILE"
echo "  slurm: $SLURM_FILE"
echo

i=0
submitted=0
while :; do
  OFFSET=$(( i * CHUNK ))
  (( OFFSET < NLINES )) || break

  REMAIN=$(( NLINES - OFFSET ))
  SPAN=$(( REMAIN < CHUNK ? REMAIN : CHUNK ))

  arr_spec="1-${SPAN}%${CONCURRENCY}"
  echo "Chunk $((i+1)): lines $((OFFSET+1))..$((OFFSET+SPAN))  OFFSET=$OFFSET  ARRAY=$arr_spec"

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "  sbatch --export=OFFSET=${OFFSET} --array=\"${arr_spec}\" \"$SLURM_FILE\""
  else
    # submit and echo the job id
    jid=$(sbatch --export=OFFSET="${OFFSET}" --array="${arr_spec}" "$SLURM_FILE" | awk '{print $4}')
    echo "  -> submitted JobID: ${jid}"
    ((submitted++))
  fi
  echo
  (( i++ ))
done

if [[ "$DRY_RUN" == "1" ]]; then
  echo "DRY RUN complete (no jobs submitted)."
else
  echo "Submitted ${submitted} array job(s)."
fi