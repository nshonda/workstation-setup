---
name: init-project
description: Use when bootstrapping Claude Code for a project after running /init, or when auditing Claude Code readiness across all repos. Detects frameworks, injects skill references, scaffolds _research/, and creates .claude/rules/.
---

# Init Project Claude

Post-`/init` setup that layers framework-aware skill references and project scaffolding on top of Claude's built-in initialization.

## Usage

Run from any project root after `/init`:

```bash
init-project-claude              # Current directory
init-project-claude /path/to/project
init-project-claude --audit      # Scan all repos under ~/workstation/
init-project-claude --audit --fix # Scan and auto-repair
```

## What It Does

1. **Detects frameworks** from `package.json`, `composer.json`, directory structure
2. **Injects `<!-- BEGIN auto-skills -->` block** into CLAUDE.md with matching skills
3. **Creates `.claude/rules/framework.md`** with contextual skill triggers
4. **Scaffolds `_research/`** and ensures it's gitignored
5. **Creates stub CLAUDE.md** if missing (every repo needs one)

Idempotent -- safe to run multiple times. Updates existing auto-skills blocks in place.

## Detected Frameworks

| Signal | Skill(s) |
|--------|----------|
| `next` in deps | `next-best-practices`, `vercel-react-best-practices` |
| `nuxt` in deps or `nuxt.config.*` | `nuxt-dev` |
| `react` (without Next) | `vercel-react-best-practices` |
| `@supabase/supabase-js` | `supabase-postgres-best-practices` |
| `silverstripe/*` in composer | `ss-dev` |
| `roots/sage`, `wpackagist-*`, `wp-content/` | `wp-dev` |
| `laravel/framework` | `laravel-dev` |
| Ansible structure (`playbook.yml`, `roles/`) | `devops-infra` |

## Audit Mode

`--audit` scans all repos under `~/workstation/{personal,work}/` and reports:

- CLAUDE.md presence
- `.claude/` directory
- `_research/` (exists + gitignored)
- Auto-skills match detected framework
- `.claude/rules/` with framework rules
- Stale skills (listed but no longer detected)

Add `--fix` to auto-repair all issues.
