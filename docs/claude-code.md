# Claude Code Setup

The Claude Code setup (`scripts/setup-claude.sh`) is the most substantial part of this repo. It turns a fresh Claude Code install into a fully configured development environment with project memory, tool integrations, automated workflows, and safety guardrails.

## How It Works

```
config.env                          direnv .envrc files
    │                                   │
    ▼                                   ▼
setup-claude.sh ──────┐         ~/workstation/work/.envrc
                      │         ~/workstation/personal/.envrc
                      │              (credentials auto-switch)
                      ▼
               ~/.claude/
               ├── CLAUDE.md          ← global instructions
               ├── RTK.md            ← token optimizer reference
               ├── includes/         ← @include files for CLAUDE.md
               ├── settings.json     ← permissions, hooks, plugins
               ├── skills/           ← slash commands
               ├── agents/           ← specialist subagents
               ├── hooks/            ← PreToolUse/SessionStart scripts
               └── hookify.*.md      ← behavioral guardrails
               ~/.claude.json        ← MCP server registrations
```

Setup reads `config.env` once and:
1. Stores credentials in the system keychain (never on disk)
2. Creates MCP wrapper scripts that fetch credentials from keychain at runtime
3. Deploys all Claude Code config from `claude/` to `~/.claude/`
4. Registers MCP servers in `~/.claude.json`
5. Installs plugins from the official and third-party marketplaces
6. Generates direnv `.envrc` files so credentials auto-switch by directory

## Design Principles

**Single source of truth.** All Claude Code config lives in this repo under `claude/`. Running `setup-claude.sh` deploys it. No manual `~/.claude/` editing — if you want to change something, change the source and re-run.

**Credentials never touch disk.** GitHub tokens, Jira/Redmine API keys are stored in the OS keychain on first run. MCP wrapper scripts and direnv `.envrc` files fetch them at runtime via `security` (macOS) or `secret-tool` (Linux).

**Directory-aware context switching.** Working in `~/workstation/work/` automatically loads work GitHub token, Jira credentials, and work git identity. Working in `~/workstation/personal/` loads personal GitHub token, Redmine credentials, and personal git identity. Claude Code inherits the right context without any manual switching.

**Subagent rule propagation.** Claude Code spawns subagents (via the Task tool) that don't inherit the parent's CLAUDE.md. The global `CLAUDE.md` includes a "Subagent Rules" section that instructs the main agent to tell every subagent to read `~/.claude/CLAUDE.md` as its first action — so tool priority, conventions, and safety rules propagate automatically.

## The Config Stack

| Layer | File | What it controls |
|-------|------|-----------------|
| **Global instructions** | `CLAUDE.md` | Tool priority (MCP > CLI > web), git conventions, anti-hallucination guards, research folder policy, worktree policy |
| **Includes** | `includes/skill-routing.md` | Which skill/plugin to invoke for ambiguous requests (e.g. "review this PR" → quick vs thorough) |
| **Includes** | `includes/subagent-rules.md` | Model routing (haiku/sonnet/opus by task complexity), rule propagation to subagents |
| **Token optimizer** | `RTK.md` | Reference doc for RTK usage — loaded by `@RTK.md` in CLAUDE.md |
| **Permissions & hooks** | `settings.json` | Auto-allowed tools, PreToolUse hook wiring, enabled plugins |
| **MCP servers** | `~/.claude.json` | Server registrations (Jira, Redmine, Slack, Context7) with connection details |

## MCP Servers

MCP (Model Context Protocol) servers give Claude Code direct access to external services — no shell commands or API calls needed. The agent calls structured tools instead of running `curl` or `gh`.

