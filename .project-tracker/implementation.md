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

### Tracker Directory Resolution

The Python state engine defaults to `.agents/project-tracker/`, honors `PROJECT_TRACKER_DIR`, and can derive a workspace root from current or legacy tracker paths passed to script entry points. This lets the plugin write current trackers while still validating a legacy self-tracker when explicitly targeted.

### Source-to-Tracker Mapping

Each tracker file now declares its own dependency boundary via front matter `sources`. The Python state engine resolves those globs to `matched_paths`, then compares the current match set against the stored snapshot.

### Staleness Detection

1. Read `sources` from doc front matter
2. Resolve them to the current `matched_paths`
3. Compare current matches to stored `.state.json` snapshot
4. Compare changed files since the per-doc baseline against current matches
5. Compare changed-file fingerprints against the dirty-input fingerprints captured during the last refresh
6. Mark file STALE when the match set changes or an unrefreshed matched file changes

`progress.md` is intentionally special-cased: it has no source front matter and becomes stale when any non-tracker file changes after its baseline, forcing manual roadmap review.

### Per-File Baseline

`.state.json` stores independent baselines, matched paths, and refreshed dirty-input fingerprints per tracker file, so each file can be updated independently:

```json
{
  "files": {
    "stack.md": {
        "baseline": "a1b2c3d",
        "updated": "2026-05-15T00:00:00Z",
        "matched_paths": ["package.json"],
        "changed_fingerprints": {
          "package.json": "sha256..."
        }
    }
  }
}
```

## Error Handling Strategy

- Python scripts fail fast on invalid front matter or state shape
- `.state.json` is script-owned and refreshed only after successful init/update/audit
- Shell helpers are limited to TODO auditing and packaging validation
- Current and legacy tracker directories are excluded from source ownership matching to prevent self-referential staleness loops

## Testing Strategy

| Test level | Location | What it covers |
|-----------|---------|---------------|
| Smoke | `scripts/test_staleness.py` | State refresh, default `.agents/project-tracker/` fixtures, glob matching, dirty-input fingerprints, unowned files, and stale reasons |
| Packaging | `scripts/validate-packaging.sh` | Marketplace manifests, plugin metadata, and skill layout |

## Performance Considerations

- Tracker-state operations use stdlib-only Python for safer parsing and path handling
- Templates remain static markdown with small front matter stubs
