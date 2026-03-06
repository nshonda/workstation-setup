# workstation-setup

Script-driven setup for multi-GitHub account development workstations. One command sets up SSH, git, GitHub CLI, and Claude Code across macOS and WSL/Linux.

## Quick Start

```bash
git clone git@github.com:<YOUR_USERNAME>/workstation-setup.git ~/workstation/personal/workstation-setup
cd ~/workstation/personal/workstation-setup
./setup.sh
```

## What It Does

1. **Dependencies** — installs gh, jq, direnv, gcloud, RTK via brew (macOS) or apt (Linux); cloudflared on macOS only
2. **SSH** — generates keys for personal + work GitHub accounts with host aliases
3. **Git** — configures identity with conditional includes (work email for `~/workstation/work/`)
4. **GitHub CLI** — authenticates both accounts, installs auto-switch wrapper
5. **Claude Code** (optional) — deploys config, skills, hooks, MCP servers, plugins; global config includes subagent rules that propagate tool priority (context7, MCP servers) and conventions to all spawned subagents

## Repo Structure

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
| [supabase](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/supabase) | Supabase integration |
| [typescript-lsp](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/typescript-lsp) | TypeScript language server |
| [php-lsp](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/php-lsp) | PHP language server |

Third-party:

| Plugin | Purpose |
|--------|---------|
| [openbrowser](https://github.com/billy-enrizky/openbrowser-ai) | Browser automation, testing, screenshots, web scraping |
| [pro-workflow](https://github.com/rohitg00/pro-workflow) | Session management, learning capture, smart commits |

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
| core-web-vitals | LCP, INP, CLS optimization | [web.dev Core Web Vitals](https://web.dev/vitals/) |
| accessibility | WCAG 2.1 compliance audit | [WCAG 2.1](https://www.w3.org/TR/WCAG21/) |
| seo | Search engine optimization | [web.dev SEO](https://web.dev/learn/seo/) |
| best-practices | Security headers, modern APIs | [web.dev](https://web.dev/) |
| docs | Documentation generation (changelogs, READMEs, ADRs, release notes) | Custom |
| api-design | REST API design patterns (resources, status codes, pagination, errors) | Custom |
| clean-code-architecture | SOLID, design patterns, clean architecture, refactoring | Custom |
| database-migrations | Schema changes, data migrations, rollbacks, zero-downtime deploys | Custom |
| dependency-vulnerability-scanner | Dependency scanning for known vulnerabilities | Custom |
| devops-infra | Docker, CI/CD, Terraform, K8s, monitoring, deployment strategies | Custom |
| subagent-catalog | Browse and install agents from the VoltAgent catalog | Custom |

### Specialist Agents

Subagent definitions in `claude/agents/`, spawned via the Task tool for targeted work:

| Agent | Model | Purpose |
|-------|-------|---------|
| architect-reviewer | opus | Architecture review, DDD, CQRS, tech debt assessment |
| mcp-developer | sonnet | Build and debug MCP servers and clients |
| prompt-engineer | sonnet | Prompt design, optimization, A/B testing for LLMs |
| dx-optimizer | sonnet | Developer experience (build times, HMR, test speed) |
| knowledge-synthesizer | sonnet | Extract patterns and learnings from completed workflows |

### Hooks

Hook scripts in `claude/hooks/`, wired via `settings.json`:

| Hook | Event | Purpose |
|------|-------|---------|
| `strip-co-authored-by.sh` | PreToolUse:Bash | Strip `Co-Authored-By: Claude` and self-attribution from git/gh commands |
| `strip-attribution-mcp.sh` | PreToolUse:mcp | Strip self-attribution from MCP tool calls (PR descriptions, comments) |
| `rtk-rewrite.sh` | PreToolUse:Bash | Rewrite CLI commands through RTK proxy for token savings |
| `replay-learnings.js` | SessionStart | Surface relevant past learnings at conversation start |

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
