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
# Glyphs are Nerd Font (built into FiraCode Nerd Font Mono). Swap any
# codepoint below to taste — the comment names the icon.
import os

from kitty.tab_bar import draw_tab_with_powerline

try:
    from kitty.boss import get_boss
except Exception:  # pragma: no cover - defensive
    def get_boss():
        return None

SHELL_ICON = "❯"    # idle shell prompt
DEFAULT_ICON = ""  # nf-fa-terminal (unknown foreground process)

# Checked top-to-bottom; first match wins. Keys are compared against the
# path-stripped tokens of the foreground process's command line, so
# "node /usr/bin/claude" matches the claude row, and short names like "go"
# can't fire on substrings of unrelated commands.
ICONS = (
    (("claude",),                                              ""),  # nf-fa-asterisk (closest to the Claude mark)
    (("codex",),                                               "󰚩"),  # nf-md-robot
    (("nvim", "vim"),                                          ""),  # nf-custom-vim
    (("micro", "nano"),                                        ""),  # nf-fa-edit (pencil)
    (("htop", "btop", "top"),                                  ""),  # nf-fa-area_chart (monitor)
    (("pytest", "jest", "vitest", "playwright"),               "󰙨"),  # nf-md-test_tube
    (("node", "npm", "npx", "pnpm", "yarn", "bun", "vite",
      "next", "tsc", "deno", "eslint", "prettier"),            ""),  # nf-dev-nodejs_small
    (("git", "lazygit", "gh", "tig"),                          ""),  # nf-dev-git
    (("python", "python3", "ipython", "pip", "uv", "poetry"),  ""),  # nf-dev-python
    (("cargo", "rustc", "rustup"),                             ""),  # nf-dev-rust
    (("go", "gofmt", "gopls"),                                 ""),  # nf-seti-go
    (("make", "cmake", "ninja", "gcc", "clang", "cc"),         ""),  # nf-fa-wrench
    (("docker", "podman", "kubectl", "docker-compose",
      "podman-compose"),                                       ""),  # nf-linux-docker
    (("pacman", "yay", "paru", "makepkg"),                     ""),  # nf-linux-archlinux
    (("systemctl", "journalctl", "dmesg"),                     ""),  # nf-fa-cogs
    (("psql", "mysql", "sqlite3", "redis-cli", "mongosh"),     ""),  # nf-dev-database
    (("ssh", "mosh", "scp", "sftp", "rsync"),                  ""),  # nf-fa-lock
    (("curl", "wget", "http", "xh"),                           ""),  # nf-fa-globe
    (("man", "less", "bat", "glow"),                           ""),  # nf-fa-book
    (("bash", "zsh", "sh", "fish"),                            SHELL_ICON),
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
            tokens = {os.path.basename(str(a)).lower() for a in argv}
            label = _dir_label(p.get("cwd", ""))
            for keys, ic in ICONS:
                if tokens & set(keys):
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
