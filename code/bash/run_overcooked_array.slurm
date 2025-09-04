#!/usr/bin/env bash
#SBATCH --job-name=overcooked-arr
#SBATCH --output=logs/%x.%A_%a.out
#SBATCH --error=logs/%x.%A_%a.err
#SBATCH --partition=normal
#SBATCH --time=02:00:00           # up to 7d allowed on normal; adjust as needed
#SBATCH --cpus-per-task=1
#SBATCH --mem=6G

set -euo pipefail
echo "Array $SLURM_ARRAY_JOB_ID task $SLURM_ARRAY_TASK_ID on $SLURM_NODELIST"
date

# Sherlock Python 3.9 + user site
module purge; module load python/3.9
export PATH="$HOME/.local/bin:$PATH"
PY_USER_SITE="$(python3 -c 'import site; print(site.getusersitepackages())')"
export PYTHONPATH="$PY_USER_SITE:$PYTHONPATH"

# Headless + no BLAS oversub
export SDL_VIDEODRIVER=dummy
export MPLBACKEND=Agg
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/tasks.txt}"

# Scratch working dir per task (optional but good hygiene)
RUN_DIR="$SCRATCH/design-overcooked/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
mkdir -p "$RUN_DIR" "$PROJECT_DIR/logs"
rsync -a --delete --exclude='.git' --exclude='.gitmodules' --exclude='__pycache__' \
  "$PROJECT_DIR/" "$RUN_DIR/"
cd "$RUN_DIR"

# Pick the Nth command and run it
CMD="$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$TASKS_FILE")"
echo "Running: $CMD"
srun bash -lc "$CMD"

echo "Done"
date