#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  make_gifs_tree.sh <MODEL_EXP_DIR> [fps]

Arguments:
  <MODEL_EXP_DIR>  Path to model outputs (the folder that contains records/)
  [fps]     Frames per second (default: 2)

Output structure (created under <MODEL_EXP_DIR>/gifs/):
  gifs/
    trial_01/
      agents=*-model=*-recipe=*/
        seed=1.gif
        seed=2.gif
        ...

Notes:
  • Requires ffmpeg.
  • Expects frame files named like t=000.png, t=001.png, ...
USAGE
}

# --- args ---
if [[ ${1:-} == "-h" || ${1:-} == "--help" || $# -lt 1 ]]; then
  usage; exit 0
fi

MODEL_EXP_DIR="${1%/}"
FPS="${2:-2}"

command -v ffmpeg >/dev/null 2>&1 || { echo "Error: ffmpeg not found." >&2; exit 1; }
[[ -d "$MODEL_EXP_DIR/records" ]] || { echo "Error: '$MODEL_EXP_DIR/records' not found." >&2; exit 1; }

OUT_ROOT="$MODEL_EXP_DIR/gifs"
mkdir -p "$OUT_ROOT"

shopt -s nullglob

# Loop over trial folders like: trial_01-agents=1-model=greedy-recipe=Salad
for TRIAL_DIR in "$MODEL_EXP_DIR/records"/trial_*; do
  [[ -d "$TRIAL_DIR" ]] || continue
  TRIAL_BN="$(basename "$TRIAL_DIR")"

  # trial_01 | agents=1-model=greedy-recipe=Salad
  TRIAL_PREFIX="${TRIAL_BN%%-*}"
  CONFIG_PART="${TRIAL_BN#*-}"

  OUT_DIR="$OUT_ROOT/$TRIAL_PREFIX/$CONFIG_PART"
  mkdir -p "$OUT_DIR"

  # Each seed folder: seed=1, seed=2, ...
  for SEED_DIR in "$TRIAL_DIR"/seed=*; do
    [[ -d "$SEED_DIR" ]] || continue
    SEED_BN="$(basename "$SEED_DIR")"
    OUT_GIF="$OUT_DIR/$SEED_BN.gif"

    if [[ -f "$OUT_GIF" ]]; then
      echo "[skip] $OUT_GIF"
      continue
    fi

    # Build GIF from frames t=*.png at requested FPS with palettegen/paletteuse
    # Using glob (t=*.png); ordering is lexicographic -> t=000.png ... t=026.png
    if compgen -G "$SEED_DIR/t=*.png" > /dev/null; then
      ffmpeg -y -v error \
        -framerate "$FPS" -pattern_type glob -i "$SEED_DIR/t=*.png" \
        -vf "fps=${FPS},split[s0][s1];[s0]palettegen=stats_mode=diff[p];[s1][p]paletteuse=dither=sierra2_4a" \
        -loop 0 "$OUT_GIF"
      echo "[ok] $OUT_GIF"
    else
      echo "[warn] No frames in $SEED_DIR"
    fi
  done
done

echo "Done. Output root: $OUT_ROOT"