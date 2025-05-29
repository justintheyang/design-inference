#!/usr/bin/env bash
# code/bash/run_one.sh

lvl_path="$1"
base="$(basename "$lvl_path" .txt)"

# 1) skip stray files
if [[ "$base" == "scratch" ]]; then
  exit 0
fi

ROOT="$(cd "$(dirname "$0")/../.."; pwd)"
LEVEL_DIR="$ROOT/stimuli/gym-cooking-levels"
PICKLE_ROOT="$ROOT/data/models/pickles"

# subdir under gym-cooking-levels
subdir="${lvl_path#$LEVEL_DIR/}"
subdir="${subdir%/*}"

# parse num_agents safely
na="${base%%-*}"
num_agents="${na//[^0-9]/}"  # strips non-digits
if [[ -z "$num_agents" ]]; then
  echo "ERROR: couldn't parse agent count from $base" >&2
  exit 1
fi

# run seeds 1 through 20
for seed in $(seq 1 20); do
  # 1) set up record directory
  export OVERCOOKED_RECORD_ROOT="$ROOT/data/models/records/$subdir/$base/seed=$seed"
  mkdir -p "$OVERCOOKED_RECORD_ROOT"

  # 2) prepare pickles directory
  outdir="$PICKLE_ROOT/$subdir"
  mkdir -p "$outdir"

  # 3) build prefix to include seed
  prefix="${base}-seed${seed}"

  # 4) assemble command
  cmd=( python gym-cooking/gym_cooking/main.py
    --num-agents "$num_agents"
    --seed "$seed"
    --level "$lvl_path"
    --record
    --model1 bd
  )
  if [[ "$num_agents" -eq 2 ]]; then
    cmd+=( --model2 bd )
  fi
  cmd+=( --output-dir "$outdir" --output-prefix "$prefix" )

  # 5) run
  echo "[ $(date +%H:%M:%S) | seed=$seed ] ${cmd[*]}"
  "${cmd[@]}"
done
