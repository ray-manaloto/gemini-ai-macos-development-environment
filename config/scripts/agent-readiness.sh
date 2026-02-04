#!/bin/bash
# =============================================================================
# agent-readiness.sh - Validate AI/LLM agent setup and readiness
# God-Tier macOS Development Environment
# =============================================================================
# Validates:
# - AI CLI tools (claude, gemini, opencode, gh)
# - Authentication status for each tool
# - oh-my-opencode configuration
# - MCP server configurations
# - Agent config directories (.claude, .gemini, .cursor, .opencode)
# - API keys availability
# - Project-level agent configs
#
# Usage:
#   agent-readiness.sh status    - Show readiness status (default)
#   agent-readiness.sh fix       - Fix common issues
#   agent-readiness.sh --json    - Output as JSON (for integration)
#   agent-readiness.sh --quiet   - Only output if issues found
#
# Works on: macOS (local) and Linux (DevContainers)
# Integrates with: oh-my-opencode hooks, mise tasks
# =============================================================================

set -euo pipefail

if [[ -t 1 && -z "${CI:-}" && -z "${NO_COLOR:-}" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

OS="$(uname -s)"
IS_CONTAINER=false
if [[ -f /.dockerenv || -f /run/.containerenv || -n "${REMOTE_CONTAINERS:-}" || -n "${CODESPACES:-}" || -n "${DEVCONTAINER:-}" ]]; then
    IS_CONTAINER=true
fi

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
TOTAL_COUNT=0

MODE="${1:-status}"
JSON_OUTPUT=false
QUIET_MODE=false
JSON_RESULTS=()

for arg in "$@"; do
    case "$arg" in
        status|fix) MODE="$arg" ;;
        --json) JSON_OUTPUT=true ;;
        --quiet) QUIET_MODE=true ;;
        --help|-h)
            echo "Usage: agent-readiness.sh [status|fix] [--json] [--quiet]"
            echo ""
            echo "Commands:"
            echo "  status    Show readiness status (default)"
            echo "  fix       Fix common issues automatically"
            echo ""
            echo "Options:"
            echo "  --json    Output as JSON (for integration)"
            echo "  --quiet   Only output if issues found"
            exit 0
            ;;
    esac
done

json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\t'/\\t}"
    printf '%s' "$str"
}

log_pass() {
    local check="$1"
    local message="$2"
    ((++PASS_COUNT))
    ((++TOTAL_COUNT))
    if $JSON_OUTPUT; then
        JSON_RESULTS+=("{\"status\":\"pass\",\"check\":\"$(json_escape "$check")\",\"message\":\"$(json_escape "$message")\"}")
    elif ! $QUIET_MODE; then
        printf '%b' "${GREEN}✅ PASS${NC}: $check - $message\n"
    fi
}

log_warn() {
    local check="$1"
    local message="$2"
    local fix="${3:-}"
    ((++WARN_COUNT))
    ((++TOTAL_COUNT))
    if $JSON_OUTPUT; then
        JSON_RESULTS+=("{\"status\":\"warn\",\"check\":\"$(json_escape "$check")\",\"message\":\"$(json_escape "$message")\",\"fix\":\"$(json_escape "$fix")\"}")
    else
        printf '%b' "${YELLOW}⚠️  WARN${NC}: $check - $message\n"
        [[ -n "$fix" ]] && printf '%b' "    ${CYAN}Fix:${NC} $fix\n"
    fi
}

log_fail() {
    local check="$1"
    local message="$2"
    local fix="${3:-}"
    ((++FAIL_COUNT))
    ((++TOTAL_COUNT))
    if $JSON_OUTPUT; then
        JSON_RESULTS+=("{\"status\":\"fail\",\"check\":\"$(json_escape "$check")\",\"message\":\"$(json_escape "$message")\",\"fix\":\"$(json_escape "$fix")\"}")
    else
        printf '%b' "${RED}❌ FAIL${NC}: $check - $message\n"
        [[ -n "$fix" ]] && printf '%b' "    ${CYAN}Fix:${NC} $fix\n"
    fi
}

log_section() {
    local title="$1"
    if ! $JSON_OUTPUT && ! $QUIET_MODE; then
        printf '\n%b' "${BLUE}━━━ $title ━━━${NC}\n"
    fi
}

check_ai_cli_tools() {
    log_section "AI CLI Tools"
    
    if command -v opencode &>/dev/null; then
        local ver
        ver=$(opencode --version 2>/dev/null | head -1 || echo "unknown")
        log_pass "opencode" "Installed ($ver)"
    else
        log_fail "opencode" "Not installed" "mise use -g opencode-ai"
    fi
    
    if command -v claude &>/dev/null; then
        local ver
        ver=$(claude --version 2>/dev/null | head -1 || echo "unknown")
        log_pass "claude" "Installed ($ver)"
    else
        log_warn "claude" "Not installed (optional)" "mise use -g claude-code"
    fi
    
    if command -v gemini &>/dev/null; then
        log_pass "gemini" "Installed"
    else
        log_warn "gemini" "Not installed (optional)" "mise use -g \"npm:@anthropic-ai/claude-code\""
    fi
    
    if command -v gh &>/dev/null; then
        local ver
        ver=$(gh --version 2>/dev/null | head -1 || echo "unknown")
        log_pass "gh" "Installed ($ver)"
    else
        log_warn "gh" "Not installed" "mise use -g github-cli"
    fi
}

