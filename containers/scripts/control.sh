#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 - "$SCRIPT_DIR" "$@" <<'PY'
import json
import os
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(sys.argv[1])
ARGS = sys.argv[2:]
SIGNAL = "RTMIN+8"
CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "dev-stacks"
LAST_PROJECT_FILE = CACHE_DIR / "last-project"
LOG_FILE = CACHE_DIR / "actions.log"


def refresh_waybar():
    subprocess.run(["pkill", f"-{SIGNAL}", "waybar"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def notify(message):
    if subprocess.run(["bash", "-lc", "command -v notify-send >/dev/null"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
        subprocess.Popen(["notify-send", "Dev Stacks", message], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def load_state():
    proc = subprocess.run([str(SCRIPT_DIR / "state.sh")], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        raise SystemExit(proc.stderr.strip() or "state.sh failed")
    return json.loads(proc.stdout)


def find_project(state, name):
    projects = state.get("projects", [])
    if not name:
        name = state.get("last_project", "")
    if not name and projects:
        return projects[0]
    for project in projects:
        if project["name"] == name:
            return project
    raise SystemExit(f"Unknown dev stack: {name or '(none)'}")


def find_service(project, name):
    for service in project.get("services", []):
        if service["name"] == name:
            return service
    raise SystemExit(f"Unknown service in {project['name']}: {name}")


def remember(project):
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    LAST_PROJECT_FILE.write_text(project["name"] + "\n")


def spawn(project, command):
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    script = r'''
workdir=$1
shift
sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
if [ "${DOCKER_HOST:-}" != "" ] && [ "${DOCKER_HOST#unix://}" != "$DOCKER_HOST" ]; then
    sock="${DOCKER_HOST#unix://}"
fi

if [ ! -S "$sock" ]; then
    mkdir -p "$(dirname "$sock")"
    if ! systemctl --user start podman.socket >/dev/null 2>&1; then
        nohup podman system service --time=0 "unix://$sock" >/dev/null 2>&1 &
    fi
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        [ -S "$sock" ] && break
        sleep 0.2
    done
fi

cd "$workdir" || exit 1
"$@"
rc=$?
pkill -RTMIN+8 waybar >/dev/null 2>&1 || true
exit "$rc"
'''
    log = open(LOG_FILE, "ab")
    subprocess.Popen(
        ["bash", "-lc", script, "dev-stacks-worker", project["working_dir"], *command],
        stdout=log,
        stderr=subprocess.STDOUT,
        start_new_session=True,
        close_fds=False,
    )


def main():
    if not ARGS:
        raise SystemExit("Usage: control.sh up|stop|toggle|service-up|service-stop|desktop <project> [service]")

    action = ARGS[0]
    if action == "desktop":
        subprocess.Popen(["podman-desktop"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        return

    state = load_state()
    project = find_project(state, ARGS[1] if len(ARGS) > 1 else "")
    if not project.get("working_dir"):
        raise SystemExit(f"No compose working directory found for {project['name']}")

    remember(project)
    refresh_waybar()

    if action == "toggle":
        action = "stop" if project.get("action") == "pause" else "up"

    if action == "up":
        spawn(project, ["podman", "compose", "up", "-d"])
    elif action == "stop":
        spawn(project, ["podman", "compose", "stop"])
    elif action in {"service-up", "service-stop"}:
        if len(ARGS) < 3:
            raise SystemExit(f"{action} needs a service name")
        service = find_service(project, ARGS[2])
        if service.get("protected"):
            notify(f"{service['name']} is marked {service.get('protect_reason') or 'protected'} and is left to Podman Desktop.")
            return
        if action == "service-up":
            spawn(project, ["podman", "compose", "up", "-d", service["name"]])
        else:
            spawn(project, ["podman", "compose", "stop", service["name"]])
    else:
        raise SystemExit(f"Unknown action: {action}")


main()
PY
