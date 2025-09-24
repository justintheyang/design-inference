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
OPTIMIZATION_OUTPUT="${SCRIPT_DIR}/optimization_results.json"
TASKS_FILE="${SCRIPT_DIR}/layouts_tasks.txt"

export OVERCOOKED_RECORD_ROOT="$LAYOUT_ROOT"

# make sure output dir exists
mkdir -p "$LAYOUT_ROOT"

# Handle optimization results based on regen-starts option
if [[ "$REGEN_STARTS" == "true" ]]; then
  echo "Finding optimal start locations for all levels..."
  
  # Clear optimization output to ensure fresh results
  rm -f "$OPTIMIZATION_OUTPUT"
  
  # Collect all optimization results in a single JSON array
  rm -f "$OPTIMIZATION_OUTPUT"  # Start fresh
  
  # Only optimize trials 1-18 (trials 19-36 use auto-generated start locations)
  for i in $(seq -w 1 18); do
  level_file="$STIMULI_ROOT/trial_${i}.txt"
  # skip non-regular files (just in case)
  [[ -f "$level_file" ]] || continue

  echo "Optimizing start locations for: $level_file"
  
  # Run optimization and append result to the array
  cd "$ROOT" && python3 "$SCRIPT_DIR/optimize_start_locations.py" \
    --level "$level_file" \
    --model "greedy" \
    --seeds 3 \
    --output "${OPTIMIZATION_OUTPUT}.tmp"
  
  # Use Python script to properly concatenate JSON
  python3 "$SCRIPT_DIR/concat_optimization_results.py" "$OPTIMIZATION_OUTPUT" "${OPTIMIZATION_OUTPUT}.tmp"

  # Check if optimization was successful
  if [[ $? -ne 0 ]]; then
    echo "Warning: Optimization failed for $level_file, skipping..."
    rm -f "${OPTIMIZATION_OUTPUT}.tmp"
  fi
  done
else
  # Check if optimization results exist when not regenerating
  if [[ ! -f "$OPTIMIZATION_OUTPUT" ]]; then
    echo "ERROR: Optimization results not found: $OPTIMIZATION_OUTPUT" >&2
    echo "Please run without --no-regen-starts to generate optimization results first." >&2
    exit 1
  fi
  echo "Using existing optimization results: $OPTIMIZATION_OUTPUT"
fi

echo "Generating layout tasks..."

# Generate tasks for both 1-agent and 2-agent layouts
> "$TASKS_FILE"  # Clear tasks file

# Generate tasks for all trials (1-36)
for i in $(seq -w 1 36); do
  level_file="$STIMULI_ROOT/trial_${i}.txt"
  # skip non-regular files (just in case)
  [[ -f "$level_file" ]] || continue

  level_name=$(basename "$level_file" .txt)
  
  # 1-agent layout (auto-placed) - no start locations needed for layout generation
  echo "python3 gym-cooking/gym_cooking/main.py --level \"$level_file\" --num-agents 0 --record --layout --output-prefix \"${LAYOUT_ROOT}\" --num-start-locations 1" >> "$TASKS_FILE"
  
  # 2-agent layout - use optimized start locations for trials 1-18 (cooks), auto-placed for trials 19-36 (dishes)
  if [[ "$level_name" =~ ^trial_(0[1-9]|1[0-8])$ ]]; then
    # Trials 1-18: Use optimized start locations
    if [[ -f "$OPTIMIZATION_OUTPUT" ]]; then
      # Extract start locations from optimization results
      agent1_loc=$(python3 -c "
import json
try:
    data = json.load(open('$OPTIMIZATION_OUTPUT'))
    for item in data:
        if item['level'].endswith('$level_name.txt'):
            print(item['agent1_location'])
            break
except:
    pass
")
      agent2_loc=$(python3 -c "
import json
try:
    data = json.load(open('$OPTIMIZATION_OUTPUT'))
    for item in data:
        if item['level'].endswith('$level_name.txt'):
            print(item['agent2_location'])
            break
except:
    pass
")
      
      if [[ -n "$agent1_loc" && -n "$agent2_loc" ]]; then
        echo "python3 gym-cooking/gym_cooking/main.py --level \"$level_file\" --num-agents 0 --record --layout --output-prefix \"${LAYOUT_ROOT}\" --num-start-locations 2 --start-location-model1 \"$agent1_loc\" --start-location-model2 \"$agent2_loc\"" >> "$TASKS_FILE"
      else
        echo "Warning: Could not find optimized start locations for $level_name, using auto-placement"
        echo "python3 gym-cooking/gym_cooking/main.py --level \"$level_file\" --num-agents 0 --record --layout --output-prefix \"${LAYOUT_ROOT}\" --num-start-locations 2" >> "$TASKS_FILE"
      fi
    else
      echo "Warning: Optimization results not found, using auto-placement for $level_name"
      echo "python3 gym-cooking/gym_cooking/main.py --level \"$level_file\" --num-agents 0 --record --layout --output-prefix \"${LAYOUT_ROOT}\" --num-start-locations 2" >> "$TASKS_FILE"
    fi
  else
    # Trials 19-36: Use auto-placement
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
