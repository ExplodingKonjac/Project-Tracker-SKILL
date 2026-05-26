#!/usr/bin/env bash
# Validate Claude Code and Codex plugin packaging metadata.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PLUGIN="."
PLUGIN_LINK="plugins/project-tracker"
CLAUDE_PLUGIN="$PLUGIN/.claude-plugin/plugin.json"
CODEX_PLUGIN="$PLUGIN/.codex-plugin/plugin.json"
CLAUDE_MARKETPLACE=".claude-plugin/marketplace.json"
CODEX_MARKETPLACE=".agents/plugins/marketplace.json"

fail() {
    echo "[ERROR] $*" >&2
    exit 1
}

json_get() {
    local file="$1" path="$2"
    if command -v node >/dev/null 2>&1; then
        node -e "const fs=require('fs'); let v=JSON.parse(fs.readFileSync(process.argv[1], 'utf8')); for (const p of process.argv[2].split('.')) v=v[p]; if (v === undefined || v === null) process.exit(2); console.log(v);" "$file" "$path"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import json,sys; v=json.load(open(sys.argv[1])); [globals().__setitem__('v', v[int(p) if isinstance(v, list) else p]) for p in sys.argv[2].split('.')]; print(v)" "$file" "$path"
    else
        fail "Need node or python3 to validate JSON"
    fi
}

for file in "$CLAUDE_PLUGIN" "$CODEX_PLUGIN" "$CLAUDE_MARKETPLACE" "$CODEX_MARKETPLACE"; do
    [ -f "$file" ] || fail "Missing $file"
    if command -v node >/dev/null 2>&1; then
        node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" "$file" || fail "Invalid JSON: $file"
    else
        python3 -m json.tool "$file" >/dev/null || fail "Invalid JSON: $file"
    fi
done

[ -L "$PLUGIN_LINK" ] || fail "$PLUGIN_LINK must be a symlink"
link_target="$(readlink "$PLUGIN_LINK")"
[ "$link_target" = ".." ] || fail "$PLUGIN_LINK must point to .."

claude_name="$(json_get "$CLAUDE_PLUGIN" "name")"
codex_name="$(json_get "$CODEX_PLUGIN" "name")"
[ "$claude_name" = "$codex_name" ] || fail "Plugin names differ: $claude_name vs $codex_name"

claude_version="$(json_get "$CLAUDE_PLUGIN" "version")"
codex_version="$(json_get "$CODEX_PLUGIN" "version")"
[ "$claude_version" = "$codex_version" ] || fail "Plugin versions differ: $claude_version vs $codex_version"

codex_skills="$(json_get "$CODEX_PLUGIN" "skills")"
[ "$codex_skills" = "./skills/" ] || fail "Codex plugin skills path must be ./skills/"

claude_source="$(json_get "$CLAUDE_MARKETPLACE" "plugins.0.source")"
[ "$claude_source" = "./plugins/project-tracker" ] || fail "Claude marketplace source must be ./plugins/project-tracker"

codex_source="$(json_get "$CODEX_MARKETPLACE" "plugins.0.source.path")"
[ "$codex_source" = "./plugins/project-tracker" ] || fail "Codex marketplace source.path must be ./plugins/project-tracker"

codex_installation="$(json_get "$CODEX_MARKETPLACE" "plugins.0.policy.installation")"
[ "$codex_installation" = "AVAILABLE" ] || fail "Codex marketplace policy.installation must be AVAILABLE"

codex_auth="$(json_get "$CODEX_MARKETPLACE" "plugins.0.policy.authentication")"
[ "$codex_auth" = "ON_INSTALL" ] || fail "Codex marketplace policy.authentication must be ON_INSTALL"

for skill in "$PLUGIN"/skills/*/SKILL.md; do
    [ -f "$skill" ] || continue
    skill_dir="$(basename "$(dirname "$skill")")"
    front_matter_count="$(grep -c '^---$' "$skill")"
    [ "$front_matter_count" -ge 2 ] || fail "$skill missing front matter"
    front_matter="$(sed -n '2,/^---$/p' "$skill")"
    echo "$front_matter" | grep -q '^name:' || fail "$skill missing name front matter"
    echo "$front_matter" | grep -q '^description:' || fail "$skill missing description front matter"
    skill_name="$(echo "$front_matter" | sed -n 's/^name:[[:space:]]*//p' | head -1)"
    [ "$skill_name" = "$skill_dir" ] || fail "$skill name '$skill_name' must match directory '$skill_dir'"
    case "$skill_name" in
        project-tracker-*) ;;
        *) fail "$skill name '$skill_name' must start with project-tracker-" ;;
    esac
done

if grep -R "CLAUDE_PLUGIN_ROOT" "$PLUGIN"/skills "$PLUGIN"/templates >/dev/null 2>&1; then
    fail "Skill and template docs must use PLUGIN_ROOT, not CLAUDE_PLUGIN_ROOT"
fi

for script in "$PLUGIN"/scripts/*.sh "$PLUGIN"/scripts/lib/*.sh; do
    [ -f "$script" ] || fail "Missing script $script"
done

for template in "$PLUGIN"/templates/*.tmpl; do
    [ -f "$template" ] || fail "Missing template $template"
done

echo "Packaging validation passed."
