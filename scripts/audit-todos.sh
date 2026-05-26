#!/usr/bin/env bash
# audit-todos.sh — scan project for TODOs, FIXMEs, and incomplete code markers.
# Outputs structured sections for the model to cross-reference against progress.md.
# Usage: audit-todos.sh <workspace-root>
set -euo pipefail

WORKSPACE="${1:?Usage: audit-todos.sh <workspace-root>}"
cd "$WORKSPACE"

# Exclude the project-tracker plugin's own directory from the scan
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR_NAME="$(basename "$PLUGIN_ROOT")"

# ── Detect languages from config files ────────────────────────────────────
INCLUDES=""
if [ -f Cargo.toml ]; then
    INCLUDES="$INCLUDES --include='*.rs'"
fi
if [ -f package.json ]; then
    INCLUDES="$INCLUDES --include='*.js' --include='*.ts' --include='*.jsx' --include='*.tsx'"
fi
if [ -f pyproject.toml ] || [ -f setup.py ] || [ -f requirements.txt ]; then
    INCLUDES="$INCLUDES --include='*.py'"
fi
if [ -f go.mod ]; then
    INCLUDES="$INCLUDES --include='*.go'"
fi
if [ -f pom.xml ] || [ -f build.gradle ] || [ -f build.gradle.kts ]; then
    INCLUDES="$INCLUDES --include='*.java' --include='*.kt'"
fi
# Always include shell and markdown
INCLUDES="$INCLUDES --include='*.sh' --include='*.md'"

echo "========================================"
echo "TODO & Stub Audit"
echo "========================================"
echo ""

# ── 1. TODO / FIXME / HACK / XXX comments ─────────────────────────────────
echo "=== TODO / FIXME / HACK / XXX ==="
eval grep -rn \
    -e 'TODO' -e 'FIXME' -e 'HACK' -e 'XXX' \
    $INCLUDES \
    --exclude-dir='.git' --exclude-dir='node_modules' --exclude-dir='target' \
    --exclude-dir='.claude' --exclude-dir='vendor' --exclude-dir='dist' \
    --exclude-dir='build' --exclude-dir='__pycache__' \
    --exclude-dir='.venv' --exclude-dir='venv' \
    --exclude-dir="$PLUGIN_DIR_NAME" \
    . 2>/dev/null || echo "  (none found)"
echo ""

# ── 2. Language-specific stubs ────────────────────────────────────────────
echo "=== Language-Specific Stubs ==="
STUB_PATTERNS=""
if [ -f Cargo.toml ]; then
    STUB_PATTERNS="$STUB_PATTERNS -e 'todo!(' -e 'unimplemented!('"
fi
if [ -f package.json ]; then
    STUB_PATTERNS="$STUB_PATTERNS -e 'throw new Error(.not implemented'"
fi
if [ -f pyproject.toml ] || [ -f setup.py ] || [ -f requirements.txt ]; then
    STUB_PATTERNS="$STUB_PATTERNS -e 'raise NotImplementedError' -e 'pass  # TODO'"
fi
if [ -f go.mod ]; then
    STUB_PATTERNS="$STUB_PATTERNS -e 'panic(\"not implemented\")'"
fi
if [ -f pom.xml ] || [ -f build.gradle ] || [ -f build.gradle.kts ]; then
    STUB_PATTERNS="$STUB_PATTERNS -e 'throw new UnsupportedOperationException'"
fi

if [ -n "$STUB_PATTERNS" ]; then
    eval grep -rn $STUB_PATTERNS $INCLUDES \
        --exclude-dir='.git' --exclude-dir='node_modules' --exclude-dir='target' \
        --exclude-dir='.claude' --exclude-dir='vendor' --exclude-dir='dist' \
        --exclude-dir='build' --exclude-dir='__pycache__' \
        --exclude-dir="$PLUGIN_DIR_NAME" \
        . 2>/dev/null || echo "  (none found)"
else
    echo "  (no recognized language)"
fi
echo ""

echo "========================================"
echo "Scan complete. Cross-reference findings against .claude/project-tracker/progress.md"
