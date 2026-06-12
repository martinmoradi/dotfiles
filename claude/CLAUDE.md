# Global preferences

## Git
- Default to a series of coherent semantic commits that follow how the work was
  built. Never one catch-all commit at the end.
- Branch + PR is the default for client/product repos (jukkai: never push main
  directly). Direct commits to main are fine only where the repo's CLAUDE.md
  says so (e.g. infra).

## Running things
- Never start dev servers or other long-running processes. Martin runs them
  himself in a separate terminal; verify against his running server or use
  one-shot commands (build, test, agent-browser).

## Writing style
- In user-facing prose, docs, and content: no "AI style" writing. In
  particular, avoid em dashes; prefer plain, direct sentences.

## Infra & ops
- Infra/ops work doubles as a learning exercise: briefly explain what you're
  doing and why as you go. Act, but teach.
- Anything prod-touching: confirm with Martin first (repo CLAUDE.md files have
  the specifics).
