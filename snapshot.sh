#!/usr/bin/env bash
# Thin shim: snapshot is now the `dot` CLI. Kept for muscle memory + docs.
# Captures machine drift (packages, VS Code, monitors, Claude config) into the repo.
set -euo pipefail
exec "$(dirname "$0")/dot" snapshot "$@"
