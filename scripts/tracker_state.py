#!/usr/bin/env python3
"""Shared tracker state helpers for project-tracker."""

from __future__ import annotations

import datetime as _dt
import fnmatch
import glob
import hashlib
import json
import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


TRACKER_DIR_ENV = "PROJECT_TRACKER_DIR"
TRACKER_DIRNAME = ".agents/project-tracker"
LEGACY_TRACKER_DIRNAME = ".project-tracker"
CLAUDE_LEGACY_TRACKER_DIRNAME = ".claude/project-tracker"
STATE_FILENAME = ".state.json"
STATE_VERSION = 1
PROGRESS_DOC = "progress.md"
DEFAULT_IGNORED_DIRS = {
    ".git",
    TRACKER_DIRNAME,
    LEGACY_TRACKER_DIRNAME,
    CLAUDE_LEGACY_TRACKER_DIRNAME,
    "node_modules",
    "target",
    "dist",
    "build",
    "__pycache__",
    ".venv",
    "venv",
    ".mypy_cache",
    ".pytest_cache",
    ".ruff_cache",
}
DEFAULT_IGNORED_FILES = {
    ".DS_Store",
}
RELEVANT_FILE_SUFFIXES = {
    ".md",
    ".json",
    ".toml",
    ".yaml",
    ".yml",
    ".sh",
    ".py",
    ".tmpl",
    ".txt",
    ".lock",
}
RELEVANT_FILE_NAMES = {
    "Dockerfile",
    "Makefile",
    "Justfile",
    "Jenkinsfile",
    "Taskfile.yml",
    "Taskfile.yaml",
    "CMakeLists.txt",
}
CONFIG_SNAPSHOT_FILES = (
    "Cargo.toml",
    "package.json",
    "pyproject.toml",
    "go.mod",
)
EXISTENCE_CHECK_DIRS = ("src", "lib", "app", "include", "tests")
EXISTENCE_CHECK_FILES = ("Dockerfile", "docker-compose.yml", "Makefile", ".github/workflows/ci.yml")


class TrackerError(RuntimeError):
    """Raised when tracker state is invalid."""


@dataclass
class DocumentSources:
    path: str
    has_front_matter: bool
    sources: list[str] | None
    error: str | None = None


