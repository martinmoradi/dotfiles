#!/usr/bin/env bash
# hyprpm-autoupdate.sh — rebuild Hyprland plugins after a Hyprland upgrade.
#
# Why this is a startup script and NOT a pacman hook:
#   `hyprpm update` must run AS THE USER, inside a live Hyprland session — it
#   builds the plugins against your $HOME and then `hyprpm reload`s them into the
#   running compositor. A PostTransaction pacman hook runs as root with no
#   graphical session, so it can do neither (and can leave root-owned files in
#   your hyprpm dir). Instead we detect a Hyprland version change on startup and
#   rebuild then — the only moment the new Hyprland is actually running.
#
# Wired up via `exec-once` in hypr/custom.conf. Idempotent: does nothing unless
# the installed Hyprland package version differs from the last one handled.
set -u

state="${XDG_STATE_HOME:-$HOME/.local/state}/hyprpm-handled"

cur="$(pacman -Q hyprland 2>/dev/null)" || exit 0
[ -n "$cur" ] || exit 0

last="$(cat "$state" 2>/dev/null || true)"
[ "$cur" = "$last" ] && exit 0   # this version already handled — nothing to do

_notify() { command -v notify-send >/dev/null 2>&1 && notify-send -a hyprpm "$@"; }

_notify "Hyprland updated" "Rebuilding plugins (hyprpm update)…"

if hyprpm update; then
    hyprpm reload
    mkdir -p "$(dirname "$state")"
    printf '%s\n' "$cur" > "$state"
    _notify "Hyprland plugins" "Rebuilt and reloaded ✓"
else
    _notify -u critical "Hyprland plugins" "hyprpm update failed — run 'hyprpm update' manually"
fi
