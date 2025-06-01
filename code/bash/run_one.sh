#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $(basename "$0") <level-path> <seed>" >&2
  exit 1
fi

lvl_path="$1"
seed="$2"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."; pwd)"
LEVEL_DIR="$ROOT/stimuli/gym-cooking-levels"
PICKLE_ROOT="$ROOT/data/models/pickles"
RECORD_ROOT="$ROOT/data/models/records"

# 1) basename & skip scratch
base="$(basename "$lvl_path" .txt)"
[[ "$base" == "scratch" ]] && exit 0

# 2) subdirectory under stimuli/…
subdir="${lvl_path#$LEVEL_DIR/}"
subdir="${subdir%/*}"

# 3) parse number of agents from filename (e.g. “2-something.txt” → 2)
na="${base%%-*}"
num_agents="${na//[^0-9]/}"
if [[ -z "$num_agents" ]]; then
  echo "ERROR: couldn't parse agent count from $base" >&2
  exit 1
fi

# 4) prepare output dirs
record_dir="$RECORD_ROOT/$subdir/$base/seed=$seed"
mkdir -p "$record_dir"
export OVERCOOKED_RECORD_ROOT="$record_dir"

outdir="$PICKLE_ROOT/$subdir"
mkdir -p "$outdir"
prefix="${base}-seed${seed}"

# 5) run the experiment
echo "[ $(date +'%H:%M:%S') | lvl=$base seed=$seed gpu=$CUDA_VISIBLE_DEVICES ] Agents=$num_agents"

python gym-cooking/gym_cooking/main.py \
  --level "$lvl_path" \
  --num-agents "$num_agents" \
  --seed "$seed" \
  --record \
  --model1 bd \
  $( [[ "$num_agents" -ge 2 ]] && echo "--model2 bd" ) \
  $( [[ "$num_agents" -ge 3 ]] && echo "--model3 bd" ) \
  $( [[ "$num_agents" -ge 4 ]] && echo "--model4 bd" ) \
  --output-dir "$outdir" \
  --output-prefix "$prefix"
