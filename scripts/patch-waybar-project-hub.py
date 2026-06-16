#!/usr/bin/env python3
"""Patch ML4W Waybar config with Project Hub and dotfiles modules."""

from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path


def strip_jsonc(text: str) -> str:
    out = []
    i = 0
    in_string = False
    escaped = False
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""

        if in_string:
            out.append(ch)
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
            continue
        if ch == "/" and nxt == "/":
            i += 2
            while i < len(text) and text[i] not in "\r\n":
                i += 1
            continue
        if ch == "/" and nxt == "*":
            i += 2
            while i + 1 < len(text) and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2
            continue

        out.append(ch)
        i += 1

    return re.sub(r",\s*([}\]])", r"\1", "".join(out))


def load_jsonc(path: Path) -> dict:
    return json.loads(strip_jsonc(path.read_text()))


def backup_once(path: Path) -> None:
    backup = Path(str(path) + ".bak")
    if not backup.exists():
        shutil.copy2(path, backup)


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n")


def array_bounds(text: str, key: str) -> tuple[int, int] | None:
    key_pos = text.find(f'"{key}"')
    if key_pos < 0:
        return None
    start = text.find("[", key_pos)
    if start < 0:
        return None

    in_string = False
    escaped = False
    depth = 0
    for i in range(start, len(text)):
        ch = text[i]
        if in_string:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            continue

        if ch == '"':
            in_string = True
        elif ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                return start, i
    return None


def module_name(line: str) -> str:
    return line.strip().rstrip(",").strip().strip('"')


def array_lines(text: str, key: str) -> tuple[int, int, list[str]] | None:
    bounds = array_bounds(text, key)
    if not bounds:
        return None

    start, end = bounds
    return start, end, text[start + 1 : end].splitlines(keepends=True)


def item_indent(lines: list[str]) -> str:
    fallback = "        "
    for line in lines:
        stripped = line.lstrip()
        if stripped.startswith('"'):
            return line[: len(line) - len(stripped)]
    return fallback


def rewrite_array(text: str, key: str, transform) -> str:
    details = array_lines(text, key)
    if not details:
        return text
    start, end, lines = details
    updated_lines = transform(lines)
    return text[: start + 1] + "".join(updated_lines) + text[end:]


def remove_modules(text: str, key: str, names: set[str]) -> str:
    return rewrite_array(text, key, lambda lines: [line for line in lines if module_name(line) not in names])


def insert_project_island(text: str) -> str:
    managed_modules = {
        "custom/containers",
        "custom/current-project",
        "custom/project-label",
        "custom/project-action",
    }

    for key in ("modules-left", "modules-center", "modules-right"):
        text = remove_modules(text, key, managed_modules)

    # The island lives on the left with the clock. If a theme had the clock on
    # the right, move it left once and keep subsequent deploys stable.
    for key in ("modules-center", "modules-right"):
        text = remove_modules(text, key, {"clock"})

    def transform_left(lines: list[str]) -> list[str]:
        indent = item_indent(lines)
        names = [module_name(line) for line in lines]
        if "clock" not in names:
            clock_entry = f'{indent}"clock",\n'
            insert_at = 0
            for index, name in enumerate(names):
                if name in {"custom/appmenu", "custom/appmenuicon"}:
                    insert_at = index + 1
                    break
            lines = [*lines]
            lines.insert(insert_at, clock_entry)

        label_entry = f'{indent}"custom/project-label",\n'
        action_entry = f'{indent}"custom/project-action",\n'
        for index, line in enumerate(lines):
            if module_name(line) == "clock":
                lines.insert(index + 1, label_entry)
                lines.insert(index + 2, action_entry)
                return lines

        lines.append(label_entry)
        lines.append(action_entry)
        return lines

    return rewrite_array(text, "modules-left", transform_left)


def insert_npm_updates(text: str) -> str:
    module = "custom/npm-updates"
    for key in ("modules-left", "modules-center", "modules-right"):
        text = remove_modules(text, key, {module})

    def transform_right(lines: list[str]) -> list[str]:
        indent = item_indent(lines)
        entry = f'{indent}"{module}",\n'
        for index, line in enumerate(lines):
            if module_name(line) == "custom/updates":
                lines = [*lines]
                lines.insert(index + 1, entry)
                return lines
        return [entry, *lines]

    return rewrite_array(text, "modules-right", transform_right)


