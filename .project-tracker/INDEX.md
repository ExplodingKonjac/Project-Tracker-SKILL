---
sources:
  - "README.md"
  - ".claude/CLAUDE.md"
  - ".claude-plugin/*.json"
  - ".codex-plugin/*.json"
  - ".agents/plugins/*.json"
---

# Project: Project-Tracker-SKILL

Claude Code and Codex plugin marketplace providing 6 namespaced skills (`project-tracker-init`, `project-tracker-learn`, `project-tracker-doctor`, `project-tracker-update`, `project-tracker-adr`, `project-tracker-audit`) for structured project documentation.

## Table of Contents

- [Stack](stack.md)
- [Toolchain](toolchain.md)
- [Architecture](architecture.md)
- [Progress](progress.md)
- [Implementation](implementation.md)
- [Data Model](data-model.md)
- [API](api.md)
- [Deployment](deployment.md)

## Tech Stack Summary

| Layer | Technology | Version |
|-------|-----------|---------|
| Language | Bash / POSIX shell | — |
| Plugin Format | Claude Code Plugin | — |
| CI/CD | None | — |

## Quick Reference Commands

```bash
# Test plugin locally
claude --plugin-dir .

# Reload after changes
/reload-plugins
```

## Project Map

- repository root — Flattened plugin root with manifests, skills, scripts, and templates
- `plugins/project-tracker` — Compatibility symlink to the plugin root
- `skills/` — 6 namespaced skill directories (`project-tracker-<name>`)
- `scripts/` — Shared Bash helper scripts
- `templates/` — Document templates for init/update
- `.claude-plugin/` — Claude Code marketplace manifest
- `.agents/plugins/` — Codex marketplace manifest

## Tracking Exclusions

- `evals/**` -- evaluation outputs are not part of the plugin tracker surface
