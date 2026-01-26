#!/bin/bash
set -e

# God-Tier macOS Development Environment Setup
# This script bootstraps a complete development environment using mise-first philosophy
# Run: ./setup.sh

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STABLE_DIR="$HOME/.config/dev-env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ${NC}  $1"; }
log_success() { echo -e "${GREEN}✓${NC}  $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
log_error() { echo -e "${RED}✗${NC}  $1"; }
log_step() { echo -e "\n${GREEN}▶${NC} $1"; }

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   🚀 God-Tier macOS Development Environment                   ║"
echo "║   Mise-First Philosophy: Mise > Bun > Pixi > Uv              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# STEP 1: Install Mise (The Orchestrator)
# ============================================================================
log_step "Installing Mise (Tool Version Manager)..."

if command -v mise &> /dev/null; then
    log_success "Mise already installed: $(mise --version)"
else
    log_info "Installing Mise..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"

    # Add to shell rc if not already present
    if ! grep -q 'mise activate' ~/.zshrc 2>/dev/null; then
        echo '' >> ~/.zshrc
        echo '# Mise - Tool Version Manager' >> ~/.zshrc
        echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc
    fi

    log_success "Mise installed: $(mise --version)"
fi

# Activate mise for this session
eval "$(mise activate bash)"

# ============================================================================
# STEP 2: Establish Stable Path
# ============================================================================
log_step "Establishing stable configuration path..."

mkdir -p "$(dirname "$STABLE_DIR")"
if [ -L "$STABLE_DIR" ] && [ "$(readlink "$STABLE_DIR")" = "$REPO_DIR" ]; then
    log_success "Stable path already configured: $STABLE_DIR"
else
    ln -sfn "$REPO_DIR" "$STABLE_DIR"
    log_success "Linked $REPO_DIR → $STABLE_DIR"
fi

# ============================================================================
# STEP 3: Install Core Generator Tools
# ============================================================================
log_step "Installing core generator tools (Pkl, Pixi, Gum)..."

mise use -g pkl prefix-dev/pixi charmbracelet/gum
log_success "Generator tools installed"

# ============================================================================
# STEP 4: Install Bun (Node Backend)
# ============================================================================
log_step "Installing Bun (JavaScript runtime)..."

mise use -g bun
log_success "Bun installed: $(bun --version)"

# ============================================================================
# STEP 5: Install Uv (Python Backend)
# ============================================================================
log_step "Installing Uv (Python package manager)..."

mise use -g uv
log_success "Uv installed: $(uv --version)"

# ============================================================================
# STEP 6: Install Starship (Cross-Shell Prompt)
# ============================================================================
log_step "Installing Starship (shell prompt)..."

if command -v starship &> /dev/null; then
    log_success "Starship already installed: $(starship --version)"
else
    mise use -g starship
    log_success "Starship installed"
fi

# Copy starship config
if [ -f "$REPO_DIR/config/starship.toml" ]; then
    mkdir -p ~/.config
    cp "$REPO_DIR/config/starship.toml" ~/.config/starship.toml
    log_success "Starship config installed to ~/.config/starship.toml"
fi

# ============================================================================
# STEP 7: Install Chezmoi (Dotfile Manager)
# ============================================================================
log_step "Installing Chezmoi (dotfile manager)..."

if command -v chezmoi &> /dev/null; then
    log_success "Chezmoi already installed: $(chezmoi --version | head -1)"
else
    mise use -g chezmoi
    log_success "Chezmoi installed"
fi

# ============================================================================
# STEP 8: Generate Mise Configuration
# ============================================================================
log_step "Generating Mise configuration from Pkl..."

mkdir -p ~/.config/mise
if command -v pkl &> /dev/null && [ -f "$STABLE_DIR/config/main.pkl" ]; then
    pkl eval -f toml "$STABLE_DIR/config/main.pkl" > ~/.config/mise/config.toml
    log_success "Configuration generated: ~/.config/mise/config.toml"
else
    log_warn "Pkl not available or main.pkl not found - using default config"
fi

# ============================================================================
# STEP 9: Install Full Tool Stack
# ============================================================================
log_step "Installing full tool stack via Mise..."

mise install
log_success "All tools installed"

# ============================================================================
# STEP 10: Initialize Chezmoi (Optional)
# ============================================================================
log_step "Setting up Chezmoi templates..."

if [ -d "$REPO_DIR/config/chezmoi" ]; then
    # Initialize chezmoi if not already done
    if [ ! -d "$HOME/.local/share/chezmoi" ]; then
        chezmoi init
    fi

    # Copy templates to chezmoi source
    cp -r "$REPO_DIR/config/chezmoi/"* "$HOME/.local/share/chezmoi/" 2>/dev/null || true
    log_success "Chezmoi templates copied"
    log_info "Run 'chezmoi apply' to apply dotfile templates"
else
    log_warn "Chezmoi templates not found in config/chezmoi/"
fi

# ============================================================================
# STEP 11: Install Additional CLI Tools
# ============================================================================
log_step "Installing additional CLI tools..."

# Core utilities
mise use -g zoxide fd ripgrep bat eza fzf jq yq delta
log_success "CLI tools installed"

# ============================================================================
# STEP 12: Setup Dashboard (Optional)
# ============================================================================
log_step "Setting up dashboard environment..."

if [ -f "$REPO_DIR/pixi.toml" ]; then
    cd "$REPO_DIR"
    pixi install
    log_success "Dashboard environment ready"
else
    log_warn "pixi.toml not found - skipping dashboard setup"
fi

# ============================================================================
# STEP 13: SwiftBar Integration (Optional)
# ============================================================================
if [ -d "/Applications/SwiftBar.app" ]; then
    log_step "Configuring SwiftBar menu bar integration..."
    defaults write com.ameba.SwiftBar PluginDirectory "$STABLE_DIR/config/scripts"
    open -a SwiftBar
    log_success "SwiftBar configured"
else
    log_info "SwiftBar not installed - menu bar status skipped"
    log_info "Install from: https://swiftbar.app"
fi

# ============================================================================
# COMPLETE
# ============================================================================
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   ✨ Setup Complete!                                          ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║   Next steps:                                                 ║"
echo "║   1. Restart your terminal (or run: source ~/.zshrc)         ║"
echo "║   2. Run: chezmoi apply  (to apply dotfile templates)        ║"
echo "║   3. Run: mise doctor    (to verify installation)            ║"
echo "║   4. Run: ./config/scripts/validate.sh (health check)        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Show installed versions
log_step "Installed versions:"
echo "  mise:     $(mise --version 2>/dev/null || echo 'not found')"
echo "  bun:      $(bun --version 2>/dev/null || echo 'not found')"
echo "  uv:       $(uv --version 2>/dev/null | head -1 || echo 'not found')"
echo "  pixi:     $(pixi --version 2>/dev/null || echo 'not found')"
echo "  starship: $(starship --version 2>/dev/null | head -1 || echo 'not found')"
echo "  chezmoi:  $(chezmoi --version 2>/dev/null | head -1 || echo 'not found')"
echo ""
