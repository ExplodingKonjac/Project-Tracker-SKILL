# Architecture

## Overview

Flattened dual-runtime plugin orchestration:

```
User Request
     |
     v
Skill Selector (Claude Code or Codex reads skill metadata)
     |
     +--> project-tracker-init/     -- scans project, generates docs
     +--> project-tracker-learn/    -- reads tracker docs, answers questions
     +--> project-tracker-doctor/   -- validates docs against project state
     +--> project-tracker-update/   -- refreshes stale docs
     +--> project-tracker-adr/      -- records architectural decisions
     +--> project-tracker-audit/    -- cross-checks progress against TODOs/stubs
     |
Scripts (shared)
     |
     +--> lib/tracker-common.sh   -- source-to-tracker mapping, git diff, .meta parsing
     +--> scan-state.sh          -- project scan for doctor
     +--> detect-changes.sh      -- staleness detection for update
     +--> audit-todos.sh         -- TODO/stub scan for audit
     |
Templates
     |
     +--> 10 .md.tmpl templates  -- document structure for init/update/adr
```

## Module Breakdown

| Module | Responsibility | Key files |
|---------------|---------------|--------------------|
| project-tracker-init | Scan project, generate tracker docs | `skills/project-tracker-init/SKILL.md`, `presets/*.md` |
| project-tracker-learn | Read and summarize tracker docs | `skills/project-tracker-learn/SKILL.md` |
| project-tracker-doctor | Validate docs against current state | `skills/project-tracker-doctor/SKILL.md`, `scripts/scan-state.sh` |
| project-tracker-update | Refresh stale docs incrementally | `skills/project-tracker-update/SKILL.md`, `scripts/detect-changes.sh` |
| project-tracker-adr | Record architectural decisions | `skills/project-tracker-adr/SKILL.md` |
| project-tracker-audit | Cross-reference progress against TODOs and stubs | `skills/project-tracker-audit/SKILL.md`, `scripts/audit-todos.sh` |
| Shared lib | Common functions for scripts | `scripts/lib/tracker-common.sh` |
| Templates | Document structure blueprints | `templates/*.md.tmpl` |
| Compatibility link | Preserve nested plugin source paths | `plugins/project-tracker -> ..` |

## Data Flow

1. User invokes a skill via slash command or model auto-invocation
2. Skill reads project state (config files, directory tree, git history)
3. Skill generates/validates/updates docs in `.claude/project-tracker/`
4. Skills share data through `.meta` file (per-file baselines)

## Design Patterns

- **Per-file baseline tracking** — each tracker file has its own baseline in `.meta` for independent staleness detection
- **Shared library** — common functions extracted from duplicated scripts into `tracker-common.sh`
- **Template-driven generation** — init and update use the same templates for consistent output
- **Flattened plugin root** — Claude Code and Codex manifests, skills, scripts, and templates live at repository root; `plugins/project-tracker` is a symlink for marketplace compatibility

## Security Boundaries

- Scripts are read-only for files outside `.claude/project-tracker/`
- All scripts are local, no network access
