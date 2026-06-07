#!/usr/bin/env bash
set -euo pipefail

# Give the key release a moment before synthesizing input back into Kitty.
sleep 0.08

types="$(wl-paste --list-types 2>/dev/null || true)"

if printf '%s\n' "$types" | grep -Eqx 'image/(png|jpeg)'; then
    exec "${HOME}/.local/bin/clip-image-paste.sh"
fi

if printf '%s\n' "$types" | grep -Eqx 'text/(plain|plain;charset=utf-8)|UTF8_STRING|STRING'; then
    wl-paste --no-newline | wtype -
    exit 0
fi

notify-send "Clipboard paste" "No pasteable text or image on the clipboard" 2>/dev/null || true
