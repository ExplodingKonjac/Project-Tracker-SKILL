#!/usr/bin/env python3
"""Scan workspace tracker health and current project state."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

from tracker_state import (
    config_snapshot,
    directory_tree,
    evaluate_workspace,
    existence_checks,
    git_inside_workspace,
    read_state,
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Scan tracker and workspace state")
    parser.add_argument("workspace", nargs="?", default=".", help="workspace root")
    parser.add_argument("tracker_dir", nargs="?", default=".project-tracker", help="tracker directory path")
    parser.add_argument("--json", action="store_true", dest="json_output", help="emit machine-readable JSON")
    return parser


def git_state(workspace: Path) -> dict[str, str]:
    if not git_inside_workspace(workspace):
        return {"head": "(not a git repo)", "branch": ""}
    head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=workspace, text=True, capture_output=True)
    branch = subprocess.run(["git", "symbolic-ref", "--short", "HEAD"], cwd=workspace, text=True, capture_output=True)
    return {
        "head": head.stdout.strip() if head.returncode == 0 else "unknown",
        "branch": branch.stdout.strip() if branch.returncode == 0 else "detached",
    }


def text_output(scan: dict) -> str:
    lines: list[str] = []
    lines.append("========================================")
    lines.append("Tracker Health Scan")
    lines.append("========================================")
    lines.append("")
    lines.append("=== Git State ===")
    lines.append(f"HEAD: {scan['git']['head']}")
    if scan["git"]["branch"]:
        lines.append(f"Branch: {scan['git']['branch']}")
    lines.append("")
    lines.append("=== Tracker Staleness ===")
    for doc in scan["tracker"]["documents"]:
        if doc["status"] == "OK":
            lines.append(f"  {doc['path']:<20} OK")
        else:
            lines.append(f"  {doc['path']:<20} {doc['status']} ({doc['reason']})")
            lines.extend(f"      {detail}" for detail in doc["details"])
    lines.append("")
    lines.append("=== Unowned Files ===")
    if scan["tracker"]["unowned_files"]:
        lines.extend(f"  {path}" for path in scan["tracker"]["unowned_files"])
    else:
        lines.append("  (none)")
    lines.append("")
    lines.append("=== Config Snapshot ===")
    if not scan["config"]:
        lines.append("  (none)")
    else:
        for name, value in scan["config"].items():
            lines.append(f"[ {name} ]")
            if isinstance(value, dict):
                for key, item in value.items():
                    lines.append(f"  {key}: {item}")
            else:
                for item in value:
                    lines.append(f"  {item}")
            lines.append("")
    lines.append("=== Directory Tree ===")
    for item in scan["directories"] or ["  (none)"]:
        lines.append(f"  {item}" if not item.startswith("  ") else item)
    lines.append("")
    lines.append("=== Existence Checks ===")
    for item in scan["checks"] or ["  (none)"]:
        lines.append(f"  {item}" if not item.startswith("  ") else item)
    lines.append("")
    lines.append("========================================")
    lines.append("Scan complete. Compare above against tracker docs.")
    return "\n".join(lines)


def main() -> int:
    args = build_parser().parse_args()
    workspace = Path(args.workspace).resolve()
    scan = {
        "git": git_state(workspace),
        "tracker": evaluate_workspace(workspace),
        "config": config_snapshot(workspace),
        "directories": directory_tree(workspace),
        "checks": existence_checks(workspace),
        "state": read_state(workspace),
    }
    if args.json_output:
        print(json.dumps(scan, indent=2, sort_keys=True))
    else:
        print(text_output(scan))
    has_doc_issue = any(doc["status"] != "OK" for doc in scan["tracker"]["documents"])
    return 1 if has_doc_issue or scan["tracker"]["unowned_files"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
