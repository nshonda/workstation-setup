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

To proceed:
- Change the path from `docs/plans/YYYY-MM-DD-<name>.md` to `_research/YYYY-MM-DD-<name>.md`
- Or change `docs/plans/` to `_research/`
- Create `_research/` if needed (it's gitignored for local development only)

Then retry the write.
