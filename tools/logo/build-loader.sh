#!/usr/bin/env bash
# Rebuilds the transparent logo animation for the loader from the client's 4K master.
# Usage: tools/logo/build-loader.sh path/to/KD_logo_animation_transparent_4K.webm
# Needs ffmpeg (with libvpx-vp9 and libx264) and Python 3 with Pillow and NumPy.
set -euo pipefail
SRC="$1"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/c" "$WORK/s"
# decode with alpha, crop to the logo, 1600 x 880
ffmpeg -hide_banner -loglevel error -c:v libvpx-vp9 -i "$SRC" -vf "crop=2560:1408:640:400,scale=1600:880:flags=lanczos" -pix_fmt rgba "$WORK/c/%04d.png"
# clean each frame and stack colour over transparency
(cd "$WORK" && python3 "$ROOT/tools/logo/clean.py")
# all 360 frames over 8 s, so nothing is dropped
ffmpeg -hide_banner -loglevel error -y -framerate 45 -i "$WORK/s/%04d.png" -c:v libx264 -pix_fmt yuv420p -preset slow -crf 18 -profile:v high -tune animation -movflags +faststart -an "$ROOT/assets/loader/KD_logo_animation_alpha_8s.mp4"
# the finished logo, for reduced motion and as a fallback
python3 -c "from PIL import Image; Image.open('$WORK/logo-last.png').save('$ROOT/assets/loader/KD_logo_last.webp', quality=92, method=6)"
echo "Wrote assets/loader/KD_logo_animation_alpha_8s.mp4 and KD_logo_last.webp"
