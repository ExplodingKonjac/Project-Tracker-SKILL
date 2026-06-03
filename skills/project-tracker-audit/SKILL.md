---
name: project-tracker-audit
disable-model-invocation: false
description: >
  Audit progress state by cross-referencing progress.md against actual
  source code. Finds unimplemented TODOs, FIXMEs, stubs, and language-
  specific incomplete markers in the codebase, then validates them
  against progress.md. Also checks whether progress.md items have
  detectable implementation in the code. Use when the user says
  "audit progress", "check progress", "find TODOs", "what's not done",
  "unimplemented work", or wants to validate that progress.md reflects
  actual project state.
when_to_use: |
  User says "audit progress", "check progress", "find TODOs",
  "what's not done", "unimplemented", "what's left to do",
  or wants to validate progress.md against the codebase.
---

# Project Tracker: Audit Progress

Cross-reference progress.md against actual source code to find unrecorded work and validate claimed progress. Two-directional: source TODOs → progress.md, and progress.md → actual code.

## Prerequisite

If `.agents/project-tracker/` does not exist or lacks `progress.md`, tell the user:

> "No progress tracker found. Run `/project-tracker-init` first."

## Process

Use `<UPPER_SNAKE_CASE>` angle-bracket placeholders for pseudocode variables. Use `<PLUGIN_ROOT>` to mean the installed project-tracker plugin root. Resolve it from the agent harness when available, or from the directory that contains this skill's `skills/`, `scripts/`, and `templates/` directories. In this flattened plugin, the repository root and `plugins/project-tracker` symlink both resolve to the same plugin root. Replace `<PLUGIN_ROOT>` with that resolved absolute path before running shell snippets.

### 1. Scan source for TODOs and stubs

Run the audit script from the workspace root:

```bash
bash "<PLUGIN_ROOT>/scripts/audit-todos.sh" .
```

The script auto-detects project languages from config files (`Cargo.toml`, `package.json`, `pyproject.toml`, `go.mod`, etc.) and runs the appropriate grep patterns. Output has two sections:

- **TODO / FIXME / HACK / XXX** — comment markers in source, shell scripts, and markdown
- **Language-Specific Stubs** — `todo!()`, `unimplemented!()`, `raise NotImplementedError`, `throw new UnsupportedOperationException`, etc.

Each line is a location: `file:line:content`.

### 2. Read progress.md

Read `.agents/project-tracker/progress.md`. Note every item in:

- **In Progress** — items actively being worked on
- **Roadmap** — planned but not started
- Optionally **Known Issues** — acknowledged problems

### 3. Cross-reference both ways

**A. TODOs not in progress.md** — For each TODO/stub found in source, check whether progress.md mentions it (in In Progress, Roadmap, or Known Issues). Report unrecorded ones:

```
[UNRECORDED] src/auth.rs:42 — TODO: implement token refresh
[UNRECORDED] src/api.rs:15 — FIXME: race condition on connect
```

**B. progress.md items with no code evidence** — For each In Progress and Roadmap item, check whether related files exist or were recently changed:

```bash
git log --oneline --since="2 weeks ago" -- <relevant-paths>
```

Report items that appear stalled:

```
[STALLED] "Script smoke tests" — no test files changed in 2 weeks
[STALLED] "CI validation" — .github/workflows/ not found
```

**C. Linked items** — TODOs that DO match a progress.md entry. These are expected:

```
[LINKED] src/tracker-common.sh:45 — TODO: Bash 3 compat → matches "Bash 3 portability fix"
```

### 4. Summarize

```
=== Audit Summary ===
  Unrecorded:  N items (TODOs not tracked in progress.md)
  Stalled:     N items (progress.md items with no code evidence)
  Linked:      N items (TODOs matched to progress.md)
  Total TODOs: N
```

### 5. Offer to update progress.md

After presenting the summary, ask the user:

> "Update progress.md with these findings?"

If the user says yes:

- Add unrecorded TODOs to **In Progress** or **Roadmap** (use judgment for which)
- Move stalled items to **Known Issues** (or remove if no longer relevant)
- Mark linked items as unchanged (they're already tracked)
- Refresh `progress.md` in script-owned state with `python3 "<PLUGIN_ROOT>/scripts/refresh_state.py" progress.md`

If the user says no, leave progress.md untouched.

## Rules

- Don't flag TODOs in vendored or generated code.
- Use judgment: a `TODO: optimize later` in a hot path is worth flagging; a `TODO: remove debug log` isn't.
- If progress.md items are vague ("Script smoke tests"), flag them as STALLED only if zero related files changed recently.
- Respect `.gitignore` — don't scan ignored files.
