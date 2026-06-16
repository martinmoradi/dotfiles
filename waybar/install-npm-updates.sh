#!/usr/bin/env bash
set -euo pipefail

terminal="$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/ml4w/settings/terminal.sh" 2>/dev/null || printf 'kitty')"
exec $terminal --class dotfiles-floating -e "$HOME/.local/bin/dot" npm terminal-update
