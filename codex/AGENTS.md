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
  clean up your process when you are done. One-shot commands such as build, test,
  or agent-browser are always fine.
- On Martin's CachyOS Linux machine, do not use the Codex in-app Browser path
  for browser automation. The GUI app is an imperfect port from the macOS build,
  and its browser runtime often is not available in a thread. Do not try to
  recover it or look for `node_repl` browser tooling. Use the `agent-browser`
  CLI for headless browser verification instead. Related startup clues include
  `MCP client for node_repl failed to start`, `Exec format error (os error 8)`,
  and `MCP startup incomplete (failed: node_repl)`.

## Writing Style

- In user-facing prose, docs, and content, avoid AI-style writing. In
  particular, avoid em dashes; prefer plain, direct sentences.

## Infra And Ops

- Infra and ops work doubles as a learning exercise. Briefly explain what is
  being done and why as you go. Act, but teach.
- Anything prod-touching: confirm with Martin first. Repo `AGENTS.md` files have
  the specifics.
