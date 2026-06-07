#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "Run with sudo: sudo $0" >&2
    exit 1
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
theme_dir="/usr/share/sddm/themes/ml4w"
target_user="${SUDO_USER:-martin}"
target_home="$(getent passwd "$target_user" | cut -d: -f6)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

if [[ -z "$target_home" ]]; then
    echo "Could not find a home directory for user: $target_user" >&2
    exit 1
fi

install -d "$theme_dir"

if [[ -d "${target_home}/.cache/ml4w-sddm-inspect/.git" ]]; then
    cp -a "${target_home}/.cache/ml4w-sddm-inspect/." "$theme_dir/"
else
    git clone --depth 1 https://github.com/mylinuxforwork/ml4w-sddm "$tmp_dir/ml4w-sddm"
    cp -a "$tmp_dir/ml4w-sddm/." "$theme_dir/"
fi

python - "$theme_dir/configs/ml4w.conf" "$target_home/.config/ml4w/colors/colors.json" <<'PY'
from configparser import ConfigParser
from pathlib import Path
import json
import sys

config_path = Path(sys.argv[1])
colors_path = Path(sys.argv[2])

colors = {
    "primary": "#b0c6ff",
    "primary_fixed": "#d9e2ff",
    "on_primary": "#142e60",
    "on_surface": "#e2e2e9",
    "surface": "#121318",
    "surface_container": "#1e1f25",
    "surface_container_high": "#282a2f",
    "outline": "#8f9099",
}
if colors_path.exists():
    colors.update(json.loads(colors_path.read_text()))

parser = ConfigParser(strict=False)
parser.optionxform = str
parser.read(config_path)

def set_value(section, key, value):
    if not parser.has_section(section):
        parser.add_section(section)
    parser[section][key] = str(value)

def q(value):
    return f'"{value}"'

set_value("General", "scale", "1.0")
set_value("General", "enable-animations", "true")
set_value("General", "background-fill-mode", q("fill"))

set_value("LockScreen", "background", q("ml4w.jpg"))
set_value("LockScreen", "blur", "28")
set_value("LockScreen", "brightness", "-0.15")
set_value("LockScreen", "saturation", "0.05")
set_value("LockScreen.Clock", "color", q(colors["primary"]))
set_value("LockScreen.Date", "color", q(colors["on_surface"]))
set_value("LockScreen.Message", "color", q(colors["on_surface"]))

set_value("LoginScreen", "background", q("ml4w.jpg"))
set_value("LoginScreen", "blur", "8")
set_value("LoginScreen", "brightness", "-0.18")
set_value("LoginScreen", "saturation", "0.02")

set_value("LoginScreen.LoginArea.Avatar", "active-border-size", "2")
set_value("LoginScreen.LoginArea.Avatar", "active-border-color", q(colors["primary"]))
set_value("LoginScreen.LoginArea.Username", "color", q(colors["on_surface"]))

set_value("LoginScreen.LoginArea.PasswordInput", "width", "240")
set_value("LoginScreen.LoginArea.PasswordInput", "height", "52")
set_value("LoginScreen.LoginArea.PasswordInput", "content-color", q(colors["on_surface"]))
set_value("LoginScreen.LoginArea.PasswordInput", "background-color", q(colors["surface_container"]))
set_value("LoginScreen.LoginArea.PasswordInput", "background-opacity", "0.72")
set_value("LoginScreen.LoginArea.PasswordInput", "border-size", "1")
set_value("LoginScreen.LoginArea.PasswordInput", "border-color", q(colors["primary"]))
set_value("LoginScreen.LoginArea.PasswordInput", "border-radius-left", "8")
set_value("LoginScreen.LoginArea.PasswordInput", "border-radius-right", "8")

set_value("LoginScreen.LoginArea.LoginButton", "background-color", q(colors["primary"]))
set_value("LoginScreen.LoginArea.LoginButton", "background-opacity", "0.85")
set_value("LoginScreen.LoginArea.LoginButton", "active-background-color", q(colors["primary_fixed"]))
set_value("LoginScreen.LoginArea.LoginButton", "active-background-opacity", "1.0")
set_value("LoginScreen.LoginArea.LoginButton", "content-color", q(colors["on_primary"]))
set_value("LoginScreen.LoginArea.LoginButton", "active-content-color", q(colors["on_primary"]))
set_value("LoginScreen.LoginArea.LoginButton", "border-radius-left", "8")
set_value("LoginScreen.LoginArea.LoginButton", "border-radius-right", "8")
set_value("LoginScreen.LoginArea.WarningMessage", "normal-color", q(colors["on_surface"]))
set_value("LoginScreen.LoginArea.WarningMessage", "warning-color", q(colors["primary"]))

