#!/bin/bash
# =============================================================================
# autofix.sh - Detect and fix tool installation issues
# God-Tier macOS Development Environment
# =============================================================================
# Detects and remediates:
# - Tool shadows (binaries in ~/.local/bin that should be managed by mise)
# - Global npm packages (should use mise npm: backend)
# - Global pip packages (should use mise pipx: backend)
# - Homebrew CLI tools (should use mise)
# - System Python/Node usage (should be isolated)
#
# Usage:
#   autofix.sh status    - Show issues (dry-run, no changes)
#   autofix.sh fix       - Fix issues with backup
#   autofix.sh --json    - Output issues as JSON (for integration)
#
# Works on: macOS (local) and Linux (DevContainers)
# =============================================================================

set -euo pipefail

# Colors (disabled in non-interactive or CI)
if [[ -t 1 && -z "${CI:-}" && -z "${NO_COLOR:-}" ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

# Detect platform
OS="$(uname -s)"
IS_CONTAINER=false
if [[ -f /.dockerenv || -f /run/.containerenv || -n "${REMOTE_CONTAINERS:-}" || -n "${CODESPACES:-}" || -n "${DEVCONTAINER:-}" ]]; then
    IS_CONTAINER=true
fi

# Configuration - use mktemp for unique backup dir to avoid collisions
BACKUP_DIR=""
init_backup_dir() {
    if [[ -z "$BACKUP_DIR" ]]; then
        BACKUP_DIR=$(mktemp -d "$HOME/.local/autofix-backup/$(date +%Y%m%d-%H%M%S)-XXXXXX")
    fi
}
MISE_MANAGED_TOOLS="bun pixi chezmoi usage pkl node starship ripgrep fd zoxide pitchfork opencode claude gh jq yq bat eza delta fzf"

# Counters
ISSUES_FOUND=0
ISSUES_FIXED=0

# Mode
MODE="${1:-status}"
JSON_OUTPUT=false

# Parse args
for arg in "$@"; do
    case "$arg" in
        status|fix) MODE="$arg" ;;
        --json) JSON_OUTPUT=true ;;
        --help|-h)
            echo "Usage: autofix.sh [status|fix] [--json]"
            echo ""
            echo "Commands:"
            echo "  status    Show issues without fixing (default)"
            echo "  fix       Fix issues with backup"
            echo ""
            echo "Options:"
            echo "  --json    Output as JSON (for integration)"
            exit 0
            ;;
    esac
done

if $JSON_OUTPUT; then
    set +e
    set +o pipefail
fi

# JSON output buffer
JSON_ISSUES=()

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\t'/\\t}"
    str="${str//$'\r'/\\r}"
    printf '%s' "$str"
}

log_issue() {
    local category="$1"
    local tool="$2"
    local message="$3"
    local fix_command="${4:-}"
    
    ((++ISSUES_FOUND))
    
    if $JSON_OUTPUT; then
        local esc_cat esc_tool esc_msg esc_fix
        esc_cat=$(json_escape "$category")
        esc_tool=$(json_escape "$tool")
        esc_msg=$(json_escape "$message")
        esc_fix=$(json_escape "$fix_command")
        JSON_ISSUES+=("{\"category\":\"$esc_cat\",\"tool\":\"$esc_tool\",\"message\":\"$esc_msg\",\"fix\":\"$esc_fix\"}")
    else
        printf '%b' "${YELLOW}⚠️  [$category]${NC} $tool: $message\n"
        if [[ -n "$fix_command" && "$MODE" == "status" ]]; then
            printf '%b' "    ${CYAN}Fix:${NC} $fix_command\n"
        fi
    fi
}

log_fixed() {
    local tool="$1"
    local action="$2"
    
    ((++ISSUES_FIXED))
    
    if ! $JSON_OUTPUT; then
        printf '%b' "${GREEN}✅ FIXED${NC}: $tool - $action\n"
    fi
}

log_ok() {
    local message="$1"
    if ! $JSON_OUTPUT; then
        printf '%b' "${GREEN}✓${NC} $message\n"
    fi
}

log_section() {
    local title="$1"
    if ! $JSON_OUTPUT; then
        printf '\n%b' "${BLUE}━━━ $title ━━━${NC}\n"
    fi
}

