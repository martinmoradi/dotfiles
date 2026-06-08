#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/waybar-reload.log"
mkdir -p "$(dirname "$LOG_FILE")"

hyprctl reload

if [ -x "$HOME/.config/waybar/launch.sh" ]; then
    setsid -f "$HOME/.config/waybar/launch.sh" >"$LOG_FILE" 2>&1
else
    echo "Waybar launch script not found: $HOME/.config/waybar/launch.sh" >"$LOG_FILE"
fi
