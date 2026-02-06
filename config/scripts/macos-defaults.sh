#!/bin/bash
# macOS Defaults Configuration for Development Environment
# This script applies developer-friendly macOS defaults.
# Run: mise run setup-mac

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}i${NC}  $1"; }
log_success() { echo -e "${GREEN}✓${NC}  $1"; }
log_warn() { echo -e "${YELLOW}!${NC}  $1"; }
log_step() { echo -e "\n${GREEN}▶${NC} $1"; }

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   🍎 macOS Developer Defaults                                 ║"
echo "║   Optimizing your Mac for development                         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# Finder Settings
# ============================================================================
log_step "Configuring Finder..."

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true
log_success "Show hidden files enabled"

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
log_success "Show all file extensions enabled"

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true
log_success "Path bar enabled"

# Show status bar in Finder
defaults write com.apple.finder ShowStatusBar -bool true
log_success "Status bar enabled"

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true
log_success "Folders sorted first"

# Disable warning when changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
log_success "Extension change warning disabled"

# Use list view by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
log_success "List view set as default"

# ============================================================================
# Dock Settings
# ============================================================================
log_step "Configuring Dock..."

# Autohide dock
defaults write com.apple.dock autohide -bool true
log_success "Dock autohide enabled"

# Speed up dock autohide animation
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.5
log_success "Dock animation speed optimized"

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false
log_success "Recent apps in Dock disabled"

# Minimize windows into their application icon
defaults write com.apple.dock minimize-to-application -bool true
log_success "Minimize to application icon enabled"

# ============================================================================
# Keyboard & Input
# ============================================================================
log_step "Configuring Keyboard..."

# Enable full keyboard access for all controls
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
log_success "Full keyboard access enabled"

# Disable press-and-hold for accent keys (enables key repeat)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
log_success "Key repeat enabled (accent popup disabled)"

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
log_success "Fast key repeat rate set"

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
log_success "Auto-correct disabled"

# Disable smart quotes and dashes (they mess with code)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
log_success "Smart quotes/dashes disabled"

# ============================================================================
# Screenshots
# ============================================================================
log_step "Configuring Screenshots..."

# Save screenshots to ~/Screenshots
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
log_success "Screenshots save to ~/Screenshots"

# Save screenshots as PNG
defaults write com.apple.screencapture type -string "png"
log_success "Screenshot format set to PNG"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true
log_success "Screenshot shadow disabled"

# ============================================================================
# Safari (for debugging)
# ============================================================================
log_step "Configuring Safari..."

# Safari is sandboxed since macOS Mojave - settings may require manual configuration
# Try non-sandboxed global setting first, then sandboxed domain
if defaults write com.apple.Safari IncludeDevelopMenu -bool true 2>/dev/null; then
  defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true 2>/dev/null || true
  defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true 2>/dev/null || true
  log_success "Safari Developer menu enabled"
else
  log_warn "Safari settings skipped (sandboxed - enable Developer menu manually in Safari > Settings > Advanced)"
fi

# Global WebKit setting (works without sandbox restrictions)
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true
log_success "Web Inspector enabled in web views"

# ============================================================================
# Terminal / iTerm2
# ============================================================================
log_step "Configuring Terminal..."

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4
log_success "Terminal UTF-8 encoding set"

# ============================================================================
# Security & Privacy (Developer-Friendly)
# ============================================================================
log_step "Configuring Security..."

# Allow apps downloaded from anywhere (requires manual step in System Preferences)
log_warn "Note: Allow apps from anywhere requires: sudo spctl --master-disable"
log_info "Run this manually if you trust all downloaded apps"

# ============================================================================
# Performance
# ============================================================================
log_step "Configuring Performance..."

# Disable animations for opening windows and popovers
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
log_success "Window animations disabled"

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1
log_success "Mission Control animation speed increased"

# ============================================================================
# Restart affected applications
# ============================================================================
log_step "Applying changes..."

# Kill affected applications
for app in "Finder" "Dock" "SystemUIServer"; do
    killall "$app" &> /dev/null || true
done

log_success "Settings applied!"

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   ✨ macOS Developer Defaults Applied!                        ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║   Some changes may require a logout/restart to take effect.   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
