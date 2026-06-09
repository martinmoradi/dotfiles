#!/usr/bin/env bash
# clip-smart-paste.sh — image-aware Ctrl+V for terminal AI CLIs.
#
# Bound to Ctrl+V in kitty/custom.conf via:
#   map ctrl+v launch --type=background --allow-remote-control ~/.local/bin/clip-smart-paste.sh
# The --allow-remote-control flag hands this process a private kitty control
# socket (KITTY_LISTEN_ON), so it can trigger kitty's own paste action.
#
#   Clipboard holds an IMAGE -> save it under ~/.cache/clip-images and type the
#       file path (Claude Code / Codex read images by path). We sleep first so
#       Ctrl is released before wtype runs — otherwise the path's chars are
#       injected as Ctrl+<char> control codes (e.g. the 'c' in ".cache" would be
#       Ctrl+C / SIGINT).
#   Clipboard holds TEXT -> trigger kitty's native bracketed paste, so multiline
#       text arrives as a single paste instead of one Enter-terminated line each.
#
# Needs: wl-clipboard, wtype, kitty (remote control via the launch flag above).
set -uo pipefail

types=$(wl-paste --list-types 2>/dev/null || true)

# Prefer an image if one is present (the screenshot-paste workflow).
if   printf '%s\n' "$types" | grep -qx 'image/png';  then mime=image/png;  ext=png
elif printf '%s\n' "$types" | grep -qx 'image/jpeg'; then mime=image/jpeg; ext=jpg
else mime=""; fi

if [ -n "$mime" ]; then
    dir="$HOME/.cache/clip-images"
    mkdir -p "$dir"
    # Drop images older than 7 days so the cache can't grow forever.
    find "$dir" -maxdepth 1 -type f -mtime +7 -delete 2>/dev/null || true
    file="$dir/$(date +%Y%m%d-%H%M%S).$ext"
    wl-paste --type "$mime" > "$file"
    # Wait for Ctrl to release before injecting the path (see header).
    sleep 0.12
    wtype "$file "
    exit 0
fi

# Text (or anything non-image): kitty's bracketed paste, which is multiline-safe.
kitty @ action paste_from_clipboard
