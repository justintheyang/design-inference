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
LOGROOT="${LOGROOT:-/scratch/users/$USER/design-inference/s1_design_inference}"

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

# Helper: compute expected pickle path for each line
mk_pickle_list() {
  awk -v dflt="$LOGROOT" '
    {
      odir=""; pref=""; seed="";
      for(i=1;i<=NF;i++){
        if($i=="--output-dir")    odir=$(i+1)
        if($i=="--output-prefix") pref=$(i+1)
        if($i=="--seed")          seed=$(i+1)
      }
      if(odir=="") odir=dflt
      p = odir "/pickles/" pref "-seed=" seed ".pkl"
      printf "%d\t%s\n", NR, p
    }' "$TASKS_FILE"
}

# Count existing vs missing
EXISTING=0
MISSING_IDX_FILE="$(mktemp)"
mk_pickle_list | while IFS=$'\t' read -r ln path; do
  if [[ -f "$path" ]]; then
    EXISTING=$((EXISTING+1))
  else
    echo "$ln" >> "$MISSING_IDX_FILE"
  fi
done
# shellcheck disable=SC2034
EXISTING=$(mk_pickle_list | awk -F'\t' '{print $2}' | xargs -r -I{} test -f "{}" && true) >/dev/null 2>&1 || true
# Robust recount (avoids subshell var scope):
EXISTING=$(mk_pickle_list | awk -F'\t' '{print $2}' | while read -r p; do [[ -f "$p" ]] && echo 1; done | wc -l)
MISSING=$(( NLINES - EXISTING ))

echo "Total tasks:    $NLINES"
echo "Already done:   $EXISTING"
echo "Will be run:    $([[ "$OVERWRITE" == "1" ]] && echo "$NLINES" || echo "$MISSING")"
echo "OVERWRITE=$OVERWRITE (1 = re-run even if pickle exists)"

# Early exit if nothing to do and not overwriting
if [[ "$OVERWRITE" != "1" && "$MISSING" -le 0 ]]; then
  echo "Nothing to run. Exiting."
  rm -f "$MISSING_IDX_FILE"
  exit 0
fi

# Helper: compress a sorted list of indices into SLURM array ranges: 5-9,12,20-22
compress_ranges() {
  awk '
    NR==1 {start=$1; prev=$1; next}
    {
      if ($1 == prev+1) { prev=$1; next }
      printf (start==prev ? "%s," : "%s-%s,", start, prev)
      start=$1; prev=$1
    }
    END { if (NR) printf (start==prev ? "%s" : "%s-%s", start, prev) }
  '
}

if [[ "$OVERWRITE" == "1" ]]; then
  # Submit everything in fixed-size chunks (span-based)
  CHUNKS=$(( (NLINES + CHUNK - 1) / CHUNK ))
  echo "Submitting ALL $NLINES tasks in $CHUNKS chunk(s) of up to $CHUNK (%$CONCURRENCY)"
  for ((i=0; i<CHUNKS; i++)); do
    OFFSET=$(( i * CHUNK ))
    SPAN=$(( NLINES - OFFSET ))
    (( SPAN > CHUNK )) && SPAN=$CHUNK
    ARR_SPEC="1-${SPAN}%${CONCURRENCY}"
    echo "Chunk $((i+1))/$CHUNKS: lines $((OFFSET+1))..$((OFFSET+SPAN)), OFFSET=$OFFSET, ARRAY=$ARR_SPEC"
    sbatch --export=OFFSET="$OFFSET",OVERWRITE_RESULTS="1" --array="$ARR_SPEC" "$SLURM_FILE"
  done
else
  # Submit ONLY missing indices, chunked by count (not by span)
  if [[ ! -s "$MISSING_IDX_FILE" ]]; then
    echo "Nothing missing. Exiting."
    rm -f "$MISSING_IDX_FILE"
    exit 0
  fi

  echo "Submitting only missing $MISSING task(s) with concurrency %$CONCURRENCY"
  # Sort numerically, split into groups of size CHUNK, compress each to ranges, submit
  mapfile -t MISSING_ARR < <(sort -n "$MISSING_IDX_FILE")
  TOTAL_MISSING=${#MISSING_ARR[@]}
  BATCHES=$(( (TOTAL_MISSING + CHUNK - 1) / CHUNK ))
  for ((b=0; b<BATCHES; b++)); do
    start=$(( b * CHUNK ))
    end=$(( start + CHUNK ))
    (( end > TOTAL_MISSING )) && end=$TOTAL_MISSING
    # Build ranges for this batch
    printf "%s\n" "${MISSING_ARR[@]:start:end-start}" | compress_ranges > /tmp/ranges.$$
    RANGES=$(cat /tmp/ranges.$$)
    rm -f /tmp/ranges.$$
    echo "Batch $((b+1))/$BATCHES: indices ${start+1}..$end of $TOTAL_MISSING → ${RANGES/%/,} (trimmed)"
    sbatch --export=OFFSET="0",OVERWRITE_RESULTS="0" --array="${RANGES}%${CONCURRENCY}" "$SLURM_FILE"
  done
fi

echo "All submissions done."
rm -f "$MISSING_IDX_FILE"