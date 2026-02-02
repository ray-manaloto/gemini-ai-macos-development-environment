#!/bin/bash
set -euo pipefail

echo "=== Verifying Environment ==="
mise doctor

ERRORS=0

check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo "MISSING: $1"
        ERRORS=$((ERRORS + 1))
    else
        echo "OK: $1 ($(command -v "$1"))"
    fi
}

check_tool bun
check_tool node
check_tool uv
check_tool pixi
check_tool starship
check_tool rg
check_tool fd
check_tool gh

if [ $ERRORS -gt 0 ]; then
    echo "WARNING: $ERRORS tool(s) missing. Run: mise install"
    exit 1
fi

echo "=== Environment Ready ==="
