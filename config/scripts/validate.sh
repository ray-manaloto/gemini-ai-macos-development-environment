#!/bin/bash
# =============================================================================
# validate.sh - Environment Health Check
# God-Tier macOS Development Environment
# =============================================================================
# Run with: mise run validate
# Also runs as mandatory pre-commit check via lefthook
# Options:
#   --strict    Treat warnings as failures (exit 1 on any warning)
#   --quiet     Only output summary
#   --autofix   Run autofix to migrate non-mise installs
# =============================================================================

set -euo pipefail

# Parse arguments
STRICT_MODE=false
QUIET_MODE=false
AUTOFIX_MODE=false
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT_MODE=true ;;
    --quiet) QUIET_MODE=true ;;
    --autofix) AUTOFIX_MODE=true ;;
  esac
done

# Resolve script root for auxiliary scripts
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT_ROOT="${DEV_ENV_ROOT:-$PROJECT_ROOT}"

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
REQUIRED_WARN=0

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

check_pass() {
    local message="$1"
    local detail="${2:-}"
    if [ -n "$detail" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $message - $detail"
    else
        echo -e "${GREEN}✅ PASS${NC}: $message"
    fi
    PASS=$((PASS + 1))
}

check_warn() {
    local message="$1"
    local detail="${2:-}"
    if [ -n "$detail" ]; then
        echo -e "${YELLOW}⚠️  WARN${NC}: $message - $detail"
    else
        echo -e "${YELLOW}⚠️  WARN${NC}: $message"
    fi
    WARN=$((WARN + 1))
}

check_warn_required() {
    local message="$1"
    local detail="${2:-}"
    if [ -n "$detail" ]; then
        echo -e "${YELLOW}⚠️  WARN${NC}: $message - $detail"
    else
        echo -e "${YELLOW}⚠️  WARN${NC}: $message"
    fi
    WARN=$((WARN + 1))
    REQUIRED_WARN=$((REQUIRED_WARN + 1))
}

check_fail() {
    local message="$1"
    local detail="${2:-}"
    if [ -n "$detail" ]; then
        echo -e "${RED}❌ FAIL${NC}: $message - $detail"
    else
        echo -e "${RED}❌ FAIL${NC}: $message"
    fi
    FAIL=$((FAIL + 1))
}

check_info() {
    local message="$1"
    local detail="${2:-}"
    if [ -n "$detail" ]; then
        echo -e "${BLUE}ℹ️  INFO${NC}: $message - $detail"
    else
        echo -e "${BLUE}ℹ️  INFO${NC}: $message"
    fi
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

    # Check npm settings (bun backend)
    NPM_BUN=$(mise settings get npm.bun 2>/dev/null || echo "not set")
    NPM_PM=$(mise settings get npm.package_manager 2>/dev/null || echo "not set")
    if [ "$NPM_BUN" = "true" ] || [ "$NPM_PM" = "bun" ]; then
        check_pass "Mise npm backend = bun"
    else
        check_warn "Mise npm.bun = $NPM_BUN, npm.package_manager = $NPM_PM (expected: npm.bun=true or package_manager=bun)"
    fi

    # Check python settings (uv venv auto)
    UV_VENV=$(mise settings get python.uv_venv_auto 2>/dev/null || echo "not set")
    if [ "$UV_VENV" = "true" ]; then
        check_pass "Mise python.uv_venv_auto = true"
    else
        check_warn "Mise python.uv_venv_auto = $UV_VENV (expected: true)"
    fi

    PY_COMPILE=$(mise settings get python.compile 2>/dev/null || echo "not set")
    if [ "$PY_COMPILE" = "false" ]; then
        check_pass "Mise python.compile = false"
    else
        check_warn "Mise python.compile = $PY_COMPILE (expected: false)"
    fi

    PIPX_UVX=$(mise settings get pipx.uvx 2>/dev/null || echo "not set")
    if [ "$PIPX_UVX" = "true" ]; then
        check_pass "Mise pipx.uvx = true"
    else
        check_warn "Mise pipx.uvx = $PIPX_UVX (expected: true)"
    fi

    # Check shell aliases for npm/npx/pip
    NPM_ALIAS=$(mise shell-alias get npm 2>/dev/null || echo "not set")
    NPX_ALIAS=$(mise shell-alias get npx 2>/dev/null || echo "not set")
    PIP_ALIAS=$(mise shell-alias get pip 2>/dev/null || echo "not set")
    if [ "$NPM_ALIAS" = "bun" ] && [ "$NPX_ALIAS" = "bunx" ] && [ "$PIP_ALIAS" = "uv pip" ]; then
        check_pass "Shell aliases for npm/npx/pip"
    else
        check_warn "Shell aliases" "npm=$NPM_ALIAS npx=$NPX_ALIAS pip=$PIP_ALIAS (expected bun/bunx/uv pip)"
    fi
else
    check_fail "Mise not installed"
fi

section "PATH Configuration"

MISE_IN_PATH=false
if echo "$PATH" | grep -q "mise/shims"; then
    check_pass "Mise shims mode: shims in PATH"
    MISE_IN_PATH=true
elif echo "$PATH" | grep -q "mise/installs"; then
    check_pass "Mise activation mode: tool paths in PATH"
    MISE_IN_PATH=true
fi

if [ "$MISE_IN_PATH" = "false" ]; then
    if grep -q "mise activate" "$HOME/.zshrc" 2>/dev/null; then
        check_pass "Mise activation configured in ~/.zshrc (restart shell to apply)"
    else
        check_warn_required "Mise NOT in PATH (add to ~/.zshrc: eval \"\$(mise activate zsh)\")"
    fi
fi

# Verify activation hooks across common shells
if ! grep -q "mise activate" "$HOME/.zshrc" 2>/dev/null; then
    check_warn_required "Mise activation missing in ~/.zshrc" "Add: eval \"\$(mise activate zsh)\""
fi
if [ -f "$HOME/.bashrc" ] && ! grep -q "mise activate" "$HOME/.bashrc" 2>/dev/null; then
    check_warn_required "Mise activation missing in ~/.bashrc" "Add: eval \"\$(mise activate bash)\""
fi
if [ -f "$HOME/.bash_profile" ] && ! grep -q "mise activate" "$HOME/.bash_profile" 2>/dev/null; then
    check_warn_required "Mise activation missing in ~/.bash_profile" "Add: eval \"\$(mise activate bash)\""
fi

if [ -d "$HOME/.local/share/mise/shims" ]; then
    SHIM_COUNT=$(ls -1 "$HOME/.local/share/mise/shims" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$SHIM_COUNT" -gt 0 ]; then
        check_pass "Shims directory has $SHIM_COUNT shims"
    else
        check_warn_required "Shims directory is empty (run: mise reshim)"
    fi
else
    check_warn_required "Shims directory missing"
fi

if [ -L "$HOME/.config/dev-env" ] || [ -d "$HOME/.config/dev-env" ]; then
    check_pass "Config symlink exists: ~/.config/dev-env"
else
    check_warn "Config symlink missing (run setup.sh)"
fi

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

# --- Code Quality ---
section "Code Quality Tools"

if command -v shellcheck &> /dev/null; then
    SHELLCHECK_PATH=$(mise which shellcheck 2>/dev/null || command -v shellcheck)
    if echo "$SHELLCHECK_PATH" | grep -q "installs/aqua"; then
        check_pass "shellcheck (aqua)" "$SHELLCHECK_PATH"
    else
        check_warn "shellcheck backend" "Expected aqua install (current: $SHELLCHECK_PATH)"
    fi
else
    check_warn "shellcheck" "Not installed"
fi

if command -v hadolint &> /dev/null; then
    HADOLINT_PATH=$(mise which hadolint 2>/dev/null || command -v hadolint)
    if echo "$HADOLINT_PATH" | grep -q "installs/aqua"; then
        check_pass "hadolint (aqua)" "$HADOLINT_PATH"
    else
        check_warn "hadolint backend" "Expected aqua install (current: $HADOLINT_PATH)"
    fi
else
    check_warn "hadolint" "Not installed"
fi

if command -v biome &> /dev/null; then
    BIOME_PATH=$(mise which biome 2>/dev/null || command -v biome)
    check_pass "biome" "$BIOME_PATH"
else
    check_warn "biome" "Not installed"
fi

# Rust native linters/formatters
if command -v rustup &> /dev/null; then
    RUST_COMPONENTS=$(rustup component list --installed 2>/dev/null || echo "")
    if echo "$RUST_COMPONENTS" | grep -q "clippy"; then
        check_pass "rust clippy" "Installed via rustup"
    else
        check_warn "rust clippy" "Missing (rustup component add clippy)"
    fi
    if echo "$RUST_COMPONENTS" | grep -q "rustfmt"; then
        check_pass "rustfmt" "Installed via rustup"
    else
        check_warn "rustfmt" "Missing (rustup component add rustfmt)"
    fi
else
    check_info "rustup not installed (optional)"
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

# Global mise config + env availability (works in any directory)
if command -v mise &> /dev/null && command -v python3 &> /dev/null; then
    GLOBAL_ENV_JSON=$(mise env --json-extended --cd "$HOME" 2>/dev/null || true)
    if [ -n "$GLOBAL_ENV_JSON" ]; then
        check_pass "Mise global env" "Available outside repo"
    else
        check_warn_required "Mise global env" "No env output from HOME (mise not globally active)"
    fi

    if [ -f "$HOME/.config/mise/config.toml" ]; then
        check_pass "Mise global config" "$HOME/.config/mise/config.toml exists"
    else
        check_warn_required "Mise global config" "Missing $HOME/.config/mise/config.toml"
    fi
else
    check_warn "Mise global env" "mise/python3 not available"
fi

# Mise-managed secrets (no shell duplicates)
if command -v mise &> /dev/null && command -v python3 &> /dev/null; then
    SECRETS_SCRIPT="${DEV_ENV_ROOT:-$(pwd)}/config/scripts/secrets-status.sh"
    if [ -f "$SECRETS_SCRIPT" ]; then
        SECRETS_OUTPUT=$(bash "$SECRETS_SCRIPT" 2>/dev/null || true)
        if [ -z "$SECRETS_OUTPUT" ]; then
            check_warn "Secrets registry" "No output from secrets-status.sh (check config/mise.toml [secrets])"
        else
            while IFS='|' read -r status key source; do
                case "$status" in
                    OK)
                        check_pass "$key" "Mise-managed ($source)"
                        ;;
                    MISSING)
                        check_warn_required "$key missing" "Set via: mise set -g --age-encrypt --prompt $key"
                        ;;
                    INVALID)
                        check_warn_required "$key not from mise" "Unset shell value and set via mise"
                        ;;
                    *)
                        check_warn "Secrets validation" "Unexpected status: $status"
                        ;;
                esac
            done <<< "$SECRETS_OUTPUT"
        fi
    else
        check_warn "Secrets validation" "secrets-status.sh not found"
    fi
