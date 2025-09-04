#!/usr/bin/env bash
#SBATCH --job-name=overcooked-one
#SBATCH --output=logs/%x.%j.out
#SBATCH --error=logs/%x.%j.err
#SBATCH --partition=normal
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=6G

set -euo pipefail

# --- Lmod / Python module (robust) ---
source /share/software/user/open/lmod/lmod/init/bash
module --ignore_cache purge
module --ignore_cache load python/3.9.0 || module --ignore_cache load python/3.12.1

# User-site packages first
export PATH="$HOME/.local/bin:$PATH"
PY_USER_SITE="$(python3 -c 'import site; print(site.getusersitepackages())')"
export PYTHONPATH="${PY_USER_SITE}:${PYTHONPATH-}"

# Headless + no BLAS oversub
export SDL_VIDEODRIVER=dummy
export MPLBACKEND=Agg
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/code/bash/s1_design_inference/tasks.txt}"
INDEX="${INDEX:?Set INDEX (1-based), e.g., sbatch --export=INDEX=5 code/bash/s1_design_inference/run_one_task.slurm}"

RUN_DIR="$SCRATCH/design-overcooked/test_$SLURM_JOB_ID"
mkdir -p "$RUN_DIR" "$PROJECT_DIR/logs"
rsync -a --delete \
  --exclude='.git' --exclude='.gitmodules' --exclude='__pycache__' \
  "$PROJECT_DIR/" "$RUN_DIR/"
cd "$RUN_DIR"

CMD="$(sed -n "${INDEX}p" "$TASKS_FILE")"
if [[ -z "${CMD:-}" ]]; then
  echo "No command for index $INDEX" >&2
  exit 1
fi

echo "Running [INDEX=$INDEX]: $CMD"
srun bash -lc "$CMD"