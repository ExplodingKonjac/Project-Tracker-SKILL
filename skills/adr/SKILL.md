---
name: adr
disable-model-invocation: false
description: >
  Record an architectural decision as a numbered ADR. Use when making or
  documenting a significant architecture, technology, or pattern choice. It guides the user through capturing context, options,
  rationale, and trade-offs as a numbered ADR in
  .claude/project-tracker/references/. Use whenever a significant
  architectural choice is made during a session, or when documenting
  why a technology, pattern, or approach was chosen over alternatives.
  The user may say "record a decision", "write an ADR", "capture that
  decision", "document why we chose X", or similar.
when_to_use: |
  User says "record a decision", "write an ADR", "capture that decision",
  "document why we chose X", or when a significant architectural choice
  is made during a session.
arguments: [title]
argument_hints: [title]
---

# Project Tracker: Record ADR

Guide the user through capturing an architectural decision and save it as a
numbered ADR file under `.claude/project-tracker/references/`.

## Arguments

| Argument | Description |
|----------|-------------|
| `title` | Short title for the decision. If omitted, the user is prompted. |

## Process

### 1. Gather Information

If `$title` was provided, use it. Otherwise, ask the user for a title.

Then prompt for each field conversationally — one question at a time:

| Question | Maps to field |
|----------|--------------|
| "What was the context? What problem or constraint drove this decision?" | **Context** |
| "What options were considered?" | **Options considered** |
| "Which option was chosen and why?" | **Decision + Rationale** |
| "What are the trade-offs?" | **Consequences** |
| "Are there related ADRs or docs?" | **References** |

For **Options considered**, ask follow-ups: "Any other alternatives?"
and "What was the deciding factor?"

### 2. Determine Next ADR Number

Find existing ADRs:

```bash
ls .claude/project-tracker/references/adr-*.md 2>/dev/null
```

Parse the highest number, increment by one. Start at 1 if none exist.

### 3. Write the ADR

Write to `.claude/project-tracker/references/adr-NNN-kebab-title.md`. Use the template at `${CLAUDE_PLUGIN_ROOT}/templates/adr-NNN-kebab-title.md.tmpl` as a starting point — fill in the `$placeholders` and remove HTML comments.

The template provides the expected structure:

```markdown
# ADR-NNN: $title

**Status:** Accepted

**Date:** $date

**Context:**

$context

**Options considered:**

1. **Option A** — description
2. **Option B** — description

**Decision:**

$decision

**Consequences:**

- Positive: ...
- Negative: ...
- Neutral: ...

**References:**

- $references
```

Format: NNN zero-padded to 3 digits, date ISO 8601, filename kebab-case.

### 4. Update References Index

If `.claude/project-tracker/references/INDEX.md` exists, insert a new entry
under the `## ADRs` section in numeric order. If no `## ADRs` section exists,
append one at the bottom.

Entry format:

```
- [ADR-003: Use PostgreSQL](adr-003-use-postgresql.md) — One-line summary of the decision
```

If `INDEX.md` does not exist, create it with a `## ADRs` section linking all existing ADRs.

When inserting, maintain numeric order — the highest-numbered ADR goes last.
Read the current INDEX.md first, find the right position, and insert there
(rather than blindly appending).

## Rules

- One question at a time.
- After writing, show: "Recorded ADR-003: Use PostgreSQL (adr-003-use-postgresql.md)"
- Do not overwrite existing ADRs.
- If `.claude/project-tracker/` doesn't exist, tell the user to run `/project-tracker:init` first.
