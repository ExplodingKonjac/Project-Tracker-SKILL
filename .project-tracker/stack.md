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
| Language | Python 3 + Bash helper scripts |
| Runtime | `python3`, Bash-compatible shell, Git |
| Package manager | None |

## Frameworks & Libraries

| Dependency | Version | Purpose |
|-----------|---------|---------|
| Python stdlib | 3.x | Tracker directory resolution, front matter parsing, glob resolution, SHA-256 dirty-input fingerprints, git diff checks, JSON state management |
| Bash helpers | Bash-compatible | TODO auditing and packaging validation |

## Database & Storage

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Primary DB | None | — |
| File storage | Git repository | Plugin files, templates, tracker docs, and script-owned `.state.json` stored in git |

## Infrastructure & Services

- No cloud services; all functionality runs through local CLI tools and plugin skill files
