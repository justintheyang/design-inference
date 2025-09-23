#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
EXP="${EXP:-s1_design_inference}"
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/code/bash/${EXP}/tasks.txt}"
SEEDS="${SEEDS:-20}"   # override via: SEEDS=50 code/bash/s1_design_inference/gen_tasks.sh
OUTDIR="${OUTDIR:-$SCRATCH/design-inference/${EXP}}"   # <- write results to SCRATCH
CACHE_FILE="${PROJECT_DIR}/code/bash/${EXP}/start_location_cache.json"

# --- Lmod / Python module (robust) ---
source /share/software/user/open/lmod/lmod/init/bash
module --ignore_cache purge
module --ignore_cache load python/3.9.0 || module --ignore_cache load python/3.12.1

# User-site visibility
export PATH="$HOME/.local/bin:$PATH"
PY_USER_SITE="$(python3 -c 'import site; print(site.getusersitepackages())')"
export PYTHONPATH="${PY_USER_SITE}:${PYTHONPATH-}"

# Headless graphics
export SDL_VIDEODRIVER=dummy
export MPLBACKEND=Agg

cd "$PROJECT_DIR"

ORCH="code/python/${EXP}/model_runs.py"
if [[ ! -f "$ORCH" ]]; then
  echo "ERROR: Orchestrator not found: $ORCH" >&2
  exit 1
fi

mkdir -p "$(dirname "$TASKS_FILE")" "$OUTDIR"

# Clear cache file to ensure fresh optimization
rm -f "$CACHE_FILE"

echo "[gen] building task list → $TASKS_FILE"

# First, generate the base task list
python3 "$ORCH" --seeds "$SEEDS" --jobs 1 --dry-run \
|| awk '/^DRY-RUN:/{sub(/^DRY-RUN:[ ]*/,""); print}' \
|| sed 's/^python[[:space:]]/python3 /' \
|| awk -v outdir="$OUTDIR" '
  # replace the value that follows --output-dir with our SCRATCH path
  {
    for (i=1; i<=NF; i++) {
      if ($i=="--output-dir" && (i+1)<=NF) { $(i+1)=outdir }
    }
    print
  }
' > "${TASKS_FILE}.txt"

# Now process the task list to add optimal start locations for 2-agent tasks
echo "[gen] optimizing start locations for 2-agent tasks..."

# Extract unique level files from the task list
LEVELS=$(awk '
  {
    for (i=1; i<=NF; i++) {
      if ($i=="--level" && (i+1)<=NF) {
        print $(i+1)
        break
      }
    }
  }
' "${TASKS_FILE}.txt" | sort -u)

# Find optimal start locations for each level
for level_file in $LEVELS; do
  echo "  Optimizing: $level_file"
  python3 "${PROJECT_DIR}/code/bash/${EXP}/optimize_start_locations.py" \
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

# Now modify the task list to include optimal start locations for 2-agent tasks
python3 -c "
import json
import sys

# Load cache data
try:
    with open('$CACHE_FILE', 'r') as f:
        cache_data = json.load(f)
except:
    cache_data = []

# Create lookup dictionary
location_cache = {}
for item in cache_data:
    location_cache[item['level']] = {
        'agent1_location': item['agent1_location'],
        'agent2_location': item['agent2_location']
    }

# Process each line in the task file
with open('${TASKS_FILE}.txt', 'r') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
            
        # Check if this is a 2-agent task
        if '--num-agents 2' in line:
            # Extract level file
            parts = line.split()
            level_file = None
            for i, part in enumerate(parts):
                if part == '--level' and i + 1 < len(parts):
                    level_file = parts[i + 1]
                    break
            
            if level_file and level_file in location_cache:
                # Add start location arguments
                locs = location_cache[level_file]
                line += f' --start-location-model1 \"{locs[\"agent1_location\"]}\" --start-location-model2 \"{locs[\"agent2_location\"]}\"'
        
        print(line)
" > "$TASKS_FILE"

# Clean up temporary file
rm -f "${TASKS_FILE}.txt"

NLINES=$(wc -l < "$TASKS_FILE" || echo 0)
echo "[gen] wrote $NLINES tasks to $TASKS_FILE"
head -3 "$TASKS_FILE" 2>/dev/null || true