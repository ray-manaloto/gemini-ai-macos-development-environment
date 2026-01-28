#!/bin/bash
# God-Tier macOS Development Environment Uninstaller
# This script safely removes the mise-based development environment
# Run: ./uninstall.sh [--dry-run] [--force]

set -e

# Colors for output (matching setup.sh)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}i${NC}  $1"; }
log_success() { echo -e "${GREEN}✓${NC}  $1"; }
log_warn() { echo -e "${YELLOW}!${NC}  $1"; }
log_error() { echo -e "${RED}✗${NC}  $1"; }
log_step() { echo -e "\n${GREEN}▶${NC} $1"; }

# Parse arguments
DRY_RUN=false
FORCE=false

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --force)
            FORCE=true
            ;;
        --help|-h)
            echo "Usage: ./uninstall.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Preview what will be deleted without making changes"
            echo "  --force      Skip confirmation prompts"
            echo "  --help       Show this help message"
            echo ""
            echo "Exit codes:"
            echo "  0  Success"
            echo "  1  Cancelled by user"
            echo "  2  Error during uninstall"
            exit 0
            ;;
    esac
done

# Paths to remove
MISE_DATA="$HOME/.local/share/mise"
MISE_CONFIG="$HOME/.config/mise"
DEV_ENV_CONFIG="$HOME/.config/dev-env"
MISE_CACHE="$HOME/Library/Caches/mise"
MISE_STATE="$HOME/.local/state/mise"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   🗑️  God-Tier macOS Development Environment Uninstaller      ║"
echo "║   This will remove mise and all managed tools                 ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

if [ "$DRY_RUN" = true ]; then
    log_warn "DRY RUN MODE - No changes will be made"
    echo ""
fi

# ============================================================================
# Show what will be deleted
# ============================================================================
log_step "The following will be removed:"

echo ""
echo "  Directories:"
[ -d "$MISE_DATA" ] && echo "    - $MISE_DATA (binaries, ~$(du -sh "$MISE_DATA" 2>/dev/null | cut -f1 || echo "?"))" || echo "    - $MISE_DATA (not found)"
[ -d "$MISE_CONFIG" ] && echo "    - $MISE_CONFIG (configuration)" || echo "    - $MISE_CONFIG (not found)"
[ -d "$DEV_ENV_CONFIG" ] && echo "    - $DEV_ENV_CONFIG (dev-env config)" || echo "    - $DEV_ENV_CONFIG (not found)"
[ -d "$MISE_CACHE" ] && echo "    - $MISE_CACHE (cache)" || echo "    - $MISE_CACHE (not found)"
[ -d "$MISE_STATE" ] && echo "    - $MISE_STATE (state)" || echo "    - $MISE_STATE (not found)"

echo ""
echo "  Shell configuration:"
echo "    - Remove mise activation from ~/.zshrc"

echo ""
echo "  Optional:"
[ -f "$CLAUDE_SETTINGS" ] && echo "    - $CLAUDE_SETTINGS (MCP config)" || echo "    - $CLAUDE_SETTINGS (not found)"

echo ""

# ============================================================================
# Confirmation
# ============================================================================
if [ "$DRY_RUN" = true ]; then
    log_info "Dry run complete. No changes were made."
    exit 0
fi

if [ "$FORCE" != true ]; then
    echo ""
    log_warn "This action cannot be undone without reinstalling."
    echo ""
    
    # Try to use gum for nice prompts, fall back to read
    if command -v gum &> /dev/null; then
        if ! gum confirm "Are you sure you want to uninstall?"; then
            log_info "Uninstall cancelled."
            exit 1
        fi
    else
        read -p "Are you sure you want to uninstall? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Uninstall cancelled."
            exit 1
        fi
    fi
fi

# ============================================================================
# Create backup
# ============================================================================
log_step "Creating backup..."

BACKUP_DIR="$HOME/mise-backup-$(date +%Y%m%d-%H%M%S)"

if [ -d "$MISE_CONFIG" ]; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$MISE_CONFIG" "$BACKUP_DIR/mise-config" 2>/dev/null || true
    log_success "Configuration backed up to: $BACKUP_DIR"
else
    log_info "No configuration to backup"
fi

# ============================================================================
# Remove mise data
# ============================================================================
log_step "Removing mise data..."

if [ -d "$MISE_DATA" ]; then
    rm -rf "$MISE_DATA"
    log_success "Removed $MISE_DATA"
