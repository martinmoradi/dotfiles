#!/usr/bin/env bash
# Thin shim: deploy is now the `dot` CLI. Kept for muscle memory + docs.
# Run `dot deploy --dry-run` to preview, `dot` (no args) for the interactive UI.
set -euo pipefail
exec "$(dirname "$0")/dot" deploy "$@"
