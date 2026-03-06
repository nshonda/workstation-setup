---
name: block-co-authored-by
enabled: true
event: bash
action: block
conditions:
  - field: command
    operator: regex_match
    pattern: git\s+commit
  - field: command
    operator: regex_match
    pattern: Co-Authored-By|co-authored-by|Co-authored-by
---

**BLOCKED: Co-Authored-By line detected in git commit**

Your global CLAUDE.md says:
> NEVER add `Co-Authored-By: Claude` (or any Claude co-author line) to commit messages.

Remove the Co-Authored-By trailer from the commit message and try again.
