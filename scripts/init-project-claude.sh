#!/usr/bin/env bash
set -euo pipefail

# init-project-claude.sh
# Auto-detects project framework and generates/updates CLAUDE.md with skill references.
# Run from any project root. Idempotent — safe to run multiple times.
#
# Usage:
#   init-project-claude              # current directory
#   init-project-claude /path/to/project

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"

# ---------- Framework Detection ----------

SKILLS=()

scan_package_json() {
    local pkg="$1"

    local all_deps
    all_deps=$(jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys[]' "$pkg" 2>/dev/null) || return 0

    if echo "$all_deps" | grep -qx "next"; then
        SKILLS+=("next-best-practices" "vercel-react-best-practices")
    fi
    # Nuxt — exact match OR @*/nuxt-layer-* pattern
    if echo "$all_deps" | grep -qx "nuxt" || echo "$all_deps" | grep -q "^@.*nuxt-layer"; then
        SKILLS+=("nuxt-dev")
    fi
    if echo "$all_deps" | grep -qx "@supabase/supabase-js"; then
        SKILLS+=("supabase-postgres-best-practices")
    fi
    # React without Next.js
    if echo "$all_deps" | grep -qx "react" && ! echo "$all_deps" | grep -qx "next"; then
        SKILLS+=("vercel-react-best-practices")
    fi
}

detect_from_package_json() {
    if ! command -v jq &>/dev/null; then
        echo "WARNING: jq not found, skipping package.json detection" >&2
        return 0
    fi

    # Check root first
    if [[ -f "$PROJECT_DIR/package.json" ]]; then
        scan_package_json "$PROJECT_DIR/package.json"
        return 0
    fi

    # Check one level deep (monorepo/nested app patterns)
    local pkg
    for pkg in "$PROJECT_DIR"/*/package.json; do
        [[ -f "$pkg" ]] || continue
        scan_package_json "$pkg"
    done
}

scan_composer_json() {
    local comp="$1"

    local all_reqs
    all_reqs=$(jq -r '(.require // {}) + (."require-dev" // {}) | keys[]' "$comp" 2>/dev/null) || return 0

    if echo "$all_reqs" | grep -q "^silverstripe/"; then
        SKILLS+=("ss-dev")
    fi
    if echo "$all_reqs" | grep -q "^roots/sage\|^roots/bedrock"; then
        SKILLS+=("wp-dev")
    fi
    # WordPress via wpackagist packages
    if echo "$all_reqs" | grep -q "^wpackagist-"; then
        SKILLS+=("wp-dev")
    fi
    if echo "$all_reqs" | grep -q "^laravel/framework\|^laravel/laravel"; then
        SKILLS+=("laravel-dev")
    fi
}

detect_from_composer_json() {
    if ! command -v jq &>/dev/null; then
        echo "WARNING: jq not found, skipping composer.json detection" >&2
        return 0
    fi

    if [[ -f "$PROJECT_DIR/composer.json" ]]; then
        scan_composer_json "$PROJECT_DIR/composer.json"
        return 0
    fi

    local comp
    for comp in "$PROJECT_DIR"/*/composer.json; do
        [[ -f "$comp" ]] || continue
        scan_composer_json "$comp"
    done
}

detect_from_directory_structure() {
    # WordPress: wp-content/ directory, wp-config.php, or themes/ with WP theme style.css
    if [[ -d "$PROJECT_DIR/wp-content" ]] || [[ -f "$PROJECT_DIR/wp-config.php" ]] || \
       { [[ -d "$PROJECT_DIR/themes" ]] && ls "$PROJECT_DIR"/themes/*/style.css &>/dev/null; }; then
        if [[ ! " ${SKILLS[*]:-} " =~ " wp-dev " ]]; then
            SKILLS+=("wp-dev")
        fi
    fi

    # Nuxt: nuxt.config.ts or nuxt.config.js
    if [[ -f "$PROJECT_DIR/nuxt.config.ts" ]] || [[ -f "$PROJECT_DIR/nuxt.config.js" ]]; then
        if [[ ! " ${SKILLS[*]:-} " =~ " nuxt-dev " ]]; then
            SKILLS+=("nuxt-dev")
        fi
    fi

    # Vue (standalone, not Nuxt) — check nested package.json too
    for pkg in "$PROJECT_DIR"/package.json "$PROJECT_DIR"/*/package.json; do
        [[ -f "$pkg" ]] || continue
        local vue_deps
        vue_deps=$(jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys[]' "$pkg" 2>/dev/null) || continue
        if echo "$vue_deps" | grep -qx "vue" && ! echo "$vue_deps" | grep -qx "nuxt"; then
            if [[ ! " ${SKILLS[*]:-} " =~ " vercel-react-best-practices " ]]; then
                SKILLS+=("vercel-react-best-practices")
            fi
        fi
    done
}

detect_from_ansible() {
    if [[ -f "$PROJECT_DIR/playbook.yml" ]] || [[ -f "$PROJECT_DIR/site.yml" ]] || [[ -d "$PROJECT_DIR/roles" && -d "$PROJECT_DIR/inventory" ]]; then
        SKILLS+=("devops-infra")
    fi
}

# ---------- Scaffold Project Structure ----------

scaffold_research_dir() {
    if [[ ! -d "$PROJECT_DIR/_research" ]]; then
        mkdir -p "$PROJECT_DIR/_research"
        echo "  Created _research/"
    fi

    # Ensure _research/ is gitignored
    local gitignore="$PROJECT_DIR/.gitignore"
    if [[ -f "$gitignore" ]]; then
        if ! grep -qx "_research/" "$gitignore" && ! grep -qx "_research" "$gitignore"; then
            echo "" >> "$gitignore"
            echo "# Claude Code research notes (local only)" >> "$gitignore"
            echo "_research/" >> "$gitignore"
            echo "  Added _research/ to .gitignore"
        fi
    else
        cat > "$gitignore" << 'GITIGNORE'
# Claude Code research notes (local only)
_research/
GITIGNORE
        echo "  Created .gitignore with _research/"
    fi
}

scaffold_claude_rules() {
    local rules_dir="$PROJECT_DIR/.claude/rules"

    # Only create if we detected skills (framework-specific rules)
    [[ ${#SKILLS[@]} -eq 0 ]] && return 0

    mkdir -p "$rules_dir"

    # Generate a framework rules file that references skills
    local rules_file="$rules_dir/framework.md"
    if [[ ! -f "$rules_file" ]]; then
        {
            echo "# Framework Rules"
            echo ""
            echo "Auto-generated by \`init-project-claude\`. Invoke these skills when working on matching files:"
            echo ""
            for skill in "${SKILLS[@]}"; do
                case "$skill" in
                    ss-dev)
                        echo "For SilverStripe PHP files, invoke the \`ss-dev\` skill."
                        ;;
                    wp-dev)
                        echo "For WordPress PHP files, invoke the \`wp-dev\` skill."
                        ;;
                    nuxt-dev)
                        echo "For Nuxt/Vue files, invoke the \`nuxt-dev\` skill."
                        ;;
                    next-best-practices)
                        echo "For Next.js files, invoke the \`next-best-practices\` skill."
                        ;;
                    vercel-react-best-practices)
                        echo "For React components, invoke the \`vercel-react-best-practices\` skill."
                        ;;
                    supabase-postgres-best-practices)
                        echo "For database queries and Supabase usage, invoke the \`supabase-postgres-best-practices\` skill."
                        ;;
                    laravel-dev)
                        echo "For Laravel PHP files, invoke the \`laravel-dev\` skill."
                        ;;
                    devops-infra)
                        echo "For infrastructure and deployment files, invoke the \`devops-infra\` skill."
                        ;;
                esac
            done
        } > "$rules_file"
        echo "  Created .claude/rules/framework.md"
    fi
}

