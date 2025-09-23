#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

usage() {
  cat <<'EOF'
Usage: get_layouts.sh

This script generates layout images for all levels, automatically determining
optimal start locations for 2-agent scenarios by running efficiency tests.
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

# Record the starting conda env (empty if none)
START_ENV="${CONDA_DEFAULT_ENV:-}"

# initialize Conda in this shell
eval "$(conda shell.bash hook)"

# Activate the environments needed for the run
conda activate base
conda activate design-overcooked

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# paths under ROOT
STIMULI_ROOT="${ROOT}/stimuli/s1_design_inference/txt"
LAYOUT_ROOT="${ROOT}/stimuli/s1_design_inference/layouts"
CACHE_FILE="${SCRIPT_DIR}/start_location_cache.json"
TASKS_FILE="${SCRIPT_DIR}/get_layouts_tasks.txt"

export OVERCOOKED_RECORD_ROOT="$LAYOUT_ROOT"

# make sure output dir exists
mkdir -p "$LAYOUT_ROOT"

# Clear cache file to ensure fresh optimization
rm -f "$CACHE_FILE"

echo "Finding optimal start locations for all levels..."

# First, find optimal start locations for each level
for level_file in "$STIMULI_ROOT"/*.txt; do
  # skip non-regular files (just in case)
  [[ -f "$level_file" ]] || continue

  echo "Optimizing start locations for: $level_file"
  python3 "$SCRIPT_DIR/optimize_start_locations.py" \
    --level "$level_file" \
    --model "greedy" \
    --seeds 3 \
    --output "${CACHE_FILE}.tmp"
  
  # Append to cache file
  if [[ -f "${CACHE_FILE}.tmp" ]]; then
    if [[ -f "$CACHE_FILE" ]]; then
      echo "," >> "$CACHE_FILE"
      tail -n +2 "${CACHE_FILE}.tmp" >> "$CACHE_FILE"
    else
      echo "[" > "$CACHE_FILE"
      cat "${CACHE_FILE}.tmp" >> "$CACHE_FILE"
    fi
    rm -f "${CACHE_FILE}.tmp"
  fi
done

# Close JSON array
if [[ -f "$CACHE_FILE" ]]; then
  echo "]" >> "$CACHE_FILE"
fi

echo "Generating layout tasks..."

# Generate tasks for both 1-agent and 2-agent layouts
> "$TASKS_FILE"  # Clear tasks file

for level_file in "$STIMULI_ROOT"/*.txt; do
  # skip non-regular files (just in case)
  [[ -f "$level_file" ]] || continue

  level_name=$(basename "$level_file" .txt)
  
  # 1-agent layout (auto-placed)
  echo "python3 gym-cooking/gym_cooking/main.py --level \"$level_file\" --num-agents 0 --record --layout --output-prefix \"${LAYOUT_ROOT}\" --num-start-locations 1" >> "$TASKS_FILE"
  
  # 2-agent layout (with optimal start locations)
  # Get optimal locations from cache
  agent1_loc=$(python3 -c "
import json
with open('$CACHE_FILE', 'r') as f:
    data = json.load(f)
for item in data:
    if item['level'] == '$level_file':
        print(item['agent1_location'])
        break
" 2>/dev/null || echo "")
  
  agent2_loc=$(python3 -c "
import json
with open('$CACHE_FILE', 'r') as f:
    data = json.load(f)
for item in data:
    if item['level'] == '$level_file':
        print(item['agent2_location'])
        break
" 2>/dev/null || echo "")
  
  if [[ -n "$agent1_loc" && -n "$agent2_loc" ]]; then
    echo "python3 gym-cooking/gym_cooking/main.py --level \"$level_file\" --num-agents 0 --record --layout --output-prefix \"${LAYOUT_ROOT}\" --num-start-locations 2 --start-location-model1 \"$agent1_loc\" --start-location-model2 \"$agent2_loc\"" >> "$TASKS_FILE"
  else
    echo "Warning: Could not find optimal locations for $level_file, using auto-placement"
    echo "python3 gym-cooking/gym_cooking/main.py --level \"$level_file\" --num-agents 0 --record --layout --output-prefix \"${LAYOUT_ROOT}\" --num-start-locations 2" >> "$TASKS_FILE"
  fi
done

echo "Executing layout generation tasks..."

# Execute all tasks
while IFS= read -r task; do
  echo "Running: $task"
  eval "$task"
done < "$TASKS_FILE"

echo "Layout generation complete!"

# Restore the environment we started with
if [[ -n "$START_ENV" ]]; then
  conda activate "$START_ENV"
else
  # If we started with no env, ensure we end with no env
  conda deactivate || true
fi
