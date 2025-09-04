#!/usr/bin/env bash
#SBATCH --job-name=overcooked-one
#SBATCH --output=$SCRATCH/design-inference/s1_design_inference/logs/%x.%j.out
#SBATCH --error=$SCRATCH/design-inference/s1_design_inference/logs/%x.%j.err
#SBATCH --partition=dev
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G

set -euo pipefail

# ----- Modules (robust) -----
source /share/software/user/open/lmod/lmod/init/bash
module --ignore_cache purge
module --ignore_cache load python/3.9.0

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

INDEX="${INDEX:?Set INDEX (1-based), e.g., sbatch --export=INDEX=5 code/bash/s1_design_inference/run_one_task.slurm}"

mkdir -p "$OUTDIR" "$OUTDIR/logs"
cd "$PROJECT_DIR"

CMD="$(sed -n "${INDEX}p" "$TASKS_FILE")"
if [[ -z "${CMD:-}" ]]; then
  echo "No command for index $INDEX" >&2
  exit 1
fi

echo "Running [INDEX=$INDEX]: $CMD"
srun --export=ALL /bin/bash -c "$CMD"