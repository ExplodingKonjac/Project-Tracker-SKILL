# Web App Preset

Generate all 9 standard tracker files. For each file, fill the corresponding template from `${CLAUDE_PLUGIN_ROOT}/templates/`:

| File | Template | Key sources | Notes |
|------|----------|-------------|-------|
| `INDEX.md` | `templates/INDEX.md.tmpl` | config files, `README.md` | End-to-end overview |
| `stack.md` | `templates/stack.md.tmpl` | config files, `Dockerfile` | Frontend + backend split |
| `toolchain.md` | `templates/toolchain.md.tmpl` | CI configs, `Makefile` | Build, lint, test pipelines |
| `architecture.md` | `templates/architecture.md.tmpl` | `src/` tree, entry points | Client-server architecture |
| `progress.md` | `templates/progress.md.tmpl` | `git log` | Feature tracker |
| `implementation.md` | `templates/implementation.md.tmpl` | `src/` entry points | Key flows |
| `data-model.md` | `templates/data-model.md.tmpl` | `prisma/`, `migrations/`, `db/` | Skip if no DB — write N/A |
| `api.md` | `templates/api.md.tmpl` | route files, `pages/api/`, handlers | REST/GraphQL + auth |
| `deployment.md` | `templates/deployment.md.tmpl` | `Dockerfile`, `deploy/`, `k8s/` | Staging + production environments |

Additionally create two subdirectories with dedicated documents:

```
.claude/project-tracker/frontend/
├── stack.md
├── architecture.md
└── toolchain.md
```

```
.claude/project-tracker/backend/
├── stack.md
├── api.md
├── data-model.md
└── deployment.md
```

When generating the root-level files, cross-reference the `frontend/` and `backend/` docs.