set_value("LoginScreen.MenuArea.Popups", "background-color", q(colors["surface_container_high"]))
set_value("LoginScreen.MenuArea.Popups", "background-opacity", "0.88")
set_value("LoginScreen.MenuArea.Popups", "active-option-background-color", q(colors["primary"]))
set_value("LoginScreen.MenuArea.Popups", "active-option-background-opacity", "0.9")
set_value("LoginScreen.MenuArea.Popups", "content-color", q(colors["on_surface"]))
set_value("LoginScreen.MenuArea.Popups", "active-content-color", q(colors["on_primary"]))
set_value("LoginScreen.MenuArea.Popups", "border-size", "1")
set_value("LoginScreen.MenuArea.Popups", "border-color", q(colors["outline"]))

for section in (
    "LoginScreen.MenuArea.Session",
    "LoginScreen.MenuArea.Layout",
    "LoginScreen.MenuArea.Keyboard",
    "LoginScreen.MenuArea.Power",
):
    set_value(section, "background-color", q(colors["surface"]))
    set_value(section, "background-opacity", "0.18")
    set_value(section, "active-background-opacity", "0.85")
    set_value(section, "content-color", q(colors["on_surface"]))
    set_value(section, "active-content-color", q(colors["primary"]))

with config_path.open("w") as f:
    parser.write(f, space_around_delimiters=False)
PY

xsetup_backup=""
if [[ -f /usr/share/sddm/scripts/Xsetup ]]; then
    xsetup_backup="/usr/share/sddm/scripts/Xsetup.bak.$(date +%Y%m%d-%H%M%S)"
    cp -a /usr/share/sddm/scripts/Xsetup "$xsetup_backup"
fi
install -m 0755 "$repo_root/sddm/sddm-xsetup" /usr/share/sddm/scripts/Xsetup

if ! command -v xrandr >/dev/null 2>&1; then
    echo
    echo "Install xorg-xrandr so SDDM can apply the monitor layout:"
    echo "  sudo pacman -S --needed xorg-xrandr"
    echo
fi

backup="/etc/sddm.conf.bak.$(date +%Y%m%d-%H%M%S)"
if [[ -f /etc/sddm.conf ]]; then
    cp -a /etc/sddm.conf "$backup"
else
    : > /etc/sddm.conf
fi

python - <<'PY'
from configparser import ConfigParser
from pathlib import Path

path = Path("/etc/sddm.conf")
parser = ConfigParser(strict=False)
parser.optionxform = str
parser.read(path)

if not parser.has_section("Theme"):
    parser.add_section("Theme")
parser["Theme"]["Current"] = "ml4w"

if not parser.has_section("General"):
    parser.add_section("General")
parser["General"]["InputMethod"] = "qtvirtualkeyboard"
parser["General"]["GreeterEnvironment"] = (
    "QML2_IMPORT_PATH=/usr/share/sddm/themes/ml4w/components/,"
    "QT_IM_MODULE=qtvirtualkeyboard"
)

if not parser.has_section("X11"):
    parser.add_section("X11")
parser["X11"]["DisplayCommand"] = "/usr/share/sddm/scripts/Xsetup"

with path.open("w") as f:
    parser.write(f, space_around_delimiters=False)
PY

"$repo_root/sddm/sync-wallpaper.sh" || {
    echo "Could not sync the current wallpaper automatically; run sddm/sync-wallpaper.sh later."
}

echo "Installed and enabled the ML4W SDDM theme."
echo "Backed up the previous SDDM config to: $backup"
if [[ -n "$xsetup_backup" ]]; then
    echo "Backed up the previous SDDM Xsetup script to: $xsetup_backup"
fi
echo "Reboot, or restart sddm from a TTY, to see the login screen changes."
