#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_JSON="$("$SCRIPT_DIR/state.sh")"

STATE_JSON="$STATE_JSON" python3 - <<'PY'
import html
import json
import os
import sys
from pathlib import Path

STATE = json.loads(os.environ.get("STATE_JSON", "{}"))
HOME = Path(os.environ.get("HOME", ""))
COLORS_PATH = HOME / ".config/ml4w/colors/colors.json"

colors = {
    "primary": "#b0c6ff",
    "tertiary": "#e0bbde",
    "error": "#ffb4ab",
    "outline": "#8f9099",
    "on_surface": "#e2e2e9",
}

try:
    colors.update(json.loads(COLORS_PATH.read_text()))
except Exception:
    pass

ICON = "󰡨"
ICON_COLOR = colors.get("on_surface", "#e2e2e9")  # match the bar's native white text
ICON_SIZE = "145%"  # the docker glyph reads small at the base size — nudge it up
# Gap between the icon and the project name. letter_spacing widens the gap
# horizontally (1024ths of a pt) without scaling the space's font, so the bar's
# line height is unaffected. Tune the number to taste.
NAME_GAP = '<span letter_spacing="8192"> </span>'

# A project's name is tinted by its health only while something is up.
# "stopped"/idle projects show the icon alone (nothing running).
name_colors = {
    "healthy": "#8bd99c",
    "running": "#8bd99c",
    "starting": colors.get("tertiary", "#e0bbde"),
    "partial": colors.get("tertiary", "#e0bbde"),
    "trouble": colors.get("error", "#ffb4ab"),
    "unhealthy": colors.get("error", "#ffb4ab"),
    "crashed": colors.get("error", "#ffb4ab"),
}


def span(color, text, size=None):
    attrs = f'foreground="{color}"'
    if size:
        attrs += f' size="{size}"'
    return f'<span {attrs}>{html.escape(str(text), quote=True)}</span>'


def icon_span(color):
    return span(color, ICON, ICON_SIZE)


def tooltip(projects):
    if STATE.get("error"):
        return "Dev stacks\n" + STATE["error"]
    if not projects:
        return "Dev stacks\nNo dev stacks discovered yet.\nRun podman compose up -d once in a project to create its stack."

    lines = ["Dev stacks"]
    for project in projects:
        lines.append(f'{project["name"]}: {project["state_label"].lower()} ({project["summary"]})')
        for service in project.get("services", []):
            suffix = ""
            if service.get("protected"):
                suffix = f' [{service.get("protect_reason") or "protected"}]'
            lines.append(f'  {service["name"]}: {service["state_label"].lower()}{suffix}')
    return "\n".join(lines)


projects = STATE.get("projects", [])
if STATE.get("error"):
    # podman itself is unreachable — flag the icon red so it's noticed.
    text = icon_span(colors.get("error", "#ffb4ab"))
    css_class = "trouble"
elif not projects:
    text = icon_span(ICON_COLOR)
    css_class = "empty"
else:
    selected = projects[0]
    wanted = STATE.get("last_project", "")
    for project in projects:
        if project["name"] == wanted:
            selected = project
            break
    css_class = selected["state"]
    name_color = name_colors.get(selected["state"])
    if name_color:
        text = f'{icon_span(ICON_COLOR)}{NAME_GAP}{span(name_color, selected["name"])}'
    else:
        # stopped / idle — nothing running, so just the docker icon
        text = icon_span(ICON_COLOR)

print(
    json.dumps(
        {
            "text": text,
            "tooltip": tooltip(projects),
            "class": css_class,
            "alt": css_class,
        },
        separators=(",", ":"),
    )
)
PY
