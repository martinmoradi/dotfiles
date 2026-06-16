# Repo Map

This repository is organized around the workstation it configures. Some folders
mirror live config targets, while others are local tools that get installed into
`~/.local/bin` or `~/.config`.

## Entrypoints

- `dot` - the front-door CLI/TUI (repo root). A module registry behind
  `deploy`, `status`, `diff`, `snapshot`, and `sync`. Run `dot` with no args
  for the interactive deploy UI. Self-installs to `~/.local/bin/dot` on first
  deploy via the `sync-hooks` module.
- `deploy.sh` - thin shim for `dot deploy`; applies this repo to the machine.
- `snapshot.sh` - thin shim for `dot snapshot`; captures selected live state.
- `dotfiles-sync` - installed from `scripts/dotfiles-sync.sh`; snapshots,
  commits, and pushes. `dot sync` execs it.

## Desktop Shell

- `hypr/` - Hyprland custom config and helpers:
  - `custom.conf` is deployed to `~/.config/hypr/conf/custom.conf`.
  - `hypridle.conf` disables automatic locking and powers displays down on idle.
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
- `npm/` - tracked npm global package specs used by `dot npm`.

## System State

- `packages/` - explicit pacman package and AUR snapshots.
- `pacman/` - pacman hook templates.
- `scripts/` - sync scripts, pacman hook installer, and deploy patch helpers.

## Generated Or Patched Live Targets

Deploy writes to:

- `~/.config/hypr/conf/custom.conf`
- `~/.config/hypr/hypridle.conf`
- `~/.config/hypr/monitors.conf`
- `~/.config/dev`
- `~/.config/quickshell-containers`
- `~/.config/quickshell-projects`
- `~/.config/waybar`
- `~/.config/kitty`
- `~/.config/Code/User`
- `~/.local/bin`

Deploy may also install a pacman hook when passwordless sudo is available.
