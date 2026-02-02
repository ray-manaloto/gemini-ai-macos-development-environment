#!/bin/bash
set -euo pipefail

echo "=== God-Tier Dev Environment: Post-Create Setup ==="

WORKSPACE_DIR=$(find /workspaces -maxdepth 1 -type d ! -name workspaces | head -1)

if [ -n "$WORKSPACE_DIR" ] && [ -f "$WORKSPACE_DIR/config/mise.toml" ]; then
    mkdir -p ~/.config/mise
    cp "$WORKSPACE_DIR/config/mise.toml" ~/.config/mise/config.toml
    mise trust ~/.config/mise/config.toml
    echo "Copied mise config from $WORKSPACE_DIR"
    
    # Trust project-level .mise.toml if it exists
    if [ -f "$WORKSPACE_DIR/.mise.toml" ]; then
        mise trust "$WORKSPACE_DIR/.mise.toml"
        echo "Trusted project .mise.toml"
    fi
fi

mise install --yes

if command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
fi

echo "=== Verifying Installation ==="
mise doctor
mise ls --installed

echo "=== Post-Create Complete ==="