else
    check_warn "Secrets validation" "mise/python3 not available"
fi

section "Autofix Migration"

AUTOFIX_SCRIPT="$SCRIPT_ROOT/config/scripts/autofix.sh"
if [ -f "$AUTOFIX_SCRIPT" ] && command -v python3 &> /dev/null; then
    AUTOFIX_TMP=$(mktemp)
    if bash "$AUTOFIX_SCRIPT" status --json > "$AUTOFIX_TMP" 2>/dev/null; then
        if [ -s "$AUTOFIX_TMP" ]; then
            AUTOFIX_ISSUES=$(python3 - "$AUTOFIX_TMP" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    raw = f.read().strip()
if not raw:
    sys.exit(0)
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)
print(data.get("issues_found", 0))
PY
            )
        fi
    fi
    rm -f "$AUTOFIX_TMP"

    if [ -z "${AUTOFIX_ISSUES:-}" ]; then
        check_warn "Autofix" "No JSON output from autofix status"
    else

        if [ "$AUTOFIX_ISSUES" -gt 0 ]; then
            check_warn_required "Autofix issues detected: $AUTOFIX_ISSUES" "Run: mise run autofix:fix"
            if [ "$AUTOFIX_MODE" = "true" ]; then
                bash "$AUTOFIX_SCRIPT" fix 2>/dev/null || true
                POST_TMP=$(mktemp)
                if bash "$AUTOFIX_SCRIPT" status --json > "$POST_TMP" 2>/dev/null; then
                    if [ -s "$POST_TMP" ]; then
                        POST_ISSUES=$(python3 - "$POST_TMP" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    raw = f.read().strip()
if not raw:
    sys.exit(0)
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)
print(data.get("issues_found", 0))
PY
                        )
                    fi
                fi
                rm -f "$POST_TMP"

                if [ -n "${POST_ISSUES:-}" ] && [ "$POST_ISSUES" -eq 0 ]; then
                    check_pass "Autofix completed" "All migration issues resolved"
                else
                    check_warn_required "Autofix remaining issues: ${POST_ISSUES:-unknown}" "Re-run: mise run autofix:fix"
                fi
            fi
        else
            check_pass "Autofix" "No migration issues detected"
        fi
    fi
