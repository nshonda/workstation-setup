# My Claude Code Setup

## Overview

A walkthrough of how I've configured Claude Code as my primary personal development assistant across multiple projects and languages.

---

## The Architecture

```
~/.claude/
├── CLAUDE.md              ← Global instructions (the "brain")
├── RTK.md                 ← Token optimization reference
├── settings.json          ← Permissions, hooks, plugins
├── settings.local.json    ← Per-machine overrides
├── hooks/
│   └── rtk-rewrite.sh    ← Transparent command rewriting
├── skills/                ← 9 custom skills
└── plugins/               ← 17 plugins from 2 marketplaces (includes slash commands)
```

---

## Layer 1: Global Instructions (CLAUDE.md)

The foundation. Loaded into every Claude Code session, in every project.

**What's in it:**
- Workspace structure and project conventions
- Tool priority hierarchy — MCP servers > plugins > CLI
- Git commit rules — no co-author lines, no self-attribution
- Research folder pattern (`_research/`)

**Key insight:** Project-level CLAUDE.md files *inherit* from global, so I never duplicate rules. The global file handles universal conventions; project files handle project-specific context.

---

## Layer 2: Credential Management

Secrets never live in config files.

**How it works:**
- **direnv** sets per-directory environment variables (GitHub tokens, Redmine credentials)
- **System credential store** holds all secrets — macOS Keychain, `secret-tool`/`pass` on Linux — nothing hardcoded
- Claude Code sees the right credentials automatically in each directory

---

## Layer 3: Token Optimization with RTK

**RTK (Rust Token Killer)** is a CLI proxy that reduces Claude Code token usage by 60-90% on common dev commands.

**How it works:**
- A PreToolUse hook (`rtk-rewrite.sh`) intercepts every Bash command
- Commands are transparently rewritten: `git status` becomes `rtk git status`
- RTK strips verbose output, keeping only what Claude needs
- Zero manual intervention — the hook handles everything

**Commands covered:**
- Git (status, diff, log, add, commit, push, pull, branch, fetch, stash, show)
- GitHub CLI (pr, issue, run)
- Cargo (test, build, clippy)
- File ops (cat, grep, ls)
- JS/TS (vitest, tsc, eslint, prettier, playwright, prisma)
- Python (pytest, ruff, pip)
- Go (test, build, vet, golangci-lint)
- Docker, kubectl, curl

**Result:** `rtk gain` shows cumulative token savings across sessions.

---

## Layer 4: MCP Servers

MCP (Model Context Protocol) servers give Claude direct access to external services without shell commands.

| MCP Server | Purpose |
|------------|---------|
| **context7** | Library docs & code examples (replaces web searches) |
| **chrome-devtools** | Browser automation, screenshots, performance profiling |
| **redmine-personal** | Redmine project tracking |
| **github** | GitHub API (PRs, issues, repos) |
| **playwright** | Browser testing automation |
| **supabase** | Database management |

**Key insight:** MCP servers are preferred over CLI tools in my tool priority hierarchy. Claude uses the GitHub MCP instead of `gh` CLI commands.

---

## Layer 5: Plugins (17 Enabled)

