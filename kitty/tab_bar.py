# Custom kitty tab bar — browser-like tabs with a per-app icon.
#
# Each tab shows:  <index> <app-icon> <directory>
# rendered with kitty's slanted powerline shape (tab_powerline_style in
# custom.conf). The index matches the F1..F5 goto_tab bindings. The icon is
# chosen from the tab's *foreground process* (so it's consistent, unlike the
# icon each program decides to print into its own title). Everything is
# wrapped in try/except and falls back to the tab title, so a bad API call or
# missing glyph can never break the tab bar.
#
# Glyphs are Nerd Font (built into MonoLisa Nerd Font Mono). Swap any
# codepoint below to taste — the comment names the icon.
import os

from kitty.tab_bar import draw_tab_with_powerline

try:
    from kitty.boss import get_boss
except Exception:  # pragma: no cover - defensive
    def get_boss():
        return None

DEFAULT_ICON = ""  #  folder (idle shell / unknown)

# Checked top-to-bottom; first match wins. Matched against the basename of the
# foreground process AND anywhere in its full command line.
ICONS = (
    (("claude",),                                              ""),  #  claude (asterisk — closest glyph to the Claude mark)
    (("codex",),                                               "󰚩"),  # robot (codex)
    (("nvim", "vim"),                                          ""),  #  vim
    (("micro", "nano"),                                        ""),  # pencil/edit
    (("htop", "btop"),                                         ""),  # graph (monitor)
    (("node", "npm", "pnpm", "yarn", "bun", "vite", "next",
      "tsc", "deno", "eslint"),                                ""),  #  node / JS
    (("git", "lazygit"),                                       ""),  #  git
    (("python", "python3", "pip", "uv", "poetry"),             ""),  #  python
    (("docker", "podman", "kubectl"),                          ""),  #  docker
    (("ssh", "mosh"),                                          ""),  #  ssh (lock)
    (("bash", "zsh", "sh"),                                    DEFAULT_ICON),  # idle shell
)


def _dir_label(cwd):
    if not cwd:
        return ""
    home = os.path.expanduser("~")
    if cwd == home:
        return "~"
    base = os.path.basename(cwd.rstrip("/"))
    return base or cwd


def _detect(tab):
    """Return (icon, label) for a tab, never raising."""
    icon, label = DEFAULT_ICON, ""
    try:
        boss = get_boss()
        t = boss.tab_for_id(tab.tab_id) if boss else None
        w = t.active_window if t else None
        procs = w.child.foreground_processes if w else []
        if procs:
            p = procs[-1]  # deepest foreground process
            argv = p.get("cmdline") or []
            cmd = " ".join(argv).lower()
            exe = os.path.basename(argv[0]).lower() if argv else ""
            label = _dir_label(p.get("cwd", ""))
            for keys, ic in ICONS:
                if exe in keys or any(k in cmd for k in keys):
                    icon = ic
                    break
    except Exception:
        pass
    if not label:
        label = (tab.title or "").strip()
    return icon, label


def draw_tab(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data):
    icon, label = _detect(tab)
    tab = tab._replace(title=f"{index} {icon} {label}")
    return draw_tab_with_powerline(
        draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data
    )
