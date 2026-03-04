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

Invoke skills by context — do not wait for slash commands. Match the user's intent to the right skill:

**Before writing code:**
- Building, creating, or adding new functionality → `superpowers:brainstorming` first, then implementation skill
- Planning a multi-step task or writing a spec → `superpowers:writing-plans`
- Starting feature work that needs branch isolation → `superpowers:using-git-worktrees`

**During implementation:**
- Implementing any feature or bugfix → `superpowers:test-driven-development`
- Guided feature development with architecture focus → `feature-dev:feature-dev`
- Building frontend/UI components or pages → `frontend-design:frontend-design`
- Building apps with Claude API / Anthropic SDK → `claude-developer-platform`
- Building MCP servers (Python/TypeScript) → `mcp-builder`
- Creating or improving skills with evals/benchmarks → `skill-creator`
- Testing web apps with Playwright → `webapp-testing`
- Executing a written plan with independent tasks → `superpowers:subagent-driven-development`
- Executing a plan from a separate session → `superpowers:executing-plans`
- 2+ independent tasks that can run in parallel → `superpowers:dispatching-parallel-agents`

**Debugging:**
- Any bug, test failure, or unexpected behavior → `superpowers:systematic-debugging`

**Documentation:**
- Writing docs, changelogs, READMEs, ADRs, release notes, or documenting changes → `docs`

**Finishing work:**
- About to claim work is done/fixed/passing → `superpowers:verification-before-completion`
- Want code reviewed before merging → `superpowers:requesting-code-review`
- Reviewing a PR → `pr-review-toolkit:review-pr` or `code-review:code-review`
- Received code review feedback → `superpowers:receiving-code-review`
- Ready to commit → `pro-workflow:commit`
- Quick commit, skip quality checks → `commit-commands:commit`
- Ready to commit + push + open PR → `commit-commands:commit-push-pr`
- Implementation complete, deciding how to integrate → `superpowers:finishing-a-development-branch`
- Clean up local branches deleted on remote → `commit-commands:clean_gone`

**Framework & stack detection (auto-invoke when working in matching project):**
- SilverStripe project detected → `ss-dev`
- WordPress project detected → `wp-dev`
- Nuxt project detected → `nuxt-dev`
- Next.js / React project detected → `next-best-practices` + `vercel-react-best-practices`
- Supabase / Postgres work → `supabase-postgres-best-practices`
- UI review, accessibility audit, design check → `web-design-guidelines`
- Web quality audit, Lighthouse audit → `web-quality-audit`
- Web performance optimization, page speed → `performance`
- Core Web Vitals (LCP, INP, CLS) → `core-web-vitals`
- Accessibility audit, WCAG, a11y → `accessibility`
- SEO audit, search optimization → `seo`
- Security headers, modern APIs, best practices → `best-practices`
- REST API design, endpoints, versioning, pagination, error responses → `api-design`
- Database migrations, schema changes, zero-downtime deploys → `database-migrations`
- Dependency vulnerability scanning, npm audit, supply chain security → `dependency-vulnerability-scanner`
- Docker, CI/CD, Terraform, K8s, infrastructure as code → `devops-infra`
- SOLID principles, design patterns, clean architecture, refactoring → `clean-code-architecture`

**Research:**
- User says "research", "investigate", "deep dive", or asks to thoroughly explore a topic, codebase question, architecture decision, or implementation approach → `research`

**Hookify (hook management):**
- Create hooks from conversation analysis or explicit instructions → `hookify:hookify`
- Write or edit hookify rule files → `hookify:writing-rules`
- List configured hookify rules → `hookify:list`
- Enable/disable hookify rules interactively → `hookify:configure`
- Get help with hookify → `hookify:help`

**Specialist agents (spawned as subagents via Task tool into ~/.claude/agents/):**
- Architecture review, DDD, CQRS, tech debt assessment → `architect-reviewer` (opus)
- Building/debugging MCP servers and clients → `mcp-developer` (sonnet)
- Prompt design, optimization, A/B testing for LLMs → `prompt-engineer` (sonnet)
- Developer experience optimization (build times, HMR, test speed) → `dx-optimizer` (sonnet)
- Extracting patterns and learnings from completed workflows → `knowledge-synthesizer` (sonnet)
- Browse/install agents from VoltAgent catalog → `/subagent-catalog:search`, `/subagent-catalog:fetch`

**Document manipulation:**
- PDF operations (merge, split, OCR, watermark, form fill) → `pdf`
- Word document creation/editing → `docx`
- Excel spreadsheet creation/editing → `xlsx`
- PowerPoint creation/editing → `pptx`

**Utilities:**
- Generate visual architecture plan → `interactive-plan`
- Creating or editing skills → `superpowers:writing-skills`
- Audit/improve CLAUDE.md files → `claude-md-management:claude-md-improver`
- Update CLAUDE.md with session learnings → `claude-md-management:revise-claude-md`
- Customize keyboard shortcuts → `keybindings-help`
- Recommend Claude Code automations → `claude-code-setup:claude-automation-recommender`
- Session wrap-up → `pro-workflow:wrap-up`
- Battle-tested Claude Code workflows → `pro-workflow:pro-workflow`
- Save a learning → `pro-workflow:learn`
- Search past learnings → `pro-workflow:search`
- List all learnings → `pro-workflow:list`
- Surface past learnings for current task → `pro-workflow:replay`
- Session & learning analytics → `pro-workflow:insights`
- Extract correction to memory → `pro-workflow:learn-rule`
- Worktree setup guide → `pro-workflow:parallel`
- Session handoff document → `pro-workflow:handoff`

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
