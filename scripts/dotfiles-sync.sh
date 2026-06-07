#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: dotfiles-sync [--all|--packages-only] [--source NAME] [--no-push]

Snapshots machine state into this repo, commits any resulting changes, and
pushes the current branch. Use --packages-only from pacman hooks; use --all for
normal dotfile/script changes, including deletions.
EOF
}

mode="all"
source_name="manual"
push=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)
            mode="all"
            ;;
        --packages-only)
            mode="packages"
            ;;
        --source)
            source_name="${2:-}"
            shift
            ;;
        --no-push)
            push=0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    echo "Refusing to run as root; run dotfiles sync as the repo owner." >&2
    exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "$script_dir/.." && pwd)"
cd "$repo_dir"

log_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-sync"
mkdir -p "$log_dir"
log_file="$log_dir/sync.log"
exec > >(tee -a "$log_file") 2>&1

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

lock_file="${XDG_RUNTIME_DIR:-/tmp}/dotfiles-sync.lock"
exec 9>"$lock_file"
if ! flock -n 9; then
    log "Another dotfiles sync is already running; skipping."
    exit 0
fi

snapshot_packages() {
    mkdir -p packages
    pacman -Qqe > packages/pacman-explicit.txt
    pacman -Qqm > packages/aur.txt
    log "Updated package snapshots."
}

snapshot_all() {
    ./snapshot.sh
}

branch="$(git branch --show-current)"
if [[ -z "$branch" ]]; then
    log "Not on a branch; skipping sync."
    exit 1
fi

log "Starting dotfiles sync: mode=$mode source=$source_name branch=$branch"

case "$mode" in
    packages)
        snapshot_packages
        git add packages/pacman-explicit.txt packages/aur.txt
        commit_message="chore(packages): sync package snapshot"
        ;;
    all)
        snapshot_all
        git add -A
        commit_message="chore(dotfiles): sync local state"
        ;;
    *)
        log "Unknown mode: $mode"
        exit 2
        ;;
esac

if git diff --cached --quiet --exit-code; then
    log "No changes to commit."
    exit 0
fi

git diff --cached --stat
git commit -m "$commit_message" -m "Triggered by: $source_name"

if [[ "$push" -eq 1 ]]; then
    if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
        git push
    else
        git push -u origin "$branch"
    fi
    log "Pushed $branch."
else
    log "Created commit without pushing."
fi
