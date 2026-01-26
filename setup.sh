#!/bin/bash
set -e

# We symlink this repo to a stable location so Pkl paths always work
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STABLE_DIR="$HOME/.config/dev-env"

echo "🚀 Bootstrapping God-Tier Environment..."

# 1. Install Mise (The Manager) - User Space Only
if ! command -v mise &> /dev/null; then
    echo "📦 Installing Mise..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
    eval "$(mise activate zsh)"
fi

# 2. Establish Stable Path (Symlink Repo)
echo "🔗 Linking repository to $STABLE_DIR..."
mkdir -p "$(dirname "$STABLE_DIR")"
ln -sfn "$REPO_DIR" "$STABLE_DIR"

# 3. Install Generator Tools (Pkl, Pixi, Gum)
echo "⚡ Installing Generator Tools..."
mise use -g pkl ubj/gum prefix-dev/pixi

# 4. Generate Configuration (Pkl -> TOML)
echo "🎯 Compiling Configuration..."
mkdir -p ~/.config/mise
# We use the stable path for the source to ensure hygiene
pkl eval -f toml "$STABLE_DIR/config/main.pkl" > ~/.config/mise/config.toml

# 5. Install Full Stack
echo "💧 Hydrating Environment (Mise > Bun > Pixi > Uv)..."
mise install

# 6. Initialize Dashboard Dependencies (Local Pixi Env)
echo "🐍 Setting up Dashboard Environment..."
pixi install

# 7. Setup SwiftBar (Menu Bar)
if [ -d "/Applications/SwiftBar.app" ]; then
    echo "🖥️  Configuring Menu Bar..."
    defaults write com.ameba.SwiftBar PluginDirectory "$STABLE_DIR/config/scripts"
    open -a SwiftBar
else
    echo "⚠️  SwiftBar not found. Install from https://swiftbar.app for menu bar status."
fi

echo "✨ Done. Run 'mise run dashboard' to start."