def now_iso() -> str:
    return _dt.datetime.now(tz=_dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def normalize_path(path: os.PathLike[str] | str) -> str:
    value = Path(path).as_posix()
    return value[2:] if value.startswith("./") else value


def file_fingerprint(workspace: Path, rel_path: str) -> str:
    path = workspace / rel_path
    if not path.exists():
        return "missing"
    if not path.is_file():
        return "non-file"
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()


def file_fingerprints(workspace: Path, rel_paths: Iterable[str]) -> dict[str, str]:
    return {path: file_fingerprint(workspace, path) for path in sorted(set(rel_paths))}


def current_tracker_dirname() -> str:
    configured = os.environ.get(TRACKER_DIR_ENV, TRACKER_DIRNAME)
    return normalize_path(configured)


def tracker_dir(workspace: Path) -> Path:
    return workspace / current_tracker_dirname()


def tracker_env_value(tracker: Path, workspace: Path) -> str:
    resolved = tracker.resolve()
    try:
        return normalize_path(resolved.relative_to(workspace.resolve()))
    except ValueError:
        return normalize_path(tracker)


def workspace_from_tracker_dir(tracker: Path) -> Path:
    resolved = tracker.resolve()
    normalized = normalize_path(tracker)
    if normalized == TRACKER_DIRNAME:
        return resolved.parents[1]
    if normalized in {LEGACY_TRACKER_DIRNAME, CLAUDE_LEGACY_TRACKER_DIRNAME}:
        return resolved.parent if normalized == LEGACY_TRACKER_DIRNAME else resolved.parents[1]
    if normalized.endswith(f"/{TRACKER_DIRNAME}"):
        return resolved.parents[1]
    if normalized.endswith(f"/{LEGACY_TRACKER_DIRNAME}"):
        return resolved.parent
    if normalized.endswith(f"/{CLAUDE_LEGACY_TRACKER_DIRNAME}"):
        return resolved.parents[1]
    return Path.cwd()


def state_path(workspace: Path) -> Path:
    return tracker_dir(workspace) / STATE_FILENAME


def read_state(workspace: Path) -> dict:
    path = state_path(workspace)
    if not path.exists():
        return {"version": STATE_VERSION, "files": {}}
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or not isinstance(data.get("files"), dict):
        raise TrackerError(f"Invalid state file: {path}")
    return data


def write_state(workspace: Path, state: dict) -> None:
    state["version"] = STATE_VERSION
    state.setdefault("files", {})
    path = state_path(workspace)
    path.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def tracker_docs(workspace: Path) -> list[str]:
    docs: list[str] = []
    base = tracker_dir(workspace)
    if not base.exists():
        return docs
    for path in sorted(base.rglob("*.md")):
        rel = normalize_path(path.relative_to(base))
        if rel.startswith("references/"):
            continue
        docs.append(rel)
    return docs


def _parse_front_matter_block(text: str) -> tuple[bool, list[str] | None, str | None]:
    if not text.startswith("---\n"):
        return False, None, None
    closing = text.find("\n---\n", 4)
    if closing == -1:
        return True, None, "front matter is not closed"
    block = text[4:closing]
    lines = block.splitlines()
    sources_started = False
    sources: list[str] = []
    saw_other_key = False
    for raw in lines:
        if not raw.strip():
            continue
        if raw.startswith("sources:"):
            if raw.strip() != "sources:":
                return True, None, "sources must be a flat list"
            sources_started = True
            continue
        if not sources_started:
            saw_other_key = True
            continue
        stripped = raw.strip()
        if not stripped.startswith("- "):
            return True, None, "sources entries must use '- value'"
        value = stripped[2:].strip()
        if not value:
            sources.append("")
            continue
        if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
            value = value[1:-1]
        sources.append(value)
    if not sources_started:
        if saw_other_key:
            return True, None, "sources key is missing"
        return True, None, "sources key is missing"
    return True, sources, None


def load_doc_sources(workspace: Path, doc_rel: str) -> DocumentSources:
    path = tracker_dir(workspace) / doc_rel
    text = path.read_text(encoding="utf-8")
    has_front_matter, sources, error = _parse_front_matter_block(text)
    if doc_rel == PROGRESS_DOC:
        return DocumentSources(path=doc_rel, has_front_matter=has_front_matter, sources=[] if has_front_matter else None, error=error)
    if not has_front_matter:
        return DocumentSources(path=doc_rel, has_front_matter=False, sources=None, error=None)
    if error:
        return DocumentSources(path=doc_rel, has_front_matter=True, sources=None, error=error)
    cleaned = [source.strip() for source in (sources or []) if source.strip()]
    if not cleaned:
        return DocumentSources(path=doc_rel, has_front_matter=True, sources=[], error=None)
    return DocumentSources(path=doc_rel, has_front_matter=True, sources=cleaned, error=None)


def parse_tracking_exclusions(workspace: Path) -> list[str]:
    index_path = tracker_dir(workspace) / "INDEX.md"
    if not index_path.exists():
        return []
    text = index_path.read_text(encoding="utf-8")
    lines = text.splitlines()
    in_section = False
    exclusions: list[str] = []
    for line in lines:
        if line.startswith("## "):
            if line.strip() == "## Tracking Exclusions":
                in_section = True
                continue
            if in_section:
                break
        if not in_section:
            continue
        stripped = line.strip()
        if not stripped.startswith("- "):
            continue
        if "`" in stripped:
            start = stripped.find("`")
            end = stripped.find("`", start + 1)
            if start != -1 and end != -1:
                exclusions.append(stripped[start + 1 : end].strip())
                continue
        value = stripped[2:].split(" -- ", 1)[0].split(":", 1)[0].strip()
        if value:
            exclusions.append(value)
    return [entry for entry in exclusions if entry]


def _pattern_has_hidden_segment(pattern: str) -> bool:
    for segment in pattern.split("/"):
        if segment.startswith(".") and segment not in {".", ".."}:
            return True
    return False


def _path_contains_hidden_segment(path: str) -> bool:
    for segment in path.split("/"):
        if segment.startswith(".") and segment not in {".", ".."}:
            return True
    return False


def _is_tracker_internal(pattern: str) -> bool:
    normalized = normalize_path(pattern)
    return any(
        normalized.startswith(f"{tracker_name}/")
        for tracker_name in (TRACKER_DIRNAME, LEGACY_TRACKER_DIRNAME, CLAUDE_LEGACY_TRACKER_DIRNAME)
    )


def resolve_sources(workspace: Path, sources: Iterable[str]) -> tuple[list[str], list[str]]:
    matched: set[str] = set()
    errors: list[str] = []
    for source in sources:
        if not source:
            errors.append("empty source pattern")
            continue
        if os.path.isabs(source):
            errors.append(f"absolute source is not allowed: {source}")
            continue
        normalized = normalize_path(source)
        if _is_tracker_internal(normalized):
            errors.append(f"tracker-internal source is not allowed: {source}")
            continue
        has_hidden = _pattern_has_hidden_segment(normalized)
        pattern = str(workspace / normalized)
        for candidate in glob.glob(pattern, recursive=True):
            candidate_path = Path(candidate)
            if not candidate_path.is_file():
                continue
            rel = normalize_path(candidate_path.relative_to(workspace))
            if not has_hidden and _path_contains_hidden_segment(rel):
                continue
            if rel.startswith(".git/") or _is_tracker_internal(rel):
                continue
            matched.add(rel)
    return sorted(matched), errors


def get_baseline(workspace: Path) -> str:
    try:
        return run_git(workspace, ["rev-parse", "HEAD"]).strip()
    except TrackerError:
        return "none"


def run_git(workspace: Path, args: list[str]) -> str:
    cmd = ["git", *args]
    result = subprocess.run(cmd, cwd=workspace, text=True, capture_output=True)
    if result.returncode != 0:
        raise TrackerError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout


def git_inside_workspace(workspace: Path) -> bool:
    result = subprocess.run(["git", "rev-parse", "--is-inside-work-tree"], cwd=workspace, text=True, capture_output=True)
    return result.returncode == 0 and result.stdout.strip() == "true"


def changed_files_since_baseline(workspace: Path, baseline: str) -> set[str]:
    changed: set[str] = set()
    if not git_inside_workspace(workspace):
        return changed
    commands: list[list[str]] = []
    if baseline and baseline != "none":
        verify = subprocess.run(["git", "cat-file", "-e", baseline], cwd=workspace, text=True, capture_output=True)
        if verify.returncode == 0:
            commands.append(["git", "diff", "--name-only", f"{baseline}..HEAD"])
    commands.extend(
        [
            ["git", "diff", "--cached", "--name-only"],
            ["git", "diff", "--name-only"],
            ["git", "ls-files", "--others", "--exclude-standard"],
        ]
    )
    for command in commands:
        result = subprocess.run(command, cwd=workspace, text=True, capture_output=True)
        if result.returncode != 0:
            continue
        for line in result.stdout.splitlines():
            path = normalize_path(line.strip())
            if path:
                changed.add(path)
    return changed


def _should_ignore_dir(rel_dir: str) -> bool:
    return rel_dir in DEFAULT_IGNORED_DIRS or rel_dir.startswith(".git/")


def _is_relevant_file(rel_path: str) -> bool:
    name = Path(rel_path).name
    suffix = Path(rel_path).suffix
    return suffix in RELEVANT_FILE_SUFFIXES or name in RELEVANT_FILE_NAMES


def collect_relevant_files(workspace: Path) -> list[str]:
    files: list[str] = []
    for root, dirs, filenames in os.walk(workspace, topdown=True, followlinks=False):
        root_path = Path(root)
        rel_root = normalize_path(root_path.relative_to(workspace)) if root_path != workspace else ""
        filtered_dirs: list[str] = []
        for directory in dirs:
            rel_dir = normalize_path(Path(rel_root, directory)) if rel_root else directory
            full_dir = root_path / directory
            if full_dir.is_symlink():
                continue
            if _should_ignore_dir(rel_dir):
                continue
            filtered_dirs.append(directory)
        dirs[:] = filtered_dirs
        for filename in filenames:
            rel = normalize_path(Path(rel_root, filename)) if rel_root else filename
            if rel.startswith(".git/") or _is_tracker_internal(rel):
                continue
            if filename in DEFAULT_IGNORED_FILES:
                continue
            if _is_relevant_file(rel):
                files.append(rel)
    return sorted(set(files))


def file_matches_any(path: str, patterns: Iterable[str]) -> bool:
    normalized = normalize_path(path)
    for pattern in patterns:
        if fnmatch.fnmatch(normalized, pattern):
            return True
    return False


def collect_unowned_files(workspace: Path, doc_matches: dict[str, list[str]], exclusions: list[str]) -> list[str]:
    owned: set[str] = set()
    for matches in doc_matches.values():
        owned.update(matches)
    unowned: list[str] = []
    for path in collect_relevant_files(workspace):
        if path in owned:
            continue
        if file_matches_any(path, exclusions):
            continue
        unowned.append(path)
    return sorted(unowned)


def docs_requiring_sources(workspace: Path) -> list[str]:
    return [doc for doc in tracker_docs(workspace) if doc != PROGRESS_DOC]


def non_tracker_changed_files(workspace: Path, baseline: str) -> list[str]:
    return sorted(
        path
        for path in changed_files_since_baseline(workspace, baseline)
        if not _is_tracker_internal(path)
        if not (workspace / path).exists() or (workspace / path).is_file()
    )


def unrefreshed_changed_files(workspace: Path, changed: Iterable[str], entry: dict) -> list[str]:
    changed_paths = sorted(set(changed))
    if not changed_paths:
        return []
    stored = entry.get("changed_fingerprints", {})
    if not isinstance(stored, dict):
        return changed_paths
    stale: list[str] = []
    for path in changed_paths:
        if stored.get(path) != file_fingerprint(workspace, path):
            stale.append(path)
    return stale


def evaluate_doc(workspace: Path, doc_rel: str, state: dict) -> tuple[dict, list[str]]:
    doc_path = tracker_dir(workspace) / doc_rel
    if not doc_path.exists():
        return {"path": doc_rel, "status": "STALE", "reason": "missing-doc", "details": []}, []

    entry = state.get("files", {}).get(doc_rel, {})
    baseline = entry.get("baseline", "none")
    stored_matches = sorted(entry.get("matched_paths", []))

    if doc_rel == PROGRESS_DOC:
        changed = non_tracker_changed_files(workspace, baseline)
        stale_changed = unrefreshed_changed_files(workspace, changed, entry)
        if stale_changed:
            return {"path": doc_rel, "status": "STALE", "reason": "matched-file-changed", "details": stale_changed}, []
        return {"path": doc_rel, "status": "OK", "reason": None, "details": []}, []

    sources_info = load_doc_sources(workspace, doc_rel)
    if not sources_info.has_front_matter:
        return {"path": doc_rel, "status": "STALE", "reason": "missing-sources", "details": []}, []
    if sources_info.error:
        return {"path": doc_rel, "status": "STALE", "reason": "invalid-sources", "details": [sources_info.error]}, []
    if sources_info.sources is None:
        return {"path": doc_rel, "status": "STALE", "reason": "missing-sources", "details": []}, []
    current_matches, errors = resolve_sources(workspace, sources_info.sources)
    if errors:
        return {"path": doc_rel, "status": "STALE", "reason": "invalid-sources", "details": errors}, current_matches
    if current_matches != stored_matches:
        details = sorted(set(current_matches).symmetric_difference(stored_matches))
        return {"path": doc_rel, "status": "STALE", "reason": "match-set-changed", "details": details}, current_matches
    changed = sorted(set(changed_files_since_baseline(workspace, baseline)).intersection(current_matches))
    stale_changed = unrefreshed_changed_files(workspace, changed, entry)
    if stale_changed:
        return {"path": doc_rel, "status": "STALE", "reason": "matched-file-changed", "details": stale_changed}, current_matches
    return {"path": doc_rel, "status": "OK", "reason": None, "details": []}, current_matches


def evaluate_workspace(workspace: Path, docs: Iterable[str] | None = None) -> dict:
    state = read_state(workspace)
    doc_paths = sorted(set(docs or tracker_docs(workspace)))
    for state_doc in state.get("files", {}):
        if state_doc not in doc_paths:
            doc_paths.append(state_doc)
    doc_statuses: list[dict] = []
    doc_matches: dict[str, list[str]] = {}
    for doc in doc_paths:
        status, matches = evaluate_doc(workspace, doc, state)
        doc_statuses.append(status)
        doc_matches[doc] = matches
    exclusions = parse_tracking_exclusions(workspace)
    unowned = collect_unowned_files(workspace, doc_matches, exclusions)
    return {
        "documents": sorted(doc_statuses, key=lambda item: item["path"]),
        "unowned_files": unowned,
        "exclusions": exclusions,
        "state": state,
    }


def refresh_docs(workspace: Path, docs: Iterable[str]) -> dict:
    doc_list = sorted(set(docs))
    state = read_state(workspace)
    files = state.setdefault("files", {})
    baseline = get_baseline(workspace)
    updated = now_iso()
    refreshed: list[str] = []
    for doc_rel in doc_list:
        doc_path = tracker_dir(workspace) / doc_rel
        if not doc_path.exists():
            raise TrackerError(f"Cannot refresh missing tracker doc: {doc_rel}")
        if doc_rel != PROGRESS_DOC:
            sources_info = load_doc_sources(workspace, doc_rel)
            if not sources_info.has_front_matter:
                raise TrackerError(f"{doc_rel} is missing sources front matter")
            if sources_info.error:
                raise TrackerError(f"{doc_rel} has invalid sources: {sources_info.error}")
            if not sources_info.sources:
                raise TrackerError(f"{doc_rel} must declare at least one non-empty source")
            matched_paths, errors = resolve_sources(workspace, sources_info.sources)
            if errors:
                raise TrackerError(f"{doc_rel} has invalid sources: {'; '.join(errors)}")
            changed_paths = sorted(set(changed_files_since_baseline(workspace, baseline)).intersection(matched_paths))
        else:
            matched_paths = []
            changed_paths = non_tracker_changed_files(workspace, baseline)
        files[doc_rel] = {
            "baseline": baseline,
            "updated": updated,
            "matched_paths": matched_paths,
            "changed_fingerprints": file_fingerprints(workspace, changed_paths),
        }
        refreshed.append(doc_rel)
    write_state(workspace, state)
    return {"baseline": baseline, "updated": updated, "refreshed": refreshed}


def config_snapshot(workspace: Path) -> dict[str, list[str] | dict[str, str]]:
    snapshot: dict[str, list[str] | dict[str, str]] = {}
    cargo = workspace / "Cargo.toml"
    if cargo.exists():
        lines = []
        current_section = None
        for line in cargo.read_text(encoding="utf-8").splitlines():
            stripped = line.strip()
            if stripped.startswith("[") and stripped.endswith("]"):
                current_section = stripped
                if stripped in {"[package]", "[workspace]", "[dependencies]", "[build-dependencies]"}:
                    lines.append(stripped)
            elif current_section == "[dependencies]" and stripped and "=" in stripped and not stripped.startswith("#"):
                lines.append(stripped.split("=", 1)[0].strip())
        snapshot["Cargo.toml"] = lines
    package = workspace / "package.json"
    if package.exists():
        data = json.loads(package.read_text(encoding="utf-8"))
        snapshot["package.json"] = {
            "name": str(data.get("name", "")),
            "version": str(data.get("version", "")),
            "deps": ", ".join(sorted((data.get("dependencies") or {}).keys())) or "(none)",
            "devDeps": ", ".join(sorted((data.get("devDependencies") or {}).keys())) or "(none)",
        }
    pyproject = workspace / "pyproject.toml"
    if pyproject.exists():
        lines = [
            line.strip()
            for line in pyproject.read_text(encoding="utf-8").splitlines()
            if line.startswith(("name", "version", "requires-python", "dependencies"))
        ]
        snapshot["pyproject.toml"] = lines
    gomod = workspace / "go.mod"
    if gomod.exists():
        snapshot["go.mod"] = gomod.read_text(encoding="utf-8").splitlines()[:5]
    return snapshot


def directory_tree(workspace: Path, max_depth: int = 2) -> list[str]:
    results: list[str] = []
    for root, dirs, files in os.walk(workspace, topdown=True, followlinks=False):
        root_path = Path(root)
        rel_root = normalize_path(root_path.relative_to(workspace)) if root_path != workspace else ""
        depth = 0 if not rel_root else rel_root.count("/") + 1
        filtered_dirs: list[str] = []
        for directory in dirs:
            rel_dir = normalize_path(Path(rel_root, directory)) if rel_root else directory
            full_dir = root_path / directory
            if full_dir.is_symlink() or _should_ignore_dir(rel_dir):
                continue
            filtered_dirs.append(directory)
        dirs[:] = filtered_dirs
        if rel_root and depth <= max_depth:
            results.append(f"{rel_root}/  ({len(files)} files)")
        if depth >= max_depth:
            dirs[:] = []
    return sorted(results)


def existence_checks(workspace: Path) -> list[str]:
    checks: list[str] = []
    for directory in EXISTENCE_CHECK_DIRS:
        path = workspace / directory
        if path.exists() and path.is_dir():
            count = sum(1 for child in path.iterdir() if child.is_dir())
            checks.append(f"{directory}/  EXISTS ({count} subdirectories)" if count else f"{directory}/  EXISTS")
    for filename in EXISTENCE_CHECK_FILES:
        path = workspace / filename
        if path.exists():
            checks.append(f"{filename}  EXISTS")
    return checks
