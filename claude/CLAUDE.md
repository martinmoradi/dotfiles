# Global preferences

## Git
- Default to a series of coherent semantic commits that follow how the work was
  built. Never one catch-all commit at the end.
- Branch + PR is the default for client/product repos (jukkai: never push main
  directly). Direct commits to main are fine only where the repo's CLAUDE.md
  says so (e.g. infra).

## Running things
- When you need a long-running process, run your own on a non-default port that
  you own. Check what's already bound first so you never collide with Martin's
  services or other agents running in parallel, and clean up your process when
  you're done.

## Browser automation
- Prefer `agent-browser` for everything it can do. It is genuinely more powerful
  and efficient than the Claude-in-Chrome MCP, and it has two modes:
  - headless for scraping, one-shot checks, DOM queries, and screenshots of
    static pages.
  - headed for real hover/scroll/framework events (Webflow IX2, GSAP), canvas,
    or anything a live compositor must actually render. Open it on the second
    monitor with the shared placement class:
    `agent-browser open <url> --headed --args "--class=claude-mcp"`.
    Hyprland pins the `claude-mcp` class floating on HDMI-A-1, the vertical
    monitor. Close it when done.
- `claude-mcp-chrome` (real Chrome + the Claude-in-Chrome extension) is the
  fallback, for when you specifically need the `mcp__claude-in-chrome__*` tools
  or an interactive session in Martin's real browser. It shares the same
  `claude-mcp` placement class. Start it before those tools if no `claude-mcp`
  browser is connected, wait ~8s for the extension to connect (an immediate
  list_connected_browsers returns empty), prefer it over the main Chrome via
  select_browser, and close it when done.
- Both launchers are defined in ~/src/perso/dotfiles and deployed onto PATH.

## Writing style
- In user-facing prose, docs, and content: no "AI style" writing. In
  particular, avoid em dashes; prefer plain, direct sentences.

## Infra & ops
- Infra/ops work doubles as a learning exercise: briefly explain what you're
  doing and why as you go. Act, but teach.
- Anything prod-touching: confirm with Martin first (repo CLAUDE.md files have
  the specifics).
