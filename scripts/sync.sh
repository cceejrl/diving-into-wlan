#!/usr/bin/env bash
#
# sync.sh — Sync Obsidian vault and code repo into Hugo project
#
#   obsidian-vault/posts/  → hugo/content.zh/posts/
#   obsidian-vault/assets/ → hugo/static/assets/
#   code/                  → hugo/static/code/
#
# Usage: ./scripts/sync.sh [--force]
#   --force  Skip draft check (sync all posts regardless of draft status)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

FORCE="${1:-}"

# Resolve paths
SRC_POSTS="$ROOT_DIR/obsidian-vault/posts"
SRC_ASSETS="$ROOT_DIR/obsidian-vault/assets"
SRC_CODE="$ROOT_DIR/code"

DST_POSTS="$ROOT_DIR/hugo/content.zh/posts"
DST_ASSETS="$ROOT_DIR/hugo/static/assets"
DST_CODE="$ROOT_DIR/hugo/static/code"

# --- helpers ---

log() { echo "[sync] $*"; }

sync_dir() {
    local src="$1"
    local dst="$2"

    if [ ! -d "$src" ]; then
        log "WARNING: source directory not found: $src (skipping)"
        return 0
    fi

    mkdir -p "$dst"

    if command -v rsync &>/dev/null; then
        rsync -a --delete --exclude='.DS_Store' --exclude='Thumbs.db' "$src/" "$dst/"
    else
        log "rsync not available, using cp (slower)"
        rm -rf "$dst"/*
        cp -r "$src"/* "$dst/" 2>/dev/null || true
    fi
}

filter_drafts() {
    local src="$1"
    local dst="$2"
    local count=0

    mkdir -p "$dst"

    find "$src" -name '*.md' -print0 | while IFS= read -r -d '' f; do
        local rel="${f#$src/}"
        local target="$dst/$rel"
        local target_dir
        target_dir="$(dirname "$target")"
        mkdir -p "$target_dir"

        if grep -q '^draft:\s*true' "$f" 2>/dev/null; then
            log "SKIP (draft): $rel"
            continue
        fi

        cp "$f" "$target"
        log "COPY: $rel"
        count=$((count + 1))
    done
}

# --- main ---

log "Syncing posts (skipping drafts)..."

if [ "$FORCE" = "--force" ]; then
    log "--force: syncing all posts"
    sync_dir "$SRC_POSTS" "$DST_POSTS"
else
    filter_drafts "$SRC_POSTS" "$DST_POSTS"
fi

log "Syncing assets..."
sync_dir "$SRC_ASSETS" "$DST_ASSETS"

log "Syncing code..."
sync_dir "$SRC_CODE" "$DST_CODE"

log "Done."
