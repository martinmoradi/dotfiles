---
name: execution-plan
description: Turn a roadmap item, spec, or feature ask into a written execution plan under the repo's plans/ directory, scoped so fresh-context agents can each execute one slice in a worktree. Use when Martin asks for an execution plan, to plan a feature or slice, or to prepare work for parallel worktree streams.
---

# Execution plan

Produce a self-contained execution plan for: $ARGUMENTS

The plan's reader is a **fresh-context agent** that has read nothing but the
repo's CLAUDE.md/AGENTS.md and this plan. Write accordingly: every decision,
file path, and constraint the executor needs must be in the plan itself.

## 1. Gather context first

- Read the relevant roadmap/spec under `plans/` (e.g. `plans/roadmaps/`,
  `plans/features/`) and any decision docs they link to. Do not invent
  product/design direction that existing docs already settle.
- Read the code the work touches (or dispatch an Explore agent for breadth).
- If the ask conflicts with the roadmap or a closed decision, stop and raise
  it with Martin before writing the plan.

## 2. Write the plan

Save to the repo's existing plans structure (match neighboring file naming,
e.g. `plans/features/<slug>-execution-plan.md`). Structure:

- **Goal / non-goals** — one short paragraph each.
- **Context** — relevant files with paths, prior art, settled decisions with
  doc links, gotchas the executor can't infer.
- **Slices** — each slice independently executable and verifiable in its own
  worktree, sized for one focused agent session. Per slice:
  - Scope: what changes, which files/dirs it owns. State explicitly which
    paths it must NOT touch (other streams own them).
  - Steps, in build order.
  - Acceptance criteria + concrete verification commands (lint, typecheck,
    targeted tests, `agent-browser` screenshots for UI work).
- **Integration order** — merge sequence, expected conflict points, what to
  re-verify after each merge, worktree cleanup.
- **Risks / open questions** — anything needing Martin's input, flagged early.

## 3. Conventions every slice must carry

These go in the plan so executors follow them without being told:

- Work happens on a branch in a worktree; never on main directly.
- Commit as a series of coherent semantic commits following build order; push
  reviewable commits as work proceeds, not one dump at the end.
- Never start dev servers; Martin runs them. Use one-shot verification.
- Run `/code-review` before declaring a slice done; finish with a PR.

## 4. Hand off

After writing, give Martin: the plan path, a one-line summary per slice, a
suggested stream assignment (which slices can run in parallel, which must be
sequential), and any open questions from §2.
