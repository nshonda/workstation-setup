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

The `_research/` folder is for local development only and must always be gitignored. Before continuing, verify that `.gitignore` contains `_research/`. If it doesn't, add it now.
