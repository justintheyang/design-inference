#!/usr/bin/env bash
#SBATCH --job-name=overcooked-one
#SBATCH --output=logs/%x.%j.out
#SBATCH --error=logs/%x.%j.err
#SBATCH --partition=normal
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=6G

set -euo pipefail
module --force purge; module load python/3.9
export PATH="$HOME/.local/bin:$PATH"
PY_USER_SITE="$(python3 -c 'import site; print(site.getusersitepackages())')"
export PYTHONPATH="$PY_USER_SITE:$PYTHONPATH"
export SDL_VIDEODRIVER=dummy
export MPLBACKEND=Agg
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1

PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/tasks.txt}"
INDEX="${INDEX:?Set INDEX (1-based), e.g., sbatch --export=INDEX=5 code/bash/s1_design_inference/run_one_task.slurm}"

RUN_DIR="$SCRATCH/design-overcooked/test_$SLURM_JOB_ID"
mkdir -p "$RUN_DIR" "$PROJECT_DIR/logs"
rsync -a --delete --exclude='.git' --exclude='.gitmodules' --exclude='__pycache__' \
  "$PROJECT_DIR/" "$RUN_DIR/"
cd "$RUN_DIR"

CMD="$(sed -n "${INDEX}p" "$TASKS_FILE")"
echo "Running [INDEX=$INDEX]: $CMD"
srun bash -lc "$CMD"