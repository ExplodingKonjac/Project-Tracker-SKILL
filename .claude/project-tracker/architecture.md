# Architecture

## Overview

Multi-skill plugin orchestration:

```
User Request
     |
     v
Skill Selector (Claude Code reads descriptions)
     |
     +--> init/     -- scans project, generates docs
     +--> learn/    -- reads tracker docs, answers questions
     +--> doctor/   -- validates docs against project state
     +--> update/   -- refreshes stale docs
     +--> adr/      -- records architectural decisions
     |
Scripts (shared)
     |
     +--> lib/tracker-common.sh   -- source-to-tracker mapping, git diff, .meta parsing
     +--> scan-state.sh          -- project scan for doctor
     +--> detect-changes.sh      -- staleness detection for update
     |
Templates
     |
     +--> 9 .md.tmpl templates   -- document structure for init/update
```

## Module Breakdown

| Module | Responsibility | Key files |
|---------------|---------------|--------------------|
| init | Scan project, generate tracker docs | `skills/init/SKILL.md`, `presets/*.md` |
| learn | Read and summarize tracker docs | `skills/learn/SKILL.md` |
| doctor | Validate docs against current state | `skills/doctor/SKILL.md`, `scripts/scan-state.sh` |
| update | Refresh stale docs incrementally | `skills/update/SKILL.md`, `scripts/detect-changes.sh` |
| adr | Record architectural decisions | `skills/adr/SKILL.md` |
| Shared lib | Common functions for scripts | `scripts/lib/tracker-common.sh` |
| Templates | Document structure blueprints | `templates/*.md.tmpl` |

## Data Flow

1. User invokes a skill via slash command or model auto-invocation
2. Skill reads project state (config files, directory tree, git history)
3. Skill generates/validates/updates docs in `.claude/project-tracker/`
4. Skills share data through `.meta` file (per-file baselines)

## Design Patterns

- **Per-file baseline tracking** — each tracker file has its own baseline in `.meta` for independent staleness detection
- **Shared library** — common functions extracted from duplicated scripts into `tracker-common.sh`
- **Template-driven generation** — init and update use the same templates for consistent output

## Security Boundaries

- Scripts are read-only for files outside `.claude/project-tracker/`
- All scripts are local, no network access
