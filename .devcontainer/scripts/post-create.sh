#!/bin/bash
set -euo pipefail

echo "=== God-Tier Dev Environment: Post-Create Setup ==="

if command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
fi

WORKSPACE_DIR="${WORKSPACE_DIR:-$(find /workspaces -maxdepth 1 -type d ! -name workspaces 2>/dev/null | head -1)}"

if [ -n "$WORKSPACE_DIR" ]; then
    if [ -f "$WORKSPACE_DIR/config/mise.toml" ]; then
        mkdir -p ~/.config/mise
        cp "$WORKSPACE_DIR/config/mise.toml" ~/.config/mise/config.toml
        mise trust ~/.config/mise/config.toml
        echo "Copied mise config from $WORKSPACE_DIR"
    fi
    
    if [ -f "$WORKSPACE_DIR/.mise.toml" ]; then
        mise trust "$WORKSPACE_DIR/.mise.toml"
        echo "Trusted project .mise.toml"
    fi
fi

echo "Installing mise tools..."
mise install --yes 2>&1 | tail -10

if [ -d /commandhistory ]; then
    mkdir -p /commandhistory
    touch /commandhistory/.zsh_history
    if ! grep -q 'HISTFILE=/commandhistory' ~/.zshrc 2>/dev/null; then
        echo 'export HISTFILE=/commandhistory/.zsh_history' >> ~/.zshrc
    fi
fi

echo ""
echo "=== Verifying Installation ==="
mise doctor || true
echo ""
mise ls --installed | head -20

echo ""
echo "=== Post-Create Complete ==="
