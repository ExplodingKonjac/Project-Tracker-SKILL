# CLI Tool Preset

Generate these tracker files. For each file, fill the corresponding template from `<PLUGIN_ROOT>/templates/`:

| File | Template | Key sources | Notes |
|------|----------|-------------|-------|
| `INDEX.md` | `templates/INDEX.md.tmpl` | config files, `README.md` | Focus on CLI use cases |
| `stack.md` | `templates/stack.md.tmpl` | config files | CLI-specific deps |
| `toolchain.md` | `templates/toolchain.md.tmpl` | CI configs, `Makefile` | Build + cross-compilation |
| `architecture.md` | `templates/architecture.md.tmpl` | `src/` tree, entry points | CLI -> core -> output flow |
| `conventions.md` | `templates/conventions.md.tmpl` | `AGENTS.md`, `.agents/rules/`, `.claude/CLAUDE.md`, linter/formatter configs | Extract conventions from project configs |
| `progress.md` | `templates/progress.md.tmpl` | `git log` | Feature history |
| `implementation.md` | `templates/implementation.md.tmpl` | `src/` entry points | Argument parsing, output formatting |
| `deployment.md` | `templates/deployment.md.tmpl` | `Dockerfile`, package scripts | Binary distribution, package managers |

Skip `api.md` — CLI tools don't expose a network API. Write `N/A` with explanation.

Skip `data-model.md` — CLI tools typically don't use a database. Write `N/A` with explanation.
