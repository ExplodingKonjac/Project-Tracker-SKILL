---
sources:
  - "scripts/*.sh"
  - "scripts/*.py"
  - "skills/**/*.md"
---

# Implementation Details

## Entry Points

| Target | File | Purpose |
|--------|------|---------|
| Init | `skills/project-tracker-init/SKILL.md` | Generates tracker docs |
| Learn | `skills/project-tracker-learn/SKILL.md` | Reads and summarizes docs |
| Doctor | `skills/project-tracker-doctor/SKILL.md` | Validates docs |
| Update | `skills/project-tracker-update/SKILL.md` | Refreshes stale docs |
| ADR | `skills/project-tracker-adr/SKILL.md` | Records decisions |
| Audit | `skills/project-tracker-audit/SKILL.md` | Cross-checks progress docs against TODOs and stubs |

## Key Algorithms

### Source-to-Tracker Mapping

Each tracker file now declares its own dependency boundary via front matter `sources`. The Python state engine resolves those globs to `matched_paths`, then compares the current match set against the stored snapshot.

### Staleness Detection

1. Read `sources` from doc front matter
2. Resolve them to the current `matched_paths`
3. Compare current matches to stored `.state.json` snapshot
4. Compare changed files since the per-doc baseline against current matches
5. Mark file STALE when the match set changes or a matched file changes

### Per-File Baseline

`.state.json` stores independent baselines per tracker file, so each file can be updated independently:

```json
{
  "files": {
    "stack.md": {
      "baseline": "a1b2c3d",
      "updated": "2026-05-15T00:00:00Z",
      "matched_paths": ["package.json"]
    }
  }
}
```

## Error Handling Strategy

- Python scripts fail fast on invalid front matter or state shape
- `.state.json` is script-owned and refreshed only after successful init/update/audit
- Thin shell wrappers keep the existing command surface stable

## Testing Strategy

| Test level | Location | What it covers |
|-----------|---------|---------------|
| Smoke | `scripts/test_staleness.py` | State refresh, glob matching, unowned files, and stale reasons |

## Performance Considerations

- Tracker-state operations use stdlib-only Python for safer parsing and path handling
- Templates remain static markdown with small front matter stubs
