---
name: warn-research-gitignore
enabled: true
event: file
action: warn
conditions:
  - field: file_path
    operator: regex_match
    pattern: _research/
---

**Check: Is `_research/` in `.gitignore`?**

The `_research/` folder is for local development only and should always be gitignored. Please verify that `.gitignore` contains `_research/`. If not, consider adding it before proceeding.

(This is a warning, not a blocker — you can continue, but the folder won't be protected from accidental commits without this entry.)
