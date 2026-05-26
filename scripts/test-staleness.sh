#!/usr/bin/env bash
# Smoke tests for project-tracker staleness detection.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR=""

cleanup() {
    if [ -n "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT

fail() {
    echo "[FAIL] $*" >&2
    exit 1
}

assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    case "$haystack" in
        *"$needle"*) ;;
        *) fail "$label: expected to find '$needle' in: $haystack" ;;
    esac
}

assert_not_contains() {
    local haystack="$1" needle="$2" label="$3"
    case "$haystack" in
        *"$needle"*) fail "$label: did not expect to find '$needle' in: $haystack" ;;
        *) ;;
    esac
}

commit_all() {
    git add .
    git -c user.email=test@example.com -c user.name=Test commit -q -m "$1"
}

reset_fixture() {
    cleanup
    TMP_DIR="$(mktemp -d)"
    cd "$TMP_DIR"
    git init -q
    mkdir -p .project-tracker/modules src
    cat > .project-tracker/.meta <<'META'
files:
  INDEX.md:
    baseline: none
    updated: 2000-01-01T00:00:00Z
  architecture.md:
    baseline: none
    updated: 2000-01-01T00:00:00Z
  progress.md:
    baseline: none
    updated: 2000-01-01T00:00:00Z
  modules/core.md:
    baseline: none
    updated: 2000-01-01T00:00:00Z
  api.md:
    baseline: none
    updated: 2000-01-01T00:00:00Z
  data-model.md:
    baseline: none
    updated: 2000-01-01T00:00:00Z
  deployment.md:
    baseline: none
    updated: 2000-01-01T00:00:00Z
  stack.md:
    baseline: none
    updated: 2000-01-01T00:00:00Z
  toolchain.md:
    baseline: none
    updated: 2000-01-01T00:00:00Z
META
    for doc in INDEX architecture progress api data-model deployment stack toolchain; do
        echo "# $doc" > ".project-tracker/$doc.md"
    done
    echo "# core" > .project-tracker/modules/core.md
    echo "v1" > src/main.js
    commit_all baseline
    local base; base="$(git rev-parse HEAD)"
    python3 - "$base" <<'PY'
from pathlib import Path
import sys
base = sys.argv[1]
p = Path(".project-tracker/.meta")
text = p.read_text()
text = text.replace("baseline: none", f"baseline: {base}")
p.write_text(text)
PY
    commit_all meta
}

run_detect() {
    bash "$ROOT/scripts/detect-changes.sh" "$@"
}

run_scan() {
    bash "$ROOT/scripts/scan-state.sh" "$@"
}

reset_fixture
echo "unstaged" >> src/main.js
out="$(run_detect .project-tracker/.meta architecture.md)"
assert_contains "$out" "STALE" "unstaged architecture"
assert_contains "$out" "src/main.js" "unstaged architecture path"
out="$(run_scan . .project-tracker)"
assert_contains "$out" "progress.md          STALE" "scan progress unstaged"

reset_fixture
echo "staged" >> src/main.js
git add src/main.js
out="$(run_detect .project-tracker/.meta modules/core.md)"
assert_contains "$out" "STALE" "nested tracker key"
assert_contains "$out" "src/main.js" "nested tracker changed path"

reset_fixture
echo "untracked" > src/new.js
out="$(run_detect .project-tracker/.meta progress.md)"
assert_contains "$out" "STALE" "untracked progress"
assert_contains "$out" "src/new.js" "untracked progress path"

reset_fixture
echo "tracker-only" >> .project-tracker/progress.md
git add .project-tracker/progress.md
commit_all tracker-only
out="$(run_detect .project-tracker/.meta progress.md)"
assert_contains "$out" "OK" "tracker-only progress"
assert_not_contains "$out" "STALE" "tracker-only progress stale"

reset_fixture
out="$(run_detect .project-tracker/.meta)"
assert_contains "$out" "INDEX.md" "full scan includes INDEX"
assert_contains "$out" "modules/core.md" "full scan includes nested module"

reset_fixture
mkdir -p app/api graphql models terraform
echo "{}" > openapi.yaml
echo "type Query { ok: Boolean }" > graphql/schema.graphql
echo "class User: pass" > models/user.py
echo "resource x" > terraform/main.tf
echo "{}" > tsconfig.json
echo "{}" > vite.config.ts
echo "lock" > pnpm-lock.yaml
out="$(run_detect .project-tracker/.meta api.md)"
assert_contains "$out" "openapi.yaml" "api openapi"
assert_contains "$out" "graphql/schema.graphql" "api graphql"
out="$(run_detect .project-tracker/.meta data-model.md)"
assert_contains "$out" "models/user.py" "data model models"
out="$(run_detect .project-tracker/.meta deployment.md)"
assert_contains "$out" "terraform/main.tf" "deployment terraform"
out="$(run_detect .project-tracker/.meta stack.md)"
assert_contains "$out" "pnpm-lock.yaml" "stack lockfile"
out="$(run_detect .project-tracker/.meta toolchain.md)"
assert_contains "$out" "tsconfig.json" "toolchain tsconfig"
assert_contains "$out" "vite.config.ts" "toolchain vite"

echo "Staleness smoke tests passed."
