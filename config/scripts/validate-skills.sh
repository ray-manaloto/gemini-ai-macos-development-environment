#!/bin/bash
# =============================================================================
# validate-skills.sh - AI Agent Skills Validation
# God-Tier macOS Development Environment
# =============================================================================
# Validates:
#   - .agents/skills/ canonical source directory
#   - Symlinks from .claude/skills/ and .opencode/skills/
#   - SKILL.md format (YAML frontmatter with name + description)
#   - No duplicate or conflicting skills
#   - bunx skills CLI availability
#   - No stale global skills (~/.claude/skills/)
#
# Usage:
#   validate-skills.sh              - Full validation (default)
#   validate-skills.sh --json       - Output as JSON
#   validate-skills.sh --quiet      - Only output if issues found
#   validate-skills.sh --fix        - Fix common issues
#
# Run via: mise run skills:validate
# =============================================================================

set -euo pipefail

# --- Color handling ---
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

# --- Counters ---
PASS=0
WARN=0
FAIL=0
TOTAL=0

# --- Mode ---
JSON_OUTPUT=false
QUIET_MODE=false
FIX_MODE=false
JSON_RESULTS=()

for arg in "$@"; do
    case "$arg" in
        --json)  JSON_OUTPUT=true ;;
        --quiet) QUIET_MODE=true ;;
        --fix)   FIX_MODE=true ;;
        --help|-h)
            echo "Usage: validate-skills.sh [--json] [--quiet] [--fix]"
            echo ""
            echo "Options:"
            echo "  --json    Output as JSON"
            echo "  --quiet   Only output if issues found"
            echo "  --fix     Fix common issues (recreate broken symlinks)"
            exit 0
            ;;
    esac
done

# --- Project root detection ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- Helpers ---
json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    printf '%s' "$str"
}

check_pass() {
    local check="$1" msg="$2"
    ((++PASS)); ((++TOTAL))
    if $JSON_OUTPUT; then
        JSON_RESULTS+=("{\"status\":\"pass\",\"check\":\"$(json_escape "$check")\",\"message\":\"$(json_escape "$msg")\"}")
    elif ! $QUIET_MODE; then
        printf '%b' "${GREEN}✅ PASS${NC}: $check - $msg\n"
    fi
}

check_warn() {
    local check="$1" msg="$2" fix="${3:-}"
    ((++WARN)); ((++TOTAL))
    if $JSON_OUTPUT; then
        JSON_RESULTS+=("{\"status\":\"warn\",\"check\":\"$(json_escape "$check")\",\"message\":\"$(json_escape "$msg")\",\"fix\":\"$(json_escape "$fix")\"}")
    else
        printf '%b' "${YELLOW}⚠️  WARN${NC}: $check - $msg\n"
        [[ -n "$fix" ]] && printf '%b' "    ${CYAN}Fix:${NC} $fix\n"
    fi
}

check_fail() {
    local check="$1" msg="$2" fix="${3:-}"
    ((++FAIL)); ((++TOTAL))
    if $JSON_OUTPUT; then
        JSON_RESULTS+=("{\"status\":\"fail\",\"check\":\"$(json_escape "$check")\",\"message\":\"$(json_escape "$msg")\",\"fix\":\"$(json_escape "$fix")\"}")
    else
        printf '%b' "${RED}❌ FAIL${NC}: $check - $msg\n"
        [[ -n "$fix" ]] && printf '%b' "    ${CYAN}Fix:${NC} $fix\n"
    fi
}

section() {
    if ! $JSON_OUTPUT && ! $QUIET_MODE; then
        printf '\n%b' "${BLUE}━━━ $1 ━━━${NC}\n"
    fi
}

# =============================================================================
# Checks
# =============================================================================

