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

Update `.project-tracker/` documents by detecting per-file staleness since the last `init` or `update`. Each tracker file tracks its own baseline in `.meta` — only regenerate files whose relevant sources changed.

This skill reuses the same generation patterns as `/project-tracker-init` (from `${CLAUDE_PLUGIN_ROOT}/skills/project-tracker-init/SKILL.md`) and the same templates (from `${CLAUDE_PLUGIN_ROOT}/templates/`). Staleness detection is handled by `${CLAUDE_PLUGIN_ROOT}/scripts/detect-changes.sh`, powered by the shared `tracker-common.sh` library.

## Prerequisite

`.project-tracker/.meta` must exist. If not, tell the user:

> "No baseline found. Run `/project-tracker-init` first."

If legacy `.claude/project-tracker/.meta` exists but `.project-tracker/.meta` does not, do not update the legacy tracker. Tell the user:

> "Found only a legacy tracker at `.claude/project-tracker/`. Run `/project-tracker-init` to create the universal `.project-tracker/` tracker before updating."

## Helper Script

A script at `${CLAUDE_PLUGIN_ROOT}/scripts/detect-changes.sh` handles staleness detection with per-file granularity.

Two modes:

**Full scan** — check all tracker files against their individual baselines:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/detect-changes.sh .project-tracker/.meta
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
bash ${CLAUDE_PLUGIN_ROOT}/scripts/detect-changes.sh .project-tracker/.meta stack.md
```

Output: `[stack.md] STALE (2 relevant files changed)` or `[stack.md] OK`.

The script uses each file's individual `baseline` from `.meta` and filters against only the source patterns relevant to that tracker doc. No ad-hoc `git diff` needed.

## Process

### 1. Read Per-File Baselines

`.project-tracker/.meta` stores one entry per tracker file:

```yaml
files:
  stack.md:
    baseline: a1b2c3d
    updated: 2026-05-11T13:00:00Z
  toolchain.md:
    baseline: e5f6g7h
    updated: 2026-05-12T09:00:00Z
  ...
```

Each file tracks its own baseline independently. Files updated at different times have different baselines.

### 2. Detect Which Files Are Stale

Run the full scan:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/detect-changes.sh .project-tracker/.meta
```

The script handles per-file baseline extraction, git diff per baseline (or mtime fallback), and source-pattern filtering.

Identify which tracker files are **STALE** — their relevant sources changed since their individual baseline.

### 3. Regenerate Stale Documents Only

For each **STALE** tracker doc:

1. Re-read the project's current state (config files, directory tree, source structure — same scan as `init` step 1).
2. Use the template at `${CLAUDE_PLUGIN_ROOT}/templates/<file>.tmpl` as the starting point (same as `init`).
3. Regenerate the file fully from current project state, following the same approach as `/project-tracker-init`.
4. For new sub-projects or modules detected, create the corresponding `modules/*.md` file.

Files marked **OK** are left untouched — this preserves any hand-edited content.

### 4. Update Per-File Baseline

For each regenerated file, update its entry in `.meta`:

```yaml
files:
  stack.md:
    baseline: <new HEAD commit hash, or "none">
    updated: <current ISO 8601 timestamp>
  # unchanged files keep their old entries as-is
```

Do not touch entries for files that were not regenerated.

### 5. Report

Summarize what changed per file:

> Updated: stack.md (new dep added), architecture.md (module restructured).  
> Skipped (no changes): toolchain.md, implementation.md, deployment.md.

## Rules

- Never touch tracker files whose sources haven't changed (marked OK by the script).
- If `.meta` is missing or corrupt, abort — do not guess a baseline.
- If changes don't map to any existing tracker file, note it to the user.
- When regenerating, use `${CLAUDE_PLUGIN_ROOT}/templates/` for structure and `${CLAUDE_PLUGIN_ROOT}/scripts/detect-changes.sh` for staleness — do not write ad-hoc detection scripts.
- `progress.md` is flagged STALE whenever any files changed (any change is potentially progress). Unlike other files, do NOT auto-regenerate it from the template. Instead, read the current file, check `git log` since its baseline, and manually update the Completed / In Progress / Roadmap sections. If nothing meaningful happened, leave it unchanged and update only its baseline.
