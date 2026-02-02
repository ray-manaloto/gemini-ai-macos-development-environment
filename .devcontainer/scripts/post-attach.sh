#!/bin/bash
set -euo pipefail

echo "=== Verifying Environment ==="

if command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
    mise doctor || true
fi

ERRORS=0

check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo "MISSING: $1"
        ERRORS=$((ERRORS + 1))
    else
        echo "OK: $1"
    fi
}

echo ""
echo "=== Tool Check ==="
check_tool bun
check_tool node
check_tool uv
check_tool pixi
check_tool starship
check_tool rg
check_tool fd
check_tool gh

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "WARNING: $ERRORS tool(s) missing. Running: mise install"
    mise install --yes || true
fi

if [ -d /commandhistory ]; then
    touch /commandhistory/.zsh_history
    export HISTFILE=/commandhistory/.zsh_history
fi

echo ""
echo "=== Environment Ready ==="
echo "Run 'mise run env:status' for full status"
