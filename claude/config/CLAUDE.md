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
  - **Always use `slack_schedule_message`** (with `post_at` = now + 120 seconds) instead of `slack_send_message`. Direct sends add "Sent using Claude" attribution that can't be stripped. Scheduled messages don't. The user can cancel in Slack's "Drafts & Sent" before delivery if needed.
  - **Slack uses mrkdwn, not markdown.** Key differences: bold = `*text*` (not `**text**`), italic = `_text_` (not `*text*`), strikethrough = `~text~`, links = `<url|display text>` (not `[text](url)`), code = `` `code` `` and ` ```code block``` `, lists = bullet only (no ordered), blockquote = `>` per line. Never send standard markdown syntax — always convert to mrkdwn before sending.
  - **Slack message structure matters.** Use `\n` newlines to separate paragraphs, introduce lists, and break sections. A message without newlines renders as a wall of text. Correct pattern: intro paragraph `\n\n` then bullet list (each `• item\n`) then `\n` then closing text. Never jam sentences together — if content has distinct sections (intro, list, notes, cc), separate them with blank lines (`\n\n`). URLs followed by a new sentence MUST have a newline or period+space between them.

If an MCP server or plugin can do the job, use it. Only fall back to CLI tools or manual approaches when no integrated tool covers the use case.

@includes/skill-routing.md

@includes/subagent-rules.md

## Git Safety

- **NEVER commit or push on main or master.** Always create a feature branch first and open a PR.
- **NEVER force push** (`--force`, `--force-with-lease`) to any branch.
- These rules are enforced by the `guard-protected-branches.sh` PreToolUse hook.

## Git Commits

- NEVER add `Co-Authored-By: Claude` (or any Claude co-author line) to commit messages.
- NEVER add promotional text like "Generated with Claude Code", "Written by Claude", or any self-attribution to commit messages, PR descriptions, code comments, or any output.

## Git Worktree Policy

**Default: use a worktree for any task that modifies code files.** Invoke `superpowers:using-git-worktrees` automatically — do not ask.

**Only skip worktrees** for:
- Single-file config/doc/markdown edits
- Typo fixes or comment-only changes

## Anti-Hallucination Guards

- Before updating or transitioning a Jira issue, always `jira_get_issue` first to confirm it exists and verify current status.
- Before updating a Redmine issue, always GET it first via `redmine_request`.
- Never fabricate issue keys, sprint IDs, or board IDs — always retrieve them from the API.
- Prefer `jira_search` with targeted JQL over `jira_get_project_issues` (token efficiency).
- Prefer `jira_get_sprint_issues` over `jira_get_board_issues` when you know the sprint.

## Conventions

- When generating markdown text intended for Redmine, use Textile formatting syntax per: https://www.redmine.org/projects/redmine/wiki/RedmineTextFormattingTextile
- Project-level CLAUDE.md files inherit all global conventions — avoid duplicating them
- Jira branch name format: `{ISSUE_KEY}-{summary-in-kebab-case}` — derive from `jira_get_issue`

## Research Folder

- Use `_research/` at the project root for dev research notes, architecture docs, and planning context. This folder is for local development only and must always be gitignored.
- When starting a task, read all files in `_research/` for project context — treat them as extensions of CLAUDE.md.
- When doing research or planning for a project, save notes and findings to `_research/` as markdown files.
- **Override plugin defaults:** Skills/plugins that write to `docs/plans/` MUST use `_research/` instead. Never create a `docs/plans/` directory.

@RTK.md
