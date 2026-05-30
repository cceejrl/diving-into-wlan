#!/usr/bin/env bash
#
# setup.sh — First-run setup for a new machine.
# Installs required tools, pulls submodules, and verifies the build.
#
# Usage: bash scripts/setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[--]${NC} $*"; }
err()  { echo -e "${RED}[!!]${NC} $*"; }

echo "============================================"
echo " Diving into WLAN — First-run Setup"
echo "============================================"
echo ""

detect_os() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        Darwin)                echo "macos" ;;
        Linux)                 echo "linux" ;;
        *)                     echo "unknown" ;;
    esac
}

OS="$(detect_os)"

# ---- git ----
echo "--- Checking git ---"
if command -v git &>/dev/null; then
    log "git $(git --version | awk '{print $3}')"
else
    err "git is required. Install: https://git-scm.com/"
    exit 1
fi

# ---- Hugo ----
echo "--- Checking Hugo ---"
if command -v hugo &>/dev/null; then
    log "hugo $(hugo version | awk '{print $2}' | sed 's/-.*//')"
else
    warn "Hugo not found. Attempting install..."
    case "$OS" in
        windows)
            winget install Hugo.Hugo.Extended --accept-source-agreements --accept-package-agreements \
                || { err "Install failed. Try: winget install Hugo.Hugo.Extended"; exit 1; }
            ;;
        macos)
            brew install hugo \
                || { err "Install failed. Try: brew install hugo"; exit 1; }
            ;;
        linux)
            if command -v snap &>/dev/null; then
                sudo snap install hugo \
                    || { err "Install failed. Try: sudo snap install hugo"; exit 1; }
            else
                err "Install Hugo manually: https://gohugo.io/installation/linux/"
                exit 1
            fi
            ;;
        *)
            err "Unknown OS. Install Hugo manually: https://gohugo.io/installation/"
            exit 1
            ;;
    esac
    log "Hugo installed."
fi

# ---- uv (Python) ----
echo "--- Checking uv ---"
if command -v uv &>/dev/null; then
    log "uv $(uv --version | awk '{print $2}')"
else
    warn "uv not found. Installing..."
    case "$OS" in
        windows)
            powershell -Command "irm https://astral.sh/uv/install.ps1 | iex" \
                || { err "Install failed. Visit: https://docs.astral.sh/uv/"; exit 1; }
            ;;
        macos|linux)
            curl -LsSf https://astral.sh/uv/install.sh | sh \
                || { err "Install failed. Visit: https://docs.astral.sh/uv/"; exit 1; }
            ;;
    esac
    log "uv installed. Restart your shell if 'uv' is not found."
fi

# ---- Submodules ----
echo "--- Pulling git submodules ---"
cd "$ROOT_DIR"
git submodule update --init --recursive
log "Submodules ready."

# ---- Build test ----
echo "--- Build test ---"
cd "$ROOT_DIR/hugo"
hugo --minify 2>&1 || {
    warn "Build failed (this is OK if repo has no posts yet — try: hugo server --buildDrafts)"
}
log "Hugo build check complete."

echo ""
echo "============================================"
echo " Setup complete!"
echo ""
echo " Next steps:"
echo "   1. Open obsidian-vault/ in Obsidian"
echo "   2. Write posts in obsidian-vault/posts/"
echo "   3. cd hugo && hugo server   (preview)"
echo "   4. Say 'publish' in Claude Code to ship!"
echo "============================================"
