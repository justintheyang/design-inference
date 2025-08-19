#!/usr/bin/env bash
set -euo pipefail

SESSION="overcooked_model_run"
ENV_NAME="design-overcooked"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."; pwd)"
LEVEL_DIR="$ROOT/stimuli/gym-cooking-levels"

# 1) Start tmux session if it doesn't exist
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux new-session -d -s "$SESSION"

  # 2) Inside tmux: set strict mode, activate conda, cd to project root
  tmux send-keys -t "$SESSION" "set -euo pipefail" C-m
  tmux send-keys -t "$SESSION" "conda activate $ENV_NAME" C-m
  tmux send-keys -t "$SESSION" "cd $ROOT" C-m


  # 3) Throttle intra‐job threading
  tmux send-keys -t "$SESSION" "export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1" C-m

  # 4) Compute number of parallel jobs (~80% of logical cores)
  tmux send-keys -t "$SESSION" "NCPU=\$(nproc); [[ \$NCPU -lt 2 ]] && NCPU=\$(nproc --all)" C-m

  tmux send-keys -t "$SESSION" "echo \$NCPU \$(nproc)" C-m
  tmux send-keys -t "$SESSION" "JOBS=\$(( NCPU * 8 / 10 ))" C-m
  tmux send-keys -t "$SESSION" "(( JOBS < 1 )) && JOBS=1" C-m

  # 5) Detect GPUs, default to 1 if none found
  tmux send-keys -t "$SESSION" "NGPU=\$(nvidia-smi --list-gpus 2>/dev/null | wc -l)" C-m
  tmux send-keys -t "$SESSION" "(( NGPU < 1 )) && NGPU=1" C-m
  # ——> **export** it so child shells see it
  tmux send-keys -t "$SESSION" "export NGPU" C-m

  # debug
  tmux send-keys -t "$SESSION" "echo '[DEBUG] NCPU='\$NCPU 'JOBS='\$JOBS 'NGPU='\$NGPU" C-m

  # 6) Build and dispatch the (level,seed) jobs
  tmux send-keys -t "$SESSION" "find \"$LEVEL_DIR\" -type f -name '*.txt' ! -name scratch.txt \\" C-m
  tmux send-keys -t "$SESSION" "  | while read -r lvl; do for seed in \$(seq 1 20); do echo \"\$lvl \$seed\"; done; done \\" C-m
  tmux send-keys -t "$SESSION" "  | xargs -n2 -P\"\$JOBS\" bash -c '\
lvl=\"\$1\"; \
seed=\"\$2\"; \
ngpu=\"\$3\"; \
gpu_id=\$(( (seed-1) % NGPU )); \
export CUDA_VISIBLE_DEVICES=\"\$gpu_id\"; \
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1; \
bash \"$ROOT/code/bash/run_one.sh\" \"\$lvl\" \"\$seed\"' _" C-m
fi

# 7) Attach so you can watch the logs
tmux attach -t "$SESSION"

