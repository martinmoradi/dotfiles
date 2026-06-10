# Repo Map

This repository is organized around the workstation it configures. Some folders
mirror live config targets, while others are local tools that get installed into
`~/.local/bin` or `~/.config`.

## Entrypoints

- `deploy.sh` - applies this repo to the live machine.
- `snapshot.sh` - captures selected live machine state back into this repo.
- `dotfiles-sync` - installed from `scripts/dotfiles-sync.sh`; snapshots,
  commits, and pushes.

## Desktop Shell

- `hypr/` - Hyprland custom config and helpers:
  - `custom.conf` is deployed to `~/.config/hypr/conf/custom.conf`.
  - `monitors.conf` is restored from snapshots.
  - helper scripts are installed into `~/.local/bin`.
- `waybar/` - shared Waybar module overrides used during deploy.
- `sddm/` - login-screen helper scripts and notes.
- `sidepad/` - patched sidepad config.

## Project Workflow

- `project-hub/` - Project Hub:
  - `projects.json` is the repo seed for the project registry.
  - `scripts/dev-project` is the CLI and Waybar state entrypoint.
  - `scripts/project-hub-watch` watches current-project infra and sends
    notifications on new non-protected trouble.
  - `quickshell/` is installed to `~/.config/quickshell-projects`.
  - `waybar/module.jsonc` defines the Project Hub Waybar modules.
  - `containers/scripts/state.sh` reads Podman/compose state.
  - `containers/scripts/control.sh` starts and stops projects or services.
  - `containers/` is still installed to `~/.config/quickshell-containers` for
    backend compatibility.

## Shell, Terminal, Editor

- `kitty/` - Kitty config plus paste/tab-bar helpers.
- `vscode/` - VS Code user settings and extension list.

## System State

- `packages/` - explicit pacman package and AUR snapshots.
- `pacman/` - pacman hook templates.
- `scripts/` - sync scripts, pacman hook installer, and deploy patch helpers.

## Generated Or Patched Live Targets

Deploy writes to:

- `~/.config/hypr/conf/custom.conf`
- `~/.config/hypr/monitors.conf`
- `~/.config/dev`
- `~/.config/quickshell-containers`
- `~/.config/quickshell-projects`
- `~/.config/waybar`
- `~/.config/kitty`
- `~/.config/Code/User`
- `~/.local/bin`

Deploy may also install a pacman hook when passwordless sudo is available.