check_authentication() {
    log_section "Authentication Status"
    
    if command -v gh &>/dev/null; then
        if gh auth status &>/dev/null; then
            log_pass "gh auth" "Authenticated"
        else
            log_warn "gh auth" "Not authenticated" "gh auth login"
        fi
    fi
    
    if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        log_pass "ANTHROPIC_API_KEY" "Set in environment"
    elif [[ -f ~/.config/claude/credentials.json ]]; then
        log_pass "ANTHROPIC_API_KEY" "Credentials file exists"
    else
        log_warn "ANTHROPIC_API_KEY" "Not found" "Set ANTHROPIC_API_KEY or run 'claude auth'"
    fi
    
    if [[ -n "${OPENAI_API_KEY:-}" ]]; then
        log_pass "OPENAI_API_KEY" "Set in environment"
    else
        log_warn "OPENAI_API_KEY" "Not found (needed for GPT models)" "Set OPENAI_API_KEY"
    fi
    
    if [[ -n "${GOOGLE_API_KEY:-}" || -n "${GEMINI_API_KEY:-}" ]]; then
        log_pass "GOOGLE_API_KEY" "Set in environment"
    else
        log_warn "GOOGLE_API_KEY" "Not found (needed for Gemini)" "Set GOOGLE_API_KEY or GEMINI_API_KEY"
    fi
}

check_opencode_config() {
    log_section "OpenCode Configuration"
    
    local user_config="$HOME/.config/opencode"
    
    if [[ -d "$user_config" ]]; then
        log_pass "opencode config dir" "Exists at $user_config"
    else
        log_fail "opencode config dir" "Missing" "mkdir -p $user_config"
        return
    fi
    
    if [[ -f "$user_config/opencode.json" ]]; then
        if command -v jq &>/dev/null && jq '.' "$user_config/opencode.json" &>/dev/null; then
            log_pass "opencode.json" "Valid JSON"
        else
            log_fail "opencode.json" "Invalid JSON" "Check syntax"
        fi
    else
        log_warn "opencode.json" "Not found" "Run 'bunx oh-my-opencode install'"
    fi
    
    if [[ -f "$user_config/oh-my-opencode.json" ]]; then
        if command -v jq &>/dev/null && jq '.' "$user_config/oh-my-opencode.json" &>/dev/null; then
            log_pass "oh-my-opencode.json" "Valid JSON"
            
            local has_agents has_categories
            has_agents=$(jq -e '.agents' "$user_config/oh-my-opencode.json" 2>/dev/null && echo "yes" || echo "no")
            has_categories=$(jq -e '.categories' "$user_config/oh-my-opencode.json" 2>/dev/null && echo "yes" || echo "no")
            
            [[ "$has_agents" == "yes" ]] && log_pass "oh-my-opencode agents" "Configured"
            [[ "$has_categories" == "yes" ]] && log_pass "oh-my-opencode categories" "Configured"
        else
            log_fail "oh-my-opencode.json" "Invalid JSON"
        fi
    else
        log_warn "oh-my-opencode.json" "Not found" "Run 'bunx oh-my-opencode install'"
    fi
}

