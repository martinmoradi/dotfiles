#!/usr/bin/env python3
"""PreToolUse guard for Bash commands.

Blocks high-blast-radius commands before they execute. Runs even in
bypassPermissions mode (the `cc` alias), so this is the last line of defense.
Exit 2 + stderr = blocked; Claude sees the reason and asks Martin instead.

Tune the patterns below; keep them high-signal — a guard that blocks
legitimate work gets disabled.
"""

import json
import os
import re
import subprocess
import sys

JUKKAI_PATHS = ("/home/martin/work/clients/jukkai", "/home/martin/src/pro/jukkai")
PROTECTED_BRANCHES = {"main", "master"}
# rm -rf targets that are never OK without asking
RM_DANGEROUS_EXACT = {"/", "~", "~/", "..", "../", "*", "$HOME", '"$HOME"', "/home/martin", "/home/martin/"}
RM_DANGEROUS_RE = re.compile(r"^/(etc|usr|var|boot|home|opt|srv|lib|lib64|bin|sbin)/?$")


def block(reason: str) -> None:
    sys.stderr.write(f"BLOCKED by ~/.claude/hooks/bash-guard.py: {reason}. "
                     "If this is genuinely intended, ask Martin to run it himself or to loosen the guard.\n")
    sys.exit(2)


def current_branch(cwd: str) -> str:
    try:
        out = subprocess.run(["git", "-C", cwd, "branch", "--show-current"],
                             capture_output=True, text=True, timeout=5)
        return out.stdout.strip()
    except Exception:
        return ""


def split_segments(cmd: str) -> list[str]:
    # Rough split on shell separators; good enough for finding rm/git invocations.
    return [s.strip() for s in re.split(r"(?:&&|\|\||[;|&\n])", cmd) if s.strip()]


def check_rm(segment: str) -> None:
    words = segment.split()
    while words and words[0] in ("sudo", "env", "command", "nohup", "time"):
        words = words[1:]
    if not words or words[0] != "rm":
        return
    flags = "".join(w for w in words[1:] if w.startswith("-"))
    if not (("r" in flags or "R" in flags) and "f" in flags):
        return
    targets = [w.strip("'\"") for w in words[1:] if not w.startswith("-")]
    for t in targets:
        expanded = os.path.expanduser(t) if t.startswith("~") else t
        if t in RM_DANGEROUS_EXACT or expanded in RM_DANGEROUS_EXACT or RM_DANGEROUS_RE.match(expanded):
            block(f"rm -rf on high-blast-radius target '{t}'")


def check_git_push(segment: str, cwd: str) -> None:
    if not re.match(r"^(sudo\s+)?git(\s+-C\s+\S+)?\s+push\b", segment):
        return
    words = segment.split()
    forced = any(w in ("--force", "-f") for w in words)
    refs = " ".join(w for w in words if not w.startswith("-"))
    targets_protected = bool(re.search(r"\b(main|master)\b", refs))
    if not targets_protected:
        branch = current_branch(cwd)
        targets_protected = branch in PROTECTED_BRANCHES
    if forced and targets_protected:
        block("force-push to main/master")
    if forced and "--force-with-lease" not in segment:
        block("force-push without --force-with-lease")
    # jukkai policy: never push main directly — branch + PR only
    if targets_protected and any(cwd.startswith(p) for p in JUKKAI_PATHS):
        block("direct push to main in a jukkai repo — policy is branch + PR")


def check_remote_prod(cmd: str) -> None:
    if not re.search(r"\bssh\s+coolify\b", cmd):
        return
    destructive = re.search(
        r"(?i)\b(drop\s+(table|database|schema)|truncate\s+table|truncate\s+\w|delete\s+from"
        r"|docker\s+(rm|rmi)\b|docker\s+volume\s+(rm|prune)|docker\s+system\s+prune"
        r"|compose\b[^|;&]*\bdown\b[^|;&]*-v|stanza-delete|rm\s+-[a-zA-Z]*[rR])",
        cmd,
    )
    if destructive:
        block(f"destructive command on the prod VPS via ssh coolify ('{destructive.group(0).strip()}')")


def check_misc(cmd: str) -> None:
    if re.search(r"\b(curl|wget)\b[^|;&]*\|\s*(sudo\s+)?(ba|z|da|fi)?sh\b", cmd):
        block("piping a downloaded script straight into a shell — download to a file and review it first")
    if re.search(r"\bmkfs\.|\bdd\s+[^;|&]*\bof=/dev/", cmd):
        block("raw disk write (mkfs/dd to /dev)")


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    cmd = (data.get("tool_input") or {}).get("command", "")
    if not cmd:
        sys.exit(0)
    cwd = data.get("cwd") or os.getcwd()

    check_misc(cmd)
    check_remote_prod(cmd)
    for segment in split_segments(cmd):
        check_rm(segment)
        check_git_push(segment, cwd)
    sys.exit(0)


if __name__ == "__main__":
    main()
