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
    if echo "$all_deps" | grep -qx "nuxt"; then
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

    if ! command -v jq &>/dev/null; then
        echo "WARNING: jq not found, skipping package.json detection" >&2
        return 0
    fi

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
    if echo "$all_reqs" | grep -q "^laravel/framework"; then
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
    # WordPress: wp-content/ directory or wp-config.php
    if [[ -d "$PROJECT_DIR/wp-content" ]] || [[ -f "$PROJECT_DIR/wp-config.php" ]]; then
        if [[ ! " ${SKILLS[*]:-} " =~ " wp-dev " ]]; then
            SKILLS+=("wp-dev")
        fi
    fi
}

detect_from_package_json
detect_from_composer_json
detect_from_directory_structure

# Deduplicate
if [[ ${#SKILLS[@]} -gt 0 ]]; then
    mapfile -t SKILLS < <(printf '%s\n' "${SKILLS[@]}" | sort -u)
fi

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

if [[ ${#SKILLS[@]} -eq 0 ]]; then
    echo "$(basename "$PROJECT_DIR"): no framework detected — skipping"
    exit 0
fi

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
        # Replace existing auto-skills block
        TEMP=$(mktemp)
        awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v block="$SKILLS_BLOCK" '
            $0 == begin { print block; skip=1; next }
            $0 == end { skip=0; next }
            !skip { print }
        ' "$CLAUDE_MD" > "$TEMP"
        mv "$TEMP" "$CLAUDE_MD"
        echo "  Updated auto-skills section"
    else
        echo "" >> "$CLAUDE_MD"
        echo "$SKILLS_BLOCK" >> "$CLAUDE_MD"
        echo "  Appended auto-skills section"
    fi
fi
