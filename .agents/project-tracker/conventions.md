---
sources:
  - "README.md"
  - ".claude/CLAUDE.md"
  - "skills/**/*.md"
  - "scripts/*.sh"
  - "scripts/*.py"
  - "templates/*.tmpl"
---

# Project Conventions

> Agents MUST read and follow these conventions.

## Coding Conventions

| Aspect | Rule | Config |
|--------|------|--------|
| Formatter | No dedicated formatter configured | — |
| Linter | No dedicated linter configured | — |
| Max line length | Not specified | — |
| Indentation | Preserve existing file style | Existing files |
| Quote style | Preserve existing file style | Existing files |
| Semicolons | Shell commands and Python statements follow language defaults | Existing files |
| Trailing commas | Preserve existing file style | Existing files |

## Naming Conventions

| Category | Convention | Example |
|----------|-----------|---------|
| Skill directories | `project-tracker-<name>` | `skills/project-tracker-update/` |
| Skill metadata names | Match the skill directory name | `name: project-tracker-update` |
| Python modules | `snake_case.py` | `tracker_state.py` |
| Shell scripts | `kebab-case.sh` where already established | `validate-packaging.sh` |
| Tracker docs | Lowercase kebab or canonical tracker names | `toolchain.md`, `data-model.md` |
| Constants | Upper snake case | `TRACKER_DIRNAME` |

## Architectural Rules

- `skills/` is the canonical workflow surface; `commands/` is legacy compatibility only.
- New tracker writes target `.agents/project-tracker/`.
- Legacy `.project-tracker/` and `.claude/project-tracker/` are read-only fallback tracker locations for learn/doctor flows.
- Tracker docs declare semantic ownership with `sources` front matter; scripts store computed sync state in `.agents/project-tracker/.state.json`.
- `progress.md` is intentionally special-cased by the state engine because progress is cross-cutting status, not a single source-owned reference doc.
- Skill and template docs use pseudocode placeholders in `<UPPER_SNAKE_CASE>` form, such as `<PLUGIN_ROOT>`, `<WORKSPACE>`, and `<TRACKER_DIR>`.
- Shell snippets that are meant to be copied as executable commands must either replace those placeholders first or use real shell variables.
- Python tracker-state scripts must remain stdlib-only.
- **Forbidden**: harness-specific `CLAUDE_PLUGIN_ROOT` references in shared skills/templates.
- **Forbidden**: literal shell-looking paths such as `"PLUGIN_ROOT/scripts/foo.py"` in skill or template snippets.

## File Organization

| What | Where | Notes |
|------|-------|-------|
| Shared skills | `skills/project-tracker-*/SKILL.md` | Claude Code and Codex share these skill files |
| Init presets | `skills/project-tracker-init/presets/` | Preset-specific tracker generation guidance |
| Script tooling | `scripts/` | Python state engine plus shell audit/packaging helpers |
| Tracker templates | `templates/*.md.tmpl` | Source structures for init/update/ADR output |
| Plugin manifests | `.claude-plugin/`, `.codex-plugin/`, `.agents/plugins/` | Runtime and marketplace metadata |
| Self-tracker docs | `.agents/project-tracker/` | Current self-test tracker location |

## Import / Module Conventions

- **Python imports**: use stdlib modules only for tracker-state scripts.
- **Module boundaries**: shared state behavior belongs in `scripts/tracker_state.py`; CLI entry points stay thin.
- **Shell helpers**: script paths are resolved from each script's own directory where possible.
- **Circular dependencies**: avoid introducing script dependencies that require package installation or runtime-specific plugin globals.

## Error Handling

- **Python scripts**: raise `TrackerError` for invalid tracker state and print concise `[ERROR] ...` diagnostics from CLI entry points.
- **Shell scripts**: use `set -euo pipefail` and a small `fail()` helper for packaging validation failures.
- **Missing tracker state**: report setup errors clearly instead of treating every file as unowned.
- **External failures**: keep scripts local-only and avoid network dependencies.

## Testing Conventions

- **Test location**: `scripts/test_staleness.py` contains smoke coverage for tracker-state behavior.
- **Test style**: create disposable workspaces under `.tmp-test-fixtures/` and clean them after successful runs.
- **Validation commands**: run `python3 scripts/test_staleness.py`, `bash scripts/validate-packaging.sh`, `python3 scripts/detect_changes.py`, and `python3 scripts/scan_state.py` for release-facing changes.
- **Coverage target**: no numeric coverage target is configured.

## Documentation Conventions

- Keep tracker docs current with project changes and refresh script-owned state after updates.
- Generated tracker docs should remove template comments and replace placeholder source patterns with real globs.
- Shared skill descriptions are intentionally short, clear, and focused on the primary workflow trigger instead of restating the full body of the skill.
- Preserve both `argument-hints` and `argument_hints` for skills that declare `arguments`.
- When a workflow needs a broad scan or focused reference-writing pass, document that subagent handoff explicitly in the relevant skill instead of burying it in process details.
- Document deliberate design exceptions as design notes, not as unresolved known issues.

## Agent Instructions

- Prefer plugin skills over ad hoc workflows when a request matches project-tracker behavior.
- Use `<UPPER_SNAKE_CASE>` for pseudocode-only variables; do not present bare uppercase identifiers as executable shell paths.
- Resolve `<PLUGIN_ROOT>` to the installed plugin root before running snippets that reference plugin scripts or templates.
- Use `.agents/project-tracker/` as the current tracker path unless the user explicitly targets a legacy tracker.
- Run local validation before considering packaging or tracker-state changes complete.
