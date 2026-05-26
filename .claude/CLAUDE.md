# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

This is a Claude Code and Codex plugin marketplace providing the **project-tracker** plugin — 6 skills (`project-tracker-init`, `project-tracker-learn`, `project-tracker-doctor`, `project-tracker-update`, `project-tracker-adr`, `project-tracker-audit`) for structured project documentation in `.project-tracker/`. Each skill is a SKILL.md file; skills share shell scripts in `scripts/` and document templates in `templates/`.

## Development

```bash
# Test the plugin locally (loads into an interactive Claude Code session)
claude --plugin-dir .

# After changes to skills/scripts/templates, reload inside Claude Code
/reload-plugins

# Marketplace version bump — update these when cutting a release:
#   .claude-plugin/marketplace.json  →  "version"
#   .claude-plugin/plugin.json  →  "version"
#   .codex-plugin/plugin.json  →  "version"

# Validate Claude Code and Codex packaging
bash scripts/validate-packaging.sh
```

## Architecture

**Marketplace → Plugin → Skills/Scripts/Templates** three-layer structure:

- `.claude-plugin/marketplace.json` — entry point, sources plugin through `./plugins/project-tracker`
- `.agents/plugins/marketplace.json` — Codex repo marketplace, sources the same plugin
- `plugins/project-tracker` — compatibility symlink to `..`
- repository root — flattened plugin root with 6 shared skills
  - `.claude-plugin/plugin.json` — Claude Code plugin manifest
  - `.codex-plugin/plugin.json` — Codex plugin manifest
  - `skills/project-tracker-<name>/SKILL.md` — each skill is a single markdown file
  - `skills/project-tracker-init/presets/` — preset configurations for different project types
  - `scripts/lib/tracker-common.sh` — shared library sourced by scripts; provides source-to-tracker mapping, git-diff-based change detection, mtime fallback, `.meta` parsing, and file classification
  - `scripts/scan-state.sh` — used by `doctor` to validate tracker docs against current project state
  - `scripts/detect-changes.sh` — used by `update` to find which tracker files are stale
  - `templates/*.md.tmpl` — markdown templates with `{{PLACEHOLDER}}` substitution for init/update

**Data flow**: Skills write docs to `.project-tracker/` in the user's workspace. Legacy `.claude/project-tracker/` is read-only fallback for learn/doctor. This repo's own `.project-tracker/` is the self-test tracker.

**Staleness model**: `.meta` stores a per-file `baseline` commit + `updated` timestamp. Each tracker file becomes STALE independently when source files matching its patterns have changed since its baseline. `tracker_patterns()` in the shared lib defines the mapping (e.g., `stack.md` ← config files, `api.md` ← routes/controllers).

## Script conventions

- All scripts use `set -euo pipefail`
- Scripts are pure shell (Bash 3+ / POSIX compatible — no `declare -A`)
- The shared lib is sourced relative to `CLAUDE_PLUGIN_ROOT` when available, falling back to `dirname "$0"/..`
- No dependencies beyond coreutils + git

## Templates

Templates use `{{PLACEHOLDER}}` syntax. The shared set of variable names across all templates: `PROJECT_NAME`, `HAS_DATABASE`, `HAS_API`, `HAS_DEPLOYMENT`, `HAS_CI`, `CLAUDE_VERSION`. Individual templates may use additional specific placeholders (check the template for exact names).
