---
name: handoff
description: Use when switching to a new Claude session, passing work to a colleague, or when user says "handoff", "hand off", "session transfer", "continue later", or "create handoff". Also invocable via /handoff.
---

# Session Handoff

Generate a structured handoff document that another Claude session (or your future self) can consume immediately to continue where you left off.

## How It Works

1. **Gather current state**:
```bash
git status
git diff --stat
git log --oneline -5
```

2. **Generate the handoff document**:

```markdown
# Session Handoff -- [date] [time]

## Status
- **Branch**: [current branch]
- **Commits this session**: [count]
- **Uncommitted changes**: [summary]
- **Tests**: passing / failing / not run

## What's Done
- [completed task 1]
- [completed task 2]

## What's In Progress
- [current task with context on where you stopped]
- [file:line that needs attention next]

## What's Pending
- [next task that hasn't been started]
- [blocked items with reason]

## Key Decisions Made
- [decision 1 and why]
- [decision 2 and why]

## Files Touched
- `path/to/file1.ts` -- [what changed]
- `path/to/file2.ts` -- [what changed]

## Gotchas for Next Session
- [thing that tripped you up]
- [non-obvious behavior discovered]

## Resume Command
> Continue working on [branch]. [1-2 sentence context]. Next step: [specific action].
```

3. **Save** to `_research/handoffs/[date]-[branch].md` (create directory if needed)

## Options

- **default**: Standard handoff with all sections
- **--full**: Include full `git diff` in the document
- **--compact**: Just the resume command and key context

## When to Use

- `/wrap-up` first (close the session properly), then `/handoff` (write the transfer doc)
- Or use `/handoff` alone when switching contexts mid-work
