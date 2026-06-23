#!/usr/bin/env bash
#
# publish.sh — Sync → build → commit → push
#
# Run this AFTER translating with the /translate skill in Claude Code.
# It syncs content, builds Hugo, and pushes to GitHub (CI auto-deploys).
#
# Usage: ./scripts/publish.sh [--no-push]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Locate hugo across platforms
find_hugo() {
    # 1. PATH
    if command -v hugo &>/dev/null; then
        echo "hugo"
        return
    fi
    # 2. Common per-user install locations
    local hugo_exe
    for candidate in \
        "$HOME/AppData/Local/Microsoft/WinGet/Links/hugo.exe" \
        "$HOME/AppData/Local/Microsoft/WinGet/Packages/Hugo.Hugo.Extended_"*"/hugo.exe" \
        /usr/local/bin/hugo \
        /opt/homebrew/bin/hugo \
        /home/linuxbrew/.linuxbrew/bin/hugo; do
        if [ -x "$candidate" ] 2>/dev/null; then
            echo "$candidate"
            return
        fi
    done
    # 3. Not found — instruct user
    echo "[ERROR] hugo not found on PATH or in common locations."
    echo "Install: https://gohugo.io/installation/"
    echo "  Windows: winget install Hugo.Hugo.Extended"
    echo "  macOS:   brew install hugo"
    echo "  Linux:   snap install hugo"
    exit 1
}

HUGO_BIN="$(find_hugo)"

NO_PUSH=false
for arg in "$@"; do
    case "$arg" in
        --no-push) NO_PUSH=true ;;
        *) echo "Unknown option: $arg"; exit 1 ;;
    esac
done

echo "============================================"
echo " Diving into WLAN — Publish Pipeline"
echo "============================================"
echo ""

# Step 1: Sync
echo "--- Step 1/3: Sync files ---"
bash "$SCRIPT_DIR/sync.sh" --force
echo ""

# Step 2: Check for untranslated files
echo "--- Step 2/3: Translation status ---"
uv run python "$SCRIPT_DIR/translate.py" --detect 2>&1 || true
echo "If files are listed above, run /translate in Claude Code before publishing."
echo ""

# Step 3: Build
echo "--- Step 3/3: Hugo build ---"
cd "$ROOT_DIR/hugo"
"$HUGO_BIN" --minify --cleanDestinationDir
echo ""

# Commit & push
if $NO_PUSH; then
    echo "--- Push skipped (--no-push) ---"
else
    echo "--- Commit & push ---"
    cd "$ROOT_DIR"
    if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
        git add -A
        git commit -m "publish: $(date '+%Y-%m-%d %H:%M')"
        echo "  Committed."
    else
        echo "  Nothing to commit."
    fi
    git push origin master 2>&1 || echo "  Push failed (check remote config)."
fi
echo ""
echo "============================================"
echo " Publish complete!"
echo "============================================"
