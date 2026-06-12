#!/usr/bin/env bash
set -euo pipefail

# Temporary escape hatch for Hyprland releases where split-monitor-workspaces
# has not caught up yet. This patches only live config. Run the normal dotfiles
# deploy again once the plugin is updated.

HYPR_CONF="${HYPR_CONF:-$HOME/.config/hypr/conf/custom.conf}"
WAYBAR_MODULES="${WAYBAR_MODULES:-$HOME/.config/waybar/modules.json}"
STAMP="$(date +%Y%m%d-%H%M%S)"

backup_file() {
    local path="$1"
    if [ -f "$path" ]; then
        cp -p "$path" "$path.split-workspaces-disabled.$STAMP.bak"
        echo "  -> backup: $path.split-workspaces-disabled.$STAMP.bak"
    fi
}

if [ ! -f "$HYPR_CONF" ]; then
    echo "Hyprland custom config not found: $HYPR_CONF" >&2
    exit 1
fi

if [ ! -f "$WAYBAR_MODULES" ]; then
    echo "Waybar modules file not found: $WAYBAR_MODULES" >&2
    exit 1
fi

backup_file "$HYPR_CONF"
backup_file "$WAYBAR_MODULES"

python3 - "$HYPR_CONF" "$WAYBAR_MODULES" <<'PY'
import json
import re
import sys
from pathlib import Path

hypr_path = Path(sys.argv[1]).expanduser()
waybar_path = Path(sys.argv[2]).expanduser()

hypr = hypr_path.read_text()

hypr = re.sub(
    r"# ----- Split monitor workspaces -----\n.*?(?=# ----- Keybinding overrides -----)",
    """# ----- Split monitor workspaces disabled -----\n"""
    """# Temporarily disabled by disable-hyprland-split-workspaces.sh.\n"""
    """# Run ~/src/perso/dotfiles/deploy.sh to restore the plugin setup.\n\n""",
    hypr,
    flags=re.S,
)

regular_binds = """# --- Workspace keybinds (fallback while split-monitor-workspaces is disabled) ---

# Unbind all default workspace binds
unbind = $mainMod, 1
unbind = $mainMod, 2
unbind = $mainMod, 3
unbind = $mainMod, 4
unbind = $mainMod, 5
unbind = $mainMod, 6
unbind = $mainMod, 7
unbind = $mainMod, 8
unbind = $mainMod, 9
unbind = $mainMod, 0
unbind = $mainMod SHIFT, 1
unbind = $mainMod SHIFT, 2
unbind = $mainMod SHIFT, 3
unbind = $mainMod SHIFT, 4
unbind = $mainMod SHIFT, 5
unbind = $mainMod SHIFT, 6
unbind = $mainMod SHIFT, 7
unbind = $mainMod SHIFT, 8
unbind = $mainMod SHIFT, 9
unbind = $mainMod SHIFT, 0
unbind = $mainMod, Tab
unbind = $mainMod SHIFT, Tab
unbind = $mainMod, mouse_down
unbind = $mainMod, mouse_up
unbind = $mainMod CTRL, down
unbind = $mainMod CTRL, 1
unbind = $mainMod CTRL, 2
unbind = $mainMod CTRL, 3
unbind = $mainMod CTRL, 4
unbind = $mainMod CTRL, 5
unbind = $mainMod CTRL, 6
unbind = $mainMod CTRL, 7
unbind = $mainMod CTRL, 8
unbind = $mainMod CTRL, 9
unbind = $mainMod CTRL, 0

# Switch to workspace
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10
bind = $mainMod, Tab, workspace, m+1
bind = $mainMod SHIFT, Tab, workspace, m-1
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move window to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

"""

hypr = re.sub(
    r"# --- Workspace keybinds .*?\n.*?(?=# ----- Window rules -----)",
    regular_binds,
    hypr,
    flags=re.S,
)

hypr_path.write_text(hypr)

modules = json.loads(waybar_path.read_text())
modules["hyprland/workspaces"] = {
    "on-scroll-up": "hyprctl dispatch workspace r-1",
    "on-scroll-down": "hyprctl dispatch workspace r+1",
    "on-click": "activate",
    "active-only": False,
    "all-outputs": True,
    "format": "{}",
    "format-icons": {
        "urgent": "",
        "active": "",
        "default": "",
    },
    "persistent-workspaces": {
        "*": 5,
    },
}
waybar_path.write_text(json.dumps(modules, indent=2) + "\n")
PY

echo "  -> disabled split-monitor-workspaces Hyprland config"
echo "  -> restored Waybar workspaces to regular Hyprland dispatches"

if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload || true
    echo "  -> hyprctl reload"
fi

LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/waybar-reload.log"
mkdir -p "$(dirname "$LOG_FILE")"
if [ -x "$HOME/.config/waybar/launch.sh" ]; then
    setsid -f "$HOME/.config/waybar/launch.sh" >"$LOG_FILE" 2>&1
    echo "  -> restarted Waybar (log: $LOG_FILE)"
else
    pkill waybar >/dev/null 2>&1 || true
    setsid -f waybar >"$LOG_FILE" 2>&1 || true
    echo "  -> restarted Waybar directly (log: $LOG_FILE)"
fi

echo ""
echo "Done. To restore split workspaces later, run:"
echo "  ~/src/perso/dotfiles/deploy.sh"
