#!/bin/bash
# =============================================================================
# pre-commit hook - God-Tier macOS Development Environment
# =============================================================================
# Runs quick validation before allowing commits.
# Orchestrated by: lefthook (git hook manager)
# Source: config/scripts/pre-commit-hook.sh
# Install: mise run hooks:install
# Skip: git commit --no-verify (use sparingly!)
#
# BLOCKING CHECKS (commit will fail):
# - Secrets detection (passwords, API keys, tokens)
# - TOML syntax errors
# - Shellcheck errors in *.sh files
# - TypeScript type errors
# - Rust cargo check errors
# - Anti-patterns:
#   - sudo usage (user-space only!)
#   - npm install -g / pip install (use mise instead!)
#   - @ts-ignore, @ts-expect-error, as any (fix types!)
# =============================================================================

set -euo pipefail

# Colors (disabled in CI or non-terminal)
if [[ -t 1 && -z "${CI:-}" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

echo -e "${BLUE}━━━ Pre-commit Validation ━━━${NC}"

# Get project root
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
cd "$PROJECT_ROOT"

# Track failures
FAILED=0

# -----------------------------------------------------------------------------
# 1. Check for secrets/sensitive files
# -----------------------------------------------------------------------------
echo -n "Checking for secrets..."
SECRETS_PATTERN='(password|secret|api_key|apikey|token|credential).*=.*["\047][^"\047]{8,}'

if git diff --cached --diff-filter=ACM -z -- '*.sh' '*.ts' '*.tsx' '*.js' '*.json' '*.toml' '*.yaml' '*.yml' '*.env*' 2>/dev/null | \
   xargs -0 grep -iE "$SECRETS_PATTERN" 2>/dev/null | grep -v -E '(op://|infisical|mise secrets|\.example|_EXAMPLE)' > /dev/null; then
    echo -e " ${RED}FAIL${NC}"
    echo -e "${YELLOW}  Possible secret detected. Use op://, infisical, or mise secrets instead.${NC}"
    FAILED=1
else
    echo -e " ${GREEN}OK${NC}"
fi

# -----------------------------------------------------------------------------
# 2. Validate TOML syntax
# -----------------------------------------------------------------------------
echo -n "Validating TOML files..."
TOML_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.toml$' || true)
if [[ -n "$TOML_FILES" ]]; then
    for f in $TOML_FILES; do
        if [[ -f "$f" ]]; then
            if ! python3 -c "import tomllib; tomllib.load(open('$f', 'rb'))" 2>/dev/null; then
                echo -e " ${RED}FAIL${NC}"
                echo -e "${YELLOW}  Invalid TOML: $f${NC}"
                FAILED=1
            fi
        fi
    done
    if [[ $FAILED -eq 0 ]]; then
        echo -e " ${GREEN}OK${NC}"
    fi
else
    echo -e " ${GREEN}SKIP${NC} (no TOML changes)"
fi

# -----------------------------------------------------------------------------
# 3. Lint shell scripts (if shellcheck available) - BLOCKING
# -----------------------------------------------------------------------------
echo -n "Linting shell scripts..."
SH_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$' | grep -v '^research/repos/' || true)
if [[ -n "$SH_FILES" ]] && command -v shellcheck &>/dev/null; then
    SHELLCHECK_ERRORS=""
    for f in $SH_FILES; do
        if [[ -f "$f" ]]; then
            if ! shellcheck -x -S warning "$f" 2>/dev/null; then
                SHELLCHECK_ERRORS="$SHELLCHECK_ERRORS $f"
            fi
        fi
    done
    if [[ -z "$SHELLCHECK_ERRORS" ]]; then
        echo -e " ${GREEN}OK${NC}"
    else
        echo -e " ${RED}FAIL${NC}"
        echo -e "${YELLOW}  shellcheck found issues in:${NC}"
        echo "$SHELLCHECK_ERRORS" | tr ' ' '\n' | grep -v '^$' | sed 's/^/    /'
        FAILED=1
    fi
elif [[ -n "$SH_FILES" ]]; then
    echo -e " ${YELLOW}SKIP${NC} (shellcheck not installed)"
else
    echo -e " ${GREEN}SKIP${NC} (no shell script changes)"
fi

# -----------------------------------------------------------------------------
# 4. Check TypeScript (if bun/tsc available)
# -----------------------------------------------------------------------------
TS_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(ts|tsx)$' || true)
if [[ -n "$TS_FILES" ]]; then
    echo -n "Checking TypeScript..."
    # Find the nearest package.json
    for dir in DevEnvManager-Tauri DevEnvManager-Iced DevEnvManager; do
        if [[ -f "$PROJECT_ROOT/$dir/package.json" ]]; then
            if echo "$TS_FILES" | grep -q "^$dir/"; then
                cd "$PROJECT_ROOT/$dir"
                if command -v bun &>/dev/null && [[ -f "tsconfig.json" ]]; then
                    if bunx tsc --noEmit 2>/dev/null; then
                        echo -e " ${GREEN}OK${NC}"
                    else
                        echo -e " ${RED}FAIL${NC}"
                        FAILED=1
                    fi
                fi
                cd "$PROJECT_ROOT"
            fi
        fi
    done
else
    : # No TS changes, skip silently
fi

# -----------------------------------------------------------------------------
# 5. Check Rust (if cargo available)
# -----------------------------------------------------------------------------
RS_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.rs$' || true)
if [[ -n "$RS_FILES" ]]; then
    echo -n "Checking Rust..."
    for dir in DevEnvManager-Tauri/src-tauri DevEnvManager-Iced; do
        if [[ -f "$PROJECT_ROOT/$dir/Cargo.toml" ]] && echo "$RS_FILES" | grep -q "^$dir/"; then
            cd "$PROJECT_ROOT/$dir"
            if cargo check --quiet 2>/dev/null; then
                echo -e " ${GREEN}OK${NC}"
            else
                echo -e " ${RED}FAIL${NC}"
                FAILED=1
            fi
            cd "$PROJECT_ROOT"
        fi
    done
else
    : # No Rust changes, skip silently
fi

# -----------------------------------------------------------------------------
# 6. Anti-pattern check (BLOCKING - these are critical rule violations)
# -----------------------------------------------------------------------------
echo -n "Checking anti-patterns..."

# Get staged files, excluding:
# - research/repos/ (external cloned repos)
# - pre-commit-hook.sh (this file contains patterns it checks for)
# - Documentation files (they explain what NOT to do, so they contain the patterns)
STAGED_SH=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$' | grep -v '^research/repos/' | grep -v 'pre-commit-hook\.sh$' || true)
STAGED_TS=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(ts|tsx)$' | grep -v '^research/repos/' || true)
# Exclude doc files from anti-pattern checks (AGENTS.md, CLAUDE.md, README.md document "what not to do")
STAGED_MD=$(git diff --cached --name-only --diff-filter=ACM | grep '\.md$' | grep -v '^research/repos/' | grep -vE '^(AGENTS|CLAUDE|README|MANUAL|MIGRATION|SECRETS)\.md$' || true)

# Check for sudo in scripts (CRITICAL: user-space only)
if [[ -n "$STAGED_SH" ]]; then
    SUDO_FILES=$(echo "$STAGED_SH" | xargs grep -l 'sudo ' 2>/dev/null || true)
    if [[ -n "$SUDO_FILES" ]]; then
        echo -e "\n  ${RED}✗ Found 'sudo' in shell scripts (user-space only):${NC}"
        echo "$SUDO_FILES" | sed 's/^/    /'
        FAILED=1
    fi
fi

# Check for npm -g / pip install (CRITICAL: use mise instead)
if [[ -n "$STAGED_SH" ]] || [[ -n "$STAGED_MD" ]]; then
    ALL_FILES="$STAGED_SH $STAGED_MD"
    GLOBAL_INSTALL=$(echo "$ALL_FILES" | tr ' ' '\n' | grep -v '^$' | xargs grep -lE '(npm install -g|npm i -g|pip install [^-])' 2>/dev/null || true)
    if [[ -n "$GLOBAL_INSTALL" ]]; then
        echo -e "\n  ${RED}✗ Found global npm/pip install (use mise instead):${NC}"
        echo "$GLOBAL_INSTALL" | sed 's/^/    /'
        FAILED=1
    fi
fi

# Check for @ts-ignore, @ts-expect-error, as any (CRITICAL: fix types, don't suppress)
if [[ -n "$STAGED_TS" ]]; then
    TS_SUPPRESS=$(echo "$STAGED_TS" | xargs grep -lE '@ts-ignore|@ts-expect-error|as any' 2>/dev/null || true)
    if [[ -n "$TS_SUPPRESS" ]]; then
        echo -e "\n  ${RED}✗ Found TypeScript error suppression (fix types instead):${NC}"
        echo "$TS_SUPPRESS" | sed 's/^/    /'
        echo -e "  ${YELLOW}Rule: NEVER use @ts-ignore, @ts-expect-error, or 'as any'${NC}"
        FAILED=1
    fi
fi

if [[ $FAILED -eq 0 ]]; then
    echo -e " ${GREEN}OK${NC}"
else
    echo -e " ${RED}FAIL${NC}"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ Pre-commit checks passed${NC}"
    exit 0
else
    echo -e "${RED}❌ Pre-commit checks failed${NC}"
    echo -e "${YELLOW}   Fix issues or use 'git commit --no-verify' to skip${NC}"
    exit 1
fi
