#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import datetime as _dt
import json
import os
import re
import subprocess
from collections import Counter, defaultdict
from pathlib import Path

try:
    import yaml
except Exception:
    yaml = None

CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "dev-stacks"
LAST_PROJECT_FILE = CACHE_DIR / "last-project"
PROJECTS_FILE = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "dev" / "projects.json"


def run_podman_ps():
    proc = subprocess.run(
        ["podman", "ps", "-a", "--format", "json"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if proc.returncode != 0:
        return [], proc.stderr.strip() or "podman ps failed"

    text = proc.stdout.strip()
    if not text:
        return [], None

    try:
        data = json.loads(text)
        if isinstance(data, dict):
            return [data], None
        return data, None
    except json.JSONDecodeError:
        rows = []
        for line in text.splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                return [], "podman returned invalid JSON"
        return rows, None


def compose_files(labels, working_dir):
    raw = labels.get("com.docker.compose.project.config_files", "")
    files = [Path(part) for part in raw.split(",") if part.strip()]

    if working_dir:
        base = Path(working_dir)
        files.extend(
            [
                base / "compose.yaml",
                base / "compose.yml",
                base / "docker-compose.yaml",
                base / "docker-compose.yml",
            ]
        )

    seen = set()
    unique_files = []
    for path in files:
        key = str(path)
        if key in seen:
            continue
        seen.add(key)
        unique_files.append(path)
    return unique_files


def load_project_registry():
    try:
        projects = json.loads(PROJECTS_FILE.read_text())
    except Exception:
        return {}

    registry = {}
    for project in projects if isinstance(projects, list) else []:
        if not isinstance(project, dict):
            continue
        project_id = project.get("id")
        path = project.get("path")
        if project_id and path:
            registry[str(project_id)] = str(Path(str(path)).expanduser())
    return registry


def load_compose_metadata(labels, working_dir):
    services = {}
    if yaml is None:
        return services

    for path in compose_files(labels, working_dir):
        try:
            if not path.exists():
                continue
            data = yaml.safe_load(path.read_text()) or {}
        except Exception:
            continue

        for name, service in (data.get("services") or {}).items():
            if not isinstance(service, dict):
                service = {}
            profiles = service.get("profiles") or []
            if isinstance(profiles, str):
                profiles = [profiles]
            services[name] = {
                "profiles": [str(profile) for profile in profiles],
                "has_build": "build" in service,
            }
        break

    return services


def container_name(container):
    names = container.get("Names") or container.get("Names", [])
    if isinstance(names, list) and names:
        return names[0]
    if isinstance(names, str):
        return names
    return container.get("Name") or container.get("Id", "")[:12]


def service_state(container):
    state = str(container.get("State") or "").lower()
    status = str(container.get("Status") or "")
    exit_code = container.get("ExitCode")

    if state == "running":
        lowered = status.lower()
        if "(unhealthy)" in lowered:
            return "unhealthy"
        if "(starting)" in lowered:
            return "starting"
        if "(healthy)" in lowered:
            return "healthy"
        return "running"

    if state == "exited":
        try:
            code = int(exit_code)
        except Exception:
            match = re.search(r"Exited \((\d+)\)", status)
            code = int(match.group(1)) if match else 0
        return "crashed" if code != 0 else "stopped"

    if state in {"created", "configured"}:
        return "stopped"
    if state in {"paused", "stopping"}:
        return state
    return state or "unknown"


def state_label(state):
    return {
        "healthy": "Healthy",
        "running": "Running",
        "starting": "Starting",
        "unhealthy": "Unhealthy",
        "crashed": "Crashed",
        "stopped": "Stopped",
        "paused": "Paused",
        "partial": "Partial",
        "trouble": "Trouble",
        "unknown": "Unknown",
    }.get(state, state.replace("-", " ").title())


def aggregate_state(services):
    if not services:
        return "stopped"

    considered = [svc for svc in services if not svc["protected"]]
    if not considered:
        considered = services

    states = [svc["state"] for svc in considered]
    if any(state in {"crashed", "unhealthy", "unknown"} for state in states):
        return "trouble"
    if any(state == "starting" for state in states):
        return "starting"
    if all(state in {"healthy", "running"} for state in states):
        return "healthy"
    if all(state == "stopped" for state in states):
        return "stopped"
    return "partial"


def project_summary(services):
    considered = [svc for svc in services if not svc["protected"]]
    protected = len(services) - len(considered)
    if not considered:
        considered = services
        protected = 0

    counts = Counter(svc["state"] for svc in considered)
    order = ["healthy", "running", "starting", "unhealthy", "crashed", "stopped", "paused", "unknown"]
    parts = []
    for state in order:
        count = counts.get(state, 0)
        if count:
            label = state_label(state).lower()
            parts.append(f"{count} {label}")
    if protected:
        parts.append(f"{protected} protected")
    return ", ".join(parts) if parts else "No services"


def action_for_state(state):
    return "pause" if state in {"healthy", "running", "starting", "partial"} else "play"


containers, error = run_podman_ps()
registry_paths = load_project_registry()
projects = defaultdict(lambda: {"containers": [], "labels": {}, "working_dir": ""})

for container in containers:
    labels = container.get("Labels") or {}
    project = labels.get("com.docker.compose.project")
    service = labels.get("com.docker.compose.service")
    if not project or not service:
        continue

    bucket = projects[project]
    bucket["containers"].append(container)
    bucket["labels"] = labels
    bucket["working_dir"] = labels.get("com.docker.compose.project.working_dir") or bucket["working_dir"]

last_project = ""
try:
    last_project = LAST_PROJECT_FILE.read_text().strip()
except Exception:
    pass

result_projects = []
for name, bucket in projects.items():
    working_dir = registry_paths.get(name) or bucket["working_dir"]
    metadata = load_compose_metadata(bucket["labels"], working_dir)
    services = []

    for container in bucket["containers"]:
        labels = container.get("Labels") or {}
        service_name = labels.get("com.docker.compose.service", container_name(container))
        meta = metadata.get(service_name, {})
        profiles = meta.get("profiles", [])
        has_build = bool(meta.get("has_build", False))
        protected = bool(profiles or has_build)
        reasons = []
        if profiles:
            reasons.append("profile")
        if has_build:
            reasons.append("build")

        state = service_state(container)
        services.append(
            {
                "name": service_name,
                "container": container_name(container),
                "state": state,
                "state_label": state_label(state),
                "status": str(container.get("Status") or ""),
                "exit_code": container.get("ExitCode"),
                "running": state in {"healthy", "running", "starting", "unhealthy"},
                "action": "none" if protected else ("pause" if state in {"healthy", "running", "starting"} else "play"),
                "profiles": profiles,
                "has_build": has_build,
                "protected": protected,
                "protect_reason": "/".join(reasons),
            }
        )

    services.sort(key=lambda svc: (svc["protected"], svc["name"]))
    project_state = aggregate_state(services)
    result_projects.append(
        {
            "name": name,
            "working_dir": working_dir,
            "state": project_state,
            "state_label": state_label(project_state),
            "summary": project_summary(services),
            "action": action_for_state(project_state),
            "attention": any((not svc["protected"]) and svc["state"] in {"crashed", "unhealthy", "unknown"} for svc in services),
            "protected_count": sum(1 for svc in services if svc["protected"]),
            "service_count": len(services),
            "services": services,
        }
    )

result_projects.sort(key=lambda project: (0 if project["name"] == last_project else 1, project["name"].lower()))
if not last_project and result_projects:
    last_project = result_projects[0]["name"]

print(
    json.dumps(
        {
            "generated_at": _dt.datetime.now(_dt.timezone.utc).isoformat(),
            "error": error,
            "last_project": last_project,
            "projects": result_projects,
        },
        separators=(",", ":"),
    )
)
PY
