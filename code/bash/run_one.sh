#!/usr/bin/env bash
# code/bash/run_one.sh

lvl="$1"
ROOT="$(cd "$(dirname "$0")/../.."; pwd)"
LEVEL_DIR="$ROOT/stimuli/gym-cooking-levels"
OUT_ROOT="$ROOT/data/models/pickles"

subdir="${lvl#"$LEVEL_DIR"/}"
base="$(basename "$lvl" .txt)"
num_agents="${base%%-*}"
num_agents="${num_agents//[^0-9]/}"

cmd="python gym-cooking/gym_cooking/main.py \
  --num-agents $num_agents \
  --level \"$lvl\" \
  --model1 bd \
  --record"

if [ "$num_agents" -eq 2 ]; then
  cmd+=" --model2 bd"
fi

outdir="$OUT_ROOT/${subdir%/*}"
mkdir -p "$outdir"
prefix="$base"
cmd+=" --output-dir \"$outdir\" --output-prefix \"$prefix\""

echo "[$(date +%H:%M:%S)] $cmd"
eval $cmd
