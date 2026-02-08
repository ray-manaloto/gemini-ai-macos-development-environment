#!/bin/bash
# =============================================================================
# validate.sh - Environment Health Check
# God-Tier macOS Development Environment
# =============================================================================
# Run with: mise run validate
# Also runs as mandatory pre-commit check via lefthook
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS=0
WARN=0
FAIL=0

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

check_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    (( ++PASS ))
}

check_warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    (( ++WARN ))
}

check_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    (( ++FAIL ))
}

check_info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $1"
}

section() {
    echo ""
    echo -e "${BLUE}━━━ $1 ━━━${NC}"
}

# -----------------------------------------------------------------------------
# Checks
# -----------------------------------------------------------------------------

echo "🏥 Running Environment Health Check..."
echo "   $(date)"

# --- Mise ---
section "Mise (Orchestrator)"

if command -v mise &> /dev/null; then
    MISE_VERSION=$(mise --version)
    check_pass "Mise installed: $MISE_VERSION"

    # Check mise doctor
    if mise doctor &> /dev/null; then
        check_pass "Mise doctor: no critical issues"
    else
        check_warn "Mise doctor reported issues (run 'mise doctor' for details)"
    fi

    # Check experimental features
    if mise config get settings.experimental 2>/dev/null | grep -q "true"; then
        check_pass "Mise experimental features enabled"
    else
        check_warn "Mise experimental features not enabled"
    fi

    # Check node backend
    NODE_BACKEND=$(mise config get settings.node_backend 2>/dev/null || echo "")
    if [ "$NODE_BACKEND" = "bun" ]; then
        check_pass "Mise node_backend = bun"
    else
        NPM_PM=$(mise config get settings.npm.package_manager 2>/dev/null || echo "not set")
        if [ "$NPM_PM" = "bun" ]; then
            check_pass "Mise npm package_manager = bun"
        else
            check_warn "Mise node_backend = ${NODE_BACKEND:-not set} (expected: bun)"
        fi
    fi

    # Check pip backend
    PIP_BACKEND=$(mise config get settings.pip_backend 2>/dev/null || echo "")
    if [ "$PIP_BACKEND" = "uv" ]; then
        check_pass "Mise pip_backend = uv"
    else
        UV_AUTO=$(mise config get settings.python.uv_venv_auto 2>/dev/null || echo "not set")
        if [ "$UV_AUTO" = "true" ]; then
            check_pass "Mise python uv_venv_auto = true"
        else
            check_warn "Mise pip_backend = ${PIP_BACKEND:-not set} (expected: uv)"
        fi
    fi
else
    check_fail "Mise not installed"
fi

# --- Core Runtimes ---
section "Core Runtimes"

# Bun
if command -v bun &> /dev/null; then
    BUN_VERSION=$(bun --version)
    check_pass "Bun installed: $BUN_VERSION"
else
    check_warn "Bun not installed"
fi

# Uv
if command -v uv &> /dev/null; then
    UV_VERSION=$(uv --version 2>&1 | head -1)
    check_pass "Uv installed: $UV_VERSION"
else
    check_warn "Uv not installed"
fi

# Pixi
if command -v pixi &> /dev/null; then
    PIXI_VERSION=$(pixi --version)
    check_pass "Pixi installed: $PIXI_VERSION"
else
    check_warn "Pixi not installed"
fi

# --- Python Isolation ---
section "Python Isolation"

if command -v python &> /dev/null; then
    PY_PATH=$(which python)
    if [[ "$PY_PATH" == *"/usr/bin/"* ]]; then
        check_fail "Using system Python: $PY_PATH"
        check_info "Python should be managed by mise/pixi/uv"
    else
        check_pass "Python isolated: $PY_PATH"
    fi
else
    check_info "Python not in PATH (will be installed per-project)"
fi

# --- Shell Tools ---
section "Shell Tools"