check_canonical_source() {
    section "Canonical Source (.agents/skills/)"

    local agents_dir="$PROJECT_ROOT/.agents/skills"

    if [[ ! -d "$agents_dir" ]]; then
        check_fail ".agents/skills/" "Directory missing" "mkdir -p .agents/skills"
        return
    fi

    local count
    count=$(find "$agents_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$count" -eq 0 ]]; then
        check_fail ".agents/skills/" "No skills found"
        return
    fi

    check_pass ".agents/skills/" "$count skills in canonical source"

    # Check each skill has SKILL.md
    local missing=0
    for skill_dir in "$agents_dir"/*/; do
        local name
        name="$(basename "$skill_dir")"
        if [[ ! -f "$skill_dir/SKILL.md" ]]; then
            check_fail "$name" "Missing SKILL.md in .agents/skills/$name/"
            ((++missing))
        fi
    done

    if [[ "$missing" -eq 0 ]]; then
        check_pass "SKILL.md files" "All $count skills have SKILL.md"
    fi
}

check_skill_format() {
    section "SKILL.md Format Validation"

    local agents_dir="$PROJECT_ROOT/.agents/skills"
    [[ ! -d "$agents_dir" ]] && return

    local valid=0
    local invalid=0

    for skill_dir in "$agents_dir"/*/; do
        local name skill_file
        name="$(basename "$skill_dir")"
        skill_file="$skill_dir/SKILL.md"

        [[ ! -f "$skill_file" ]] && continue

        # Check YAML frontmatter exists (starts with ---)
        local first_line
        first_line="$(head -1 "$skill_file")"
        if [[ "$first_line" != "---" ]]; then
            check_fail "$name frontmatter" "SKILL.md missing YAML frontmatter (must start with ---)"
            ((++invalid))
            continue
        fi

        # Check closing frontmatter
        local has_closing
        has_closing="$(awk 'NR>1 && /^---$/{print "yes"; exit}' "$skill_file")"
        if [[ "$has_closing" != "yes" ]]; then
            check_fail "$name frontmatter" "SKILL.md missing closing --- in frontmatter"
            ((++invalid))
            continue
        fi

        # Check name field exists
        if ! grep -q '^name:' "$skill_file"; then
            check_fail "$name metadata" "Missing 'name:' field in frontmatter"
            ((++invalid))
            continue
        fi

        # Check description field exists
        if ! grep -q '^description:' "$skill_file"; then
            check_fail "$name metadata" "Missing 'description:' field in frontmatter"
            ((++invalid))
            continue
        fi

        # Check description is not empty/generic
        local desc_len
        desc_len="$(grep '^description:' "$skill_file" | wc -c | tr -d ' ')"
        if [[ "$desc_len" -lt 30 ]]; then
            check_warn "$name description" "Description is very short ($desc_len chars) - may not trigger reliably"
        fi

        ((++valid))
    done

    if [[ "$invalid" -eq 0 ]]; then
        check_pass "YAML frontmatter" "All $valid skills have valid name + description"
    fi
}

