# Progress & Roadmap

## Current Phase

Phase 2: Plugin packaging — initial release

## Completed

- [x] 5 project-tracker skills designed and implemented
- [x] Skills extracted from `.claude/skills/` into plugin format
- [x] Shared library `tracker-common.sh` extracted from duplicated code
- [x] 9 document templates created
- [x] Presets expanded with template references
- [x] Bash 3 portability fix (replaced `declare -A`)
- [x] Marketplace scaffold with `marketplace.json`
- [x] README and .gitignore created

## In Progress

- [ ] Script smoke tests
- [ ] Description optimization for better triggering

## Known Issues & Technical Debt

- Orphaned skill-local scripts removed but git history still has old paths

## Roadmap

- [ ] CI validation (JSON + YAML lint on push)
- [ ] Live test against real projects
