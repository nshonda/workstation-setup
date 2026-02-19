---
name: block-self-promotion
enabled: true
event: bash
conditions:
  - field: command
    operator: regex_match
    pattern: gh\s+pr\s+(comment|create|edit|review)|gh\s+issue\s+(comment|create)|git\s+commit
  - field: command
    operator: regex_match
    pattern: Generated with.*Claude|Written by Claude|Claude Code\)|Co-Authored-By.*Claude|🤖.*Claude
action: block
---

**BLOCKED: Self-promotional text detected in command**

Your global CLAUDE.md says:
> NEVER add promotional text like "Generated with Claude Code", "Written by Claude", or any self-attribution to commit messages, PR descriptions, code comments, or any output.

Remove the self-promotional text before running this command. This includes:
- "Generated with Claude Code" footers
- "Written by Claude" attributions
- "Co-Authored-By: Claude" lines
- Any Claude self-attribution emoji/links

The code-review plugin template includes this text by default — strip it.
