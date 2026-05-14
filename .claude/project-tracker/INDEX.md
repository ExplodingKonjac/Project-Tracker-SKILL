# Project: Project-Tracker-SKILL

Claude Code plugin marketplace providing 5 skills (init, learn, doctor, update, adr) for structured project documentation.

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
claude --plugin-dir plugins/project-tracker

# Reload after changes
/reload-plugins
```

## Project Map

- `plugins/project-tracker/` — Plugin root with skills, scripts, and templates
- `plugins/project-tracker/skills/` — 5 skill directories (init, learn, doctor, update, adr)
- `plugins/project-tracker/scripts/` — Shared Bash helper scripts
- `plugins/project-tracker/templates/` — Document templates for init/update
- `.claude-plugin/` — Marketplace manifest
