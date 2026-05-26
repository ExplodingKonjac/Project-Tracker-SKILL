# Library Preset

Generate these tracker files. For each file, fill the corresponding template from `PLUGIN_ROOT/templates/`:

| File | Template | Key sources | Notes |
|------|----------|-------------|-------|
| `INDEX.md` | `templates/INDEX.md.tmpl` | config files, `README.md` | Focus on library API surface |
| `stack.md` | `templates/stack.md.tmpl` | config files | Language + deps only |
| `toolchain.md` | `templates/toolchain.md.tmpl` | CI configs, `Makefile` | Focus on build + test |
| `architecture.md` | `templates/architecture.md.tmpl` | `src/` tree, public API | Focus on module structure |
| `conventions.md` | `templates/conventions.md.tmpl` | `AGENTS.md`, `.agents/rules/`, `.claude/CLAUDE.md`, linter/formatter configs | Extract conventions from project configs |
| `progress.md` | `templates/progress.md.tmpl` | `git log`, `CHANGELOG.md` | Version history is key |
| `implementation.md` | `templates/implementation.md.tmpl` | `src/` entry points | Focus on public API design |
| `data-model.md` | `templates/data-model.md.tmpl` | schema files | Skip if no data layer — write N/A |

Skip `api.md` — libraries expose an API via code, not a network endpoint. Write `N/A` with explanation.

Skip `deployment.md` — libraries are distributed as packages, not deployed as services. Write `N/A` with explanation.
