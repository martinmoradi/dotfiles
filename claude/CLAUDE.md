# Global preferences

## Git
- Default to a series of coherent semantic commits that follow how the work was
  built. Never one catch-all commit at the end.
- Branch + PR is the default for client/product repos (jukkai: never push main
  directly). Direct commits to main are fine only where the repo's CLAUDE.md
  says so (e.g. infra).
- No agent attribution on commits or PRs: never add `Co-Authored-By: Claude`
  trailers or "Generated with Claude Code" lines. Work ships under Martin's name.

## Running things
- When you need a long-running process, run your own on a non-default port that
  you own. Check what's already bound first so you never collide with Martin's
  services or other agents running in parallel, and clean up your process when
  you're done.

## Browser automation
- `agent-browser` is the browser tool. Orient with `agent-browser skills get
  core --full` (version-matched patterns + full command reference) instead of
  guessing flags.
- Headless for scraping, DOM queries, static screenshots; headed for real
  hover/scroll/framework events (GSAP, Webflow IX2), canvas, or live-compositor
  rendering. Open headed on the second monitor with `agent-browser open <url>
  --headed --args "--class=claude-mcp"` (Hyprland pins that class to HDMI-A-1).
  Close it when done.
- React work: launch `--enable react-devtools`, then `react tree`, `react
  inspect <id>`, `react renders start/stop`, `react suspense`. Perf:
  `agent-browser vitals [url] [--json]` (Core Web Vitals + hydration).

## Writing style
- In user-facing prose, docs, and content: no "AI style" writing. In
  particular, avoid em dashes; prefer plain, direct sentences.

## Infra & ops
- Infra/ops work doubles as a learning exercise: briefly explain what you're
  doing and why as you go. Act, but teach.
- Anything prod-touching: confirm with Martin first (repo CLAUDE.md files have
  the specifics).
