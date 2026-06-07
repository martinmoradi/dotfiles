#!/usr/bin/env bash
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/clip-images"
mkdir -p "$cache_dir"

# Keep the terminal-friendly screenshot cache from growing forever.
find "$cache_dir" -maxdepth 1 -type f -name 'screenshot-*.png' -mtime +7 -delete 2>/dev/null || true

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Screenshot copied" "$1" 2>/dev/null || true
    fi
}

picker_pid=""
cleanup() {
    if [[ -n "$picker_pid" ]]; then
        kill "$picker_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Freeze the screen while selecting, matching ML4W's screenshot menu behavior.
if command -v hyprpicker >/dev/null 2>&1; then
    hyprpicker -r -z >/dev/null 2>&1 &
    picker_pid=$!
    sleep 0.1
fi

region="$(slurp -b "#00000080" -c "#888888ff" -w 1 || true)"
if [[ -z "$region" ]]; then
    exit 0
fi

cleanup
trap - EXIT

file="$cache_dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
grim -g "$region" "$file"

# The explicit MIME type is what makes paste targets recognize this as an image.
wl-copy --type image/png < "$file"
notify "Area copied to the clipboard."
