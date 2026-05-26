# Progress & Roadmap

## Current Phase

Phase 2: Plugin packaging — 0.2.0 feature complete

## Completed

- [x] 6 project-tracker skills designed and implemented
- [x] Skills extracted from `.claude/skills/` into plugin format
- [x] Shared library `tracker-common.sh` extracted from duplicated code
- [x] 10 document templates created (added `conventions.md.tmpl`)
- [x] Presets expanded with template references
- [x] Bash 3 portability fix (replaced `declare -A`)
- [x] Marketplace scaffold with `marketplace.json`
- [x] README and .gitignore created
- [x] `conventions.md` tracker document — template, staleness patterns, preset rows, learn/doctor skill integration
- [x] Shared skill metadata made Codex-compatible while preserving Claude Code skill files
- [x] Flattened plugin structure — plugin files moved to repository root and `plugins/project-tracker` now symlinks to `..`
- [x] Skill directories and skill names namespaced as `project-tracker-<name>`
- [x] Skill directories and front-matter names use `project-tracker-<name>`
- [x] Universal `.project-tracker/` directory adopted for Claude Code and Codex tracker docs
- [x] Staleness detection fixed for nested tracker docs, uppercase docs, staged/unstaged/untracked changes, and broader project file coverage
- [x] `progress.md` staleness detection — special-cased in `detect-changes.sh` so any non-tracker change flags it for manual review
- [x] `audit` skill — 6th skill, cross-references source TODOs against progress.md both ways, `audit-todos.sh` script with auto language detection and self-exclusion
- [x] Version bumped to 0.2.0 across plugin.json and marketplace.json

## In Progress

- [ ] Script smoke tests
- [ ] Description optimization for better triggering

## Known Issues & Technical Debt

- Orphaned skill-local scripts removed but git history still has old paths
- `conventions.md` template added but not yet generated in this repo's `.project-tracker/` (needs fresh `init` run)

## Roadmap

- [ ] CI validation (JSON + YAML lint on push)
- [ ] Live test against real projects
- [ ] Marketplace release (0.2.0)
