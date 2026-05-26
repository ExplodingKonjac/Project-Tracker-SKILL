---
name: project-tracker-init
disable-model-invocation: false
description: Initialize project tracker docs under .project-tracker by scanning the current project and generating structured documentation.
when_to_use: |
  User invokes /project-tracker-init, or says instructions like "init project tracker",
  "document this project", "create project docs".
arguments: [preset]
argument-hints: [preset]
---

# Project Tracker: Init

Read the current project's codebase and generate a structured set of `.md` files under `<WORKSPACE>/.project-tracker/`, documenting the project's technology choices, architecture, progress, and implementation details.

## Arguments

| Argument | Description |
|----------|-------------|
| `preset` | Project type: `default`, `library`, `web-app`, or `cli-tool`. If omitted, `default` is used. |

## Presets

Preset definitions in `${CLAUDE_PLUGIN_ROOT}/skills/project-tracker-init/presets/` control which tracker files to generate. The `$preset` argument selects which preset to use:

| Preset | Definition | Behavior |
|--------|-----------|----------|
| `default` | `${CLAUDE_PLUGIN_ROOT}/skills/project-tracker-init/presets/default.md` | All 10 standard files |
| `library` | `${CLAUDE_PLUGIN_ROOT}/skills/project-tracker-init/presets/library.md` | Skip `api.md`, `deployment.md` |
| `web-app` | `${CLAUDE_PLUGIN_ROOT}/skills/project-tracker-init/presets/web-app.md` | All 10 + `frontend/` and `backend/` subdirs |
| `cli-tool` | `${CLAUDE_PLUGIN_ROOT}/skills/project-tracker-init/presets/cli-tool.md` | Skip `api.md`, `data-model.md` |

If `$preset` is empty or unrecognized, read `${CLAUDE_PLUGIN_ROOT}/skills/project-tracker-init/presets/default.md`.

## Process

