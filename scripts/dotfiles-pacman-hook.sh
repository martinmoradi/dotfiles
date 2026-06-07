#!/usr/bin/env bash
set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "$script_dir/.." && pwd)"
sync_script="$script_dir/dotfiles-sync.sh"

repo_owner="$(stat -c %U "$repo_dir" 2>/dev/null || printf '%s' "${SUDO_USER:-}")"
sync_user="${DOTFILES_SYNC_USER:-$repo_owner}"

if [[ -z "$sync_user" || ! -x "$sync_script" ]]; then
    exit 0
fi

home_dir="$(getent passwd "$sync_user" | cut -d: -f6)"
uid="$(id -u "$sync_user" 2>/dev/null || true)"

run_as_user() {
    if [[ -n "$uid" && -S "/run/user/$uid/bus" ]] && command -v systemd-run >/dev/null 2>&1; then
        local unit="dotfiles-sync-pacman-$(date +%s)-$$"
        runuser -u "$sync_user" -- env \
            HOME="$home_dir" \
            XDG_RUNTIME_DIR="/run/user/$uid" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
            systemd-run --user --quiet --collect --unit="$unit" \
            "$sync_script" --packages-only --source pacman
        return $?
    fi

    runuser -u "$sync_user" -- env HOME="$home_dir" \
        "$sync_script" --packages-only --source pacman
}

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    run_as_user >/dev/null 2>&1 || true
else
    "$sync_script" --packages-only --source pacman >/dev/null 2>&1 || true
fi

exit 0
