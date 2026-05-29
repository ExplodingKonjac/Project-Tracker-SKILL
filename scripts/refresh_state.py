#!/usr/bin/env python3
"""Refresh .project-tracker/.state.json after tracker updates."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from tracker_state import TrackerError, docs_requiring_sources, refresh_docs, tracker_docs


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Refresh tracker state entries")
    parser.add_argument("docs", nargs="*", help="tracker-relative docs to refresh")
    parser.add_argument("--init", action="store_true", help="refresh all tracker docs")
    parser.add_argument("--tracker-dir", default=".project-tracker", help="tracker directory path")
    parser.add_argument("--json", action="store_true", dest="json_output", help="emit machine-readable JSON")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    tracker_dir = Path(args.tracker_dir)
    workspace = tracker_dir.resolve().parent if tracker_dir.name == ".project-tracker" else Path.cwd()
    if args.init or not args.docs:
        docs = tracker_docs(workspace)
    else:
        docs = args.docs
    try:
        result = refresh_docs(workspace, docs)
    except TrackerError as exc:
        print(f"[ERROR] {exc}")
        return 1
    if args.json_output:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"Refreshed {len(result['refreshed'])} tracker docs at {result['updated']}")
        for doc in result["refreshed"]:
            print(f"  {doc}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
