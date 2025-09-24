#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

usage() {
  cat <<'EOF'
Usage: get_layouts.sh [OPTIONS]

Options:
  --no-regen-starts Use existing optimization results (skip regeneration)
  -h, --help        Show this help message

This script generates layout images for all levels, automatically determining
optimal start locations for 2-agent scenarios by running efficiency tests.
By default, it regenerates optimization results. Use --no-regen-starts to skip
regeneration if optimization results already exist.
EOF
}

# Parse args
REGEN_STARTS=true  # Default: regenerate starts
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-regen-starts)
      REGEN_STARTS=false
      shift
      ;;
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
ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# paths under ROOT
STIMULI_ROOT="${ROOT}/stimuli/s1_design_inference/txt"
LAYOUT_ROOT="${ROOT}/stimuli/s1_design_inference/layouts"
START_LOCATIONS_FILE="${SCRIPT_DIR}/start_locations.json"
TASKS_FILE="${SCRIPT_DIR}/layouts_tasks.txt"

export OVERCOOKED_RECORD_ROOT="$LAYOUT_ROOT"

# make sure output dir exists
mkdir -p "$LAYOUT_ROOT"

# Handle start locations based on regen-starts option
if [[ "$REGEN_STARTS" == "true" ]]; then
  echo "Finding optimal start locations for all trials..."

  # Remove existing file to ensure fresh results
  rm -f "$START_LOCATIONS_FILE"

  # Run the comprehensive start location finder
  cd "$ROOT" && python3 code/python/s1_design_inference/find_start_locations.py \
    --output "$START_LOCATIONS_FILE" \
    --seeds 3

  # Check if start location generation was successful
  if [[ $? -ne 0 ]]; then
    echo "ERROR: Start location generation failed" >&2
    exit 1
  fi
else
  # Check if start locations exist when not regenerating
  if [[ ! -f "$START_LOCATIONS_FILE" ]]; then
    echo "ERROR: Start locations file not found: $START_LOCATIONS_FILE" >&2
    echo "Please run without --no-regen-starts to generate start locations first." >&2
    exit 1
  fi
  echo "Using existing start locations: $START_LOCATIONS_FILE"
fi

echo "Generating layout tasks..."

# Generate tasks for both 1-agent and 2-agent layouts
> "$TASKS_FILE"  # Clear tasks file

# Generate tasks for all trials (1-36)
for i in $(seq -w 1 36); do
  level_file="$STIMULI_ROOT/trial_${i}.txt"
  # skip non-regular files (just in case)
  [[ -f "$level_file" ]] || continue

  trial_id="trial_$(printf '%02d' $((10#$i)))"

  # 1-agent layout - use start location from JSON
  agent1_loc=$(python3 -c "
import json
try:
    with open('$START_LOCATIONS_FILE') as f:
        data = json.load(f)
    for item in data:
        if item['trial_id'] == '$trial_id':
            print(item['agent1_location'])
            break
except:
    pass
")

  if [[ -n "$agent1_loc" ]]; then
    echo "python3 gym-cooking/gym_cooking/main.py --level \"$level_file\" --num-agents 0 --record --layout --output-prefix \"${LAYOUT_ROOT}\" --num-start-locations 1 --start-location-model1 \"$agent1_loc\"" >> "$TASKS_FILE"
  else
    # Fallback to auto-placement if location not found
    echo "python3 gym-cooking/gym_cooking/main.py --level \"$level_file\" --num-agents 0 --record --layout --output-prefix \"${LAYOUT_ROOT}\" --num-start-locations 1" >> "$TASKS_FILE"
  fi

  # 2-agent layout - extract both locations from JSON
  agent2_loc=$(python3 -c "
import json
try:
    with open('$START_LOCATIONS_FILE') as f:
        data = json.load(f)
    for item in data:
        if item['trial_id'] == '$trial_id':
            agent2 = item.get('agent2_location')
            print(agent2 if agent2 is not None else '')
            break
except:
    pass
")

  if [[ -n "$agent1_loc" && -n "$agent2_loc" ]]; then
    # Use optimized locations for 2-agent layout (cooks trials)
    echo "python3 gym-cooking/gym_cooking/main.py --level \"$level_file\" --num-agents 0 --record --layout --output-prefix \"${LAYOUT_ROOT}\" --num-start-locations 2 --start-location-model1 \"$agent1_loc\" --start-location-model2 \"$agent2_loc\"" >> "$TASKS_FILE"
  elif [[ -n "$agent1_loc" ]]; then
    # Single agent layout (dish trials) - but show 2 locations for consistency in display
    echo "python3 gym-cooking/gym_cooking/main.py --level \"$level_file\" --num-agents 0 --record --layout --output-prefix \"${LAYOUT_ROOT}\" --num-start-locations 1 --start-location-model1 \"$agent1_loc\"" >> "$TASKS_FILE"
  else
    # Fallback to auto-placement
    echo "Warning: Could not find start locations for $trial_id, using auto-placement"
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
