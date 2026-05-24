# Default Preset

Generate all 10 standard tracker files. For each file, fill the corresponding template from `${CLAUDE_PLUGIN_ROOT}/templates/`:

| File | Template | Key sources | Notes |
|------|----------|-------------|-------|
| `INDEX.md` | `templates/INDEX.md.tmpl` | `Cargo.toml`, `package.json`, `README.md` | Main project overview |
| `stack.md` | `templates/stack.md.tmpl` | config files, `Dockerfile` | Versions from `package.json` `engines`, `Cargo.toml` edition |
| `toolchain.md` | `templates/toolchain.md.tmpl` | CI configs, `Makefile`, `Dockerfile` | Extract actual CI steps |
| `architecture.md` | `templates/architecture.md.tmpl` | `src/` tree, entry points | Create ASCII diagram from module structure |
| `conventions.md` | `templates/conventions.md.tmpl` | `.claude/CLAUDE.md`, `.editorconfig`, linter/formatter configs | Extract conventions from project configs |
| `progress.md` | `templates/progress.md.tmpl` | `git log`, `CHANGELOG.md` | Use last 10 commits for recent work |
| `implementation.md` | `templates/implementation.md.tmpl` | `src/` entry points, test dirs | Focus on non-trivial logic |
| `data-model.md` | `templates/data-model.md.tmpl` | `prisma/`, `migrations/`, `db/` | Skip if no data layer — write N/A |
| `api.md` | `templates/api.md.tmpl` | route files, OpenAPI specs | Skip if no network API — write N/A |
| `deployment.md` | `templates/deployment.md.tmpl` | `Dockerfile`, `deploy/`, `k8s/` | Skip if not deployed — write N/A |

If the project has distinct sub-components, also create subdirectories per the standards in the init SKILL.md.
