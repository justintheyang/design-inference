#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# initialize Conda in this shell
eval "$(conda shell.bash hook)"
conda activate base
conda activate design-overcooked

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# paths under ROOT
STIMULI_ROOT="${ROOT}/stimuli/s1_design_inference/txt"
LAYOUT_ROOT="${ROOT}/stimuli/s1_design_inference/img"

export OVERCOOKED_RECORD_ROOT="$LAYOUT_ROOT"

# make sure output dir exists
mkdir -p "$LAYOUT_ROOT"

# iterate through each .txt file in STIMULI_ROOT
for level_file in "$STIMULI_ROOT"/*.txt; do
  # skip non‑regular files (just in case)
  [[ -f "$level_file" ]] || continue

  echo "Recording layout for: $level_file"
  python gym-cooking/gym_cooking/main.py \
    --level "$level_file" \
    --num-agents 0 \
    --record \
    --layout
done

conda activate base