# Check if tool is managed by mise
is_mise_managed() {
    local tool="$1"
    mise which "$tool" &>/dev/null
}

# Get mise path for tool
get_mise_path() {
    local tool="$1"
    mise which "$tool" 2>/dev/null || echo ""
}

# -----------------------------------------------------------------------------
# Detection Functions
# -----------------------------------------------------------------------------

detect_shadows() {
    log_section "Tool Shadows (~/.local/bin)"
    
    local found=0
    for tool in $MISE_MANAGED_TOOLS; do
        local local_bin="$HOME/.local/bin/$tool"
        
        local mise_path
        mise_path=$(get_mise_path "$tool")
        [[ -z "$mise_path" ]] && continue
        
        if [[ -f "$local_bin" && ! -L "$local_bin" ]]; then
            local file_type
            file_type=$(file -b "$local_bin" 2>/dev/null | head -c 20)
            
            if [[ "$file_type" == "Mach-O"* || "$file_type" == "ELF"* ]]; then
                local local_hash mise_hash
                local_hash=$(shasum -a 256 "$local_bin" 2>/dev/null | cut -d' ' -f1 || echo "local")
                mise_hash=$(shasum -a 256 "$mise_path" 2>/dev/null | cut -d' ' -f1 || echo "mise")
                
                if [[ "$local_hash" != "$mise_hash" ]]; then
                    log_issue "SHADOW" "$tool" "Binary in ~/.local/bin differs from mise-managed version" "mv \"$local_bin\" \"<backup_dir>/\""
                    ((++found))
                    
                    if [[ "$MODE" == "fix" ]]; then
                        init_backup_dir
                        mv "$local_bin" "$BACKUP_DIR/"
                        log_fixed "$tool" "Moved to $BACKUP_DIR"
                    fi
                fi
            fi
        fi
    done
    
    [[ $found -eq 0 ]] && log_ok "No tool shadows detected"
}

# Detect global npm packages
detect_npm_global() {
    log_section "Global npm Packages"
    
    # Skip if npm not available
    if ! command -v npm &>/dev/null; then
        log_ok "npm not in PATH (good - use bun via mise)"
        return
    fi
    
    # Check for global packages
    # Check if npm is pointing to system or standalone
    local npm_path
    npm_path=$(which npm 2>/dev/null || echo "")
    
    if [[ "$npm_path" == "/usr/local/bin/npm" || "$npm_path" == "/usr/bin/npm" ]]; then
        log_issue "NPM_GLOBAL" "npm" "Using system npm at $npm_path" "Use 'mise use -g \"npm:<package>\"' instead"
        return
    fi
    
    local global_packages
    set +e
    global_packages=$(npm list -g --depth=0 --json 2>/dev/null || echo "{}")
    global_packages=$(echo "$global_packages" | jq -r '.dependencies // {} | keys[]' 2>/dev/null || echo "")
    if ! $JSON_OUTPUT; then
        set -e
    fi
    
    if [[ -n "$global_packages" ]]; then
        local found=0
        for pkg in $global_packages; do
            # Skip npm itself
            [[ "$pkg" == "npm" || "$pkg" == "corepack" ]] && continue
            
            log_issue "NPM_GLOBAL" "$pkg" "Globally installed via npm" "mise use -g \"npm:$pkg\""
            ((++found))
            
            if [[ "$MODE" == "fix" ]]; then
                local uninstall_ok=false reinstall_ok=false
                npm uninstall -g "$pkg" 2>/dev/null && uninstall_ok=true
                mise use -g "npm:$pkg" 2>/dev/null && reinstall_ok=true
                if $uninstall_ok && $reinstall_ok; then
                    log_fixed "$pkg" "Migrated to mise npm backend"
                elif $uninstall_ok; then
                    log_fixed "$pkg" "Uninstalled (mise install may need retry)"
                fi
            fi
        done
        
        [[ $found -eq 0 ]] && log_ok "No problematic npm global packages"
    else
        log_ok "No global npm packages detected"
    fi
}

