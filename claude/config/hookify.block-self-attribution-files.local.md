---
name: block-self-attribution-files
enabled: true
event: file
action: block
conditions:
  - field: new_text
    operator: regex_match
    pattern: Generated with.*Claude|Written by Claude|Authored by Claude|Claude Code\)|Powered by Claude|Made with Claude|Built with Claude|Created by Claude
---

**BLOCKED: Self-attribution text detected in file write**

Your global CLAUDE.md says:
> NEVER add promotional text like "Generated with Claude Code", "Written by Claude", or any self-attribution to commit messages, PR descriptions, code comments, or any output.

Remove the self-promotional text before writing this file.
