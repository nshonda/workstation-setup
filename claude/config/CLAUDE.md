# CLAUDE.md

This file provides global guidance to Claude Code (claude.ai/code) across all repositories.

## Workspace Structure

- All repos live under `~/workstation/` split by account:
  - `~/workstation/personal/` — personal GitHub account
  - `~/workstation/work/` — work GitHub account
- **direnv** manages per-directory environment variables (GitHub tokens, Jira creds, Redmine creds) — credentials are pulled from the system credential store (macOS Keychain, `secret-tool`/`pass` on Linux), never hardcoded
- Git identity switches automatically via `includeIf` (personal email for personal repos, work email for work repos)

## Tool Priority

Always prefer integrated tools (MCP servers, plugins, skills) over manual alternatives or raw CLI commands. Use whatever facilitates the task most effectively:

- **MCP servers** over shell commands or web searches (e.g., use Jira MCP instead of curl to Jira API)
- **Plugins and skills** over manual multi-step workflows (e.g., use commit-commands plugin over hand-rolling git commands)
- **GitHub MCP** over `gh` CLI for GitHub operations (PRs, issues, repos) — token is set per-directory via direnv (personal vs work)
- **context7** over web searches for library/framework documentation and code examples
- **openbrowser** for browser automation, testing, screenshots, form filling, web scraping, and accessibility audits
- **Jira MCP** for all Jira interactions (issues, sprints, boards)
- **Redmine MCP** for all Redmine interactions
- **Slack MCP** — two workspaces: `slack-onerhino` (personal/oneRhino) and `slack-basis` (work/Basis). Use the one matching the current workspace context.

If an MCP server or plugin can do the job, use it. Only fall back to CLI tools or manual approaches when no integrated tool covers the use case.

## Skill Routing

Invoke skills by context. Most skills self-describe their triggers — only non-obvious routing is listed here.

**Workflow sequencing:**
- Building new functionality → `superpowers:brainstorming` first, then implementation skill
- Starting feature work → `superpowers:using-git-worktrees` (auto-decide per Git Worktree Policy)
- Implementing any feature or bugfix → `superpowers:test-driven-development`
- About to claim work is done → `superpowers:verification-before-completion`

**Disambiguation:**
- PR review → `code-review:code-review` (quick, posts comment) or `pr-review-toolkit:review-pr` (thorough multi-aspect)
- Commit → `pro-workflow:commit` (quality checks) or `commit-commands:commit` (quick)
- Commit + push + PR → `commit-commands:commit-push-pr`

**Non-obvious routing:**
- Executing a plan with independent tasks → `superpowers:subagent-driven-development`
- Executing a plan from separate session → `superpowers:executing-plans`
- 2+ independent parallel tasks → `superpowers:dispatching-parallel-agents`
- Bug/test failure/unexpected behavior → `superpowers:systematic-debugging`
- Code review before merging → `superpowers:requesting-code-review`
- Received review feedback → `superpowers:receiving-code-review`
- Implementation complete, deciding integration → `superpowers:finishing-a-development-branch`
- Clean up gone branches → `commit-commands:clean_gone`
- Multi-line commands for manual execution → `clipboard` (auto-trigger)
- Visual architecture plan → `interactive-plan`
- Creating/editing skills → `superpowers:writing-skills`

**Specialist agents (spawned as subagents via Task tool into ~/.claude/agents/):**
- Architecture review, DDD, CQRS, tech debt assessment → `architect-reviewer` (opus)
- Building/debugging MCP servers and clients → `mcp-developer` (sonnet)

**Framework skills:** Enabled per-project via `init-project-claude`. Not globally routed.

## Subagent Rules

When using the Task tool, **always include this instruction at the start of every subagent prompt**:

> As your first action, read `/Users/natalihonda/.claude/CLAUDE.md` and follow all rules in it. Pay special attention to Tool Priority (prefer MCP servers over CLI/web search — especially context7 for library docs via ToolSearch). Also read the project-level CLAUDE.md if one exists in the working directory.

This ensures subagents inherit the full global config — tool priority, conventions, git rules, and everything else — without maintaining a separate copy.

### Model Routing

Match the model to task complexity:

- **haiku** — simple file lookups, grep searches, straightforward single-file edits, quick code generation
- **sonnet** — multi-file changes, moderate refactors, standard feature work, code review
- **opus** — architectural decisions, complex debugging, security-sensitive code, cross-cutting changes

Default to haiku when unsure — escalate only when the task clearly needs deeper reasoning.

## Git Commits

- NEVER add `Co-Authored-By: Claude` (or any Claude co-author line) to commit messages.
- NEVER add promotional text like "Generated with Claude Code", "Written by Claude", or any self-attribution to commit messages, PR descriptions, code comments, or any output.

## Git Worktree Policy

**Default: use a worktree for any task that modifies code files.** Invoke `superpowers:using-git-worktrees` automatically — do not ask.

**Only skip worktrees** for:
- Single-file config/doc/markdown edits
- Typo fixes or comment-only changes

This prevents collisions when multiple Claude Code sessions run in the same repo.

## Anti-Hallucination Guards

- Before updating or transitioning a Jira issue, always `jira_get_issue` first to confirm it exists and verify current status.
- Before updating a Redmine issue, always GET it first via `redmine_request`.
- Never fabricate issue keys, sprint IDs, or board IDs — always retrieve them from the API.
- Prefer `jira_search` with targeted JQL over `jira_get_project_issues` (token efficiency).
- Prefer `jira_get_sprint_issues` over `jira_get_board_issues` when you know the sprint.

## Conventions

- When generating markdown text intended for Redmine, use Textile formatting syntax per: https://www.redmine.org/projects/redmine/wiki/RedmineTextFormattingTextile
- Project-level CLAUDE.md files inherit all global conventions — avoid duplicating them

## Jira Branch Names

When creating a branch for a Jira ticket, use this format:
```
{ISSUE_KEY}-{summary-in-kebab-case}
```

To generate from Jira MCP issue data:
1. Get issue with `jira_get_issue`
2. Take the `key` (e.g., `PROJ-123`)
3. Take the `summary`, lowercase it, replace spaces with hyphens
4. Combine: `PROJ-123-fix-the-broken-thing`

## Research Folder

- Use `_research/` at the project root for dev research notes, architecture docs, and planning context. This folder is for local development only and must always be gitignored.
- When starting a task, read all files in `_research/` for project context — treat them as extensions of CLAUDE.md.
- When doing research or planning for a project, save notes and findings to `_research/` as markdown files.
- **Override plugin defaults:** Skills/plugins that write to `docs/plans/` (e.g., `writing-plans`, `brainstorming`, `subagent-driven-development`) MUST use `_research/` instead. Replace `docs/plans/YYYY-MM-DD-<name>.md` with `_research/YYYY-MM-DD-<name>.md`. Never create a `docs/plans/` directory.

@RTK.md
