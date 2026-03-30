#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Deploying from $DOTFILES ..."

# Hyprland custom config
cp "$DOTFILES/hypr/custom.conf" "$HOME/.config/hypr/conf/custom.conf"
echo "  -> hypr/conf/custom.conf"

# Kitty custom config
cp "$DOTFILES/kitty/custom.conf" "$HOME/.config/kitty/custom.conf"
echo "  -> kitty/custom.conf"

# Fish conf.d (only our 50-martin-* files, don't clobber ml4w's)
for f in "$DOTFILES"/fish/conf.d/*.fish; do
    cp "$f" "$HOME/.config/fish/conf.d/"
    echo "  -> fish/conf.d/$(basename "$f")"
done

# Sidepad: patched for multi-monitor absolute positioning
cp "$DOTFILES/sidepad/sidepad" "$HOME/.config/sidepad/sidepad"
chmod +x "$HOME/.config/sidepad/sidepad"
echo "  -> sidepad/sidepad"

# Waybar: patch workspace module in modules.json for split-monitor-workspaces
WAYBAR_MODULES="$HOME/.config/waybar/modules.json"
if [ -f "$WAYBAR_MODULES" ]; then
    python3 -c "
import json, re

# Read current modules.json (strip // comments for JSON parsing)
with open('$WAYBAR_MODULES') as f:
    text = f.read()
clean = re.sub(r'//.*', '', text)
# Handle trailing commas before } or ]
clean = re.sub(r',\s*([}\]])', r'\1', clean)
modules = json.loads(clean)

# Read override
with open('$DOTFILES/waybar/modules-workspace-override.jsonc') as f:
    text = f.read()
clean = re.sub(r'//.*', '', text)
clean = re.sub(r',\s*([}\]])', r'\1', clean)
override = json.loads(clean)

# Merge workspace module
modules['hyprland/workspaces'] = override['hyprland/workspaces']

# Write back (can't preserve comments, but functional)
# Back up original first
import shutil
shutil.copy2('$WAYBAR_MODULES', '$WAYBAR_MODULES.bak')

with open('$WAYBAR_MODULES', 'w') as f:
    json.dump(modules, f, indent=2)
"
    echo "  -> waybar/modules.json (workspace module patched, backup at modules.json.bak)"
fi

# Update hyprland plugin and reload
echo "Updating split-monitor-workspaces plugin..."
hyprpm update -n && echo "  -> hyprpm updated" || echo "  !! hyprpm update failed (may need sudo first time)"

echo "Reloading hyprland..."
hyprctl reload

echo "Restarting waybar..."
killall waybar 2>/dev/null; sleep 0.5
~/.config/waybar/launch.sh &

echo "Done. Restart kitty manually to apply terminal changes."
