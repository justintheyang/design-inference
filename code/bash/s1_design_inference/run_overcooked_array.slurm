#!/usr/bin/env bash
#SBATCH --job-name=overcooked-arr
#SBATCH --output=/scratch/users/%u/design-inference/s1_design_inference/logs/%x.%A_%a.out
#SBATCH --error=/scratch/users/%u/design-inference/s1_design_inference/logs/%x.%A_%a.err
#SBATCH --partition=hns
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G

set -euo pipefail
echo "Array $SLURM_ARRAY_JOB_ID task $SLURM_ARRAY_TASK_ID on $SLURM_NODELIST"
date

# ----- Modules (robust) -----
source /share/software/user/open/lmod/lmod/init/bash
module --ignore_cache purge
module --ignore_cache load python/3.9.0 || module --ignore_cache load python/3.12.1

# ----- Python user-site visibility -----
export PATH="$HOME/.local/bin:$PATH"
PY_USER_SITE="$(python3 -m site --user-site)"
export PYTHONUSERBASE="$HOME/.local"
export PYTHONPATH="$PY_USER_SITE:${PYTHONPATH-}"
unset PYTHONNOUSERSITE

# ----- Headless + 1-threaded BLAS -----
export SDL_VIDEODRIVER=dummy
export MPLBACKEND=Agg
export SDL_AUDIODRIVER=dummy
export AUDIODRIVER=dummy
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

PROJECT_DIR="${PROJECT_DIR:-$HOME/src/design-inference}"
TASKS_FILE="${TASKS_FILE:-$PROJECT_DIR/code/bash/s1_design_inference/tasks.txt}"
OUTDIR="${OUTDIR:-$SCRATCH/design-inference/s1_design_inference}"

# ensure dirs
mkdir -p "$OUTDIR" "$OUTDIR/logs"
cd "$PROJECT_DIR"

# ----- Map array index → tasks.txt line via OFFSET -----
OFFSET="${OFFSET:-0}"
LINE_IDX=$(( SLURM_ARRAY_TASK_ID + OFFSET ))
CMD="$(sed -n "${LINE_IDX}p" "$TASKS_FILE")"
if [[ -z "${CMD:-}" ]]; then
  echo "No command for line $LINE_IDX (OFFSET=$OFFSET, TASK_ID=$SLURM_ARRAY_TASK_ID)" >&2
  exit 1
fi

echo "Running (line $LINE_IDX): $CMD"
srun --export=ALL /bin/bash -c "$CMD"

echo "Done"
date