From two marketplaces:
- **claude-plugins-official** (Anthropic's marketplace) — 16 plugins
- **pro-workflow** (community) — 1 plugin

### Development Workflow
| Plugin | What it does |
|--------|-------------|
| **superpowers** | Brainstorming, TDD, systematic debugging, parallel agents |
| **feature-dev** | Guided feature development with architecture focus |
| **commit-commands** | Smart commits, branch cleanup, push + PR |
| **pr-review-toolkit** | Multi-agent PR review (code, types, tests, security) |
| **code-review** | Single-PR code review |
| **code-simplifier** | Post-implementation cleanup |

### Language Support
| Plugin | What it does |
|--------|-------------|
| **typescript-lsp** | TypeScript/JS language server integration |
| **php-lsp** | PHP/Intelephense language server integration |

### Infrastructure
| Plugin | What it does |
|--------|-------------|
| **github** | GitHub MCP server (HTTP transport) |
| **playwright** | Playwright MCP server (browser automation) |
| **supabase** | Supabase MCP server |

### Quality & Safety
| Plugin | What it does |
|--------|-------------|
| **security-guidance** | Security-focused hooks |
| **hookify** | Create custom hooks from conversation analysis |
| **claude-md-management** | Audit and improve CLAUDE.md files |
| **claude-code-setup** | Analyze codebases and recommend automations |

### Design
| Plugin | What it does |
|--------|-------------|
| **frontend-design** | Production-grade UI generation |

### Meta
| Plugin | What it does |
|--------|-------------|
| **pro-workflow** | Session lifecycle hooks, learning capture, quality gates |

---

## Layer 6: Custom Skills

Skills are reusable behavior definitions that Claude activates by context — no slash command required. A routing table in CLAUDE.md maps contexts to skills explicitly.

### Framework Skills (auto-detected by project type)

| Skill | Triggers On | What It Does |
|-------|------------|--------------|
| `ss-dev` | SilverStripe project | Version detection (SS3/4/5), page types, extensions, dev/build reminders |
| `wp-dev` | WordPress project | Plugin/theme detection, WP coding standards, CPT/shortcode patterns |
| `nuxt-dev` | Nuxt project | Nuxt 3/4 detection, auto-imports, SSR data fetching, Nitro/H3 |
| `next-best-practices` | Next.js project | File conventions, RSC boundaries, async APIs, data patterns, metadata |
| `vercel-react-best-practices` | React/Next.js project | 57 performance rules across 8 priority categories |
| `supabase-postgres-best-practices` | Supabase/Postgres work | Query optimization, connection management, RLS, schema design |

### Utility Skills (contextually invoked)

| Skill | Triggers On | What It Does |
|-------|------------|--------------|
| `web-design-guidelines` | UI review, accessibility audit | Web Interface Guidelines compliance check |
| `research` | Deep investigation needed | 6-agent parallel research with consensus analysis |
| `interactive-plan` | Architecture planning | Self-contained HTML doc with Mermaid diagrams, phase tracking, feedback |

### Contextual Skill Routing

CLAUDE.md contains an explicit routing table that maps user intent to skills:
- "Build something new" → `brainstorming` → implementation skill
- "Plan a multi-step task" → `writing-plans`
- "Fix this bug" → `systematic-debugging`
- "Investigate this" → `research`
- Working in a Next.js project → `next-best-practices` + `vercel-react-best-practices` auto-activate
- Working with Supabase/Postgres → `supabase-postgres-best-practices`
- "Review my UI" → `web-design-guidelines`
- "Ready to commit" → `commit-commands:commit`
- "Verify before claiming done" → `verification-before-completion`

This eliminates the need for slash commands — Claude reads the routing table and invokes the right skill by context.

---

## Layer 7: Slash Commands (Plugin-Provided)

All slash commands come from plugins — no custom command files needed.

### From pro-workflow
| Command | Purpose |
|---------|---------|
| `/learn` | Best practices guide + capture lessons to SQLite |
| `/learn-rule` | Extract a correction to permanent memory |
| `/search` | Full-text search learnings (BM25 ranking) |
| `/list` | Browse all captured learnings |
| `/replay` | Surface relevant past learnings before starting a task |
| `/insights` | Session analytics, correction heatmaps, productivity metrics |
| `/commit` | Quality-gated commits (lint, typecheck, test, audit, then commit) |
| `/wrap-up` | End-of-session checklist (changes audit, quality check, learning capture) |
| `/handoff` | Generate a handoff document for the next session |
| `/parallel` | Git worktree setup for parallel Claude sessions |

### From commit-commands
| Command | Purpose |
|---------|---------|
| `/commit` | Smart commit with quality gates |
| `/commit-push-pr` | Commit, push, and open a PR |
| `/clean_gone` | Clean up stale local branches |

---

## Layer 8: Hooks

Hooks run scripts automatically at lifecycle events.

### RTK Auto-Rewrite (PreToolUse)
- Every Bash command is intercepted
- Matching commands get rewritten through RTK
- Transparent to Claude — it doesn't know the rewrite happened

### Pro-Workflow Hooks (auto-generated)
- **PreToolUse**: Quality gate on edits; lint/typecheck reminder before commits
- **PostToolUse**: Post-edit checks on source files; suggest learnings from test failures
- **SessionStart**: Load learned patterns and previous session context
- **SessionEnd**: Prompt for learnings, update LEARNED.md
- **UserPromptSubmit**: Track prompts, detect task drift and correction patterns
- **Stop**: Periodic wrap-up reminder; auto-capture `[LEARN]` blocks

---

## Layer 9: Persistent Memory

### Auto Memory (`~/.claude/projects/.../memory/MEMORY.md`)
- Loaded into every session's system prompt
- Records stable patterns confirmed across interactions
- Workspace structure, plugin management notes, key file paths

### Pro-Workflow Learning Database (`~/.pro-workflow/data.db`)
- SQLite with FTS5 full-text search
- Every lesson captured via `/learn save` or `[LEARN]` tags
- Searchable by keyword, category, project
- Tracks `times_applied` for each learning
- Powers `/replay`, `/search`, `/insights`

---

## The Workflow in Practice

### Starting a session
1. Claude loads global CLAUDE.md + project CLAUDE.md + auto memory
2. Pro-workflow loads session context and past learnings
3. I run `/replay <task>` to surface relevant past lessons

### During development
1. Skills activate based on project type (SS, WP, Nuxt)
2. RTK silently optimizes every command
3. MCP servers handle external service interactions
4. Superpowers plugin guides brainstorming/TDD/debugging workflows

### Ending a session
1. `/wrap-up` — changes audit, quality check, learning capture
2. `/handoff` — structured document for next session

---

## Key Takeaways

1. **Layer your configuration** — global rules, project specifics, framework skills
2. **Automate the repetitive** — hooks handle quality gates so you don't forget
3. **Build knowledge over time** — persistent learnings get smarter every session
4. **Optimize tokens** — RTK pays for itself in reduced API costs
5. **Use MCP servers** — direct service access beats shell commands
6. **Keep secrets out of config** — direnv + system credential store = secure credential management
7. **Skills fire by context, not slash commands** — a routing table in CLAUDE.md maps user intent to skills, eliminating the need for explicit `/skill` invocations
8. **Parallel everything** — 6-agent research, git worktrees, background tasks
