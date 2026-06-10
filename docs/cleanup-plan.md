# Cleanup Plan

The repo can stay named `dotfiles`, but its internal identity is now "personal
workstation layer." The cleanup direction is to make that explicit while keeping
deployment stable.

## Current Choice

Keep top-level folders that mirror familiar live config targets:

- `hypr/`
- `waybar/`
- `zsh/`
- `kitty/`
- `vscode/`
- `sddm/`

This keeps simple things simple. If a future task says "change Kitty" or
"change Hypr," the folder is obvious.

## What To Improve Next

The custom workflow now lives in `project-hub/`. That folder is the first
product-shaped area of the repo: it has a CLI, UI, Waybar integration, registry,
infra backend, and notifications.

1. Keep extracting deploy helpers when logic grows beyond plain file copies.
   `scripts/patch-waybar-project-hub.py` is the first example.
2. Consider splitting `deploy.sh` into install sections only if it starts
   gaining more real logic:
   - desktop shell
   - project hub
   - terminal/shell/editor
   - system sync
3. Keep `packages/` and `pacman/` separate. One is state, the other is install
   machinery.

## Candidate Future Shape

```text
project-hub/
  projects.json
  quickshell/
  scripts/
  waybar/
  containers/

desktop/
  hypr/
  waybar/
  sddm/
  sidepad/

terminal/
  zsh/
  kitty/

system/
  packages/
  pacman/
```

That is cleaner on paper, but it would make the repo less directly searchable by
the names of the live tools. Do that move only if the current top-level starts
feeling noisy in daily use.

## Rule Of Thumb

If a folder is mostly copied into an existing app's config directory, keeping it
at the top level is fine. If a folder is a custom product with its own CLI, UI,
state, and notifications, it deserves a named product folder.
