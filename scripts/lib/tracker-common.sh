# tracker-common.sh — shared library for project-tracker scripts
# Source this from other scripts:
#   source "$PLUGIN_ROOT/scripts/lib/tracker-common.sh"
#
# Provides: tracker_dir, tracker_meta, tracker_patterns, matches_tracker,
#           collect_changes, collect_mtime, classify, tracked_files,
#           meta_field, non_tracker_changes, relevant_changes
set -euo pipefail

# ── Tracker location ──────────────────────────────────────────────────────
# PROJECT_TRACKER_DIR can override the canonical location for tests or custom
# workspaces. The plugin default is harness-neutral.
tracker_dir() {
    echo "${PROJECT_TRACKER_DIR:-.project-tracker}"
}

tracker_meta() {
    local dir="${1:-$(tracker_dir)}"
    echo "${dir%/}/.meta"
}

tracker_path_from_meta() {
    local meta="${1:-$(tracker_meta)}"
    dirname "$meta" | sed 's|^\./||' | sed 's|/*$||'
}

escape_ere() {
    sed 's/[][(){}.^$*+?|\\]/\\&/g'
}

# ── Source-to-tracker mapping ──────────────────────────────────────────────
# Returns source file patterns relevant to a given tracker doc.
tracker_patterns() {
    case "$1" in
        INDEX.md)           echo "README.md README package.json Cargo.toml pyproject.toml go.mod AGENTS.md .github/ .gitlab/ Makefile Justfile" ;;
        stack.md)           echo "Cargo.toml Cargo.lock package.json package-lock.json npm-shrinkwrap.json pnpm-lock.yaml yarn.lock bun.lockb pyproject.toml poetry.lock uv.lock requirements.txt requirements-dev.txt setup.py setup.cfg go.mod go.sum CMakeLists.txt Gemfile Gemfile.lock composer.json composer.lock pom.xml build.gradle build.gradle.kts gradle.properties Dockerfile Dockerfile* docker-compose.yml compose.yml" ;;
        toolchain.md)       echo ".github/ .gitlab/ .circleci/ Jenkinsfile Makefile Justfile Taskfile.yml Taskfile.yaml package.json tsconfig.json jsconfig.json vite.config.js vite.config.ts next.config.js next.config.mjs webpack.config.js rollup.config.js eslint.config.js .eslintrc .eslintrc.js .eslintrc.cjs .eslintrc.yaml .eslintrc.yml .eslintrc.json biome.json pyproject.toml tox.ini pytest.ini ruff.toml rustfmt.toml .prettierrc .prettierrc.js .prettierrc.cjs .prettierrc.yaml .prettierrc.yml .prettierrc.json prettier.config.js prettier.config.cjs tests/ spec/" ;;
        architecture.md|implementation.md) echo "src/ lib/ app/ include/ packages/ crates/ cmd/ internal/ services/ apps/ components/ server/ client/ main.go main.py index.js index.ts" ;;
        data-model.md)      echo "prisma/ schema/ migrations/ db/ database/ models/ entities/ orm/ sql/ schema.prisma schema.sql *.schema.sql *.sql" ;;
        api.md)             echo "routes/ controllers/ handlers/ api/ endpoints/ pages/api/ app/api/ server/api/ openapi.yaml openapi.yml openapi.json swagger.yaml swagger.yml swagger.json graphql/ schema.graphql *.graphql proto/ *.proto" ;;
        deployment.md)      echo "Dockerfile Dockerfile* docker-compose.yml docker-compose.yaml compose.yml compose.yaml .dockerignore deploy/ deployment/ k8s/ kubernetes/ chart/ charts/ helm/ terraform/ terragrunt/ pulumi/ infra/ infrastructure/ fly.toml vercel.json netlify.toml railway.toml render.yaml" ;;
        conventions.md)     echo "AGENTS.md .agents/rules/ .codex/ CLAUDE.md .claude/CLAUDE.md .claude/rules/ .editorconfig .eslintrc.js .eslintrc.cjs .eslintrc.yaml .eslintrc.yml .eslintrc.json .eslintrc .prettierrc .prettierrc.js .prettierrc.cjs .prettierrc.yaml .prettierrc.yml .prettierrc.json prettier.config.js prettier.config.cjs .prettierrc.toml rustfmt.toml .stylelintrc.js .stylelintrc.cjs .stylelintrc.json .stylelintrc.yaml .stylelintrc.yml .stylelintrc biome.json .markdownlint.json .markdownlint.yaml .markdownlint.yml .markdownlint-cli2.jsonc pyproject.toml" ;;
        progress.md)         echo "" ;;
        modules/*)          echo "src/ lib/ app/ include/ packages/ crates/ cmd/ internal/ services/ apps/" ;;
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
            $p | $p/* | */$p | */$p/*) return 0 ;;
        esac
        case "$base" in $p) return 0 ;; esac
    done
    return 1
}

# ── Collect changed files via git since a baseline commit ──────────────────
collect_changes() {
    local baseline="$1"
    [ "$baseline" = "none" ] || [ -z "$baseline" ] && return 1
    git rev-parse --is-inside-work-tree &>/dev/null || return 1
    git cat-file -e "$baseline" &>/dev/null || return 1
    {
        git diff --name-only "$baseline..HEAD" 2>/dev/null || true
        git diff --cached --name-only 2>/dev/null || true
        git diff --name-only 2>/dev/null || true
        git ls-files --others --exclude-standard 2>/dev/null || true
    } | awk 'NF && !seen[$0]++'
    return 0
}

# ── Collect changed files via mtime fallback ────────────────────────────────
collect_mtime() {
    local updated="$1"
    [ -z "$updated" ] && return 1
    local ref_time; ref_time=$(echo "$updated" | sed 's/T/ /' | sed 's/Z$//')
    local tracker; tracker="$(tracker_dir)"
    tracker="${tracker#./}"
    find . -type f -newermt "$ref_time" \
        ! -path './.git/*' ! -path './node_modules/*' \
        ! -path './target/*' ! -path "./$tracker/*" \
        ! -path './.claude/project-tracker/*' \
        2>/dev/null | sed 's|^\./||'
    return 0
}

# ── Parse .meta file fields ────────────────────────────────────────────────
# List tracked markdown files from the YAML-style .meta file.
tracked_files() {
    local meta="${1:-$(tracker_meta)}"
    awk '
        /^files:[[:space:]]*$/ { in_files = 1; next }
        in_files && /^  [^ ].*\.md:[[:space:]]*$/ {
            line = $0
            sub(/^  /, "", line)
            sub(/:[[:space:]]*$/, "", line)
            print line
        }
    ' "$meta" 2>/dev/null
}

# Extract a per-file field from the YAML-style .meta file.
meta_field() {
    local file="$1" field="$2" meta="${3:-$(tracker_meta)}"
    awk -v key="$file" -v wanted="$field" '
        $0 == "  " key ":" { in_file = 1; next }
        in_file && /^  [^ ].*:[[:space:]]*$/ { exit }
        in_file {
            prefix = "    " wanted ":"
            if (index($0, prefix) == 1) {
                value = substr($0, length(prefix) + 1)
                sub(/^[[:space:]]*/, "", value)
                print value
                exit
            }
        }
    ' "$meta" 2>/dev/null
}

# Remove generated tracker docs from a changed-file stream.
non_tracker_changes() {
    local meta="${1:-$(tracker_meta)}"
    local tracker_path; tracker_path="$(tracker_path_from_meta "$meta")"
    local tracker_ere; tracker_ere="$(printf '%s' "$tracker_path" | escape_ere)"
    grep -v -E "^(${tracker_ere}|\\.claude/project-tracker)/" || true
}

# Return changed files relevant to a tracker file.
relevant_changes() {
    local tracker_file="$1" meta="${2:-$(tracker_meta)}"
    if [ "$tracker_file" = "progress.md" ]; then
        non_tracker_changes "$meta"
        return 0
    fi

    while IFS= read -r changed; do
        [ -z "$changed" ] && continue
        matches_tracker "$changed" "$tracker_file" && echo "$changed"
    done
    return 0
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
