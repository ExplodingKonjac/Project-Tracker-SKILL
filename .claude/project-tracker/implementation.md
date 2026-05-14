# Implementation Details

## Entry Points

| Target | File | Purpose |
|--------|------|---------|
| Init | `skills/init/SKILL.md` | Generates tracker docs |
| Learn | `skills/learn/SKILL.md` | Reads and summarizes docs |
| Doctor | `skills/doctor/SKILL.md` | Validates docs |
| Update | `skills/update/SKILL.md` | Refreshes stale docs |
| ADR | `skills/adr/SKILL.md` | Records decisions |

## Key Algorithms

### Source-to-Tracker Mapping

Each tracker file (stack.md, toolchain.md, etc.) maps to specific source file patterns. The mapping in `tracker-common.sh` determines whether a changed source file affects a given tracker doc:

- `stack.md` ← config files (Cargo.toml, package.json, etc.)
- `toolchain.md` ← CI configs (.github/, tests/)
- `architecture.md | implementation.md` ← source dirs (src/, lib/, app/)
- `data-model.md` ← schema dirs (prisma/, migrations/)
- `api.md` ← route dirs (routes/, controllers/, api/)
- `deployment.md` ← deploy configs (Dockerfile, docker-compose, k8s/)

### Staleness Detection

1. Read baseline commit from `.meta` per file
2. Run `git diff --name-only baseline..HEAD`
3. Filter changed files through source-to-tracker mapping
4. Mark file STALE if any relevant sources changed

### Per-File Baseline

`.meta` stores independent baselines per tracker file, so each file can be updated independently:

```yaml
files:
  stack.md:
    baseline: a1b2c3d
    updated: 2026-05-15T00:00:00Z
```

## Error Handling Strategy

- Scripts use `set -euo pipefail` for strict error detection
- `.meta` validation at the start of update/doctor — abort with message if missing
- No silent failures: every command has `|| true` fallback where needed

## Testing Strategy

| Test level | Location | What it covers |
|-----------|---------|---------------|
| None yet | — | No test suite currently |

## Performance Considerations

- Scripts are lightweight (git diff, find, grep) — no heavy computation
- Templates are static markdown — no runtime rendering cost
