#!/usr/bin/env bash
# clip-image-paste.sh — bridge a clipboard image into a terminal AI CLI.
#
# Terminals can't hand a raw clipboard bitmap to Claude Code / Codex; those
# tools read image *files by path*. So this saves whatever image is on the
# Wayland clipboard to a file under ~/.cache/clip-images, then types that
# file's path into the focused window (via wtype). Claude Code auto-detects
# the path and loads the image; for Codex, pass the printed path to --image.
#
# Bound to Super+Shift+V in hypr/custom.conf. Needs: wl-clipboard, wtype.
set -euo pipefail

dir="$HOME/.cache/clip-images"
mkdir -p "$dir"

# Auto-cleanup: drop images older than 7 days so the cache can't grow forever.
# (Runs before we save the new one, so today's paste is always safe.)
find "$dir" -maxdepth 1 -type f -mtime +7 -delete 2>/dev/null || true

# Pick the best available format on the clipboard (exact-match the MIME line).
types=$(wl-paste --list-types 2>/dev/null || true)
if   printf '%s\n' "$types" | grep -qx 'image/png';  then mime=image/png;  ext=png
elif printf '%s\n' "$types" | grep -qx 'image/jpeg'; then mime=image/jpeg; ext=jpg
else
    notify-send "Clipboard paste" "No image on the clipboard" 2>/dev/null || true
    exit 1
fi

file="$dir/$(date +%Y%m%d-%H%M%S).$ext"
wl-paste --type "$mime" > "$file"

# Type the path into the focused window (the terminal prompt). Trailing space,
# no Enter — so you can review/edit before sending.
wtype "$file "