# Starship
if command -v starship &> /dev/null; then
    STARSHIP_VERSION=$(starship --version | head -1)
    check_pass "Starship installed: $STARSHIP_VERSION"

    # Check config exists
    if [ -f "$HOME/.config/starship.toml" ]; then
        check_pass "Starship config exists"
    else
        check_warn "Starship config not found at ~/.config/starship.toml"
    fi
else
    check_warn "Starship not installed"
fi

# Zoxide
if command -v zoxide &> /dev/null; then
    ZOXIDE_VERSION=$(zoxide --version)
    check_pass "Zoxide installed: $ZOXIDE_VERSION"
else
    check_warn "Zoxide not installed"
fi

# --- Search Tools ---
section "Search Tools"

# Ripgrep
if command -v rg &> /dev/null; then
    RG_VERSION=$(rg --version | head -1)
    check_pass "Ripgrep installed: $RG_VERSION"
else
    check_warn "Ripgrep not installed"
fi

# fd
if command -v fd &> /dev/null; then
    FD_VERSION=$(fd --version)
    check_pass "fd installed: $FD_VERSION"
else
    check_warn "fd not installed"
fi

# ast-grep
if command -v sg &> /dev/null; then
    SG_VERSION=$(sg --version 2>&1 | head -1)
    check_pass "ast-grep installed: $SG_VERSION"
else
    check_warn "ast-grep (sg) not installed"
fi

# --- Dotfile Management ---
section "Dotfile Management"

# Chezmoi
if command -v chezmoi &> /dev/null; then
    CHEZMOI_VERSION=$(chezmoi --version | head -1)
    check_pass "Chezmoi installed: $CHEZMOI_VERSION"
else
    check_warn "Chezmoi not installed"
fi

# --- Secrets ---
section "Secrets Management"

# 1Password CLI
if command -v op &> /dev/null; then
    OP_VERSION=$(op --version)
    check_pass "1Password CLI installed: $OP_VERSION"
else
    check_warn "1Password CLI not installed"
fi

# Infisical
if command -v infisical &> /dev/null; then
    check_pass "Infisical installed"
else
    check_info "Infisical not installed (optional)"
fi

# --- Containers ---
section "Containers"

# OrbStack
if command -v orb &> /dev/null; then
    check_pass "OrbStack available"
    if orb status &> /dev/null; then
        check_pass "OrbStack running"
    else
        check_warn "OrbStack not running"
    fi
elif command -v docker &> /dev/null; then
    check_pass "Docker available (not OrbStack)"
else
    check_warn "No container runtime found"
fi

# DevPod
if command -v devpod &> /dev/null; then
    check_pass "DevPod installed"
else
    check_info "DevPod not installed (optional)"
fi

# --- Cloud ---
section "Cloud (SkyPilot)"

if command -v sky &> /dev/null; then
    check_pass "SkyPilot installed"
    if sky check &> /dev/null 2>&1; then
        check_pass "SkyPilot configured with cloud credentials"
    else
        check_warn "SkyPilot cloud credentials not configured"
    fi
else
    check_warn "SkyPilot not installed"
fi

# --- AI Tools ---
section "AI Tools"

# GitHub CLI
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -1)
    check_pass "GitHub CLI installed: $GH_VERSION"

    # Check auth
    if gh auth status &> /dev/null 2>&1; then
        check_pass "GitHub CLI authenticated"
    else
        check_warn "GitHub CLI not authenticated (run 'gh auth login')"
    fi
else
    check_warn "GitHub CLI not installed"
fi

# --- Summary ---
section "Summary"

TOTAL=$((PASS + WARN + FAIL))
echo ""
echo "Results: $PASS passed, $WARN warnings, $FAIL failed (out of $TOTAL checks)"
echo ""

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}❌ Environment has critical issues that need attention.${NC}"
    exit 1
elif [ $WARN -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Environment is functional but has some warnings.${NC}"
    echo "   Run 'mise install' to install missing tools."
    exit 0
else
    echo -e "${GREEN}✅ Environment is fully configured and healthy!${NC}"
    exit 0
fi
