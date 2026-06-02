#!/usr/bin/env python3
"""Scenario tests for tracker staleness and ownership gaps."""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
from pathlib import Path

from tracker_state import read_state


ROOT = Path(__file__).resolve().parent
TRACKER_DIR = ".agents/project-tracker"


def run(cmd: list[str], cwd: Path) -> str:
    result = subprocess.run(cmd, cwd=cwd, text=True, capture_output=True)
    if result.returncode != 0:
        raise AssertionError(f"Command failed: {' '.join(cmd)}\nSTDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}")
    return result.stdout


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def tracker_doc(title: str, sources: list[str] | None) -> str:
    if sources is None:
        return f"# {title}\n"
    lines = ["---", "sources:"]
    lines.extend(f'  - "{source}"' for source in sources)
    lines.extend(["---", f"# {title}", ""])
    return "\n".join(lines)


def create_fixture() -> Path:
    scratch_root = ROOT.parent / ".tmp-test-fixtures"
    scratch_root.mkdir(exist_ok=True)
    workspace = Path(tempfile.mkdtemp(dir=scratch_root))
    run(["git", "init", "-q"], workspace)
    write(workspace / f"{TRACKER_DIR}/INDEX.md", tracker_doc("Index", ["README.md"]) + "## Tracking Exclusions\n- `evals/**` -- evaluation artifacts\n")
    write(workspace / f"{TRACKER_DIR}/architecture.md", tracker_doc("Architecture", ["src/**/*.js", "src/**/*.ts"]))
    write(workspace / f"{TRACKER_DIR}/modules/core.md", tracker_doc("Core", ["src/**/*.js"]))
    write(workspace / f"{TRACKER_DIR}/api.md", tracker_doc("API", ["openapi.yaml", "graphql/**/*.graphql"]))
    write(workspace / f"{TRACKER_DIR}/data-model.md", tracker_doc("Data", ["models/**/*.py"]))
    write(workspace / f"{TRACKER_DIR}/deployment.md", tracker_doc("Deployment", ["terraform/**/*.tf"]))
    write(workspace / f"{TRACKER_DIR}/stack.md", tracker_doc("Stack", ["package.json", "pnpm-lock.yaml"]))
    write(workspace / f"{TRACKER_DIR}/toolchain.md", tracker_doc("Toolchain", ["tsconfig.json", "vite.config.ts", "scripts/**/*.sh"]))
    write(workspace / f"{TRACKER_DIR}/progress.md", "# Progress\n")
    write(workspace / "README.md", "hello\n")
    write(workspace / "src/main.js", "console.log('hello')\n")
    run(["git", "add", "."], workspace)
    run(["git", "-c", "user.email=test@example.com", "-c", "user.name=Test", "commit", "-q", "-m", "baseline"], workspace)
    run(["python3", str(ROOT / "refresh_state.py"), "--init"], workspace)
    return workspace


def detect(workspace: Path, *args: str) -> tuple[int, str]:
    result = subprocess.run(["python3", str(ROOT / "detect_changes.py"), *args], cwd=workspace, text=True, capture_output=True)
    return result.returncode, result.stdout


def detect_json(workspace: Path, *args: str) -> dict:
    result = subprocess.run(["python3", str(ROOT / "detect_changes.py"), "--json", *args], cwd=workspace, text=True, capture_output=True)
    if result.returncode not in {0, 1}:
        raise AssertionError(result.stderr or result.stdout)
    return json.loads(result.stdout)


def assert_contains(haystack: str, needle: str, label: str) -> None:
    if needle not in haystack:
        raise AssertionError(f"{label}: expected to find {needle!r}\n{haystack}")


def test_matched_file_changed() -> None:
    workspace = create_fixture()
    try:
        write(workspace / "src/main.js", "console.log('updated')\n")
        code, out = detect(workspace, TRACKER_DIR, "architecture.md")
        assert code == 1
        assert_contains(out, "matched-file-changed", "matched file reason")
        assert_contains(out, "src/main.js", "matched file path")
    finally:
        shutil.rmtree(workspace)


