# Skill Routing

Most skills self-describe their triggers. Only disambiguation and non-obvious routing listed here.

**Workflow sequence:** brainstorming → worktree → TDD → implementation → verification-before-completion

**Disambiguation:**
- PR review → `code-review:code-review` (quick) or `pr-review-toolkit:review-pr` (thorough)
- Commit → `commit-commands:commit` | Commit + push + PR → `commit-commands:commit-push-pr`

**Non-obvious routing:**
- Plan with independent tasks → `superpowers:subagent-driven-development`
- Plan from separate session → `superpowers:executing-plans`
- Bug/test failure → `superpowers:systematic-debugging`
- Creating/editing skills → `superpowers:writing-skills`

**Specialist agents (~/.claude/agents/):**
- Architecture/DDD/tech debt → `architect-reviewer` (opus)
- MCP servers/clients → `mcp-developer` (sonnet)
