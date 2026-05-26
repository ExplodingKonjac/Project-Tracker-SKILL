#!/usr/bin/env bash
# scan-state.sh — scan current project state and check tracker health.
# Outputs structured text sections for the model to compare against tracker docs.
# Usage: scan-state.sh <workspace-root>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/tracker-common.sh"

WORKSPACE="${1:?Usage: scan-state.sh <workspace-root> [tracker-dir]}"
cd "$WORKSPACE"

TRACKER_DIR="${2:-$(tracker_dir)}"
PROJECT_TRACKER_DIR="$TRACKER_DIR"
export PROJECT_TRACKER_DIR
META="$(tracker_meta "$TRACKER_DIR")"

echo "========================================
Tracker Health Scan
========================================"
echo ""

# ── 1. Git state ──────────────────────────────────────────────────────────
echo "=== Git State ==="
if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    HEAD_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    echo "HEAD: $HEAD_COMMIT"
    BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
    echo "Branch: $BRANCH"
else
    echo "HEAD: (not a git repo)"
fi
echo ""

# ── 2. Staleness (per-file, from .meta) ───────────────────────────────────
echo "=== Tracker Staleness ==="

if [ -f "$META" ]; then
    TRACKED=$(tracked_files "$META" || true)

    if [ -z "$TRACKED" ]; then
        echo "  (no per-file entries in .meta)"
    else
        echo "  Per-file baselines from .meta:"
        echo ""
        while IFS= read -r tf; do
            [ -z "$tf" ] && continue
            baseline=$(meta_field "$tf" "baseline" "$META")
            updated=$(meta_field "$tf" "updated" "$META")

            if [ ! -f "$TRACKER_DIR/$tf" ]; then
                printf "  %-20s MISSING (tracked in .meta but file gone)\n" "$tf"
                continue
            fi

            all=$(collect_changes "$baseline" || collect_mtime "$updated" || true)
            if [ -z "$all" ]; then
                printf "  %-20s OK\n" "$tf"
                continue
            fi

            relevant=$(echo "$all" | relevant_changes "$tf" "$META")

            if [ -z "$relevant" ]; then
                printf "  %-20s OK\n" "$tf"
            else
                cnt=$(echo "$relevant" | grep -c . || true)
                if [ "$tf" = "progress.md" ]; then
                    printf "  %-20s STALE (%d non-tracker changes — manual review needed)\n" "$tf" "$cnt"
                else
                    printf "  %-20s STALE (%d relevant files changed)\n" "$tf" "$cnt"
                fi
                echo "$relevant" | sed 's/^/      /'
            fi
        done <<< "$TRACKED"
    fi
else
    echo "  (no .meta found)"
fi
echo ""

# ── 3. Config snapshot ───────────────────────────────────────────────────
echo "=== Config Snapshot ==="
if [ -f Cargo.toml ]; then
    echo "[ Cargo.toml ]"
    grep -E '^\[(package|workspace|dependencies|build-dependencies)\]' Cargo.toml 2>/dev/null | sed 's/^/  /' || true
    sed -n '/^\[dependencies\]/,/^\[/p' Cargo.toml 2>/dev/null | grep -E '^[a-zA-Z_-]' | sed 's/^/  /' || true
    echo ""
fi
if [ -f package.json ]; then
    echo "[ package.json ]"
    node -e "const p=require('./package.json');\
        console.log('  name: '+p.name);\
        console.log('  version: '+p.version);\
        console.log('  deps: '+(p.dependencies?Object.keys(p.dependencies).join(', '):'(none)'));\
        console.log('  devDeps: '+(p.devDependencies?Object.keys(p.devDependencies).join(', '):'(none)'));" 2>/dev/null || \
    echo "  (could not parse)"
    echo ""
fi
if [ -f pyproject.toml ]; then
    echo "[ pyproject.toml ]"
    grep -E '^(name|version|requires-python|dependencies)' pyproject.toml 2>/dev/null | sed 's/^/  /' || true
    echo ""
fi
if [ -f go.mod ]; then
    echo "[ go.mod ]"
    head -5 go.mod | sed 's/^/  /'
    echo ""
fi
echo ""

# ── 4. Directory tree (depth 2) ──────────────────────────────────────────
echo "=== Directory Tree ==="
find . -maxdepth 2 -type d \
    ! -path '.' \
    ! -path './.git' ! -path './.git/*' \
    ! -path './node_modules' ! -path './node_modules/*' \
    ! -path './target' ! -path './target/*' \
    ! -path './.project-tracker' ! -path './.project-tracker/*' \
    ! -path './.claude/project-tracker' ! -path './.claude/project-tracker/*' \
    2>/dev/null | sort | while read -r d; do
    depth=$(echo "$d" | tr -cd '/' | wc -c)
    [ "$depth" -gt 2 ] && continue
    prefix="  "
    [ "$depth" -eq 2 ] && prefix="    "
    basename=$(basename "$d")
    fcount=$(find "$d" -maxdepth 1 -type f 2>/dev/null | wc -l)
    echo "$prefix$basename/  ($fcount files)"
done
echo ""

# ── 5. Existence checks ──────────────────────────────────────────────────
echo "=== Existence Checks ==="
for dir in src lib app include tests; do
    if [ -d "$dir" ]; then
        subs=$(find "$dir" -maxdepth 1 -type d 2>/dev/null | wc -l)
        [ "$subs" -gt 0 ] && echo "  $dir/  EXISTS ($subs subdirectories)" || echo "  $dir/  EXISTS"
    fi
done
for file in Dockerfile docker-compose.yml Makefile .github/workflows/ci.yml; do
    [ -f "$file" ] && echo "  $file  EXISTS"
done
echo ""

echo "========================================"
echo "Scan complete. Compare above against tracker docs."
