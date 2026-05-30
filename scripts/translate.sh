#!/usr/bin/env bash
#
# translate.sh — Sync + detect files needing translation.
# Actual translation is done by Claude Code via the /translate skill.
#
# Usage:
#   ./scripts/translate.sh              # sync and check
#   ./scripts/translate.sh --status     # show translation coverage
#   ./scripts/translate.sh --reset      # clear translation cache
#   ./scripts/translate.sh --force      # sync, reset cache, re-detect all

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

case "${1:-}" in
    --status)
        uv run python "$SCRIPT_DIR/translate.py" --status
        ;;
    --reset)
        uv run python "$SCRIPT_DIR/translate.py" --reset
        ;;
    --force)
        bash "$SCRIPT_DIR/sync.sh" --force
        uv run python "$SCRIPT_DIR/translate.py" --reset
        echo ""
        uv run python "$SCRIPT_DIR/translate.py" --detect
        ;;
    *)
        bash "$SCRIPT_DIR/sync.sh" --force
        echo ""
        uv run python "$SCRIPT_DIR/translate.py" --detect
        echo ""
        echo "---"
        echo "Run /translate in Claude Code to translate these files."
        ;;
esac
