# SDDM setup

This machine uses SDDM for the login/session picker and Hyprland after login.
They are configured separately:

- SDDM runs as a system service before `martin` logs in.
- The current SDDM greeter is Xorg-based, so Hyprland `monitor=` rules do not
  affect the login screen.
- Hyprland reads the ML4W dotfiles after login, including
  `~/.config/hypr/monitors.conf`.

## Current Hyprland monitor layout

From `~/dotfiles/hypr/monitors.conf`:

```conf
monitor=HDMI-A-1,2560x1440@58.95,2560x0,1.0
monitor=HDMI-A-1,transform,1
monitor=DP-1,2560x1440@279.95,0x455,1.0
```

The matching SDDM/Xorg layout is encoded in `sddm-xsetup` using `xrandr`.
Because Xorg may name outputs differently than Hyprland, the script tries the
Hyprland names first and then common Xorg alternatives. The portrait monitor
uses `xrandr --rotate left`, which matches the physical orientation at the
SDDM greeter even though Hyprland stores it as `transform,1`.

## Apply

Run from this repo:

```sh
sudo pacman -S --needed xorg-xrandr
sudo ./sddm/apply-ml4w-sddm.sh
```

The apply script installs the ML4W SDDM theme to
`/usr/share/sddm/themes/ml4w`, enables it in `/etc/sddm.conf`, enables the
Qt virtual keyboard, and hooks `/usr/share/sddm/scripts/Xsetup` so SDDM uses
the real monitor layout before drawing the greeter. It also tunes the theme
with the current ML4W color palette and syncs the current wallpaper.

`sync-wallpaper.sh` copies the current ML4W wallpaper into the SDDM theme as
`backgrounds/ml4w.jpg`. Re-run it after changing wallpapers if you want the
login screen to follow.

## Important

Restarting SDDM kills the current graphical session. To test without surprise,
reboot, or switch to a TTY and then run:

```sh
sudo systemctl restart sddm
```
