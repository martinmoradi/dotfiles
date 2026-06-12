#!/usr/bin/env bash
# PostToolUse (Edit|Write) — format the edited file with the repo's own formatter.
# Silent no-op when the file is outside a repo or the repo has no formatter installed.

f=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty')
[ -n "$f" ] && [ -f "$f" ] || exit 0

case "$f" in
  */node_modules/*|*/.git/*|*/dist/*|*/build/*) exit 0 ;;
esac

root=$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null) || exit 0

case "$f" in
  *.py)
    if command -v ruff >/dev/null 2>&1 && [ -f "$root/pyproject.toml" ]; then
      ruff format "$f" >/dev/null 2>&1
    fi
    ;;
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.css|*.scss|*.md|*.mdx|*.astro|*.html|*.yml|*.yaml)
    if [ -x "$root/node_modules/.bin/prettier" ]; then
      "$root/node_modules/.bin/prettier" --write --ignore-unknown --log-level silent "$f" >/dev/null 2>&1
    fi
    ;;
esac
exit 0
