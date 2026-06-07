Dev Stacks — a per-project infra pulse for Waybar + Quickshell

Context

The need started small: "see at a glance if my dev DB is up, and click to bring it up instead of typing db:up." Codex
turned that into a full Podman-Desktop clone with fragile patching of ML4W's own files. We deliberately walked it back
to the genuinely useful, nicely-designed core:

- The unit is a project's infra, not a container. "Play" = bring up a project's infra; the app you develop is run native
  in a terminal and is never touched.
- No conventions imposed on any repo. "Play" = plain podman compose up -d, which respects each repo's own defaults
  (profiles, deps). Your own jukkai/compose.yaml already gates studio-api behind profiles: [studio-api], so compose up
  already starts postgres only — automatically correct, and equally correct for repos you pull (where the full default
  stack is what you want).
- No hacking into ML4W. The popover is its own Quickshell instance living in our dotfiles — the exact pattern ML4W
  itself uses for overview (qs -p …/overview). ML4W's shell.qml and theme QML are never touched.
- It must look and feel native to the ML4W desktop (same glass chrome, same slide animation, same theme colors that
  track the wallpaper).

Outcome: a small bar indicator 󰡨 jukkai ● (green = healthy, red = trouble) that opens a calm, themed popover listing
your projects — play/pause per stack, auto-expanding whatever's unhealthy. Right-click escapes to podman-desktop for the
rare surgery.

Architecture

Two pieces, two deploy mechanisms — and only one small, supported touch into ML4W's config.

┌───────────────────────────────┬──────────────────────────┬────────────────────────────────────────────────────────┐
│ Piece │ What it is │ Deploy mechanism │
├───────────────────────────────┼──────────────────────────┼────────────────────────────────────────────────────────┤
│ Quickshell popover + helper │ files we own │ cp -r a folder + an exec-once line in our own │
│ scripts │ │ hypr/custom.conf │
├───────────────────────────────┼──────────────────────────┼────────────────────────────────────────────────────────┤
│ Waybar bar item │ 1 module def + 1 layout │ idempotent JSON merge in deploy.sh (same pattern it │
│ │ entry │ already uses) │
└───────────────────────────────┴──────────────────────────┴────────────────────────────────────────────────────────┘

The popover runs as a separate qs instance (qs -p ~/.config/quickshell-containers), so it cannot break on ML4W updates
and needs zero edits to ML4W's shell.qml. The bar click targets our instance explicitly: qs -p
~/.config/quickshell-containers ipc call containers toggle.

Source layout (new folder in ~/dotfiles)

~/dotfiles/containers/
shell.qml # ShellRoot { ContainersWindow {} } — our instance root
ContainersWindow.qml # the popover panel (PanelWindow + IpcHandler target:"containers")
Theme.qml # singleton; reads ~/.config/ml4w/colors/colors.json (auto-matches theme)
scripts/
status.sh # → Waybar JSON: bar face (current project + health dot) + tooltip
state.sh # → full grouped JSON for the panel (projects → services → state)
control.sh # up|stop|service-up|service-stop|desktop <project> [service]
waybar/module.jsonc # the custom/containers definition, for the deploy merge

Deploy targets (extend ~/dotfiles/deploy.sh)

- cp -r ~/dotfiles/containers → ~/.config/quickshell-containers/ (a real dir we own, NOT inside ML4W's symlinked
  ~/.config/quickshell).
- Autostart: add exec-once = qs -p ~/.config/quickshell-containers to ~/dotfiles/hypr/custom.conf (we already own &
  deploy this file — no patch).
- Waybar module def: extend the existing Python merge (deploy.sh:55-83) to also set modules['custom/containers'] = <our
  def>. Idempotent.
- Bar placement: insert "custom/containers" into modules-right of the active theme config
  (~/.config/waybar/themes/ml4w-glass-center/config) and ideally all themes/\*/config for theme-switch resilience — guarded
  so re-running doesn't duplicate.
- Backups: snapshot each ML4W-owned file we touch once (only if no .bak exists) — improving on deploy.sh's current
  overwrite-the-backup behavior (deploy.sh:79).

The engine (helper scripts)

Discovery from podman ps -a --format json:

- Group by label com.docker.compose.project; service name from com.docker.compose.service; project dir from
  com.docker.compose.project.working_dir (e.g. /home/martin/work/clients/jukkai/repo).
- Per-service state from the JSON: running = State=="running"; healthy/starting/unhealthy parsed from the Status string
  (healthy) / (starting) / (unhealthy); crashed = State=="exited" && ExitCode != 0 (this is exactly your studio-api
  exit 137); stopped = exited 0.
- Project health = aggregate of its services (green only if all up & healthy; red if any crashed/unhealthy; amber if any
  starting).

Actions (control.sh), all run detached, no terminal needed:

