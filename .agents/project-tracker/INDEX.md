---
sources:
  - "README.md"
  - ".claude/CLAUDE.md"
  - ".claude-plugin/*.json"
  - ".codex-plugin/*.json"
  - ".agents/plugins/*.json"
---

# Project: Project-Tracker-SKILL

Claude Code and Codex plugin marketplace providing 6 namespaced skills (`project-tracker-init`, `project-tracker-learn`, `project-tracker-doctor`, `project-tracker-update`, `project-tracker-adr`, `project-tracker-audit`) for structured project documentation. Current generated tracker docs target `.agents/project-tracker/`, and this repository's self-tracker now uses that current location.

## Table of Contents

- [Stack](stack.md)
- [Toolchain](toolchain.md)
- [Architecture](architecture.md)
- [Conventions](conventions.md)
- [Progress](progress.md)
- [Implementation](implementation.md)
- [Data Model](data-model.md)
- [API](api.md)
- [Deployment](deployment.md)

## Tech Stack Summary

| Layer | Technology | Version |
|-------|-----------|---------|
| Language | Python 3 + Bash helper scripts | — |
| Plugin Format | Claude Code + Codex plugin marketplace | 0.3.1 |
| CI/CD | None | — |

## Quick Reference Commands

```bash
# Validate manifests and skill metadata
bash scripts/validate-packaging.sh

# Test tracker-state behavior
python3 scripts/test_staleness.py

# Test plugin locally
claude --plugin-dir .

# Reload after changes
/reload-plugins
```

## Project Map

- repository root — Flattened plugin root with manifests, skills, scripts, and templates
- `plugins/project-tracker` — Compatibility symlink to the plugin root
- `skills/` — 6 namespaced skill directories (`project-tracker-<name>`)
- `skills/project-tracker-init/presets/` — Preset guidance for default, library, web-app, and cli-tool trackers
- `scripts/` — Python tracker-state tools plus audit and packaging shell helpers
- `templates/` — 11 document templates for init/update/ADR, including `conventions.md`
- `.claude-plugin/` — Claude Code plugin and marketplace manifests
- `.codex-plugin/` — Codex plugin manifest
- `.agents/plugins/` — Codex marketplace manifest
- skill docs — Use `<UPPER_SNAKE_CASE>` angle-bracket pseudocode placeholders, such as `<PLUGIN_ROOT>`, and real shell variables only in executable snippets

## Tracking Exclusions

- `evals/**` -- evaluation outputs are not part of the plugin tracker surface
- `.tmp-test-fixtures/**` -- transient staleness-test workspaces are generated and cleaned by smoke tests