else
    log_info "$MISE_DATA not found"
fi

# ============================================================================
# Remove mise configuration
# ============================================================================
log_step "Removing mise configuration..."

if [ -d "$MISE_CONFIG" ]; then
    rm -rf "$MISE_CONFIG"
    log_success "Removed $MISE_CONFIG"
else
    log_info "$MISE_CONFIG not found"
fi

if [ -d "$DEV_ENV_CONFIG" ]; then
    rm -rf "$DEV_ENV_CONFIG"
    log_success "Removed $DEV_ENV_CONFIG"
else
    log_info "$DEV_ENV_CONFIG not found"
fi

# ============================================================================
# Remove mise cache and state
# ============================================================================
log_step "Removing mise cache and state..."

if [ -d "$MISE_CACHE" ]; then
    rm -rf "$MISE_CACHE"
    log_success "Removed $MISE_CACHE"
else
    log_info "$MISE_CACHE not found"
fi

if [ -d "$MISE_STATE" ]; then
    rm -rf "$MISE_STATE"
    log_success "Removed $MISE_STATE"
else
    log_info "$MISE_STATE not found"
fi

# ============================================================================
# Remove mise binary
# ============================================================================
log_step "Removing mise binary..."

if [ -f "$HOME/.local/bin/mise" ]; then
    rm -f "$HOME/.local/bin/mise"
    log_success "Removed ~/.local/bin/mise"
else
    log_info "mise binary not found in ~/.local/bin"
fi

# ============================================================================
# Clean up shell configuration
# ============================================================================
log_step "Cleaning up shell configuration..."

if [ -f "$HOME/.zshrc" ]; then
    # Create backup of .zshrc
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak-$(date +%Y%m%d-%H%M%S)"
    
    # Remove mise-related lines
    sed -i '' '/# Mise - Tool Version Manager/d' "$HOME/.zshrc" 2>/dev/null || true
    sed -i '' '/mise activate/d' "$HOME/.zshrc" 2>/dev/null || true
    sed -i '' '/eval "$(.*mise/d' "$HOME/.zshrc" 2>/dev/null || true
    
    log_success "Removed mise activation from ~/.zshrc"
    log_info "Backup saved to ~/.zshrc.bak-*"
else
    log_info "~/.zshrc not found"
fi

# ============================================================================
# Optional: Remove MCP configuration
# ============================================================================
if [ -f "$CLAUDE_SETTINGS" ]; then
    log_step "MCP configuration found..."
    
    if [ "$FORCE" = true ]; then
        REMOVE_MCP="y"
    else
        if command -v gum &> /dev/null; then
            if gum confirm "Remove mise MCP configuration from Claude?"; then
                REMOVE_MCP="y"
            else
                REMOVE_MCP="n"
            fi
        else
            read -p "Remove mise MCP configuration from Claude? (y/N) " -n 1 -r REMOVE_MCP
            echo ""
        fi
    fi
    
    if [[ $REMOVE_MCP =~ ^[Yy]$ ]]; then
        # Backup Claude settings
        cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.bak-$(date +%Y%m%d-%H%M%S)"
        
        # Remove mise server from MCP config (simplified - just notes it)
        log_warn "Please manually remove 'mise' entry from $CLAUDE_SETTINGS"
        log_info "Backup saved to $CLAUDE_SETTINGS.bak-*"
    else
        log_info "Keeping MCP configuration"
    fi
fi

# ============================================================================
# Verification
# ============================================================================
log_step "Verifying uninstall..."

ERRORS=0

if [ -d "$MISE_DATA" ]; then
    log_error "Failed to remove $MISE_DATA"
    ERRORS=$((ERRORS + 1))
fi

if [ -d "$MISE_CONFIG" ]; then
    log_error "Failed to remove $MISE_CONFIG"
    ERRORS=$((ERRORS + 1))
fi

if command -v mise &> /dev/null; then
    log_warn "mise command still available (may be in another location)"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"

if [ $ERRORS -eq 0 ]; then
    echo "║   ✨ Uninstall Complete!                                      ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║   - Configuration backed up to: ~/mise-backup-*              ║"
    echo "║   - Please restart your terminal or run: source ~/.zshrc     ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    exit 0
else
    echo "║   ⚠️  Uninstall completed with $ERRORS error(s)                  ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║   Some files may need manual removal.                        ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    exit 2
fi