def test_match_set_changed() -> None:
    workspace = create_fixture()
    try:
        write(workspace / "src/extra.ts", "export const extra = true\n")
        code, out = detect(workspace, TRACKER_DIR, "architecture.md")
        assert code == 1
        assert_contains(out, "match-set-changed", "match set reason")
        assert_contains(out, "src/extra.ts", "new match path")
    finally:
        shutil.rmtree(workspace)


def test_unowned_file() -> None:
    workspace = create_fixture()
    try:
        write(workspace / "scripts/helper.py", "print('hi')\n")
        code, out = detect(workspace)
        assert code == 1
        assert_contains(out, "=== Unowned Files ===", "unowned header")
        assert_contains(out, "scripts/helper.py", "unowned path")
    finally:
        shutil.rmtree(workspace)


def test_exclusion_suppresses_unowned() -> None:
    workspace = create_fixture()
    try:
        write(workspace / "evals/result.md", "skip me\n")
        payload = detect_json(workspace)
        assert "evals/result.md" not in payload["unowned_files"]
    finally:
        shutil.rmtree(workspace)


def test_missing_sources() -> None:
    workspace = create_fixture()
    try:
        write(workspace / f"{TRACKER_DIR}/stack.md", "# Stack\n")
        code, out = detect(workspace, TRACKER_DIR, "stack.md")
        assert code == 1
        assert_contains(out, "missing-sources", "missing sources reason")
    finally:
        shutil.rmtree(workspace)


def test_refresh_updates_only_targeted_docs() -> None:
    workspace = create_fixture()
    try:
        write(workspace / "src/extra.ts", "export const extra = true\n")
        run(["python3", str(ROOT / "refresh_state.py"), "architecture.md"], workspace)
        state = read_state(workspace)
        assert "src/extra.ts" in state["files"]["architecture.md"]["matched_paths"]
        assert "src/extra.ts" not in state["files"]["modules/core.md"]["matched_paths"]
        code, out = detect(workspace, TRACKER_DIR, "architecture.md")
        if code != 0:
            raise AssertionError(out)
    finally:
        shutil.rmtree(workspace)


def test_refresh_tracks_dirty_file_fingerprints() -> None:
    workspace = create_fixture()
    try:
        write(workspace / "src/main.js", "console.log('reviewed dirty state')\n")
        run(["python3", str(ROOT / "refresh_state.py"), "architecture.md"], workspace)
        code, out = detect(workspace, TRACKER_DIR, "architecture.md")
        if code != 0:
            raise AssertionError(out)

        write(workspace / "src/main.js", "console.log('changed after refresh')\n")
        code, out = detect(workspace, TRACKER_DIR, "architecture.md")
        assert code == 1
        assert_contains(out, "src/main.js", "changed after refresh")
    finally:
        shutil.rmtree(workspace)


def test_progress_refresh_tracks_dirty_workspace_fingerprints() -> None:
    workspace = create_fixture()
    try:
        write(workspace / "README.md", "reviewed progress input\n")
        run(["python3", str(ROOT / "refresh_state.py"), "progress.md"], workspace)
        code, out = detect(workspace, TRACKER_DIR, "progress.md")
        if code != 0:
            raise AssertionError(out)

        write(workspace / "README.md", "changed after progress refresh\n")
        code, out = detect(workspace, TRACKER_DIR, "progress.md")
        assert code == 1
        assert_contains(out, "README.md", "progress changed after refresh")
    finally:
        shutil.rmtree(workspace)


def main() -> int:
    for test in [
        test_matched_file_changed,
        test_match_set_changed,
        test_unowned_file,
        test_exclusion_suppresses_unowned,
        test_missing_sources,
        test_refresh_updates_only_targeted_docs,
        test_refresh_tracks_dirty_file_fingerprints,
        test_progress_refresh_tracks_dirty_workspace_fingerprints,
    ]:
        test()
    print("Tracker staleness tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
