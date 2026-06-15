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
- Default to `agent-browser` (headless) for anything it can do: scraping,
  one-shot checks, DOM queries, screenshots of static pages.
- When headless is not enough (real GPU/canvas, extensions, visual rendering
  that needs a live compositor, or hand-off to the Claude-in-Chrome MCP), use
  the dedicated Chrome: launch `claude-mcp-chrome` (isolated profile, class
  `claude-mcp`, pinned 1280x900 on the HDMI-A-1 vertical monitor). Start it
  before using mcp__claude-in-chrome__* tools if no `claude-mcp` browser is
  connected, and prefer that instance over the main Chrome via select_browser.
  The extension needs a few seconds to connect after launch, so wait ~8s
  before the first list_connected_browsers (an immediate call returns empty).
  Close it when done; relaunching re-applies its placement. (Defined in
  ~/src/perso/dotfiles, deployed onto PATH.)

## Writing style
- In user-facing prose, docs, and content: no "AI style" writing. In
  particular, avoid em dashes; prefer plain, direct sentences.

## Infra & ops
- Infra/ops work doubles as a learning exercise: briefly explain what you're
  doing and why as you go. Act, but teach.
- Anything prod-touching: confirm with Martin first (repo CLAUDE.md files have
  the specifics).
