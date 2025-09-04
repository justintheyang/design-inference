#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  pngs2gif.sh -d <png_dir> [-r <fps>] [-s <start_frame>] [-e <end_frame>] [-o <output.gif>]

Options:
  -d   Directory containing frames like prefix_0.png, prefix_1.png, ...
  -r   Framerate (fps). Default: 2
  -s   Start frame number (inclusive). Default: min available
  -e   End frame number (inclusive).   Default: max available
  -o   Output GIF path. Default: <png_dir>/<basename(png_dir)>.gif

Notes:
  • Requires ffmpeg.
  • Frames are matched by *_<number>.png and sorted numerically.
USAGE
}

dir="" fps=2 start="" end="" out=""
while getopts ":d:r:s:e:o:h" opt; do
  case "$opt" in
    d) dir="$OPTARG" ;;
    r) fps="$OPTARG" ;;
    s) start="$OPTARG" ;;
    e) end="$OPTARG" ;;
    o) out="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage; exit 2 ;;
    :)  echo "Missing value for -$OPTARG" >&2; usage; exit 2 ;;
  esac
done

[[ -n "$dir" ]] || { echo "Error: -d <png_dir> is required." >&2; usage; exit 2; }
[[ -d "$dir" ]] || { echo "Error: directory not found: $dir" >&2; exit 1; }
command -v ffmpeg >/dev/null 2>&1 || { echo "Error: ffmpeg not found." >&2; exit 1; }

# Default output path
if [[ -z "$out" ]]; then
  base="$(basename "$dir")"
  out="$dir/${base}.gif"
fi

# Build "num<TAB>path" lines, sort numerically by num.
tmp_sorted="$(mktemp)"
cleanup() { rm -f "$tmp_sorted" "$listfile" 2>/dev/null || true; }
trap cleanup EXIT

# Find frames safely (handles spaces/newlines), extract numeric suffix via sed (portable on macOS).
abs_dir="$(cd "$dir" && pwd)"

find "$abs_dir" -maxdepth 1 -type f -name "*_[0-9]*.png" -print0 \
| while IFS= read -r -d '' f; do
    bn=${f##*/}  # filename only
    num="$(printf '%s\n' "$bn" | sed -n 's/.*_\([0-9][0-9]*\)\.png$/\1/p')"
    if [[ -n "$num" ]]; then
      printf '%s\t%s\n' "$num" "$f"
    fi
  done \
| LC_ALL=C sort -n -k1,1 > "$tmp_sorted"

# Filter by start/end (if provided) and emit ffmpeg concat list.
listfile="$(mktemp)"
frames_found=0
while IFS=$'\t' read -r num path; do
  # numeric filtering in shell (works on mac bash 3.2)
  if [[ -n "$start" ]] && (( num < start )); then continue; fi
  if [[ -n "$end"   ]] && (( num > end   )); then continue; fi
  printf "file '%s'\n" "$path" >> "$listfile"
  frames_found=$((frames_found + 1))
done < "$tmp_sorted"

if (( frames_found == 0 )); then
  echo "Error: No frames match *_<num>.png in range in '$dir'." >&2
  exit 1
fi

# High-quality GIF (palettegen/paletteuse). Keep requested FPS.
ffmpeg -y -v error \
  -r "$fps" -f concat -safe 0 -i "$listfile" \
  -vf "fps=${fps},split[s0][s1];[s0]palettegen=stats_mode=diff[p];[s1][p]paletteuse=dither=sierra2_4a" \
  "$out"

echo "Done: $out"
