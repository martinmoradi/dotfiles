#!/usr/bin/env bash
# claude-mcp-chrome — launch a dedicated Chrome instance for Claude-in-Chrome
# MCP automation.
#
# Why a separate instance:
#  - isolated profile (own --user-data-dir) — never touches your main browsing
#  - distinct window class (claude-mcp) — Hyprland can float/size/pin it
#  - a distinct browser the MCP can select as its own instance
#  - a fixed window size (set by the Hyprland rule) — so screenshot pixels match
#    CSS pixels and coordinate-based clicks/hovers land correctly
#
# One-time setup after first launch: install the Claude browser extension in
# this profile (https://claude.ai/chrome) and sign in to claude.ai with the same
# account as Claude Code.
set -euo pipefail

PROFILE="${XDG_DATA_HOME:-$HOME/.local/share}/claude-mcp-chrome"
mkdir -p "$PROFILE"

exec google-chrome-stable \
    --user-data-dir="$PROFILE" \
    --class=claude-mcp \
    --no-first-run \
    --no-default-browser-check \
    --new-window "${1:-about:blank}"
