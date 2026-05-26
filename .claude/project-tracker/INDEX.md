# Project: Project-Tracker-SKILL

Claude Code and Codex plugin marketplace providing 6 skills (init, learn, doctor, update, adr, audit) for structured project documentation.

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
- `skills/` — 6 skill directories (init, learn, doctor, update, adr, audit)
- `scripts/` — Shared Bash helper scripts
- `templates/` — Document templates for init/update
- `.claude-plugin/` — Claude Code marketplace manifest
- `.agents/plugins/` — Codex marketplace manifest
