# workstation-setup

Script-driven setup for multi-GitHub account development workstations. One config file, one command — consistent SSH, git, GitHub CLI, and Claude Code across macOS and WSL/Linux. Fork it, fill in `config.env`, run `./setup.sh` on any new machine.

## Quick Start

```bash
git clone git@github.com:<YOUR_USERNAME>/workstation-setup.git ~/workstation/personal/workstation-setup
cd ~/workstation/personal/workstation-setup
cp config.env.example config.env
# Edit config.env with your values
./setup.sh
```

## Configuration

All configuration lives in `config.env` (gitignored). Copy the example and fill in your values:

| Variable | Required | Where to get it |
|----------|----------|-----------------|
| `WS_FULL_NAME` | Yes | Your name for git commits |
| `WS_PERSONAL_EMAIL` | Yes | Email for personal repos |
| `WS_WORK_EMAIL` | Yes | Email for work repos |
| `WS_PERSONAL_GH_USER` | Yes | Your personal GitHub username |
| `WS_WORK_GH_USER` | Yes | Your work GitHub username |
| `GH_PERSONAL_TOKEN` | Yes | [github.com/settings/tokens](https://github.com/settings/tokens) (personal account) |
| `GH_WORK_TOKEN` | Yes | [github.com/settings/tokens](https://github.com/settings/tokens) (work account) |
| `JIRA_URL` | No | e.g. `company.atlassian.net` — leave blank to skip |
| `JIRA_EMAIL` | No | Your Atlassian account email |
| `JIRA_TOKEN` | No | [Atlassian API tokens](https://id.atlassian.com/manage-profile/security/api-tokens) |
| `REDMINE_URL` | No | e.g. `redmine.example.com` — leave blank to skip |
| `REDMINE_KEY` | No | Redmine > My Account > API access key |
| `CONTEXT7_KEY` | No | [context7.com/dashboard](https://context7.com) > API Keys |
| `GCS_BUCKET` | No | See [GCS setup](docs/gcs-setup.md) |

Credentials are stored in the system keychain (macOS Keychain / gnome-keyring) on first run. The `config.env` file is only read at setup time.

## What It Does

1. **Dependencies** — installs gh, jq, direnv, gcloud, RTK via brew (macOS) or apt (Linux); cloudflared on macOS only
2. **SSH** — generates keys for personal + work GitHub accounts with host aliases
3. **Git** — configures identity with conditional includes (work email for `~/workstation/work/`)
4. **GitHub CLI** — authenticates both accounts, installs auto-switch wrapper
5. **Claude Code** — deploys config, skills, hooks, MCP servers, plugins; global config includes subagent rules that propagate tool priority (context7, MCP servers) and conventions to all spawned subagents

## Repo Structure

- `config.env.example` — configuration template (copy to `config.env`)
- `scripts/` — setup scripts (all idempotent, safe to re-run)
- `claude/` — Claude Code configuration (deployed to `~/.claude/` by setup-claude.sh)
- `docs/` — reference documentation

## Re-running

All scripts are idempotent. Re-run `./setup.sh` or any individual script to update.

## References

### System Dependencies

| Tool | Purpose |
|------|---------|
| [GitHub CLI (`gh`)](https://cli.github.com/) | Multi-account GitHub auth + auto-switch wrapper |
| [direnv](https://direnv.net/) | Per-directory environment variables (tokens, credentials) |
| [jq](https://jqlang.github.io/jq/) | JSON processing for config merging |
| [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) | Cloudflare Tunnel client |
| [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) | GCS access for interactive plan uploads |
| [RTK](https://github.com/rtk-ai/rtk) | Token-optimized CLI proxy for Claude Code |
| [uv](https://docs.astral.sh/uv/) | Python package manager (used by MCP server wrappers) |

### MCP Servers

| Server | Purpose |
|--------|---------|
| [mcp-atlassian](https://github.com/sooperset/mcp-atlassian) | Jira + Confluence integration |
| [mcp-redmine](https://github.com/runekaagaard/mcp-redmine) | Redmine issue tracking |
| [Slack MCP](https://mcp.slack.com/) | Slack (two workspaces: `slack-onerhino` personal, `slack-basis` work, OAuth) |
| [Context7](https://context7.com/) | Library/framework documentation lookup |

### Claude Code Plugins

From [claude-plugins-official](https://github.com/anthropics/claude-plugins-official):

| Plugin | Purpose |
|--------|---------|
| [superpowers](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/superpowers) | Brainstorming, TDD, debugging, verification, git worktrees |
| [feature-dev](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/feature-dev) | Guided feature development with architecture focus |
| [commit-commands](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/commit-commands) | Git commit, push, and PR workflows |
| [code-review](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-review) | GitHub pull request code review |
| [pr-review-toolkit](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit) | Multi-agent PR review (code, tests, types, comments) |
| [code-simplifier](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-simplifier) | Post-implementation code simplification |
| [frontend-design](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/frontend-design) | Production-grade frontend/UI development |
| [hookify](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/hookify) | Create and manage Claude Code hooks |
| [security-guidance](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/security-guidance) | Security best practices |
| [claude-md-management](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-md-management) | Audit and improve CLAUDE.md files |
| [claude-code-setup](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-code-setup) | Recommend Claude Code automations for a project |
| [github](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/github) | GitHub MCP server (issues, PRs, repos) |

Third-party:

| Plugin | Purpose |
|--------|---------|
| [openbrowser](https://github.com/billy-enrizky/openbrowser-ai) | Browser automation, testing, screenshots, web scraping |

### Claude Code Skills (bundled)

Skills are deployed to `~/.claude/skills/` — see [`claude/skills/`](claude/skills/) for source.

| Skill | Purpose | Based on |
|-------|---------|----------|
| research | 6-agent parallel deep research | Custom |
| interactive-plan | HTML architecture plans with Mermaid diagrams ([GCS setup](docs/gcs-setup.md)) | Custom |
| [web-quality-audit](https://github.com/nicholasgriffintn/web-quality-skills) | Lighthouse-based web quality audit (150+ checks) | [addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills) |
| [web-design-guidelines](https://github.com/vercel-labs/web-interface-guidelines) | UI review for Web Interface Guidelines | [vercel-labs/web-interface-guidelines](https://github.com/vercel-labs/web-interface-guidelines) |
| [next-best-practices](https://nextjs.org/docs) | Next.js file conventions, RSC, data patterns | [Next.js docs](https://nextjs.org/docs) |
| [vercel-react-best-practices](https://vercel.com/blog) | React + Next.js performance (57 rules) | [Vercel Engineering blog](https://vercel.com/blog) |
| [supabase-postgres-best-practices](https://supabase.com/docs/guides/database) | Postgres schema and query optimization (70+ rules) | [Supabase docs](https://supabase.com/docs/guides/database) |
| ss-dev | SilverStripe CMS development (SS3/4/5) | [SilverStripe docs](https://docs.silverstripe.org/) |
| nuxt-dev | Nuxt 3/4 framework conventions | [Nuxt docs](https://nuxt.com/docs) |
| wp-dev | WordPress plugin/theme development | [WordPress Developer Resources](https://developer.wordpress.org/) |
| performance | Web performance optimization | [web.dev](https://web.dev/performance/) |
| accessibility | WCAG 2.1 compliance audit | [WCAG 2.1](https://www.w3.org/TR/WCAG21/) |
| seo | Search engine optimization | [web.dev SEO](https://web.dev/learn/seo/) |
| best-practices | Security headers, modern APIs | [web.dev](https://web.dev/) |
| docs | Documentation generation (changelogs, READMEs, ADRs, release notes) | Custom |
| api-design | REST API design patterns (resources, status codes, pagination, errors) | Custom |
| database-migrations | Schema changes, data migrations, rollbacks, zero-downtime deploys | Custom |
| devops-infra | Docker, CI/CD, Terraform, K8s, monitoring, deployment strategies | Custom |
| subagent-catalog | Browse and install agents from the VoltAgent catalog | Custom |
| clipboard | Copy commands to system clipboard for pasting into SSH sessions | Custom |
| wrap-up | End-of-session context saving and handoff prep | Custom |
| handoff | Create handoff documents for session/colleague transfer | Custom |

### Specialist Agents

Subagent definitions in `claude/agents/`, spawned via the Task tool for targeted work:

| Agent | Model | Purpose |
|-------|-------|---------|
| architect-reviewer | opus | Architecture review, DDD, CQRS, tech debt assessment |
| mcp-developer | sonnet | Build and debug MCP servers and clients |

### Hooks

Hook scripts in `claude/hooks/`, wired via `settings.json`:

| Hook | Event | Purpose |
|------|-------|---------|
| `strip-co-authored-by.sh` | PreToolUse:Bash | Strip `Co-Authored-By: Claude` and self-attribution from git/gh commands |
| `strip-attribution-mcp.sh` | PreToolUse:mcp | Strip self-attribution from MCP tool calls (PR descriptions, comments) |
| `slack-schedule-rewrite.sh` | PreToolUse:mcp | Rewrite `send_message` → `schedule_message` to avoid Slack attribution |
| `validate-mcp-inputs.sh` | PreToolUse:mcp | Validate MCP tool inputs before execution |
| `rtk-rewrite.sh` | PreToolUse:Bash | Rewrite CLI commands through RTK proxy for token savings |
| `cross-project-memory.js` | SessionStart | Surface relevant past learnings at conversation start |

### Hookify Rules

Hookify rule files in `claude/config/`, deployed to `~/.claude/`:

| Rule | Purpose |
|------|---------|
| `hookify.block-co-authored-by.local.md` | Block Co-Authored-By lines in commits |
| `hookify.block-self-promotion.local.md` | Block promotional self-attribution text |
| `hookify.block-self-attribution-files.local.md` | Block self-attribution in file writes |
| `hookify.block-docs-plans.local.md` | Block creation of `docs/plans/` (use `_research/` instead) |
| `hookify.block-hardcoded-credentials.local.md` | Block hardcoded credentials in code |
| `hookify.warn-research-gitignore.local.md` | Warn if `_research/` is not gitignored |

### Additional Docs

- [SSH multi-account setup](docs/ssh-github-multi-account.md)
- [WSL setup](docs/wsl-setup.md)
- [GCS setup for interactive plans](docs/gcs-setup.md)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
