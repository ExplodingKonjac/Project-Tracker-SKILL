# Progress & Roadmap

## Current Phase

Phase 2: Plugin packaging — expanding tracker surface

## Completed

- [x] 5 project-tracker skills designed and implemented
- [x] Skills extracted from `.claude/skills/` into plugin format
- [x] Shared library `tracker-common.sh` extracted from duplicated code
- [x] 10 document templates created (added `conventions.md.tmpl`)
- [x] Presets expanded with template references
- [x] Bash 3 portability fix (replaced `declare -A`)
- [x] Marketplace scaffold with `marketplace.json`
- [x] README and .gitignore created
- [x] `conventions.md` tracker document — template, staleness patterns (30+ config file variants), preset rows, learn/doctor skill integration
- [x] `disable-model-invocation: true` set on all 5 skills
- [x] Skill name field removed, simplified to description-based triggering

## In Progress

- [ ] Script smoke tests
- [ ] Description optimization for better triggering

## Known Issues & Technical Debt

- Orphaned skill-local scripts removed but git history still has old paths
- `conventions.md` template added but not yet generated in this repo's `.claude/project-tracker/` (needs fresh `init` run)

## Roadmap

- [ ] CI validation (JSON + YAML lint on push)
- [ ] Live test against real projects
- [ ] Version bump and marketplace release (0.2.0)
