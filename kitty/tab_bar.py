"""Stable tab titles for Kitty's native powerline tab bar."""

import os
import re


SHELL_TITLE = re.compile(r"^(?:ba|z|fi)?sh(?: in .*)?$", re.IGNORECASE)
CLAUDE_SPINNERS = frozenset("✢✳✶✽✻")


def _directory_label(cwd):
    if not cwd:
        return ""
    cwd = cwd.rstrip("/") or "/"
    if cwd == os.path.expanduser("~"):
        return "~"
    return os.path.basename(cwd) or cwd


def _clean_title(title):
    title = (title or "").strip()
    # Claude uses changing Braille and star characters as an activity spinner.
    # They are useful inside the TUI but make a tab label flicker constantly.
    while title and (
        "\u2800" <= title[0] <= "\u28ff" or title[0] in CLAUDE_SPINNERS
    ):
        title = title[1:].lstrip()
    return title


def draw_title(data):
    """Return ``<index>/ <directory> | <task>`` for Kitty's {custom} field."""
    index = str(data.get("index", "")).strip()
    tab = data.get("tab")
    cwd = getattr(tab, "active_oldest_wd", "") if tab else ""
    directory = _directory_label(cwd)
    title = _clean_title(data.get("title", ""))

    # An idle shell adds no information beyond the directory. Applications can
    # still provide a useful task title, and a manually assigned tab title also
    # arrives through this field.
    if SHELL_TITLE.fullmatch(title) or title in {cwd, directory}:
        title = ""

    if index and directory:
        identity = f"{index}/ {directory}"
    else:
        identity = index or directory
    if identity and title:
        return f"{identity} | {title}"
    return identity or title