# Detect global pip packages
detect_pip_global() {
    log_section "Global pip Packages"
    
    # Skip pip detection if uv is managing Python
    if command -v uv &>/dev/null && [[ -n "${UV_SYSTEM_PYTHON:-}" || -n "${VIRTUAL_ENV:-}" ]]; then
        log_ok "Python managed by uv"
        return
    fi
    
    # Check for system Python usage
    local python_path
    python_path=$(which python3 2>/dev/null || which python 2>/dev/null || echo "")
    
    if [[ "$python_path" == "/usr/bin/python"* || "$python_path" == "/usr/local/bin/python"* ]]; then
        log_issue "PIP_GLOBAL" "python" "Using system Python at $python_path" "Use mise-managed Python or pixi/uv"
    fi
    
    # Check for pip installed packages outside venv
    if command -v pip &>/dev/null && [[ -z "${VIRTUAL_ENV:-}" ]]; then
        local user_packages
    set +e
    user_packages=$(pip list --user 2>/dev/null || true)
    user_packages=$(echo "$user_packages" | tail -n +3 | awk '{print $1}' || echo "")
    if ! $JSON_OUTPUT; then
        set -e
    fi
        
        if [[ -n "$user_packages" ]]; then
            local found=0
            for pkg in $user_packages; do
                # Skip common system packages
                [[ "$pkg" == "pip" || "$pkg" == "setuptools" || "$pkg" == "wheel" ]] && continue
                
                log_issue "PIP_USER" "$pkg" "Installed via pip --user" "mise use -g \"pipx:$pkg\" or use uv"
                ((++found))
                
                if [[ "$MODE" == "fix" ]]; then
                    pip uninstall -y "$pkg" 2>/dev/null || true
                    mise use -g "pipx:$pkg" 2>/dev/null || true
                    log_fixed "$pkg" "Migrated to mise pipx backend"
                fi
            done
            
            [[ $found -eq 0 ]] && log_ok "No problematic pip user packages"
        else
            log_ok "No pip user packages detected"
        fi
    else
        log_ok "pip not available or in venv (good)"
    fi
}

# Detect Homebrew CLI tools that should be managed by mise (macOS only)
detect_brew_cli() {
    log_section "Homebrew CLI Tools"
    
    # Skip on Linux/containers
    if [[ "$OS" != "Darwin" ]]; then
        log_ok "Skipping Homebrew check (not macOS)"
        return
    fi
    
    BREW_BIN="$(command -v brew 2>/dev/null || true)"
    if [[ -z "$BREW_BIN" ]]; then
        for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
            if [[ -x "$candidate" ]]; then
                BREW_BIN="$candidate"
                break
            fi
        done
    fi

    if [[ -z "$BREW_BIN" ]]; then
        log_ok "Homebrew not installed"
        return
    fi
    
    # Tools that should be managed by mise, not brew
    local cli_tools_to_check="node python ripgrep fd bat eza jq yq starship zoxide fzf"
    
    local found=0
    for tool in $cli_tools_to_check; do
        if "$BREW_BIN" list "$tool" &>/dev/null; then
            log_issue "BREW_CLI" "$tool" "Installed via Homebrew" "$BREW_BIN uninstall $tool && mise use -g $tool"
            ((++found))
            
            if [[ "$MODE" == "fix" ]]; then
                "$BREW_BIN" uninstall "$tool" 2>/dev/null || true
                mise use -g "$tool" 2>/dev/null || true
                log_fixed "$tool" "Migrated from Homebrew to mise"
            fi
        fi
    done
    
    [[ $found -eq 0 ]] && log_ok "No CLI tools installed via Homebrew that should be mise-managed"
}

# Detect PATH ordering issues
detect_path_issues() {
    log_section "PATH Configuration"
    
    # Check if mise shims or installs are in PATH
    if echo "$PATH" | grep -q 'mise/shims'; then
        log_ok "Mise shims in PATH"
    elif echo "$PATH" | grep -q 'mise/installs'; then
        log_ok "Mise activation mode in PATH"
    else
        log_issue "PATH" "mise" "Mise not in PATH" "Add 'eval \"\$(mise activate bash)\"' to shell config"

        if [[ "$MODE" == "fix" ]]; then
            # Can't auto-fix PATH - needs shell config change
            echo -e "${YELLOW}    Manual fix required: Add mise activation to your shell config${NC}"
        fi
    fi
    
    local path_order
    path_order=$(echo "$PATH" | tr ':' '\n' | grep -n -E '(local/bin|mise/shims)' | head -2 || true)
    
    if [[ -n "$path_order" ]]; then
        if echo "$path_order" | grep -q 'local/bin' && echo "$path_order" | head -1 | grep -q 'local/bin'; then
            if echo "$path_order" | grep -q 'mise/shims'; then
                log_issue "PATH_ORDER" "PATH" "$HOME/.local/bin comes before mise shims" "Reorder PATH in shell config"
            fi
        fi
    fi
}