0. **Load preset** — read the file at `${CLAUDE_PLUGIN_ROOT}/skills/project-tracker-init/presets/$preset.md` (fall back to `${CLAUDE_PLUGIN_ROOT}/skills/project-tracker-init/presets/default.md` if `$preset` is empty or the file doesn't exist) to determine which files to generate.

1. **Scan the project root**:
   - Read root config files (`Cargo.toml`, `package.json`, `pyproject.toml`, `go.mod`, `CMakeLists.txt`, etc.) to detect language, dependencies, and toolchain.
   - List directory tree (max depth 3) to understand module structure.
   - Check `.github/workflows/` for CI/CD pipeline.
   - Check root for `Dockerfile`, `docker-compose.yml`, `.dockerignore`.

2. **Analyze source code**:
   - Inspect entry points (`main.rs`, `main.go`, `main.py`, `index.ts`, etc.) for module layout and primary dependencies.
   - Identify test directories and test patterns.
   - Spot key config or schema files.

3. **Generate** each file specified by the loaded preset under `<WORKSPACE>/.project-tracker/`. Use the corresponding template from `${CLAUDE_PLUGIN_ROOT}/templates/` as a starting point for each file — fill in sections, expand where needed, and remove HTML comments. Preset-specific guidance is in the preset file itself.

4. **Record baseline** — write `.project-tracker/.meta` with the current tracking snapshot for future `update` use.

## Baseline Tracking

After generating all files, create `.project-tracker/.meta` with one entry per generated file:

```yaml
files:
  stack.md:
    baseline: <current HEAD commit hash, or "none">
    updated: <ISO 8601 timestamp>
  toolchain.md:
    baseline: <same hash>
    updated: <same timestamp>
  ...
```

- Run `git rev-parse HEAD` to get the baseline commit. If not a git repo, write `none`.
- Each tracker file gets its own entry. On `init` all entries share the same baseline; on `update` only changed files get their baseline refreshed.
- Subdirectory documents (e.g., `modules/*.md`) are tracked the same way, using their relative path under `.project-tracker/` as the key.
- This file is consumed by `/project-tracker-update` to detect per-file staleness.

## Mandatory Document Structure (default preset)

The structure below applies to the `default` preset. Other presets omit or add
files as defined in their preset file.

```
<WORKSPACE>/.project-tracker/
├── INDEX.md                    # Overview, purpose, and index
├── stack.md                    # Technology stack & rationale
├── toolchain.md                # Build, lint, test, CI/CD, dev setup
├── architecture.md             # Architecture design & module layout
├── conventions.md              # Coding standards, naming rules, architectural rules
├── progress.md                 # Current status & roadmap
├── implementation.md           # Key implementation details & patterns
├── data-model.md               # Data model, schema, persistence
├── api.md                      # API surface (if applicable)
└── deployment.md               # Build, package, deploy configuration
```

### File-by-file requirements

| File | Required content |
|------|-----------------|
| `INDEX.md` | One-line project description, table of contents linking to all files, tech stack summary (3-5 bullets), quick-reference commands (build, test, run) |
| `stack.md` | Language & runtime version, frameworks/libraries with rationale for each major choice, database & storage layer, infrastructure / cloud services |
| `toolchain.md` | Build system & commands, linter / formatter / static analysis setup, test framework & coverage targets, CI/CD pipeline steps, dev environment prerequisites, required env vars |
| `architecture.md` | ASCII architecture diagram or textual description, module/crate/package breakdown with responsibilities, key data flow paths, design patterns used, security boundaries |
| `conventions.md` | Coding conventions (formatter/linter rules), naming conventions (files, variables, functions, types), architectural rules (invariants, forbidden patterns), file organization, import/module conventions, error handling, testing, documentation, agent instructions (from `AGENTS.md`, `.agents/rules/`, `.claude/CLAUDE.md`, and `.claude/rules/`) |
| `progress.md` | Current phase or milestone, completed features checklist, known issues & technical debt, roadmap / next steps (use placeholders for unknown items) |
| `implementation.md` | Entry point(s) & request trace, key algorithms or non-trivial logic, error handling strategy, testing strategy breakdown, performance considerations |
| `data-model.md` | Entity / table listing with key fields, relationship descriptions (1:1, 1:N, M:N), migration strategy, cache layer description |
| `api.md` | Endpoint listing (method, path, auth, description), request/response shape or schema reference, rate limiting & pagination |
| `deployment.md` | Build artifact description, packaging format (Docker, .vsix, .deb, etc.), deployment environments & promotion, health checks & monitoring, rollback procedure |

## Subdirectory Standards (for complex projects)

When the project has distinct sub-components, create subdirectories to keep files focused:

```
.project-tracker/
├── INDEX.md
├── stack.md
├── ...
├── modules/                    # Monorepo / workspace members
│   ├── core.md                 # One file per package/crate/service
│   ├── cli.md
│   └── vscode-extension.md
├── references/                 # External references, ADRs, decisions
│   ├── adr-001-auth-flow.md
│   └── adr-002-db-choice.md
└── ops/                        # Operations, runbooks, monitoring
    ├── runbooks/
    └── alerts.md
```

| Subdirectory | When to create | Content |
|-------------|---------------|---------|
| `modules/` | Project is a monorepo with multiple packages, crates, or services | One `.md` per module covering its responsibility, entry point, key dependencies, and unique patterns |
| `references/` | Project has architectural decision records or external spec links | ADRs, links to design docs, dependency references |
| `ops/` | Project has deployment, monitoring, or operational concerns | Runbooks, alert descriptions, backup/restore procedures |
| `frontend/` | Project has a significant UI component | Component hierarchy, state management pattern, routing, styling system |
| `backend/` | Project has a significant server-side component | Service topology, middleware chain, background jobs, data pipeline |

## Rules

- **Skip existing files** — never overwrite. Report which files were created and which were skipped.
- All files use **English** with clear heading hierarchy (`# title`, `## sections`).
- For inapplicable files that the preset still requires, write `N/A` with a one-line explanation — do not omit the file.
- Analyze source code directly; do not read existing `.project-tracker/*` or legacy `.claude/project-tracker/*` documentation files.
