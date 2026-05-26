#!/usr/bin/env bash
# detect-changes.sh — detect files changed since last tracker baseline.
# Supports per-file tracking via .meta.
#
# Usage:
#   detect-changes.sh <path-to-.meta>              # full project scan
#   detect-changes.sh <path-to-.meta> <tracker-file>  # per-file check
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/tracker-common.sh"

META_FILE="${1:?Usage: detect-changes.sh <path-to-.meta> [tracker-file]}"
TRACKER_FILE="${2:-}"
PROJECT_TRACKER_DIR="$(dirname "$META_FILE")"
export PROJECT_TRACKER_DIR
if [ ! -f "$META_FILE" ]; then
    echo "[ERROR] .meta file not found: $META_FILE"
    exit 1
fi

tracker_path_from_meta() {
    dirname "$META_FILE" | sed 's|^\./||' | sed 's|/*$||'
}

escape_ere() {
    sed 's/[][(){}.^$*+?|\\]/\\&/g'
}

non_tracker_changes() {
    local tracker_path; tracker_path="$(tracker_path_from_meta)"
    local tracker_ere; tracker_ere="$(printf '%s' "$tracker_path" | escape_ere)"
    grep -v -E "^(${tracker_ere}|\\.claude/project-tracker)/" || true
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE 1: Per-file check
# ═══════════════════════════════════════════════════════════════════════════
if [ -n "$TRACKER_FILE" ]; then
    BASELINE=$(meta_field "$TRACKER_FILE" "baseline" "$META_FILE")
    UPDATED=$(meta_field "$TRACKER_FILE" "updated" "$META_FILE")

    if [ -z "$BASELINE" ] && [ -z "$UPDATED" ]; then
        echo "[$TRACKER_FILE] UNTRACKED (no entry in .meta)"
        exit 0
    fi

    ALL_CHANGES=$(collect_changes "$BASELINE" || collect_mtime "$UPDATED" || true)

    # progress.md: any change is potentially progress (exclude tracker docs themselves)
    if [ "$TRACKER_FILE" = "progress.md" ]; then
        if [ -n "$ALL_CHANGES" ]; then
            NON_TRACKER=$(echo "$ALL_CHANGES" | non_tracker_changes)
            COUNT=$(echo "$NON_TRACKER" | grep -c . || true)
            if [ "$COUNT" -gt 0 ]; then
                echo "[$TRACKER_FILE] STALE ($COUNT non-tracker changes — manual review needed)"
            else
                echo "[$TRACKER_FILE] OK"
            fi
        else
            echo "[$TRACKER_FILE] OK"
        fi
        exit 0
    fi

    if [ -z "$ALL_CHANGES" ]; then
        echo "[$TRACKER_FILE] OK"
        exit 0
    fi

    RELEVANT=""
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        if matches_tracker "$f" "$TRACKER_FILE"; then
            RELEVANT="$RELEVANT$f"$'\n'
        fi
    done <<< "$ALL_CHANGES"

    if [ -z "$RELEVANT" ]; then
        echo "[$TRACKER_FILE] OK"
        exit 0
    fi

    COUNT=$(echo "$RELEVANT" | grep -c . || true)
    echo "[$TRACKER_FILE] STALE ($COUNT relevant files changed)"
    echo "$RELEVANT" | sed 's/^/  /'
    exit 0
fi

# ═══════════════════════════════════════════════════════════════════════════
# MODE 2: Full project scan (per-file granularity)
# ═══════════════════════════════════════════════════════════════════════════
echo "=== Per-File Staleness ==="
TRACKER_FILES=$(grep -E '^  [a-z].*\.md:' "$META_FILE" | sed 's/:$//' | sed 's/^  //' || true)

if [ -z "$TRACKER_FILES" ]; then
    echo "  (no file entries in .meta)"
    exit 0
fi

ANY_STALE=false
while IFS= read -r tf; do
    [ -z "$tf" ] && continue
    BASELINE=$(meta_field "$tf" "baseline" "$META_FILE")
    UPDATED=$(meta_field "$tf" "updated" "$META_FILE")

    if [ -z "$BASELINE" ] && [ -z "$UPDATED" ]; then
        printf "  %-20s UNTRACKED\n" "$tf"
        continue
    fi

    ALL_CHANGES=$(collect_changes "$BASELINE" || collect_mtime "$UPDATED" || true)

    # progress.md: any change is potentially progress (exclude tracker docs themselves)
    if [ "$tf" = "progress.md" ]; then
        if [ -n "$ALL_CHANGES" ]; then
            NON_TRACKER=$(echo "$ALL_CHANGES" | non_tracker_changes)
            TOTAL=$(echo "$NON_TRACKER" | wc -l | tr -d ' ')
            if [ "$TOTAL" -gt 0 ]; then
                ANY_STALE=true
                printf "  %-20s STALE (%d non-tracker changes — manual review needed)\n" "$tf" "$TOTAL"
            else
                printf "  %-20s OK\n" "$tf"
            fi
        else
            printf "  %-20s OK\n" "$tf"
        fi
        continue
    fi

    if [ -z "$ALL_CHANGES" ]; then
        printf "  %-20s OK\n" "$tf"
        continue
    fi

    RELEVANT=""
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        if matches_tracker "$f" "$tf"; then
            RELEVANT="$RELEVANT$f"$'\n'
        fi
    done <<< "$ALL_CHANGES"

    if [ -z "$RELEVANT" ]; then
        printf "  %-20s OK\n" "$tf"
    else
        ANY_STALE=true
        CNT=$(echo "$RELEVANT" | grep -c . || true)
        printf "  %-20s STALE (%d files)\n" "$tf" "$CNT"
        echo "$RELEVANT" | sed 's/^/      /'
    fi
done <<< "$TRACKER_FILES"

if [ "$ANY_STALE" = false ]; then
    echo "  (all files up to date)"
fi

echo ""
echo "=== All Changed Files (categorized) ==="
# Collect all changes from the oldest baseline
OLDEST=""
while IFS= read -r tf; do
    [ -z "$tf" ] && continue
    b=$(meta_field "$tf" "baseline" "$META_FILE")
    if [ -n "$b" ] && [ "$b" != "none" ]; then
        OLDEST="$b"
        break
    fi
done <<< "$TRACKER_FILES"

ALL_FILES=$(collect_changes "$OLDEST" || true)
if [ -n "$ALL_FILES" ]; then
    TOTAL=$(echo "$ALL_FILES" | wc -l | tr -d ' ')
    echo "Total: $TOTAL files"
    echo ""
    # bash 3 compatible: iterate categories instead of associative array
    for cat in config source test ci build docs other; do
        cnt=0
        items=""
        while IFS= read -r f; do
            [ -z "$f" ] && continue
            if [ "$(classify "$f")" = "$cat" ]; then
                cnt=$((cnt + 1))
                items="$items  $f"$'\n'
            fi
        done <<< "$ALL_FILES"
        if [ "$cnt" -gt 0 ]; then
            printf "[%s] (%d files)\n" "$cat" "$cnt"
            echo "$items"
        fi
    done
else
    echo "No changes detected."
fi
