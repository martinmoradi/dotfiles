#!/usr/bin/env bash
set -euo pipefail

dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hook_src="$dotfiles/pacman/99-dotfiles-sync.hook.in"
hook_dst="/etc/pacman.d/hooks/99-dotfiles-sync.hook"
hook_tmp="$(mktemp)"
hook_exec="${HOME}/.local/bin/dotfiles-pacman-hook"

cleanup() {
    rm -f "$hook_tmp"
}
trap cleanup EXIT

mkdir -p "$(dirname "$hook_exec")"
ln -sf "$dotfiles/scripts/dotfiles-pacman-hook.sh" "$hook_exec"

sed "s|@HOOK_EXEC@|$hook_exec|g" "$hook_src" > "$hook_tmp"
sudo install -D -m 644 "$hook_tmp" "$hook_dst"
echo "Installed $hook_dst"
