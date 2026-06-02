# Project Tracker Marketplace

A Claude Code and Codex plugin marketplace for structured project documentation.

## What It Does

The **project-tracker** plugin helps you maintain living documentation of any codebase:

| Skill | Slash command | Purpose |
|-------|--------------|---------|
| **project-tracker-init** | `/project-tracker-init` | Scan a project and generate structured tracker docs |
| **project-tracker-learn** | `/project-tracker-learn` | Understand a project by reading its tracker docs |
| **project-tracker-doctor** | `/project-tracker-doctor` | Validate tracker docs against current project state |
| **project-tracker-update** | `/project-tracker-update` | Refresh stale tracker docs after project changes |
| **project-tracker-adr** | `/project-tracker-adr` | Record an architectural decision as a numbered ADR |
| **project-tracker-audit** | `/project-tracker-audit` | Cross-reference progress docs against TODOs and stubs |

Tracker docs live at `.agents/project-tracker/` in your workspace and capture tech stack, architecture, toolchain, progress, implementation details, data model, API surface, and deployment config.
Tracker docs own their semantic dependency intent through `sources` front matter, while scripts keep sync bookkeeping in `.agents/project-tracker/.state.json`.
Legacy `.project-tracker/` and `.claude/project-tracker/` docs can be read by learn and doctor flows, but new writes go to `.agents/project-tracker/`.

## Installation

### Claude Code

```bash
# From a local clone
/plugin marketplace add /path/to/project-tracker-marketplace

# Or install the flattened plugin root directly
claude --plugin-dir /path/to/project-tracker-marketplace
```

### As a marketplace (for team distribution)

```bash
/plugin marketplace add https://github.com/ExplodingKonjac/Project-Tracker-SKILL
```

### Codex

```bash
# From a local clone
codex plugin marketplace add /path/to/project-tracker-marketplace

# Or from this repository root, open Codex and browse the repo marketplace
codex
/plugins
```

The Codex marketplace lives at `.agents/plugins/marketplace.json` and points at `./plugins/project-tracker`.
That path is a compatibility symlink to the flattened plugin root.

## Quick Start

```bash
# Generate tracker docs for the current project
/project-tracker-init

# After making changes, check if docs are still accurate
/project-tracker-doctor

# Update only the stale files
/project-tracker-update

# Before starting a task, learn the project
/project-tracker-learn

# Record an architectural decision
/project-tracker-adr "Why we chose SQLite"

# Audit progress against source TODOs and stubs
/project-tracker-audit
```

## Directory Layout

```
Project-Tracker-SKILL/
├── .claude-plugin/
│   ├── marketplace.json           # Claude Code marketplace manifest
│   └── plugin.json                # Claude Code plugin manifest
├── .codex-plugin/
│   └── plugin.json                # Codex plugin manifest
├── .agents/
│   └── plugins/marketplace.json   # Codex marketplace manifest
├── plugins/
│   └── project-tracker -> ..      # Compatibility symlink to plugin root
├── skills/                        # 6 shared project-tracker-* skills
├── scripts/
│   ├── tracker_state.py
│   ├── refresh_state.py
│   ├── scan_state.py
│   ├── detect_changes.py
│   ├── audit-todos.sh
│   ├── test_staleness.py
│   └── validate-packaging.sh      # Claude/Codex packaging validation
├── templates/                     # Document templates for init/update
│   ├── INDEX.md.tmpl
│   ├── stack.md.tmpl
│   ├── toolchain.md.tmpl
│   ├── architecture.md.tmpl
│   ├── progress.md.tmpl
│   ├── implementation.md.tmpl
│   ├── data-model.md.tmpl
│   ├── api.md.tmpl
│   ├── deployment.md.tmpl
│   └── adr-NNN-kebab-title.md.tmpl
└── README.md
```

## Development

```bash
# Validate manifests and skill metadata
bash scripts/validate-packaging.sh

# Test staleness detection behavior
python3 scripts/test_staleness.py

# Test the plugin locally
claude --plugin-dir .

# After changes, reload
/reload-plugins
```
