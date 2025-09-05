#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

usage() {
  cat <<'EOF'
Usage: get_layouts.sh --num-start-locations <1|2>

Options:
  --num-start-locations  Number of start locations to use (1 or 2). Required.
  -h, --help             Show this help and exit.
EOF
}

# Parse args
NUM_START_LOCATIONS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --num-start-locations)
      [[ $# -ge 2 ]] || { echo "Error: --num-start-locations requires a value." >&2; usage; exit 1; }
      NUM_START_LOCATIONS="$2"
      shift 2
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

# Validate required arg
if [[ -z "${NUM_START_LOCATIONS}" ]]; then
  echo "Error: --num-start-locations is required." >&2
  usage
  exit 1
fi
if [[ "${NUM_START_LOCATIONS}" != "1" && "${NUM_START_LOCATIONS}" != "2" ]]; then
  echo "Error: --num-start-locations must be 1 or 2." >&2
  exit 1
fi

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

export OVERCOOKED_RECORD_ROOT="$LAYOUT_ROOT"

# make sure output dir exists
mkdir -p "$LAYOUT_ROOT"

# iterate through each .txt file in STIMULI_ROOT
for level_file in "$STIMULI_ROOT"/*.txt; do
  # skip non-regular files (just in case)
  [[ -f "$level_file" ]] || continue

  echo "Recording layout for: $level_file"
  python gym-cooking/gym_cooking/main.py \
    --level "$level_file" \
    --num-agents 0 \
    --record \
    --layout \
    --output-prefix "${LAYOUT_ROOT}" \
    --num-start-locations "${NUM_START_LOCATIONS}"
done

# Restore the environment we started with
if [[ -n "$START_ENV" ]]; then
  conda activate "$START_ENV"
else
  # If we started with no env, ensure we end with no env
  conda deactivate || true
fi
