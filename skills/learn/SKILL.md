---
name: learn
disable-model-invocation: false
description: >
  Learn a project quickly from existing .claude/project-tracker docs instead
  of analyzing the full codebase. Use when the user needs to understand the
  current project, architecture, status, conventions, or implementation before
  feature work, bug fixing, code review, or onboarding. It reads structured tracker docs in
  .claude/project-tracker/ instead of analyzing the full codebase.
  Also
  triggered on session resume when the project is tracked. The user may
  say "learn this project", "understand this codebase", "what is this
  project", or just start describing a task that requires project context.
when_to_use: |
  User says "learn this project", "understand this codebase",
  "what is this project", or any task that requires understanding the
  project architecture before proceeding (feature planning, bug fixing,
  code review, onboarding). Also triggered on session resume when the
  project is tracked.
---

# Project Tracker: Learn

Understand the current project by reading `.claude/project-tracker/` documents, not by analyzing the full codebase. This is the fast path to project comprehension.

## When No Tracker Exists

If `.claude/project-tracker/` does not exist or is empty, do not attempt to analyze the codebase as a fallback. Instead, tell the user:

> "This project has no tracker. Run `/project-tracker:init` first to generate it."

## Staleness Check

Before reading tracker docs, check `.claude/project-tracker/.meta` for staleness:

```bash
# quick staleness check — look for STALE entries in the meta file
grep -E '^\s+' .claude/project-tracker/.meta 2>/dev/null | grep -v "baseline:\|updated:" || true
```

If the tracker files are stale (the project has changed since the last `init` or `update`), warn the user:

> "The tracker docs may be stale — run `/project-tracker:doctor` to check."

This ensures the user doesn't make decisions based on outdated information. Proceed with reading the docs regardless (the docs are better than nothing, but the user should know).

## Reading Protocol

1. **Always read** `<WORKSPACE>/.claude/project-tracker/INDEX.md` first — it provides the project overview, tech stack summary, and quick-reference commands.

2. **Choose additional files** based on the task at hand:

   | If the task involves... | Also read... |
   |------------------------|-------------|
   | Understanding tech decisions | `stack.md` |
   | Building, testing, CI/CD | `toolchain.md` |
   | Module layout, data flow | `architecture.md` |
   | Following project conventions or rules | `conventions.md` |
   | Current status, what's done vs pending | `progress.md` |
   | Auditing progress or finding unimplemented work | `progress.md` + run `/project-tracker:audit` |
   | How things work internally | `implementation.md` |
   | Database, storage, schema | `data-model.md` |
   | API endpoints, integration | `api.md` |
   | Building, packaging, deploying | `deployment.md` |

   Also check for subdirectories (`modules/`, `references/`, `ops/`, etc.) and read relevant files from those as needed.

3. **Summarize what you learned** in 3-5 sentences before proceeding with the user's task. This confirms comprehension and lets the user correct any misinterpretation early.

## Code Reading Discipline

- **First pass**: answer questions using only tracker docs. The docs exist precisely to avoid heavy codebase browsing.
- **Second pass**: if the user asks for verification that requires source-level detail ("are you sure that's how X works?", "show me the actual code"), then read specific source files as needed. Always anchor back to the tracker docs when explaining.

## Rules

- Do not `cargo build`, `npm install`, or run the project just to understand it.
- Do not recursively list the entire source tree — the tracker already captures the structure.
- If the tracker is incomplete for your task, note what's missing to the user rather than inferring from source code.
- When the conversation context is tight, prefer re-reading tracker files over keeping raw source in context.