- Play: cd <working_dir> && podman compose up -d (respects profiles → infra-only on jukkai).
- Pause: cd <working_dir> && podman compose stop (gentle: keeps containers + volumes; not down).
- Per-service (expanded rows): podman compose up -d <svc> / podman compose stop <svc>.
- Desktop: podman-desktop.
- On every action, write ~/.cache/dev-stacks/last-project (the bar's "face") and pkill -RTMIN+<N> waybar to refresh the
  bar instantly.

Discovery boundary (documented behaviour, not a bug): a project appears once it has containers (created by at least one
compose up); a freshly-pulled, never-started repo won't show until its first up.

Waybar module (custom/containers)

"custom/containers": {
"exec": "~/.config/quickshell-containers/scripts/status.sh",
"return-type": "json",
"interval": 5, // catches external compose up/down
"signal": <N>, // instant refresh from control.sh (pick an RTMIN+N unused in modules.json)
"format": "{}", // text carries 󰡨 <project> <colored dot>
"on-click": "qs -p ~/.config/quickshell-containers ipc call containers toggle",
"on-click-middle": "~/.config/quickshell-containers/scripts/control.sh toggle $(cat
~/.cache/dev-stacks/last-project)",
"on-click-right": "podman-desktop"
}

status.sh emits the dot as pango markup colored from colors.json so it matches the theme, plus a class for state-based
CSS, and a tooltip listing each project → service → state. Placed near tray/custom/notification in modules-right.

Look & feel (grounded in ML4W's real chrome)

Match the existing panels exactly so it reads as native — modelled on CalendarApp/CalendarWindow.qml:

- Window: PanelWindow, color: "transparent", anchored top-right (mirror of Calendar's top-left), WlrLayershell.layer:
  Overlay. Background Rectangle { color: Theme.background; opacity: 0.95; border.color: Theme.primary; border.width: 2;
  radius: 10 }.
- Open/close: slide-down via Behavior on margin NumberAnimation { duration: 350; easing.type: Easing.OutQuint } with the
  Overlay. Background Rectangle { color: Theme.background; opacity: 0.95; border.color: Theme.primary; border.width: 2;
  radius: 10 }.
  Overlay. Background Rectangle { color: Theme.background; opacity: 0.95; border.color: Theme.primary; border.width: 2;
  radius: 10 }.
  Overlay. Background Rectangle { color: Theme.background; opacity: 0.95; border.color: Theme.primary; border.width: 2;
  radius: 10 }.
  Overlay. Background Rectangle { color: Theme.background; opacity: 0.95; border.color: Theme.primary; border.width: 2;
  radius: 10 }.
  Overlay. Background Rectangle { color: Theme.background; opacity: 0.95; border.color: Theme.primary; border.width: 2;
  radius: 10 }.
  Overlay. Background Rectangle { color: Theme.background; opacity: 0.95; border.color: Theme.primary; border.width: 2;
  radius: 10 }.
  showWindow map-guard ML4W uses; HyprlandFocusGrab (click-outside) + Escape shortcut to close.
- Theme: our Theme.qml reuses ML4W's tokens and reads the same ~/.config/ml4w/colors/colors.json, reloading on panel
  open so colors track wallpaper/theme changes. Font Theme.fontFamily ("Fira Sans Semibold"), accents Theme.primary.
- State color language — harmonized with the warm Material-You palette, not generic stoplight:
  - healthy → a soft green tuned to the dark warm background (the one custom token),
  - starting → Theme.tertiary (the palette's gold) with a gentle opacity pulse,
  - crashed/unhealthy → Theme.error (already in the palette),
  - stopped → Theme.outline (dim).
    Dots animate between states with Behavior on color { ColorAnimation { duration: 250 } }.
- Rows: generous padding (margins ~20, spacing ~15, like ML4W). Each project = ● <name> left, master play/pause
  icon-button right (transparent, Theme.primary, monospace nerd glyph ⏵/⏸ — same ActionIcon style as Calendar), and an
  expand chevron. Last-used project sorts to top. Expanded rows are indented services, each with a small dot + state label

* per-service play/pause. A project auto-expands when unhealthy so the problem is visible with no click.

- Empty state: a calm "No dev stacks running" line.

Phasing

Built as one feature, in this internal order (each step independently testable):

1.  Scripts (status.sh/state.sh/control.sh) — get correct JSON + working play/pause from the CLI first.
2.  Waybar module + deploy merge — bar shows 󰡨 jukkai ●, click-middle toggles, refresh works.
3.  Quickshell popover — the themed panel + IPC toggle (the "looks nice" centerpiece).
4.  deploy.sh wiring for all of the above (copy, autostart, idempotent JSON patches, one-time backups).

Verification

- ~/.config/quickshell-containers/scripts/state.sh | jq → valid JSON; shows project jukkai, service postgres (and
  studio-api flagged via its profile/build), both initially stopped.
- Run deploy.sh; reload Waybar (Super+Shift+B) and start our qs instance. Bar shows 󰡨 jukkai ● dim/stopped.
- Left-click → themed popover slides from top-right, matches ML4W glass; jukkai row collapsed, green/red dot correct.
- Click play on jukkai → postgres comes up; dot animates stopped → starting (amber pulse) → healthy (green) once
  pg_isready passes; bar updates within ~1s (signal). Confirm studio-api was not started.
- Click pause → compose stop; dot returns to stopped; bar updates.
- Right-click bar → podman-desktop launches.
- Kill the qs instance and re-run deploy.sh twice → confirm no duplicate custom/containers entries in modules.json or
  theme config (idempotency), and .bak files preserve the pre-feature originals.

Non-goals (v1)

- No delete/rm, no down (teardown) button — recreate/surgery lives in podman-desktop via right-click.
- No logs button — app logs live in your terminal (native dev); container logs are a debugging-session concern.
- The widget never starts/stops your app containers (those behind build:/profiles) — infra only.
- No autostart/restart-policy changes to containers.
