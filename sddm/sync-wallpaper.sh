#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "Run with sudo: sudo $0" >&2
    exit 1
fi

target_user="${SUDO_USER:-martin}"
target_home="$(getent passwd "$target_user" | cut -d: -f6)"

if [[ -z "$target_home" ]]; then
    echo "Could not find a home directory for user: $target_user" >&2
    exit 1
fi

wallpaper_file="${target_home}/.cache/ml4w/hyprland-dotfiles/current_wallpaper"
theme_background="/usr/share/sddm/themes/ml4w/backgrounds/ml4w.jpg"

if [[ ! -r "$wallpaper_file" ]]; then
    echo "No ML4W current wallpaper file found at: $wallpaper_file" >&2
    exit 1
fi

wallpaper="$(<"$wallpaper_file")"
if [[ ! -r "$wallpaper" ]]; then
    echo "Current wallpaper does not exist or is not readable: $wallpaper" >&2
    exit 1
fi

if [[ ! -d "$(dirname "$theme_background")" ]]; then
    echo "ML4W SDDM theme is not installed at /usr/share/sddm/themes/ml4w" >&2
    exit 1
fi

tmp="$(mktemp --suffix=.jpg)"
trap 'rm -f "$tmp"' EXIT

mime_type="$(file --mime-type -b "$wallpaper")"
case "$mime_type" in
    image/jpeg)
        cp "$wallpaper" "$tmp"
        ;;
    image/png)
        convert "$wallpaper" "$tmp"
        ;;
    *)
        echo "Unsupported wallpaper type for SDDM sync: $mime_type" >&2
        exit 1
        ;;
esac

install -m 0644 "$tmp" "$theme_background"
echo "Synced SDDM wallpaper from: $wallpaper"
