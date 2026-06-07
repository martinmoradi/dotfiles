#!/usr/bin/env bash
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/clip-images"
mkdir -p "$cache_dir"

# Keep the terminal-friendly screenshot cache from growing forever.
find "$cache_dir" -maxdepth 1 -type f -name 'active-*.png' -mtime +7 -delete 2>/dev/null || true

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Screenshot copied" "$1" 2>/dev/null || true
    fi
}

file="$cache_dir/active-$(date +%Y%m%d-%H%M%S).png"

grimblast save active "$file" >/dev/null
wl-copy --type image/png < "$file"
notify "Active window copied to the clipboard."