def remove_marked_block(text: str, start: str, end: str) -> str:
    if start not in text or end not in text:
        return text
    before, rest = text.split(start, 1)
    _, after = rest.split(end, 1)
    return before.rstrip() + "\n\n" + after.lstrip()


def clone_npm_update_css(text: str, start: str, end: str) -> str:
    blocks = []
    blocks.append("""#custom-npm-updates {
    font-size: 15px;
}""")

    pattern = re.compile(r"(?ms)#custom-updates\.red\s*\{.*?^\}")
    match = pattern.search(text)
    if match:
        blocks.append(match.group(0).replace("#custom-updates", "#custom-npm-updates", 1))

    if len(blocks) == 1:
        blocks.append("""#custom-npm-updates.red {
    border-radius: 8px;
    margin:6px 0px 6px 7px;
    padding:0px 6px 0px 6px;
    background-color: @error;
    color:@on_error;
}""")

    return f"{start}\n" + "\n\n".join(blocks) + f"\n{end}\n"


def patch_style(path: Path) -> bool:
    if not path.exists():
        return False

    old_start = "/* dotfiles current-project start */"
    old_end = "/* dotfiles current-project end */"
    start = "/* dotfiles project-hub start */"
    end = "/* dotfiles project-hub end */"
    project_block = f"""{start}
#custom-project-action.running {{
    color: #8bd99c;
}}

#custom-project-action.working {{
    color: #e0bbde;
}}

#custom-project-action.alert {{
    color: #ffb4ab;
}}

#custom-project-action.stopped {{
    color: #c5c6d0;
}}
{end}
"""
    npm_start = "/* dotfiles npm-updates start */"
    npm_end = "/* dotfiles npm-updates end */"

    original = path.read_text()
    npm_block = clone_npm_update_css(original, npm_start, npm_end)
    updated = remove_marked_block(original, old_start, old_end)
    updated = remove_marked_block(updated, start, end)
    updated = remove_marked_block(updated, npm_start, npm_end)
    updated = updated.rstrip() + "\n\n" + project_block + "\n" + npm_block

    if updated == original:
        return False

    backup_once(path)
    path.write_text(updated)
    return True


def patch_waybar(
    modules_path: Path,
    workspace_override_path: Path,
    project_module_path: Path,
    npm_module_path: Path,
    themes_dir: Path,
    waybar_dir: Path,
) -> None:
    modules = load_jsonc(modules_path)
    workspace_override = load_jsonc(workspace_override_path)
    project_module = load_jsonc(project_module_path)
    npm_module = load_jsonc(npm_module_path)

    backup_once(modules_path)
    modules["hyprland/workspaces"] = workspace_override["hyprland/workspaces"]
    modules.pop("custom/current-project", None)
    modules.pop("custom/containers", None)
    modules.update(project_module)
    modules.update(npm_module)
    write_json(modules_path, modules)

    touched_themes = []
    for config_path in sorted(themes_dir.glob("*/config")):
        data = load_jsonc(config_path)
        includes = data.get("include", [])
        if isinstance(includes, str):
            includes = [includes]
        if "~/.config/waybar/modules.json" not in includes:
            continue

        if not any(isinstance(data.get(key), list) for key in ("modules-left", "modules-center", "modules-right")):
            continue

        original = config_path.read_text()
        updated = insert_project_island(original)
        updated = insert_npm_updates(updated)
        if updated == original:
            continue

        backup_once(config_path)
        config_path.write_text(updated)
        touched_themes.append(config_path.name if config_path.parent == themes_dir else config_path.parent.name)

    styled = []
    style_paths = {waybar_dir / "style.css", *themes_dir.glob("**/style.css")}
    for style_path in sorted(style_paths):
        if patch_style(style_path):
            styled.append(str(style_path.relative_to(waybar_dir)))

    print("themes=" + ",".join(touched_themes))
    print("styles=" + ",".join(styled))


def main() -> int:
    if len(sys.argv) != 7:
        print(
            "Usage: patch-waybar-project-hub.py "
            "<modules.json> <workspace-override.jsonc> <project-module.jsonc> "
            "<npm-module.jsonc> <themes-dir> <waybar-dir>",
            file=sys.stderr,
        )
        return 2

    patch_waybar(*(Path(arg).expanduser() for arg in sys.argv[1:]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
