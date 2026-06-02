---
sources:
  - "README.md"
  - "skills/**/*.md"
  - "scripts/*.sh"
  - "scripts/*.py"
  - "templates/*.tmpl"
---

# Architecture

## Overview

Flattened dual-runtime plugin orchestration with current writes to `.agents/project-tracker/` and read-only fallback support for legacy `.project-tracker/` and `.claude/project-tracker/` trackers:

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
     +--> tracker_state.py       -- tracker path resolution, front matter parsing, dirty-input fingerprints, state I/O
     +--> scan_state.py          -- project scan for doctor, with selectable tracker path
     +--> detect_changes.py      -- staleness detection for update, with selectable tracker path
     +--> refresh_state.py       -- baseline and matched-path refresh, with selectable tracker path
     +--> audit-todos.sh         -- TODO/stub scan for audit
     +--> validate-packaging.sh  -- manifest and skill metadata validation
     |
Templates
     |
     +--> 11 .md.tmpl templates  -- document structure for init/update/adr
```

## Module Breakdown

| Module | Responsibility | Key files |
|---------------|---------------|--------------------|
| project-tracker-init | Scan project, generate tracker docs | `skills/project-tracker-init/SKILL.md`, `templates/*.md.tmpl` |
| project-tracker-learn | Read and summarize tracker docs | `skills/project-tracker-learn/SKILL.md` |
| project-tracker-doctor | Validate docs against current state | `skills/project-tracker-doctor/SKILL.md`, `scripts/scan_state.py` |
| project-tracker-update | Refresh stale docs incrementally | `skills/project-tracker-update/SKILL.md`, `scripts/detect_changes.py` |
| project-tracker-adr | Record architectural decisions | `skills/project-tracker-adr/SKILL.md` |
| project-tracker-audit | Cross-reference progress against TODOs and stubs | `skills/project-tracker-audit/SKILL.md`, `scripts/audit-todos.sh` |
| Shared state engine | Resolve active tracker path, parse front matter, fingerprint refreshed dirty inputs, evaluate staleness, collect ownership gaps | `scripts/tracker_state.py` |
| Packaging validation | Validate plugin manifests and skill metadata | `scripts/validate-packaging.sh` |
| Templates | Document structure blueprints, including ADR and conventions templates | `templates/*.md.tmpl` |
| Compatibility link | Preserve nested plugin source paths | `plugins/project-tracker -> ..` |

## Data Flow

1. User invokes a skill via slash command or model auto-invocation
2. Skill reads project state (config files, directory tree, git history)
3. Skill generates/validates/updates docs in `.agents/project-tracker/`
4. Learn and doctor may inspect legacy `.project-tracker/` or `.claude/project-tracker/` trackers when the current tracker is missing
5. Scripts persist sync state in `.state.json`, while docs keep agent-authored `sources`

## Design Patterns

- **Per-doc sources** — tracker docs declare their dependency boundary in front matter
- **Script-owned state** — `.state.json` stores baselines and matched paths, not agent-authored intent
- **Dirty-worktree refresh snapshots** — refreshed docs store fingerprints for changed inputs so reviewed uncommitted work does not remain permanently stale
- **Selectable tracker root** — scripts default to `.agents/project-tracker/` and can target legacy trackers via CLI path or `PROJECT_TRACKER_DIR`
- **Template-driven generation** — init and update use the same templates for consistent output
- **Flattened plugin root** — Claude Code and Codex manifests, skills, scripts, and templates live at repository root; `plugins/project-tracker` is a symlink for marketplace compatibility

## Security Boundaries

- Scripts write only to `.agents/project-tracker/` when a skill explicitly generates or updates tracker docs
- Legacy `.project-tracker/` and `.claude/project-tracker/` paths are excluded from source ownership scans and treated as fallback tracker locations
- All scripts are local, no network access
