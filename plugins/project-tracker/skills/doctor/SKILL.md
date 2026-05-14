---
name: doctor
disable-model-invocation: true
description: >
  This skill should be used to validate project tracker documents against
  the actual project state. Run BEFORE starting important work (feature
  planning, refactoring, code review) to ensure the project tracker is
  reliable and up to date. The user may say "check tracker health",
  "validate tracker", "verify docs", "is the tracker accurate", or ask
  any question that would be misinformed by stale documentation.
when_to_use: |
  User says "check tracker health", "validate tracker", "verify docs",
  "is the tracker accurate", or before starting important work to
  ensure the tracker is reliable.
---

# Project Tracker: Check Health

Validate that `.claude/project-tracker/` documents still reflect the actual project. Compares claims in tracker docs against current source code, configuration, and directory structure.

## Process

### 1. Scan Current State

Run `scan-state.sh` from the workspace root:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/scan-state.sh <workspace-root>
```

This outputs five sections:
- **Git State** — current HEAD and branch
- **Tracker Staleness** — per-file STALE/OK status (each file checked against its own `baseline` from `.meta`)
- **Config Snapshot** — current dependencies extracted from `Cargo.toml`, `package.json`, etc.
- **Directory Tree** — top 2 levels of the project structure
- **Existence Checks** — whether key directories and files exist

### 2. Verify Claims Per Tracker File

Read each tracker document and compare against the scan output or directly against source files:

| Tracker file | What to verify | How |
|---|---|---|
| `stack.md` | Language/runtime version matches config | Compare edition field in `Cargo.toml`, `engines` in `package.json`, or `requires-python` in `pyproject.toml` |
| `stack.md` | Listed dependencies exist in config | Cross-reference dependency names in tracker with `[dependencies]` / `dependencies` from config snapshot |
| `toolchain.md` | Build commands work | Run `cargo check`, `npm run build`, etc. as dry-run (just check exit code, don't modify) |
| `toolchain.md` | CI config exists | Check `.github/workflows/` or equivalent matches the description |
| `architecture.md` | Listed modules/dirs exist | Compare module paths against directory tree output |
| `architecture.md` | Entry points exist | Check each mentioned entry point file directly |
| `implementation.md` | Core files exist | Check each mentioned source file exists |
| `data-model.md` | Schema files exist | Check each mentioned schema/migration file |
| `api.md` | Route files exist | Check each mentioned route/handler file |
| `deployment.md` | Deploy configs exist | Check Dockerfile, deploy scripts, k8s configs |
| `progress.md` | Tick items are still accurate | Check if completed items are actually in the code, add new findings |
| `INDEX.md` | Quick-ref commands still work | Run each command as dry-run |

### 3. Report Results

For each finding, prefix with a severity:

| Prefix | Meaning |
|--------|---------|
| `[ERROR]` | Tracker claims something that is factually wrong (dep listed but not in config, dir referenced but deleted) |
| `[WARN]` | Tracker is stale (source changed since last update) or likely inaccurate |
| `[INFO]` | Minor drift, missing detail, or tracker still OK |

Example output:

```
[ERROR] stack.md: claims dependency "clap 3" but Cargo.toml has "clap 4"
[ERROR] architecture.md: module "texpand-core/src/graph.rs" no longer exists
[WARN]  implementation.md: STALE — src/expander.rs changed since last update
[WARN]  toolchain.md: CI uses GitHub Actions but .github/workflows/ is missing
[INFO]  progress.md: "Phase 4: VSCode extension" is marked WIP but looks complete
[INFO]  all other files: OK
```

## Rules

- Use `scan-state.sh` for the mechanical parts (staleness, config, directory). Do not run ad-hoc `find`, `git diff`, or `grep` across the entire project.
- For config content comparisons, you may need to read specific config files directly — `scan-state.sh` only extracts dependency names, not full content.
- If `.meta` is missing, skip staleness checks but still compare content claims against current source.
- Report actionable findings only. Skip trivial observations like "file was reformatted".
- Do not modify any tracker files — this is read-only.