check_symlinks() {
    section "Symlink Architecture"

    local agents_dir="$PROJECT_ROOT/.agents/skills"
    [[ ! -d "$agents_dir" ]] && return

    local targets=(".claude/skills" ".opencode/skills")

    for target_rel in "${targets[@]}"; do
        local target_dir="$PROJECT_ROOT/$target_rel"

        if [[ ! -d "$target_dir" ]]; then
            check_fail "$target_rel/" "Directory missing" "mkdir -p $target_rel"
            continue
        fi

        local total=0
        local symlinked=0
        local broken=0
        local direct=0
        local missing_from_target=()

        # Check each canonical skill has a symlink in target
        for skill_dir in "$agents_dir"/*/; do
            local name
            name="$(basename "$skill_dir")"
            local target_link="$target_dir/$name"

            if [[ -L "$target_link" ]]; then
                # It's a symlink — check it resolves
                if [[ -d "$target_link" ]]; then
                    ((++symlinked))
                else
                    check_fail "$target_rel/$name" "Broken symlink" "ln -sf \"../../.agents/skills/$name\" \"$target_rel/$name\""
                    ((++broken))

                    if $FIX_MODE; then
                        rm -f "$target_link"
                        ln -sf "../../.agents/skills/$name" "$target_link"
                        printf '%b' "    ${GREEN}Fixed:${NC} Recreated symlink\n"
                    fi
                fi
            elif [[ -d "$target_link" ]]; then
                check_warn "$target_rel/$name" "Direct copy instead of symlink" "rm -rf \"$target_rel/$name\" && ln -sf \"../../.agents/skills/$name\" \"$target_rel/$name\""
                ((++direct))

                if $FIX_MODE; then
                    rm -rf "$target_link"
                    ln -sf "../../.agents/skills/$name" "$target_link"
                    printf '%b' "    ${GREEN}Fixed:${NC} Replaced with symlink\n"
                fi
            else
                missing_from_target+=("$name")
            fi

            ((++total))
        done

        # Report missing symlinks
        for name in "${missing_from_target[@]}"; do
            check_fail "$target_rel/$name" "Missing from $target_rel/" "ln -sf \"../../.agents/skills/$name\" \"$target_rel/$name\""

            if $FIX_MODE; then
                ln -sf "../../.agents/skills/$name" "$target_dir/$name"
                printf '%b' "    ${GREEN}Fixed:${NC} Created symlink\n"
            fi
        done

        if [[ "$broken" -eq 0 && "$direct" -eq 0 && "${#missing_from_target[@]}" -eq 0 ]]; then
            check_pass "$target_rel/" "$symlinked/$total skills properly symlinked"
        fi

        # Check for orphan symlinks (in target but not in canonical)
        for entry in "$target_dir"/*/; do
            [[ ! -e "$entry" && ! -L "$entry" ]] && continue
            local entry_name
            entry_name="$(basename "$entry")"
            if [[ ! -d "$agents_dir/$entry_name" ]]; then
                check_warn "$target_rel/$entry_name" "Orphan skill (exists in $target_rel/ but not in .agents/skills/)"
            fi
        done
    done
}

check_no_global_skills() {
    section "Global Skills (Should Be Empty)"

    local global_dir="$HOME/.claude/skills"
    local global_display="\$HOME/.claude/skills/"
    if [[ -d "$global_dir" ]]; then
        local count
        count=$(find "$global_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$count" -gt 0 ]]; then
            check_warn "$global_display" "$count global skills found (should be project-level only)" "rm -rf $global_dir/*"
        else
            check_pass "$global_display" "Empty (correct - skills are project-level)"
        fi
    else
        check_pass "$global_display" "Does not exist (correct)"
    fi
}

check_no_duplicates() {
    section "Duplicate Detection"

    local agents_dir="$PROJECT_ROOT/.agents/skills"
    [[ ! -d "$agents_dir" ]] && return

    # Check for duplicate names (use find instead of ls for robustness)
    local names
    names="$(find "$agents_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)"
    local dupes
    dupes="$(echo "$names" | uniq -d)"

    if [[ -n "$dupes" ]]; then
        check_fail "duplicates" "Duplicate skill names found: $dupes"
    else
        local count
        count="$(echo "$names" | wc -l | tr -d ' ')"
        check_pass "duplicates" "No duplicates among $count skills"
    fi
}

check_skills_cli() {
    section "Skills CLI (bunx)"

    if command -v bunx &>/dev/null; then
        check_pass "bunx" "Available"

        # Check bunx skills works
        local version
        version="$(bunx skills --version 2>/dev/null || echo "unknown")"
        if [[ "$version" != "unknown" ]]; then
            check_pass "skills CLI" "Version $version"
        else
            check_warn "skills CLI" "Could not determine version" "bunx skills --version"
        fi
    else
        check_warn "bunx" "Not available (needed for skill management)" "mise use -g bun"
    fi
}

