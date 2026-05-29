---
sources:
  - "README.md"
  - ".claude-plugin/*.json"
  - ".codex-plugin/*.json"
  - ".agents/plugins/*.json"
  - "scripts/*.py"
---

# Technology Stack

## Language & Runtime

| Property | Value |
|----------|-------|
| Language | Python 3 + shell wrappers |
| Runtime | `python3`, Bash-compatible shell, Git |
| Package manager | None |

## Frameworks & Libraries

| Dependency | Version | Purpose |
|-----------|---------|---------|
| Python stdlib | 3.x | Tracker-state parsing, glob resolution, JSON state management |
| Shell wrappers | Bash-compatible | Preserve stable CLI entrypoints for skills and users |

## Database & Storage

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Primary DB | None | — |
| File storage | Git repository | Scripts and docs stored in git |

## Infrastructure & Services

- No cloud services, all local CLI tools
