# Dotfiles

Personal Linux workstation config and local tooling.

This started as a place to back up dotfiles. It now owns the custom layer that
sits on top of the machine: Hyprland/ML4W tweaks, Waybar modules, shell and
terminal config, package snapshots, Project Hub, and the scripts that deploy or
sync that state.

## Daily Commands

`dot` is the front door. Run `./dot` from the repo the first time; it installs
itself to `~/.local/bin/dot`, so after one deploy plain `dot` works anywhere.

```bash
dot              # interactive UI: tabs + checkboxes + drift markers
dot status       # what has drifted between repo and machine
dot deploy       # apply everything (dot deploy hypr waybar for a subset)
dot deploy --dry-run
dot snapshot     # capture machine drift back into the repo
dot sync         # snapshot, commit, and push
```

- `dot status` / `dot diff [module]` show drift without changing anything.
- `dot deploy [modules...]` applies repo state; `--dry-run` previews it.
- The old entrypoints still work: `./deploy.sh` and `./snapshot.sh` are thin
  shims for `dot deploy` / `dot snapshot`, and `dot sync` calls `dotfiles-sync`.

## Repo Map

- `hypr/` - Hyprland custom config, idle/display policy, desktop reload, screenshots, clipboard image helpers.
- `waybar/` - shared Waybar module overrides used by deploy-time patching.
- `project-hub/` - project registry, Quickshell UI, Waybar modules, watcher, and Dev Stacks backend.
- `kitty/` - Kitty config and custom tab bar.
- `vscode/` - VS Code user settings and extension snapshot.
- `npm/` - tracked npm global package specs for `dot npm`.
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
installed pacman packages, VS Code extensions, and monitor layout. Capture those
with `dot snapshot` before committing. Npm globals are managed explicitly with
`dot npm ...`.

## Project Hub

Project Hub is the main custom workflow in this repo. It discovers projects
under `~/src/pro` and `~/src/perso`, keeps a current-project registry, exposes
Waybar state, and uses the bundled Dev Stacks backend for per-project infra
controls.

The source lives in `project-hub/`. The Quickshell install targets remain
`~/.config/quickshell-projects` and `~/.config/quickshell-containers` for
compatibility.
