# Dotfiles

Personal Linux workstation config and local tooling.

This started as a place to back up dotfiles. It now owns the custom layer that
sits on top of the machine: Hyprland/ML4W tweaks, Waybar modules, shell and
terminal config, package snapshots, Project Hub, and the scripts that deploy or
sync that state.

## Daily Commands

```bash
./deploy.sh
./snapshot.sh
dotfiles-sync --all
```

- `./deploy.sh` applies repo state to the live machine.
- `./snapshot.sh` captures drift from the live machine back into the repo.
- `dotfiles-sync --all` snapshots, commits, and pushes local state.

## Repo Map

- `hypr/` - Hyprland custom config, desktop reload, screenshots, clipboard image helpers.
- `waybar/` - shared Waybar module overrides used by deploy-time patching.
- `project-hub/` - project registry, Quickshell UI, Waybar modules, watcher, and Dev Stacks backend.
- `kitty/` - Kitty config and custom tab bar.
- `vscode/` - VS Code user settings and extension snapshot.
- `packages/` - package snapshots for restore or audit.
- `pacman/` - pacman hook templates for package snapshot sync.
- `scripts/` - repo automation and deploy helpers.
- `sddm/` - login-screen scripts and notes.
- `sidepad/` - patched sidepad config.

See `docs/repo-map.md` for the longer map and `docs/cleanup-plan.md` for the
current organization direction.

## Mental Model

The repo is the source of truth. Live config under `~/.config`, `~/.local/bin`,
and system hook locations is generated or patched from here.

The exception is machine state that naturally changes outside the repo:
installed packages, VS Code extensions, and monitor layout. Capture those with
`./snapshot.sh` before committing.

## Project Hub

Project Hub is the main custom workflow in this repo. It discovers projects
under `~/src/pro` and `~/src/perso`, keeps a current-project registry, exposes
Waybar state, and uses the bundled Dev Stacks backend for per-project infra
controls.

The source lives in `project-hub/`. The Quickshell install targets remain
`~/.config/quickshell-projects` and `~/.config/quickshell-containers` for
compatibility.
