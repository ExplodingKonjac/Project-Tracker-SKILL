---
name: project-tracker-doctor
disable-model-invocation: false
description: >
  Check whether project tracker docs still match the current project state.
when_to_use: |
  User says "check tracker health", "validate tracker", "verify docs",
  "is the tracker accurate", or before starting important work to
  ensure the tracker is reliable.
---

# Project Tracker: Check Health

Validate that `.agents/project-tracker/` documents still reflect the actual project. Compares claims in tracker docs against current source code, configuration, and directory structure.

If `.agents/project-tracker/` is missing but legacy `.project-tracker/` or `.claude/project-tracker/` exists, validate the legacy tracker read-only and recommend creating the current tracker with `/project-tracker-init`.

Run this skill in a subagent so tracker-health verification does not consume the
main agent context with broad repo inspection details.

## Process

Use `<UPPER_SNAKE_CASE>` angle-bracket placeholders for pseudocode variables. Use `<PLUGIN_ROOT>` to mean the installed project-tracker plugin root. Resolve it from the agent harness when available, or from the directory that contains this skill's `skills/`, `scripts/`, and `templates/` directories. In this flattened plugin, the repository root and `plugins/project-tracker` symlink both resolve to the same plugin root. Replace `<PLUGIN_ROOT>` with that resolved absolute path before running shell snippets.

Before running the health check, spawn a subagent for this skill and let that
subagent own the scan, claim verification, and findings summary.

### 1. Scan Current State

Run the health scan from the workspace root:

```bash
python3 "<PLUGIN_ROOT>/scripts/scan_state.py" . .agents/project-tracker
```

This outputs five sections:

- **Git State** — current HEAD and branch
- **Tracker Staleness** — per-file STALE/OK status (each file checked against its own `baseline` from `.state.json`, current `matched_paths`, and front matter `sources`)
- **Unowned Files** — relevant project files not owned by any tracker doc or explicit exclusion
- **Config Snapshot** — current dependencies extracted from `Cargo.toml`, `package.json`, etc.
- **Directory Tree** — top 2 levels of the project structure
- **Existence Checks** — whether key directories and files exist

### 2. Verify Claims Per Tracker File

Read each tracker document and compare against the scan output or directly against source files:

| Tracker file        | What to verify                                                                                   | How                                                                                                          |
| ------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| `stack.md`          | Language/runtime version matches config                                                          | Compare edition field in `Cargo.toml`, `engines` in `package.json`, or `requires-python` in `pyproject.toml` |
| `stack.md`          | Listed dependencies exist in config                                                              | Cross-reference dependency names in tracker with `[dependencies]` / `dependencies` from config snapshot      |
| `toolchain.md`      | Build commands work                                                                              | Run `cargo check`, `npm run build`, etc. as dry-run (just check exit code, don't modify)                     |
| `toolchain.md`      | CI config exists                                                                                 | Check `.github/workflows/` or equivalent matches the description                                             |
| `architecture.md`   | Listed modules/dirs exist                                                                        | Compare module paths against directory tree output                                                           |
| `architecture.md`   | Entry points exist                                                                               | Check each mentioned entry point file directly                                                               |
| `conventions.md`    | Claimed linter/formatter configs exist                                                           | Check each config file path mentioned (`.eslintrc.js`, `rustfmt.toml`, etc.) exists                          |
| `conventions.md`    | `AGENTS.md`, `.agents/rules/`, `.claude/CLAUDE.md`, and `.claude/rules/` references are accurate | Compare claims against actual file contents                                                                  |
| `implementation.md` | Core files exist                                                                                 | Check each mentioned source file exists                                                                      |
| `data-model.md`     | Schema files exist                                                                               | Check each mentioned schema/migration file                                                                   |
| `api.md`            | Route files exist                                                                                | Check each mentioned route/handler file                                                                      |
| `deployment.md`     | Deploy configs exist                                                                             | Check Dockerfile, deploy scripts, k8s configs                                                                |
| `progress.md`       | Tick items are still accurate                                                                    | Check if completed items are actually in the code, add new findings                                          |
| `INDEX.md`          | Quick-ref commands still work                                                                    | Run each command as dry-run                                                                                  |

### 3. Report Results

For each finding, prefix with a severity:

| Prefix    | Meaning                                                                                                     |
| --------- | ----------------------------------------------------------------------------------------------------------- |
| `[ERROR]` | Tracker claims something that is factually wrong (dep listed but not in config, dir referenced but deleted) |
| `[WARN]`  | Tracker is stale (source changed since last update) or likely inaccurate                                    |
| `[INFO]`  | Minor drift, missing detail, or tracker still OK                                                            |

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

- Use `scan_state.py` for the mechanical parts (staleness, ownership gaps, config, directory). Do not read `.state.json` directly or run ad-hoc repository-wide scans unless you need to verify a specific claim.
- For config content comparisons, you may need to read specific config files directly — `scan_state.py` only extracts dependency names, not full content.
- If `.state.json` is missing, recommend running `/project-tracker-init` again before trusting stale checks.
- Report actionable findings only. Skip trivial observations like "file was reformatted".
- Do not modify any tracker files — this is read-only.
