#!/usr/bin/env bash
# Register the repo-local git filters referenced by .gitattributes.
#
# The clean filter strips Claude Code's runtime picks (model, effortLevel) from
# claude/settings.json on stage, so day-to-day toggles never enter history while
# the live working file keeps them. Filter *commands* can't live in .gitattributes
# (only the filter name does), and .git/config isn't committed, so this runs on
# every `dot deploy` to keep a fresh clone self-healing. Idempotent.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v jq >/dev/null 2>&1; then
  echo "install-git-filters: jq not found; claude/settings.json filter inactive" >&2
  echo "  (model/effort would then enter history — install jq to strip them)" >&2
  exit 0
fi

git -C "$repo" config filter.claude-runtime.clean "jq --indent 2 'del(.model, .effortLevel)'"
git -C "$repo" config filter.claude-runtime.smudge "cat"
echo "install-git-filters: claude-runtime clean filter registered"
