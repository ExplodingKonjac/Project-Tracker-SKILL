# tracker-common.sh — shared library for project-tracker scripts
# Source this from other scripts:
#   source "${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/scripts/lib/tracker-common.sh"
#
# Provides: tracker_patterns, matches_tracker, collect_changes,
#           collect_mtime, classify, meta_field
set -euo pipefail

# ── Source-to-tracker mapping ──────────────────────────────────────────────
# Returns source file patterns relevant to a given tracker doc.
tracker_patterns() {
    case "$1" in
        stack.md)           echo "Cargo.toml package.json pyproject.toml go.mod CMakeLists.txt Gemfile setup.py" ;;
        toolchain.md)       echo ".github/ .gitlab/ tests/ spec/" ;;
        architecture.md|implementation.md) echo "src/ lib/ app/ include/" ;;
        data-model.md)      echo "prisma/ schema/ migrations/ db/" ;;
        api.md)             echo "routes/ controllers/ handlers/ api/ endpoints/" ;;
        deployment.md)      echo "Dockerfile docker-compose deploy/ k8s/ chart/" ;;
        conventions.md)     echo "CLAUDE.md .claude/CLAUDE.md .claude/rules/ .editorconfig .eslintrc.js .eslintrc.cjs .eslintrc.yaml .eslintrc.yml .eslintrc.json .eslintrc .prettierrc .prettierrc.js .prettierrc.cjs .prettierrc.yaml .prettierrc.yml .prettierrc.json prettier.config.js prettier.config.cjs .prettierrc.toml rustfmt.toml .stylelintrc.js .stylelintrc.cjs .stylelintrc.json .stylelintrc.yaml .stylelintrc.yml .stylelintrc biome.json .markdownlint.json .markdownlint.yaml .markdownlint.yml .markdownlint-cli2.jsonc pyproject.toml" ;;
        progress.md|INDEX.md) echo "" ;;
        modules/*)          echo "src/ lib/ app/ include/" ;;
        *)                  echo "" ;;
    esac
}

# ── Check if a changed file matches a tracker's patterns ───────────────────
matches_tracker() {
    local file="$1" tracker="$2"
    local patterns; patterns=$(tracker_patterns "$tracker")
    [ -z "$patterns" ] && return 1
    local base; base=$(basename "$file")
    local p
    for pat in $patterns; do
        p="${pat%/}"
        case "$file" in
            "$p" | "$p/"* | */"$p" | */"$p"/*) return 0 ;;
        esac
        case "$base" in "$p") return 0 ;; esac
    done
    return 1
}

# ── Collect changed files via git since a baseline commit ──────────────────
collect_changes() {
    local baseline="$1"
    [ "$baseline" = "none" ] || [ -z "$baseline" ] && return 1
    git rev-parse --is-inside-work-tree &>/dev/null || return 1
    git cat-file -e "$baseline" &>/dev/null || return 1
    git diff --name-only "$baseline..HEAD" 2>/dev/null
    return 0
}

# ── Collect changed files via mtime fallback ────────────────────────────────
collect_mtime() {
    local updated="$1"
    [ -z "$updated" ] && return 1
    local ref_time; ref_time=$(echo "$updated" | sed 's/T/ /' | sed 's/Z$//')
    find . -type f -newermt "$ref_time" \
        ! -path './.git/*' ! -path './node_modules/*' \
        ! -path './target/*' ! -path './.claude/*' \
        2>/dev/null | sed 's|^\./||'
    return 0
}

# ── Parse .meta file fields ────────────────────────────────────────────────
# Extract a per-file field from the YAML-style .meta file.
meta_field() {
    local file="$1" field="$2" meta="${3:-.claude/project-tracker/.meta}"
    sed -n "/^  $file:/,/^  [a-z]/p" "$meta" 2>/dev/null \
        | grep "$field:" | sed "s/.*$field:[[:space:]]*//"
}

# ── Classify a changed file into a category ────────────────────────────────
classify() {
    local path="$1"
    case "$path" in
        Cargo.toml | package.json | pyproject.toml | go.mod | go.sum | \
        CMakeLists.txt | Gemfile | *.gemspec | setup.py | *.sln | *.csproj)
            echo "config" ;;
        src/* | lib/* | app/* | include/* | python/* | java/* | rust/*)
            echo "source" ;;
        tests/* | spec/* | *_test.go | *_test.py | *_spec.rb | *.test.*)
            echo "test" ;;
        .github/* | .gitlab/* | .circleci/* | Jenkinsfile*)
            echo "ci" ;;
        Dockerfile* | docker-compose* | Makefile | Justfile | *.mk)
            echo "build" ;;
        *.md | *.rst | docs/*)
            echo "docs" ;;
        *)
            echo "other" ;;
    esac
}
