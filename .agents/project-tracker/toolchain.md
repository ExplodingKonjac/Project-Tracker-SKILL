---
sources:
  - ".gitignore"
  - "scripts/*.sh"
  - "scripts/*.py"
---

# Toolchain & Dev Setup

## Build System

| Tool | Command | Output |
|------|---------|--------|
| None | — | No build artifact; plugin files, templates, and scripts are used directly |

## Linting & Formatting

| Tool | Config file | Run command |
|------|-----------|-------------|
| None | — | — |

## Testing

| Aspect | Detail |
|--------|--------|
| Framework | Local smoke scripts |
| Coverage target | None |
| Packaging validation | `bash scripts/validate-packaging.sh` |
| Placeholder validation | Packaging validation rejects shell snippets that use literal `"PLUGIN_ROOT/...` paths; skill docs use `<UPPER_SNAKE_CASE>` angle-bracket placeholders for pseudocode variables |
| Argument metadata validation | Packaging validation requires `argument-hints` and `argument_hints` when a skill declares `arguments` |
| Self-audit validation | Packaging validation runs `audit-todos.sh` against this repo and rejects workflow-doc TODO noise |
| Staleness behavior | `python3 scripts/test_staleness.py` |
| Dirty refresh behavior | Covered by `scripts/test_staleness.py` fingerprint tests |
| Manual tracker update check | `python3 scripts/detect_changes.py` for the current `.agents/project-tracker/` self-tracker |

## CI/CD Pipeline

No CI/CD pipeline configured.

## Development Environment

| Requirement | Value |
|-----------|-------|
| Required tools | Claude Code CLI or Codex plugin surface, `python3`, Git |
| Validate locally | `bash scripts/validate-packaging.sh`, `python3 scripts/test_staleness.py` |
| Test plugin locally | `claude --plugin-dir .` |
