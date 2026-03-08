# Subagent Rules

When using the Task tool, **always include this instruction at the start of every subagent prompt**:

> As your first action, read `/Users/natalihonda/.claude/CLAUDE.md` and follow all rules in it. Pay special attention to Tool Priority (prefer MCP servers over CLI/web search — especially context7 for library docs via ToolSearch). Also read the project-level CLAUDE.md if one exists in the working directory.

This ensures subagents inherit the full global config — tool priority, conventions, git rules, and everything else — without maintaining a separate copy.

## Model Routing

Match the model to task complexity:

- **haiku** — simple file lookups, grep searches, straightforward single-file edits, quick code generation
- **sonnet** — multi-file changes, moderate refactors, standard feature work, code review
- **opus** — architectural decisions, complex debugging, security-sensitive code, cross-cutting changes

Default to haiku when unsure — escalate only when the task clearly needs deeper reasoning.
