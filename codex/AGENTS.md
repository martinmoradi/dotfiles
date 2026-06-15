# Global Preferences

## Git

- Default to a series of coherent semantic commits that follow how the work was
  built. Never one catch-all commit at the end.
- Branch + PR is the default for client/product repos. For jukkai, never push
  main directly. Direct commits to main are fine only where the repo's
  `AGENTS.md` says so, such as infra.

## Running Things

- When you need a long-running process, run your own on a non-default port that
  you own. Check what is already bound first so you never collide with Martin's
  services or other agents running in parallel, tell Martin the port or URL, and
  clean up your process when you are done.

## Browser Automation

- `agent-browser` is the browser tool, never the Codex in-app browser (broken
  here, not worth recovering: `node_repl` / "Exec format error" startup
  failures). Orient with `agent-browser skills get core --full` (version-matched
  patterns + full command reference) instead of guessing flags.
- Headless for scraping, DOM queries, static screenshots; headed for real
  hover/scroll/framework events (GSAP, Webflow IX2), canvas, or live-compositor
  rendering. Open headed on the second monitor with `agent-browser open <url>
  --headed --args "--class=claude-mcp"` (Hyprland pins that class to HDMI-A-1).
  Close it when done.
- React work: launch `--enable react-devtools`, then `react tree`, `react
  inspect <id>`, `react renders start/stop`, `react suspense`. Perf:
  `agent-browser vitals [url] [--json]` (Core Web Vitals + hydration).

## Writing Style

- In user-facing prose, docs, and content, avoid AI-style writing. In
  particular, avoid em dashes; prefer plain, direct sentences.

## Infra And Ops

- Infra and ops work doubles as a learning exercise. Briefly explain what is
  being done and why as you go. Act, but teach.
- Anything prod-touching: confirm with Martin first. Repo `AGENTS.md` files have
  the specifics.