else
    check_warn "Autofix" "autofix.sh or python3 not available"
fi

section "Containers (Optional)"

if command -v orb &> /dev/null; then
    check_pass "OrbStack available"
    if orb status &> /dev/null; then
        check_pass "OrbStack running"
    else
        check_info "OrbStack installed but not running"
    fi
elif command -v docker &> /dev/null; then
    check_pass "Docker available"
else
    check_info "No container runtime (install OrbStack for containers)"
fi

# DevPod
if command -v devpod &> /dev/null; then
    check_pass "DevPod installed"
else
    check_info "DevPod not installed (optional)"
fi

section "Cloud (Optional)"

if command -v sky &> /dev/null; then
    check_pass "SkyPilot installed"
    if sky check &> /dev/null 2>&1; then
        check_pass "SkyPilot configured with cloud credentials"
    else
        check_info "SkyPilot credentials not configured (optional for cloud agents)"
    fi
else
    check_info "SkyPilot not installed (optional for cloud agents)"
fi

section "AI Tools"

if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -1)
    check_pass "GitHub CLI installed: $GH_VERSION"

    if gh auth status &> /dev/null 2>&1; then
        check_pass "GitHub CLI authenticated"
    else
        check_info "GitHub CLI not authenticated (run 'gh auth login' to enable)"
    fi
else
    check_warn "GitHub CLI not installed"
fi

section "Summary"

TOTAL=$((PASS + WARN + FAIL))
echo ""
echo "Results: $PASS passed, $WARN warnings ($REQUIRED_WARN required), $FAIL failed (out of $TOTAL checks)"
if [ "$STRICT_MODE" = "true" ]; then
    echo "Mode: STRICT (warnings treated as failures)"
fi
echo ""

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}❌ Environment has critical issues that need attention.${NC}"
    exit 1
elif [ "$STRICT_MODE" = "true" ] && [ $REQUIRED_WARN -gt 0 ]; then
    echo -e "${RED}❌ STRICT MODE: $REQUIRED_WARN required warning(s) found.${NC}"
    echo "   Fix warnings or run without --strict flag."
    exit 1
elif [ $WARN -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Environment is functional but has some warnings.${NC}"
    echo "   Run 'mise install' to install missing tools."
    exit 0
else
    echo -e "${GREEN}✅ Environment is fully configured and healthy!${NC}"
    exit 0
fi