| Server | Transport | What it enables |
|--------|-----------|-----------------|
| [mcp-atlassian](https://github.com/sooperset/mcp-atlassian) | stdio | Jira issues, sprints, boards + Confluence pages, search |
| [mcp-redmine](https://github.com/runekaagaard/mcp-redmine) | stdio | Redmine issues, time entries, file uploads |
| [Slack MCP](https://mcp.slack.com/) | HTTP/OAuth | Two workspaces: `slack-onerhino` (personal) and `slack-basis` (work) — read channels, search, send messages |
| [Context7](https://context7.com/) | HTTP | Library/framework docs lookup — replaces web searches for API references |

Jira and Redmine servers use wrapper scripts (`~/.local/bin/mcp-*-wrapper`) that fetch credentials from the keychain before launching the actual MCP server process. This keeps credentials out of `~/.claude.json`.

**Why two Slack workspaces?** Slack's MCP server uses OAuth per-workspace. Each workspace gets its own server entry with a separate OAuth flow. First use triggers a browser-based login for each.

## Hooks

Hooks are shell scripts that run before or after Claude Code tool calls. They intercept and modify tool inputs/outputs at the system level — the agent doesn't know they exist.

| Hook | Trigger | Problem it solves |
|------|---------|-------------------|
| `strip-co-authored-by.sh` | PreToolUse:Bash | Claude's system prompt hardcodes `Co-Authored-By: Claude` in commit instructions. This hook strips it from git/gh commands before execution. |
| `strip-attribution-mcp.sh` | PreToolUse:GitHub MCP | Strips "Generated with Claude Code" from PR descriptions and issue comments sent through the GitHub MCP plugin. |
| `slack-schedule-rewrite.sh` | PreToolUse:Slack MCP | `slack_send_message` adds "Sent using Claude" server-side (can't be stripped). This rewrites it to `slack_schedule_message` (+120s) which doesn't add attribution. |
| `validate-mcp-inputs.sh` | PreToolUse:Jira/Redmine MCP | Validates inputs before mutating operations (update issue, transition, add comment, add worklog) to catch bad data before it hits the API. |
| `rtk-rewrite.sh` | PreToolUse:Bash | Transparently rewrites CLI commands through [RTK](https://github.com/rtk-ai/rtk) proxy for 60-90% token savings on command output. |
| `cross-project-memory.js` | UserPromptSubmit | Surfaces relevant past learnings from the memory system at conversation start, providing cross-project context. |

## Hookify Rules

Behavioral guardrails defined as markdown files, enforced through the [hookify plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/hookify).

| Rule | Type | What it prevents |
|------|------|-----------------|
| `block-co-authored-by` | Block | `Co-Authored-By: Claude` lines in commits (backup for the hook) |
| `block-self-promotion` | Block | Promotional text like "Generated with Claude Code" in any output |
| `block-self-attribution-files` | Block | Self-attribution in file writes (code comments, READMEs) |
| `block-docs-plans` | Block | Creation of `docs/plans/` directory (convention: use `_research/` instead) |
| `block-hardcoded-credentials` | Block | Hardcoded API keys, tokens, or passwords in code |
| `warn-research-gitignore` | Warn | Missing `_research/` entry in `.gitignore` |

## Plugins

Plugins add skills (slash commands), agents, and tool integrations. Installed from plugin marketplaces and enabled in `settings.json`.

From [claude-plugins-official](https://github.com/anthropics/claude-plugins-official):

| Plugin | What it adds |
|--------|-------------|
| [superpowers](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/superpowers) | Brainstorming, TDD, systematic debugging, verification, git worktrees, parallel agents |
| [feature-dev](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/feature-dev) | Guided feature development with codebase exploration and architecture focus |
| [commit-commands](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/commit-commands) | `/commit`, `/commit-push-pr`, `/clean_gone` — git workflow automation |
| [code-review](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-review) | Quick PR code review via `/code-review` |
| [pr-review-toolkit](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit) | Thorough multi-agent PR review (code quality, tests, types, comments, silent failures) |
| [code-simplifier](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-simplifier) | Post-implementation code simplification and cleanup |
| [frontend-design](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/frontend-design) | Production-grade frontend/UI with high design quality |
| [hookify](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/hookify) | Create and manage behavioral guardrail rules |
| [security-guidance](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/security-guidance) | Security best practices and vulnerability guidance |
| [claude-md-management](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-md-management) | Audit and improve CLAUDE.md files across repos |
| [claude-code-setup](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-code-setup) | Recommend Claude Code automations for a project |
| [github](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/github) | GitHub MCP server for issues, PRs, repos, code search |

Third-party:

| Plugin | What it adds |
|--------|-------------|
| [openbrowser](https://github.com/billy-enrizky/openbrowser-ai) | Browser automation, e2e testing, screenshots, form filling, web scraping, accessibility audits |

## Skills (Bundled)

Skills are slash commands deployed to `~/.claude/skills/`. They provide domain-specific knowledge and workflows that Claude Code follows when invoked. Source is in [`claude/skills/`](../claude/skills/).

| Skill | What it does | Based on |
|-------|-------------|----------|
| research | Launches 6 parallel research agents for deep codebase investigation | Custom |
| interactive-plan | Generates HTML architecture plans with Mermaid diagrams, optional [GCS upload](gcs-setup.md) | Custom |
| [web-quality-audit](https://github.com/nicholasgriffintn/web-quality-skills) | Lighthouse-based audit: performance, accessibility, SEO, best practices (150+ checks) | [addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills) |
| [web-design-guidelines](https://github.com/vercel-labs/web-interface-guidelines) | UI review against Web Interface Guidelines | [vercel-labs/web-interface-guidelines](https://github.com/vercel-labs/web-interface-guidelines) |
| [next-best-practices](https://nextjs.org/docs) | Next.js file conventions, RSC, data patterns | [Next.js docs](https://nextjs.org/docs) |
| [vercel-react-best-practices](https://vercel.com/blog) | React + Next.js performance (57 rules) | [Vercel Engineering blog](https://vercel.com/blog) |
| [supabase-postgres-best-practices](https://supabase.com/docs/guides/database) | Postgres schema and query optimization (70+ rules) | [Supabase docs](https://supabase.com/docs/guides/database) |
| ss-dev | SilverStripe CMS development (SS3/4/5) | [SilverStripe docs](https://docs.silverstripe.org/) |
| nuxt-dev | Nuxt 3/4 framework conventions | [Nuxt docs](https://nuxt.com/docs) |
| wp-dev | WordPress plugin/theme development | [WordPress Developer Resources](https://developer.wordpress.org/) |
| performance | Core Web Vitals optimization (LCP, INP, CLS) | [web.dev](https://web.dev/performance/) |
| accessibility | WCAG 2.1 compliance audit | [WCAG 2.1](https://www.w3.org/TR/WCAG21/) |
| seo | Search engine optimization | [web.dev SEO](https://web.dev/learn/seo/) |
| best-practices | Security headers, modern APIs, code quality | [web.dev](https://web.dev/) |
| docs | Documentation generation (changelogs, READMEs, ADRs, release notes) | Custom |
| api-design | REST API design patterns (resources, status codes, pagination, errors) | Custom |
| database-migrations | Schema changes, data migrations, rollbacks, zero-downtime deploys | Custom |
| devops-infra | Docker, CI/CD, Terraform, K8s, monitoring, deployment strategies | Custom |
| subagent-catalog | Browse and install agents from the VoltAgent catalog | Custom |
| clipboard | Copy commands to system clipboard for pasting into SSH sessions | Custom |
| wrap-up | End-of-session context saving and handoff prep | Custom |
| handoff | Create handoff documents for session/colleague transfer | Custom |

## Specialist Agents

Agent definitions in `claude/agents/` are spawned via the Task tool for targeted, model-appropriate work.

| Agent | Model | What it does |
|-------|-------|-------------|
| architect-reviewer | opus | Architecture review, DDD, CQRS, tech debt assessment, system design evaluation |
| mcp-developer | sonnet | Build, debug, and optimize MCP servers and clients |

## Permissions Model

`settings.json` pre-approves safe, read-only operations so Claude Code doesn't prompt for every command:

- **All read tools** — Read, Glob, Grep, WebFetch, WebSearch, ToolSearch
- **All MCP read operations** — Jira, Redmine, GitHub, Slack (read/search), Context7, GDocs
- **Safe Bash commands** — `git status/log/diff/branch/show`, `ls`, `pwd`, `which`, `docker ps/images`, `direnv`, `rtk`
- **Slack writes** — only `schedule_message` and `send_message_draft` (not `send_message`, which adds attribution)

Destructive operations (file writes, git push, issue mutations) still require user approval.
