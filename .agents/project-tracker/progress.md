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
- [x] Skill docs now use `<PLUGIN_ROOT>` for pseudocode path placeholders instead of shell-looking literal `PLUGIN_ROOT/...` paths
- [x] Packaging validation now rejects literal `"PLUGIN_ROOT/...` shell snippets in skills/templates
- [x] Missing current tracker or baseline state now reports a concise setup error instead of dumping all files as unowned
- [x] Staleness smoke coverage added for missing tracker and missing `.state.json` diagnostics
- [x] Argument-taking skills now declare both `argument-hints` and `argument_hints`
- [x] Packaging validation now requires both argument hint spellings when a skill declares `arguments`
- [x] `project-tracker-adr`, `project-tracker-audit`, `project-tracker-doctor`, and `project-tracker-update` now explicitly tell the caller to run them in subagents
- [x] Skill descriptions were simplified to short, clear, focused summaries
- [x] `project-tracker-init` and `project-tracker-adr` now restore the `argument_hints` metadata required by packaging validation
- [x] Repo guidance updated as the self-test tracker path migrated from legacy `.project-tracker/` to current `.agents/project-tracker/`
- [x] `audit-todos.sh` now suppresses plugin skill docs, README, and packaging scripts during self-audit
- [x] Packaging validation now checks that self-audit does not report project-tracker workflow docs as TODO findings
- [x] Init/update skill docs now describe `.state.json` `changed_fingerprints`
- [x] Staleness smoke tests now remove the empty `.tmp-test-fixtures/` scratch root after successful runs
- [x] This repository's self-tracker migrated from legacy `.project-tracker/` to current `.agents/project-tracker/`
- [x] Self-tracker now includes generated `conventions.md`
- [x] Project guidance now records the `<UPPER_SNAKE_CASE>` pseudocode placeholder pattern
- [x] Version bumped to 0.3.1 across Claude and Codex plugin manifests
- [x] Staleness detection fixed for nested tracker docs, uppercase docs, staged/unstaged/untracked changes, and broader project file coverage
- [x] `progress.md` staleness detection — special-cased in the tracker-state engine so any non-tracker change flags it for manual review
- [x] `audit` skill — 6th skill, cross-references source TODOs against progress.md both ways, `audit-todos.sh` script with auto language detection and self-exclusion
- [x] Claude and Codex plugin manifest versions kept in sync
- [x] `.meta`-based stale detection replaced with front matter `sources` plus script-owned `.state.json`
- [x] Python tracker-state scripts added for stale detection, health scans, and state refresh
- [x] Legacy shell wrappers removed in favor of direct Python entrypoints
- [x] Templates and self-tracker docs updated to include `sources` front matter and tracking exclusions
- [x] Packaging validation script added for marketplace and skill metadata checks
- [x] Staleness smoke test added for Python tracker-state behavior
- [x] Legacy `.project-tracker/` self-tracker content refreshed to describe the `.agents/project-tracker/` migration

## In Progress

- [ ] Continue live testing against real projects before marketplace release

## Known Issues & Technical Debt

- None currently recorded.

## Design Notes

- `progress.md` remains a deliberate special case outside front matter source ownership because it tracks cross-cutting project status rather than one bounded source set.

## Roadmap

- [ ] CI validation (JSON lint + Python syntax check on push)
- [ ] Live test against real projects
- [ ] Marketplace release (0.3.1)
