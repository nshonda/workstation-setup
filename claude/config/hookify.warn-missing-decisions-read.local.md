---
name: warn-missing-decisions-read
enabled: true
event: file_write
action: warn
conditions:
  - field: file_path
    operator: regex_match
    pattern: (src/services/|src/routes/|src/middleware/|src/models/)
---

**Check: Have you read `.decisions/` for past architectural decisions?**

Before making architectural choices (library selection, pattern choice, API design, data model), read all files in `.decisions/` at the project root to avoid contradicting prior work.

(This is a warning, not a blocker — you can continue, but reading past decisions first helps maintain consistency across sessions.)
