---
name: block-docs-plans
enabled: true
event: file
action: block
conditions:
  - field: file_path
    operator: regex_match
    pattern: docs/plans/
---

**Blocked: Writing to `docs/plans/` is not allowed.**

All plans, designs, research notes, and architecture docs must go to `_research/` (gitignored), not `docs/plans/`.

Replace the path:
- `docs/plans/YYYY-MM-DD-<name>.md` -> `_research/YYYY-MM-DD-<name>.md`
- `docs/plans/` -> `_research/`

Create `_research/` if it doesn't exist. This folder is gitignored and used for local development context only.
