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

## Writing style
- In user-facing prose, docs, and content: no "AI style" writing. In
  particular, avoid em dashes; prefer plain, direct sentences.

## Infra & ops
- Infra/ops work doubles as a learning exercise: briefly explain what you're
  doing and why as you go. Act, but teach.
- Anything prod-touching: confirm with Martin first (repo CLAUDE.md files have
  the specifics).