check_expected_skills() {
    section "Expected Skills Inventory"

    local agents_dir="$PROJECT_ROOT/.agents/skills"
    [[ ! -d "$agents_dir" ]] && return

    # Custom project skills
    local custom_skills=(mise-expert bats-testing shell-scripting rust-dev menu-bar-dev)
    for skill in "${custom_skills[@]}"; do
        if [[ -d "$agents_dir/$skill" && -f "$agents_dir/$skill/SKILL.md" ]]; then
            check_pass "custom/$skill" "Present"
        else
            check_fail "custom/$skill" "Missing" "Create .agents/skills/$skill/SKILL.md"
        fi
    done

    # Installed skills from trusted sources
    local installed_skills=(skill-creator mcp-builder webapp-testing systematic-debugging test-driven-development verification-before-completion web-design-guidelines)
    for skill in "${installed_skills[@]}"; do
        if [[ -d "$agents_dir/$skill" && -f "$agents_dir/$skill/SKILL.md" ]]; then
            check_pass "installed/$skill" "Present"
        else
            check_warn "installed/$skill" "Missing" "bunx skills add <source> --skill $skill --agent claude-code opencode -y"
        fi
    done

    # OpenSpec workflow skills
    local openspec_skills=(openspec-apply-change openspec-archive-change openspec-bulk-archive-change openspec-continue-change openspec-explore openspec-ff-change openspec-new-change openspec-onboard openspec-sync-specs openspec-verify-change)
    local openspec_count=0
    for skill in "${openspec_skills[@]}"; do
        if [[ -d "$agents_dir/$skill" && -f "$agents_dir/$skill/SKILL.md" ]]; then
            ((++openspec_count))
        fi
    done

    if [[ "$openspec_count" -eq "${#openspec_skills[@]}" ]]; then
        check_pass "openspec/*" "All $openspec_count OpenSpec skills present"
    else
        check_warn "openspec/*" "Only $openspec_count/${#openspec_skills[@]} OpenSpec skills found"
    fi

    # Dev workflow skills
    local dev_skills=(analyze investigate tdd refactor)
    local dev_count=0
    for skill in "${dev_skills[@]}"; do
        if [[ -d "$agents_dir/$skill" && -f "$agents_dir/$skill/SKILL.md" ]]; then
            ((++dev_count))
        fi
    done

    if [[ "$dev_count" -eq "${#dev_skills[@]}" ]]; then
        check_pass "dev/*" "All $dev_count dev workflow skills present"
    else
        check_warn "dev/*" "Only $dev_count/${#dev_skills[@]} dev workflow skills found"
    fi
}

# =============================================================================
# Summary
# =============================================================================

print_summary() {
    if $JSON_OUTPUT; then
        printf '{"summary":{"pass":%d,"warn":%d,"fail":%d,"total":%d},"results":[%s]}\n' \
            "$PASS" "$WARN" "$FAIL" "$TOTAL" \
            "$(IFS=,; echo "${JSON_RESULTS[*]}")"
    elif ! $QUIET_MODE || [[ $WARN -gt 0 || $FAIL -gt 0 ]]; then
        printf '\n%b' "${BLUE}━━━ Skills Validation Summary ━━━${NC}\n"
        printf "Results: %d passed, %d warnings, %d failed (out of %d checks)\n" \
            "$PASS" "$WARN" "$FAIL" "$TOTAL"

        if [[ $FAIL -gt 0 ]]; then
            printf '\n%b' "${RED}Skills setup has issues.${NC} Run with --fix to auto-repair symlinks.\n"
        elif [[ $WARN -gt 0 ]]; then
            printf '\n%b' "${YELLOW}Skills functional with warnings.${NC}\n"
        else
            printf '\n%b' "${GREEN}All skills validated successfully!${NC}\n"
        fi
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    if ! $JSON_OUTPUT && ! $QUIET_MODE; then
        printf '%b' "${BLUE}=== AI Agent Skills Validation ===${NC}\n"
        printf "Project: %s\n" "$PROJECT_ROOT"
    fi

    check_canonical_source
    check_skill_format
    check_symlinks
    check_no_global_skills
    check_no_duplicates
    check_skills_cli
    check_expected_skills

    print_summary

    [[ $FAIL -gt 0 ]] && exit 1
    exit 0
}

main "$@"