check_mcp_config() {
    log_section "MCP (Model Context Protocol)"
    
    local project_mcp=".mcp.json"
    local claude_mcp=".claude/.mcp.json"
    
    if [[ -f "$project_mcp" ]]; then
        if command -v jq &>/dev/null && jq '.' "$project_mcp" &>/dev/null; then
            log_pass ".mcp.json" "Valid project MCP config"
            
            local servers
            servers=$(jq -r '.mcpServers | keys[]' "$project_mcp" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
            [[ -n "$servers" ]] && log_pass "MCP servers" "Configured: $servers"
        else
            log_fail ".mcp.json" "Invalid JSON"
        fi
    else
        log_warn ".mcp.json" "Not found (MCP not configured for this project)"
    fi
    
    if [[ -f "$claude_mcp" ]]; then
        log_pass ".claude/.mcp.json" "Claude-specific MCP config exists"
    fi
}

check_agent_configs() {
    log_section "Agent Config Directories"
    
    local configs=(
        ".claude:Claude Code"
        ".Claude:Claude Code (alt)"
        ".gemini:Gemini CLI"
        ".cursor:Cursor"
        ".opencode:OpenCode"
    )
    
    for config in "${configs[@]}"; do
        local dir="${config%%:*}"
        local name="${config##*:}"
        
        if [[ -d "$dir" ]]; then
            local count
            count=$(find "$dir" -type f \( -name "*.md" -o -name "*.toml" -o -name "*.json" \) 2>/dev/null | wc -l | tr -d ' ')
            log_pass "$dir" "$name config exists ($count files)"
        fi
    done
    
    if [[ -d ".claude/skills" || -d ".claude/skills-external" ]]; then
        local skill_count
        skill_count=$(find .claude/skills* -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
        log_pass "Claude skills" "$skill_count skills available"
    fi
    
    if [[ -d ".claude/agents-external" ]]; then
        local agent_count
        agent_count=$(find .claude/agents-external -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        log_pass "Claude agents" "$agent_count external agents available"
    fi
}

check_project_readiness() {
    log_section "Project AI Readiness"
    
    if [[ -f "AGENTS.md" ]]; then
        log_pass "AGENTS.md" "Project knowledge base exists"
    else
        log_warn "AGENTS.md" "Not found" "Create AGENTS.md for AI context"
    fi
    
    if [[ -f "CLAUDE.md" ]]; then
        log_pass "CLAUDE.md" "AI assistant context exists"
    fi
    
    if [[ -f "llms.txt" ]]; then
        log_pass "llms.txt" "LLM documentation index exists"
    else
        log_warn "llms.txt" "Not found" "Create llms.txt for LLM discoverability"
    fi
    
    if [[ -d "openspec" ]]; then
        log_pass "openspec/" "OpenSpec workflow configured"
    fi
}

fix_common_issues() {
    log_section "Fixing Common Issues"
    
    local user_config="$HOME/.config/opencode"
    if [[ ! -d "$user_config" ]]; then
        mkdir -p "$user_config"
        printf '%b' "${GREEN}Created${NC}: $user_config\n"
    fi
    
    if ! command -v opencode &>/dev/null && command -v mise &>/dev/null; then
        printf '%b' "Installing opencode via mise...\n"
        mise use -g opencode-ai 2>/dev/null || true
    fi
    
    if ! command -v gh &>/dev/null && command -v mise &>/dev/null; then
        printf '%b' "Installing gh via mise...\n"
        mise use -g github-cli 2>/dev/null || true
    fi
    
    if [[ ! -f "$user_config/oh-my-opencode.json" ]] && command -v bunx &>/dev/null; then
        printf '%b' "${YELLOW}Run 'bunx oh-my-opencode install' to configure oh-my-opencode${NC}\n"
    fi
    
    printf '%b' "\n${GREEN}Fix complete.${NC} Run 'agent-readiness.sh status' to verify.\n"
}

print_summary() {
    if $JSON_OUTPUT; then
        printf '{"summary":{"pass":%d,"warn":%d,"fail":%d,"total":%d},"results":[%s]}\n' \
            "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT" "$TOTAL_COUNT" \
            "$(IFS=,; echo "${JSON_RESULTS[*]}")"
    elif ! $QUIET_MODE || [[ $WARN_COUNT -gt 0 || $FAIL_COUNT -gt 0 ]]; then
        printf '\n%b' "${BLUE}━━━ Summary ━━━${NC}\n"
        printf '%b' "Results: ${GREEN}$PASS_COUNT passed${NC}"
        [[ $WARN_COUNT -gt 0 ]] && printf '%b' ", ${YELLOW}$WARN_COUNT warnings${NC}"
        [[ $FAIL_COUNT -gt 0 ]] && printf '%b' ", ${RED}$FAIL_COUNT failed${NC}"
        printf " (out of $TOTAL_COUNT checks)\n"
        
        if [[ $FAIL_COUNT -gt 0 ]]; then
            printf '%b' "\n${RED}Some checks failed.${NC} Run 'agent-readiness.sh fix' to auto-fix.\n"
        elif [[ $WARN_COUNT -gt 0 ]]; then
            printf '%b' "\n${YELLOW}Some warnings detected.${NC} Review above for optional improvements.\n"
        else
            printf '%b' "\n${GREEN}All checks passed!${NC} AI agent setup is ready.\n"
        fi
    fi
}

main() {
    if [[ "$MODE" == "fix" ]]; then
        fix_common_issues
        exit 0
    fi
    
    if ! $JSON_OUTPUT && ! $QUIET_MODE; then
        printf '%b' "${BLUE}=== AI/LLM Agent Readiness Check ===${NC}\n"
        printf '%b' "Platform: $OS"
        $IS_CONTAINER && printf '%b' " (Container)"
        printf '\n'
    fi
    
    check_ai_cli_tools
    check_authentication
    check_opencode_config
    check_mcp_config
    check_agent_configs
    check_project_readiness
    
    print_summary
    
    [[ $FAIL_COUNT -gt 0 ]] && exit 1
    exit 0
}

main "$@"
