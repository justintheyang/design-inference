#!/usr/bin/env bash
# code/bash/run_model.sh

SESSION="overcooked_model_run"
ENV_NAME="design-overcooked"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."; pwd)"
LEVEL_DIR="$ROOT/stimuli/gym-cooking-levels"

# 1) create/attach tmux session
tmux has-session -t $SESSION 2>/dev/null || tmux new-session -d -s $SESSION

# 2) inside tmux: activate conda env
tmux send-keys -t $SESSION "conda deactivate" C-m
tmux send-keys -t $SESSION "conda activate $ENV_NAME" C-m
tmux send-keys -t $SESSION "cd $ROOT" C-m

# 3) in tmux: kick off parallel runs using the external script
tmux send-keys -t $SESSION "
JOBS=\$(sysctl -n hw.ncpu)
find \"$LEVEL_DIR\" -type f -name '*.txt' \\
  | xargs -n1 -P\$JOBS bash -c '$ROOT/code/bash/run_one.sh \"\$0\"'
" C-m

# 5) finally, attach so you can watch logs
tmux attach -t $SESSION
