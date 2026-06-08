# Agent Notes

This repo is Martin's personal Linux workstation layer. Treat it as live
machine config plus custom local tools, not as a generic dotfiles template.

## Working Rules

- Work from `/home/martin/src/perso/dotfiles`.
- Keep project repos such as `/home/martin/src/pro/jukkai` out of dotfiles
  commits unless the user explicitly asks for a separate change there.
- Prefer editing repo files, then use `./deploy.sh` to apply them. Avoid
  hand-editing live files in `~/.config` unless the task is specifically to
  inspect or verify the deployed result.
- Preserve ML4W compatibility. Many Waybar and Hyprland changes are patches on
  top of ML4W-managed config, not full replacements.
- Do not commit package snapshot churn unless it is intentional.

## Important Commands

```bash
./deploy.sh
./snapshot.sh
python3 -m py_compile dev/scripts/dev-project dev/scripts/project-hub-watch scripts/patch-waybar-project-hub.py
bash -n deploy.sh containers/scripts/control.sh containers/scripts/state.sh containers/scripts/status.sh hypr/reload-desktop.sh
dev-project hub-state | python3 -m json.tool >/dev/null
```

## Structure

- `dev/` owns Project Hub UI, registry, Waybar modules, and watcher scripts.
- `containers/` remains the Podman/compose backend used by Project Hub.
- `scripts/` contains repo automation and deploy helpers.
- `deploy.sh` is the main repo-to-machine entrypoint.
- `snapshot.sh` is the machine-to-repo capture script.

Read `README.md` and `docs/repo-map.md` before larger structural changes.
