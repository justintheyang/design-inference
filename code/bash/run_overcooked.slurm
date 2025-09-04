#!/usr/bin/env bash
#SBATCH --job-name=overcooked
#SBATCH --output=logs/%x.%j.out
#SBATCH --error=logs/%x.%j.err
#SBATCH --partition=normal
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G

set -euo pipefail

echo "Job $SLURM_JOB_ID on $SLURM_JOB_NODELIST"
date

# Load Sherlock Python 3.9
module purge
module load python/3.9

# Ensure user-installed packages and scripts are visible
export PATH="$HOME/.local/bin:$PATH"
PY_USER_SITE="$(python3 -c 'import site; print(site.getusersitepackages())')"
export PYTHONPATH="$PY_USER_SITE:$PYTHONPATH"

# Prevent oversubscription of BLAS libraries
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"
export MKL_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"
export OPENBLAS_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"

# Headless mode for pygame/matplotlib
export SDL_VIDEODRIVER=dummy
export MPLBACKEND=Agg

# Stage to SCRATCH for faster I/O (optional)
PROJECT_DIR="$HOME/src/design-inference"
RUN_DIR="$SCRATCH/design-overcooked/$SLURM_JOB_ID"
PY_SCRIPT="model_runs.py"
EXTRA_ARGS=""   # e.g., --level stimuli/s1_design_inference/txt/trial_01.txt --seed 1

mkdir -p "$RUN_DIR" "$PROJECT_DIR/logs"
rsync -a --delete \
  --exclude='.git' --exclude='.gitmodules' --exclude='__pycache__' \
  "$PROJECT_DIR/" "$RUN_DIR/"

cd "$RUN_DIR"

echo "Running: python3 $PY_SCRIPT $EXTRA_ARGS"
srun python3 "$PY_SCRIPT" $EXTRA_ARGS

echo "Done."
date