# ---------- Generate Skills Section ----------

BEGIN_MARKER="<!-- BEGIN auto-skills -->"
END_MARKER="<!-- END auto-skills -->"

generate_skills_section() {
    echo "$BEGIN_MARKER"
    echo ""
    echo "## Framework Skills"
    echo ""
    echo "Auto-detected by \`init-project-claude\`. When working in this project, auto-invoke these skills:"
    echo ""
    for skill in "${SKILLS[@]}"; do
        echo "- \`$skill\`"
    done
    echo ""
    echo "$END_MARKER"
}

# ---------- Apply to CLAUDE.md ----------

detect_from_package_json
detect_from_composer_json
detect_from_directory_structure
detect_from_ansible

# Deduplicate
if [[ ${#SKILLS[@]} -gt 0 ]]; then
    mapfile -t SKILLS < <(printf '%s\n' "${SKILLS[@]}" | sort -u)
fi

# Always scaffold _research/ regardless of framework detection
scaffold_research_dir

if [[ ${#SKILLS[@]} -eq 0 ]]; then
    echo "$(basename "$PROJECT_DIR"): no framework detected — scaffolded _research/ only"
    exit 0
fi

# Scaffold .claude/rules/ for detected frameworks
scaffold_claude_rules

echo "$(basename "$PROJECT_DIR"): ${SKILLS[*]}"

SKILLS_BLOCK=$(generate_skills_section)

if [[ ! -f "$CLAUDE_MD" ]]; then
    cat > "$CLAUDE_MD" << NEWFILE
# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

$SKILLS_BLOCK
NEWFILE
    echo "  Created CLAUDE.md"
else
    if grep -q "$BEGIN_MARKER" "$CLAUDE_MD"; then
        # Replace existing auto-skills block using sed + temp file
        TEMP=$(mktemp)
        BLOCK_FILE=$(mktemp)
        echo "$SKILLS_BLOCK" > "$BLOCK_FILE"
        # Print lines before BEGIN marker, insert new block, skip until after END marker
        sed -n "1,/^${BEGIN_MARKER}$/{ /^${BEGIN_MARKER}$/!p; }" "$CLAUDE_MD" > "$TEMP"
        cat "$BLOCK_FILE" >> "$TEMP"
        sed -n "/^${END_MARKER}$/,\${ /^${END_MARKER}$/!p; }" "$CLAUDE_MD" >> "$TEMP"
        mv "$TEMP" "$CLAUDE_MD"
        rm -f "$BLOCK_FILE"
        echo "  Updated auto-skills section"
    else
        echo "" >> "$CLAUDE_MD"
        echo "$SKILLS_BLOCK" >> "$CLAUDE_MD"
        echo "  Appended auto-skills section"
    fi
fi
