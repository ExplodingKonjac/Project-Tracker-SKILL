---
name: project-tracker-update
disable-model-invocation: false
description: >
  Update project tracker documents when the project has changed since the
  last init or update. It detects per-file
  staleness and regenerates only the affected documents, preserving
  hand-edited content in unchanged files. Use after significant project
  changes: new dependencies, refactors, architecture changes, or any time
  the user says "update tracker", "sync project tracker", "refresh docs",
  or "is the tracker up to date".
when_to_use: |
  User says "update tracker", "sync project tracker", "refresh docs",
  or after significant project changes (new dependencies, refactors,
  architecture changes).
---

# Project Tracker: Update

Update `.agents/project-tracker/` documents by detecting per-file staleness since the last `init` or `update`. Each tracker file declares its own dependency boundary via front matter `sources`, while `.agents/project-tracker/.state.json` tracks baseline commits and resolved `matched_paths`.

Use `PLUGIN_ROOT` to mean the installed project-tracker plugin root. Resolve it from the agent harness when available, or from the directory that contains this skill's `skills/`, `scripts/`, and `templates/` directories. In this flattened plugin, the repository root and `plugins/project-tracker` symlink both resolve to the same plugin root. When running shell snippets, set `PLUGIN_ROOT` to that resolved absolute path first.

This skill reuses the same generation patterns as `/project-tracker-init` (from `PLUGIN_ROOT/skills/project-tracker-init/SKILL.md`) and the same templates (from `PLUGIN_ROOT/templates/`). Staleness detection is handled by `PLUGIN_ROOT/scripts/detect_changes.py`.

## Prerequisite

`.agents/project-tracker/.state.json` must exist. If not, tell the user:

> "No baseline found. Run `/project-tracker-init` first."

## Helper Script

A script at `PLUGIN_ROOT/scripts/detect_changes.py` handles staleness detection with per-file granularity.

Two modes:

**Full scan** — check all tracker files against their individual baselines:

```bash
python3 "PLUGIN_ROOT/scripts/detect_changes.py" .agents/project-tracker
```

Output shows per-file staleness:

```
=== Per-File Staleness ===
  stack.md             STALE (2 files)
      Cargo.toml
      src/expander.rs
  toolchain.md         OK
  architecture.md      STALE (1 files)
      src/lib.rs
  implementation.md    STALE (1 files)
      src/lib.rs
  deployment.md        OK
```

**Per-file check** — check a specific tracker file:

```bash
python3 "PLUGIN_ROOT/scripts/detect_changes.py" .agents/project-tracker stack.md
```

Output: `[stack.md] STALE (matched-file-changed)` or `[stack.md] OK`.

The script resolves each doc's front matter `sources`, compares the current match set to `.state.json`, and checks matched files against the doc baseline. New unmatched files are reported separately as ownership gaps.

## Process

### 1. Read Script-Owned State

`.agents/project-tracker/.state.json` stores one entry per tracker file, including `baseline`, `updated`, and `matched_paths`.

Each file tracks its own baseline independently. Staleness includes committed changes after the baseline plus current staged, unstaged, and untracked workspace changes, as well as changes to the resolved match set for `sources`.

### 2. Detect Which Files Are Stale

Run the full scan:

```bash
python3 "PLUGIN_ROOT/scripts/detect_changes.py" .agents/project-tracker
```

The script handles per-file state loading, source resolution, match-set comparison, and git diff checks.

Identify which tracker files are **STALE**, and resolve any reported unowned files before treating the tracker as current.

### 3. Regenerate Stale Documents Only

For each **STALE** tracker doc:

1. Re-read the project's current state (config files, directory tree, source structure — same scan as `init` step 1).
2. Update the doc content and, if needed, revise its front matter `sources`.
3. Use the template at `PLUGIN_ROOT/templates/<file>.tmpl` as the starting point when regenerating.
4. For new sub-projects or modules detected, create the corresponding `modules/*.md` file.
5. For files reported as unowned, either assign them to an existing doc's `sources`, create a new tracked doc, or add an explicit tracking exclusion.

Files marked **OK** are left untouched — this preserves any hand-edited content.

### 4. Refresh Script-Owned State

For each regenerated file, run:

```bash
python3 "PLUGIN_ROOT/scripts/refresh_state.py" stack.md architecture.md
```

The refresh script updates `baseline`, `updated`, and `matched_paths` for the listed docs. Do not edit `.state.json` manually.

### 5. Report

Summarize what changed per file:

> Updated: stack.md (new dep added), architecture.md (module restructured).  
> Skipped (no changes): toolchain.md, implementation.md, deployment.md.

## Rules

- Never touch tracker files whose sources haven't changed (marked OK by the script).
- If `.state.json` is missing or corrupt, abort — do not guess a baseline.
- If changes don't map to any existing tracker file, resolve them as ownership gaps rather than ignoring them.
- When regenerating, use `PLUGIN_ROOT/templates/` for structure and `PLUGIN_ROOT/scripts/detect_changes.py` plus `refresh_state.py` for state management.
- `progress.md` is flagged STALE whenever any non-tracker files changed. Unlike other files, do NOT auto-regenerate it from the template. Instead, read the current file, check `git log` and workspace changes since its baseline, and manually update the Completed / In Progress / Roadmap sections before refreshing its state entry.
