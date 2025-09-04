#!/usr/bin/env bash
#SBATCH --job-name=overcooked-one
#SBATCH --output=logs/%x.%j.out
#SBATCH --error=logs/%x.%j.err
#SBATCH --partition=dev
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G

set -euo pipefail

# --- Lmod / Python module (robust) ---
source /share/software/user/open/lmod/lmod/init/bash
module --ignore_cache purge
module --ignore_cache load python/3.9.0

# User-site packages first
export PATH="$HOME/.local/bin:$PATH"
PY_USER_SITE="$(python3 -m site --user-site)"
export PYTHONUSERBASE="$HOME/.local"              # <— add
export PYTHONPATH="$PY_USER_SITE:${PYTHONPATH-}"
unset PYTHONNOUSERSITE                            # <— add

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
rsync -a --delete --exclude='.git' --exclude='.gitmodules' --exclude='__pycache__' "$PROJECT_DIR/" "$RUN_DIR/"
cd "$RUN_DIR"

CMD="$(sed -n "${INDEX}p" "$TASKS_FILE")"
if [[ -z "${CMD:-}" ]]; then
  echo "No command for index $INDEX" >&2
  exit 1
fi

echo "Running [INDEX=$INDEX]: $CMD"
echo "PATH=$PATH"
command -v python3 || true
python3 -V || true
echo "PY_USER_SITE=$PY_USER_SITE"
echo "PYTHONPATH=$PYTHONPATH"
# sanity check *inside the same shell* that srun will use:
python3 - <<'PY'
import sys, site
print("preflight python:", sys.executable)
print("preflight user-site:", site.getusersitepackages())
print("preflight ENABLE_USER_SITE:", getattr(site, "ENABLE_USER_SITE", None))
try:
    import networkx as nx
    print("preflight networkx:", nx.__version__, nx.__file__)
except Exception as e:
    print("preflight networkx import FAILED:", e)
PY

# run the command through bash (no -l), preserving env
srun /bin/bash -c "$CMD"