#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Deploying from $DOTFILES ..."

# Hyprland custom config
cp "$DOTFILES/hypr/custom.conf" "$HOME/.config/hypr/conf/custom.conf"
echo "  -> hypr/conf/custom.conf"

# Hyprland plugin auto-rebuild script (run via exec-once in custom.conf)
mkdir -p "$HOME/.local/bin"
cp "$DOTFILES/hypr/hyprpm-autoupdate.sh" "$HOME/.local/bin/hyprpm-autoupdate.sh"
chmod +x "$HOME/.local/bin/hyprpm-autoupdate.sh"
echo "  -> ~/.local/bin/hyprpm-autoupdate.sh"

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

echo ""
echo "Done. To apply changes:"
echo "  - Hyprland: Super+Shift+R to reload config (or hyprctl reload)"
echo "  - Waybar:   Super+Shift+B to reload (or killall waybar && ~/.config/waybar/launch.sh &)"
echo "  - Kitty:    restart the terminal manually"
