#!/usr/bin/env python3
"""Detect tracker staleness from front matter sources and JSON state."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

from tracker_state import TRACKER_DIR_ENV, TRACKER_DIRNAME, evaluate_workspace, tracker_baseline_error, tracker_docs, tracker_env_value, workspace_from_tracker_dir


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Detect project-tracker staleness")
    parser.add_argument("tracker", nargs="?", default=TRACKER_DIRNAME, help="tracker directory path")
    parser.add_argument("doc", nargs="?", help="single tracker doc to inspect")
    parser.add_argument("--json", action="store_true", dest="json_output", help="emit machine-readable JSON")
    return parser


def _text_output(result: dict, single_doc: str | None) -> str:
    documents = result["documents"]
    unowned = result["unowned_files"]
    lines: list[str] = []
    if single_doc:
        doc = next((item for item in documents if item["path"] == single_doc), {"path": single_doc, "status": "STALE", "reason": "missing-doc", "details": []})
        if doc["status"] == "OK" and not unowned:
            return f"[{doc['path']}] OK"
        if doc["status"] == "OK" and unowned:
            lines.append(f"[{doc['path']}] OK")
        else:
            lines.append(f"[{doc['path']}] {doc['status']} ({doc['reason']})")
            lines.extend(f"  {detail}" for detail in doc["details"])
        if unowned:
            lines.append("")
            lines.append("=== Unowned Files ===")
            lines.extend(f"  {path}" for path in unowned)
        return "\n".join(lines)

    lines.append("=== Tracker Staleness ===")
    any_issue = False
    for doc in documents:
        if doc["status"] == "OK":
            lines.append(f"  {doc['path']:<20} OK")
            continue
        any_issue = True
        lines.append(f"  {doc['path']:<20} {doc['status']} ({doc['reason']})")
        lines.extend(f"      {detail}" for detail in doc["details"])
    if not any_issue:
        lines.append("  (all tracked docs are up to date)")
    lines.append("")
    lines.append("=== Unowned Files ===")
    if unowned:
        lines.extend(f"  {path}" for path in unowned)
    else:
        lines.append("  (none)")
    return "\n".join(lines)


def main() -> int:
    args = build_parser().parse_args()
    tracker_dir = Path(args.tracker)
    workspace = workspace_from_tracker_dir(tracker_dir)
    os.environ[TRACKER_DIR_ENV] = tracker_env_value(tracker_dir, workspace)
    baseline_error = tracker_baseline_error(workspace)
    if baseline_error:
        if args.json_output:
            print(json.dumps({"error": baseline_error}, indent=2, sort_keys=True))
        else:
            print(baseline_error)
        return 1
    doc_list = [args.doc] if args.doc else tracker_docs(workspace)
    result = evaluate_workspace(workspace, docs=doc_list)
    if args.doc:
        result["documents"] = [item for item in result["documents"] if item["path"] == args.doc] or [{"path": args.doc, "status": "STALE", "reason": "missing-doc", "details": []}]
    if args.json_output:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(_text_output(result, args.doc))
    has_doc_issue = any(doc["status"] != "OK" for doc in result["documents"])
    return 1 if has_doc_issue or result["unowned_files"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
