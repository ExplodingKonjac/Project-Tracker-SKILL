# Progress & Roadmap

## Current Phase

Phase 4: `.agents/project-tracker/` migration stabilization and marketplace packaging

## Completed

- [x] 6 project-tracker skills designed and implemented
- [x] Skills extracted from `.claude/skills/` into plugin format
- [x] Shared library `tracker-common.sh` extracted from duplicated code
- [x] 10 document templates created (added `conventions.md.tmpl`)
- [x] Presets expanded with template references
- [x] Bash 3 portability fix (replaced `declare -A`)
- [x] Marketplace scaffold with `marketplace.json`
- [x] README and .gitignore created
- [x] `conventions.md` tracker support — template, staleness patterns, and learn/doctor skill integration
- [x] Shared skill metadata made Codex-compatible while preserving Claude Code skill files
- [x] Flattened plugin structure — plugin files moved to repository root and `plugins/project-tracker` now symlinks to `..`
- [x] Skill directories and skill names namespaced as `project-tracker-<name>`
- [x] Skill directories and front-matter names use `project-tracker-<name>`
- [x] Universal `.project-tracker/` directory adopted for Claude Code and Codex tracker docs
- [x] Default tracker storage moved to `.agents/project-tracker/`
- [x] Current tracker path made configurable with `PROJECT_TRACKER_DIR` plus explicit script tracker path arguments
- [x] Learn and doctor flows updated to treat `.project-tracker/` and `.claude/project-tracker/` as legacy fallback tracker directories
- [x] ADR and audit flows updated to use `.agents/project-tracker/` paths
- [x] Refreshed dirty source inputs now store fingerprints in `.state.json`, preventing reviewed uncommitted work from staying stale forever
- [x] Staleness smoke coverage added for dirty matched files and dirty `progress.md` refreshes
- [x] Staleness detection fixed for nested tracker docs, uppercase docs, staged/unstaged/untracked changes, and broader project file coverage
- [x] `progress.md` staleness detection — special-cased in the tracker-state engine so any non-tracker change flags it for manual review
- [x] `audit` skill — 6th skill, cross-references source TODOs against progress.md both ways, `audit-todos.sh` script with auto language detection and self-exclusion
- [x] Version bumped to 0.3.0 across Claude and Codex plugin manifests
- [x] `.meta`-based stale detection replaced with front matter `sources` plus script-owned `.state.json`
- [x] Python tracker-state scripts added for stale detection, health scans, and state refresh
- [x] Legacy shell wrappers removed in favor of direct Python entrypoints
- [x] Templates and self-tracker docs updated to include `sources` front matter and tracking exclusions
- [x] Packaging validation script added for marketplace and skill metadata checks
- [x] Staleness smoke test added for Python tracker-state behavior
- [x] Legacy `.project-tracker/` self-tracker content refreshed to describe the `.agents/project-tracker/` migration

## In Progress

- [ ] Generate or migrate this repository's self-tracker to the current `.agents/project-tracker/` location

## Known Issues & Technical Debt

- `progress.md` remains a deliberate special case outside front matter source ownership
- `conventions.md` template exists but this repo still lacks a generated `conventions.md` tracker doc
- This repository still uses a legacy `.project-tracker/` self-tracker, while new plugin writes target `.agents/project-tracker/`

## Roadmap

- [ ] CI validation (JSON lint + Python syntax check on push)
- [ ] Live test against real projects
- [ ] Marketplace release (0.3.0)
