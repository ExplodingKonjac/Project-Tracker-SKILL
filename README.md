# Project Tracker Marketplace

A [Claude Code](https://code.claude.com) plugin marketplace for structured project documentation.

## What It Does

The **project-tracker** plugin helps you maintain living documentation of any codebase:

| Skill | Slash command | Purpose |
|-------|--------------|---------|
| **init** | `/project-tracker:init` | Scan a project and generate structured tracker docs |
| **learn** | `/project-tracker:learn` | Understand a project by reading its tracker docs |
| **doctor** | `/project-tracker:doctor` | Validate tracker docs against current project state |
| **update** | `/project-tracker:update` | Refresh stale tracker docs after project changes |
| **adr** | `/project-tracker:adr` | Record an architectural decision as a numbered ADR |

Tracker docs live at `.claude/project-tracker/` in your workspace and capture tech stack, architecture, toolchain, progress, implementation details, data model, API surface, and deployment config.

## Installation

### As a plugin

```bash
# From a local clone
/plugin marketplace add /path/to/project-tracker-marketplace

# Or install the plugin directly
claude --plugin-dir /path/to/project-tracker-marketplace/plugins/project-tracker
```

### As a marketplace (for team distribution)

```bash
/plugin marketplace add https://github.com/ExplodingKonjac/Project-Tracker-SKILL
```

## Quick Start

```bash
# Generate tracker docs for the current project
/project-tracker:init

# After making changes, check if docs are still accurate
/project-tracker:doctor

# Update only the stale files
/project-tracker:update

# Before starting a task, learn the project
/project-tracker:learn

# Record an architectural decision
/project-tracker:adr "Why we chose SQLite"
```

## Directory Layout

```
Project-Tracker-SKILL/
├── .claude-plugin/
│   └── marketplace.json           # Marketplace manifest (sources ./plugins/project-tracker)
├── plugins/project-tracker/
│   ├── .claude-plugin/
│   │   └── plugin.json            # Plugin manifest
│   ├── skills/                    # 5 skills (init, learn, doctor, update, adr)
│   ├── scripts/                   # Shared helper scripts
│   │   ├── lib/tracker-common.sh
│   │   ├── scan-state.sh
│   │   └── detect-changes.sh
│   └── templates/                 # Document templates for init/update
│       ├── INDEX.md.tmpl
│       ├── stack.md.tmpl
│       ├── toolchain.md.tmpl
│       ├── architecture.md.tmpl
│       ├── progress.md.tmpl
│       ├── implementation.md.tmpl
│       ├── data-model.md.tmpl
│       ├── api.md.tmpl
│       ├── deployment.md.tmpl
│       └── adr-NNN-kebab-title.md.tmpl
└── README.md
```

## Development

```bash
# Test the plugin locally
claude --plugin-dir plugins/project-tracker

# After changes, reload
/reload-plugins
```
