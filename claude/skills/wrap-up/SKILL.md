---
name: wrap-up
description: Use when ending a coding session, before closing the terminal, or when user says "wrap up", "end session", "done for now", or "call it a day". Also invocable via /wrap-up.
---

# Session Wrap-Up

End your Claude Code session with intention. Run this checklist in order.

## Checklist

### 1. Changes Audit
```bash
git status
git diff --stat
```
- What files were modified?
- Any uncommitted changes that should be committed or stashed?
- Any TODOs left in code?

### 2. Quality Check
Run whatever quality gates the project has (skip if not applicable):
```bash
npm run lint 2>&1 | head -20    # or pnpm/yarn/composer equivalent
npm run typecheck 2>&1 | head -20
npm test -- --changed --passWithNoTests 2>&1 | tail -10
```
- All checks passing?
- Any warnings to address next session?

### 3. Memory Update
Review what was learned this session:
- What mistakes were made?
- What patterns worked well?
- Any non-obvious gotchas discovered?

Update the project's auto-memory (`MEMORY.md`) if anything is worth preserving for future sessions. Skip if nothing notable.

### 4. Next Session Context
- What's the next logical task?
- Any blockers to note?
- Context to preserve for next time?

### 5. Summary
Write one paragraph: what was accomplished, current state, what's next.

After completing checklist, ask: "Ready to end session?"
