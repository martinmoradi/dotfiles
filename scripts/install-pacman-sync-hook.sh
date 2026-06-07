#!/usr/bin/env bash
set -euo pipefail

dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hook_src="$dotfiles/pacman/99-dotfiles-sync.hook.in"
hook_dst="/etc/pacman.d/hooks/99-dotfiles-sync.hook"
hook_tmp="$(mktemp)"

cleanup() {
    rm -f "$hook_tmp"
}
trap cleanup EXIT

sed "s|@DOTFILES@|$dotfiles|g" "$hook_src" > "$hook_tmp"
sudo install -D -m 644 "$hook_tmp" "$hook_dst"
echo "Installed $hook_dst"
