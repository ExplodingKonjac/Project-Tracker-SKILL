# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

This is a Claude Code and Codex plugin marketplace providing the **project-tracker** plugin — 6 skills (`project-tracker-init`, `project-tracker-learn`, `project-tracker-doctor`, `project-tracker-update`, `project-tracker-adr`, `project-tracker-audit`) for structured project documentation in `.agents/project-tracker/`. Each skill is a SKILL.md file; tracker docs keep agent-authored `sources` front matter, scripts keep sync bookkeeping in `.agents/project-tracker/.state.json`, and document templates live in `templates/`.

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
  - `scripts/tracker_state.py` — shared Python helpers for front matter parsing, glob resolution, state I/O, and change detection
  - `scripts/scan_state.py` — used by `doctor` to validate tracker docs against current project state
  - `scripts/detect_changes.py` — used by `update` to find which tracker files are stale
  - `scripts/refresh_state.py` — refreshes `.state.json` after successful init/update/audit
  - `templates/*.md.tmpl` — markdown templates with `{{PLACEHOLDER}}` substitution for init/update

**Data flow**: Skills write docs to `.agents/project-tracker/` in the user's workspace. Docs declare `sources` in front matter, scripts resolve those globs to `matched_paths`, and `.state.json` stores per-doc baseline state. Legacy `.project-tracker/` and `.claude/project-tracker/` are read-only fallbacks for learn/doctor. This repo's own `.agents/project-tracker/` is the self-test tracker.

**Staleness model**: `.state.json` stores a per-file `baseline`, `updated`, and `matched_paths` snapshot. Each tracker file becomes STALE independently when its current `sources` match set changes or any matched file changes since baseline. Files matched by no doc are reported as ownership gaps.

## Script conventions

- Shell wrappers use `set -euo pipefail`
- Tracker-state logic uses stdlib-only Python 3
- Skill docs use `PLUGIN_ROOT` as a harness-neutral placeholder for the installed plugin root.
- Python scripts are invoked relative to their own script path and do not require a harness-specific plugin-root environment variable.
- Runtime requirements: `python3` and `git`

## Templates

Templates use `{{PLACEHOLDER}}` syntax. The shared set of variable names across all templates: `PROJECT_NAME`, `HAS_DATABASE`, `HAS_API`, `HAS_DEPLOYMENT`, `HAS_CI`, `CLAUDE_VERSION`. Individual templates may use additional specific placeholders (check the template for exact names).