# Detect mise configuration issues
detect_mise_config() {
    log_section "Mise Configuration"
    
    if ! command -v mise &>/dev/null; then
        log_issue "MISE" "mise" "Mise not installed" "Run setup.sh"
        return
    fi
    
    # Check experimental features
    if ! mise config get settings.experimental 2>/dev/null | grep -q "true"; then
        log_issue "MISE_CONFIG" "experimental" "Experimental features not enabled" "mise settings set experimental true"
        
        if [[ "$MODE" == "fix" ]]; then
            mise settings set experimental true 2>/dev/null || true
            log_fixed "experimental" "Enabled experimental features"
        fi
    else
        log_ok "Experimental features enabled"
    fi
    
    # Check npm backend
    local npm_pkg_mgr
    npm_pkg_mgr=$(mise settings get npm.package_manager 2>/dev/null || echo "")
    if [[ "$npm_pkg_mgr" != "bun" ]]; then
        log_issue "MISE_CONFIG" "npm.package_manager" "Not set to bun (current: ${npm_pkg_mgr:-not set})" "mise settings set npm.package_manager bun"
        
        if [[ "$MODE" == "fix" ]]; then
            mise settings set npm.package_manager bun 2>/dev/null || true
            log_fixed "npm.package_manager" "Set to bun"
        fi
    else
        log_ok "npm.package_manager = bun"
    fi
    
    # Check python uv_venv_auto
    local uv_venv
    uv_venv=$(mise settings get python.uv_venv_auto 2>/dev/null || echo "")
    if [[ "$uv_venv" != "true" ]]; then
        log_issue "MISE_CONFIG" "python.uv_venv_auto" "Not enabled" "mise settings set python.uv_venv_auto true"
        
        if [[ "$MODE" == "fix" ]]; then
            mise settings set python.uv_venv_auto true 2>/dev/null || true
            log_fixed "python.uv_venv_auto" "Enabled"
        fi
    else
        log_ok "python.uv_venv_auto = true"
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    if ! $JSON_OUTPUT; then
        echo "🔧 Autofix Tool - God-Tier macOS Development Environment"
        echo "   Mode: $MODE | Platform: $OS | Container: $IS_CONTAINER"
        echo "   $(date)"
    fi
    
    # Run all detections
    detect_mise_config
    detect_shadows
    detect_path_issues
    detect_npm_global
    detect_pip_global
    detect_brew_cli
    
    # Output JSON if requested
    if $JSON_OUTPUT; then
        echo "{"
        echo "  \"issues_found\": $ISSUES_FOUND,"
        echo "  \"issues_fixed\": $ISSUES_FIXED,"
        echo "  \"mode\": \"$MODE\","
        echo "  \"platform\": \"$OS\","
        echo "  \"is_container\": $IS_CONTAINER,"
        echo "  \"issues\": ["
        local first=true
        for issue in "${JSON_ISSUES[@]:-}"; do
            if $first; then
                first=false
            else
                echo ","
            fi
            echo -n "    $issue"
        done
        echo ""
        echo "  ]"
        echo "}"
        exit 0
    fi
    
    # Summary
    log_section "Summary"
    
    if [[ "$MODE" == "fix" ]]; then
        echo ""
        echo "Fixed $ISSUES_FIXED of $ISSUES_FOUND issue(s)"
        if [[ $ISSUES_FIXED -gt 0 ]]; then
            echo "Backup location: $BACKUP_DIR"
            echo ""
            echo "Run 'mise reshim' to update shims"
        fi
    else
        echo ""
        if [[ $ISSUES_FOUND -gt 0 ]]; then
            echo -e "${YELLOW}Found $ISSUES_FOUND issue(s)${NC}"
            echo ""
            echo "Run 'mise run autofix:fix' to apply fixes"
            echo "Or run individual fixes shown above"
            exit 1
        else
            echo -e "${GREEN}✅ No issues found - environment is clean!${NC}"
        fi
    fi
}

main "$@"
