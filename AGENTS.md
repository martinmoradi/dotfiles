# Agent Notes

This repo is Martin's personal Linux workstation layer. Treat it as live
machine config plus custom local tools, not as a generic dotfiles template.

## Working Rules

- Work from `/home/martin/src/perso/dotfiles`.
- Keep project repos such as `/home/martin/src/pro/jukkai` out of dotfiles
  commits unless the user explicitly asks for a separate change there.
- Prefer editing repo files, then use `dot deploy` (or `./deploy.sh`, now a
  shim) to apply them. Avoid hand-editing live files in `~/.config` unless the
  task is specifically to inspect or verify the deployed result.
- Preserve ML4W compatibility. Many Waybar and Hyprland changes are patches on
  top of ML4W-managed config, not full replacements.
- Do not commit package snapshot churn unless it is intentional.

## Important Commands

```bash
dot                 # interactive deploy/status TUI (no args)
dot status          # repo-vs-machine drift; dot diff [module] for line diffs
dot deploy          # apply repo state (dot deploy hypr waybar for a subset)
dot deploy --dry-run
dot snapshot        # capture machine drift into the repo
python3 -m py_compile dot project-hub/scripts/dev-project project-hub/scripts/project-hub-watch scripts/patch-waybar-project-hub.py
bash -n deploy.sh snapshot.sh project-hub/containers/scripts/control.sh project-hub/containers/scripts/state.sh project-hub/containers/scripts/status.sh hypr/reload-desktop.sh
dev-project hub-state | python3 -m json.tool >/dev/null
```

## Shell

- Login shell is **zsh**.
  Stock `~/.zshrc` (ML4W loader, do not edit) sources `~/.config/zshrc/*` in
  order; `~/.config/zshrc/custom/<name>` overrides the same-named stock file.
- Personal zsh config: `zsh/conf.d/50-martin` (env, history, keybindings,
  `EDITOR=micro`, the claude/codex sleep-inhibitor wrappers) and
  `zsh/custom/20-customization` (oh-my-zsh from `/usr/share/oh-my-zsh` via the
  `oh-my-zsh-git` pacman package, plus the plugin list). The large alias set
  comes from OMZ plugins (`git` plugin alone is ~200), not hand-written.

## Structure

- `project-hub/` owns Project Hub UI, registry, Waybar modules, watcher scripts,
  and the Podman/compose backend.
- `scripts/` contains repo automation and deploy helpers.
- `dot` is the front-door CLI/TUI: a module registry plus deploy, status, diff,
  snapshot, and sync. Run `./dot` from the repo; it self-installs to
  `~/.local/bin/dot` on first deploy.
- `deploy.sh` and `snapshot.sh` are thin shims that exec `dot deploy` / `dot
  snapshot`.

Read `README.md` and `docs/repo-map.md` before larger structural changes.
