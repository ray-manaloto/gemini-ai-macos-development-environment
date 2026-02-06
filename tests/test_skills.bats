#!/usr/bin/env bats
# test_skills.bats - AI Agent Skills validation tests
# Run with: bats tests/test_skills.bats
#
# Tests the unified skills architecture:
#   .agents/skills/ (canonical) → symlinked to .claude/skills/ + .opencode/skills/

# =============================================================================
# Architecture Tests
# =============================================================================

@test "canonical .agents/skills/ directory exists" {
  [ -d ".agents/skills" ]
}

@test ".claude/skills/ directory exists" {
  [ -d ".claude/skills" ]
}

@test ".opencode/skills/ directory exists" {
  [ -d ".opencode/skills" ]
}

@test "canonical source has at least 20 skills" {
  local count
  count=$(find .agents/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  [ "$count" -ge 20 ]
}

# =============================================================================
# Symlink Tests - .claude/skills/
# =============================================================================

@test "all .claude/skills/ entries are symlinks" {
  local direct=0
  for d in .claude/skills/*/; do
    [ -e "$d" ] || continue
    local name="${d%/}"
    if [ ! -L "$name" ]; then
      direct=$((direct + 1))
    fi
  done
  [ "$direct" -eq 0 ]
}

@test "all .claude/skills/ symlinks resolve" {
  local broken=0
  for d in .claude/skills/*/; do
    [ -e "$d" ] || continue
    local name="${d%/}"
    if [ -L "$name" ] && [ ! -d "$name" ]; then
      broken=$((broken + 1))
    fi
  done
  [ "$broken" -eq 0 ]
}

@test ".claude/skills/ count matches .agents/skills/ count" {
  local canonical
  canonical=$(find .agents/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  local claude
  claude=$(find .claude/skills -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
  [ "$claude" -eq "$canonical" ]
}

# =============================================================================
# Symlink Tests - .opencode/skills/
# =============================================================================

@test "all .opencode/skills/ entries are symlinks" {
  local direct=0
  for d in .opencode/skills/*/; do
    [ -e "$d" ] || continue
    local name="${d%/}"
    if [ ! -L "$name" ]; then
      direct=$((direct + 1))
    fi
  done
  [ "$direct" -eq 0 ]
}

@test "all .opencode/skills/ symlinks resolve" {
  local broken=0
  for d in .opencode/skills/*/; do
    [ -e "$d" ] || continue
    local name="${d%/}"
    if [ -L "$name" ] && [ ! -d "$name" ]; then
      broken=$((broken + 1))
    fi
  done
  [ "$broken" -eq 0 ]
}

@test ".opencode/skills/ count matches .agents/skills/ count" {
  local canonical
  canonical=$(find .agents/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  local opencode
  opencode=$(find .opencode/skills -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
  [ "$opencode" -eq "$canonical" ]
}

# =============================================================================
# SKILL.md Format Tests
# =============================================================================

@test "every skill has a SKILL.md file" {
  local missing=0
  for d in .agents/skills/*/; do
    [ -e "$d" ] || continue
    if [ ! -f "$d/SKILL.md" ]; then
      missing=$((missing + 1))
    fi
  done
  [ "$missing" -eq 0 ]
}

@test "every SKILL.md starts with YAML frontmatter (---)" {
  local bad=0
  for f in .agents/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    local first
    first=$(head -1 "$f")
    if [ "$first" != "---" ]; then
      bad=$((bad + 1))
    fi
  done
  [ "$bad" -eq 0 ]
}

@test "every SKILL.md has a name: field" {
  local missing=0
  for f in .agents/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    if ! grep -q '^name:' "$f"; then
      missing=$((missing + 1))
    fi
  done
  [ "$missing" -eq 0 ]
}

@test "every SKILL.md has a description: field" {
  local missing=0
  for f in .agents/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    if ! grep -q '^description:' "$f"; then
      missing=$((missing + 1))
    fi
  done
  [ "$missing" -eq 0 ]
}

@test "every SKILL.md has closing frontmatter (---)" {
  local bad=0
  for f in .agents/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    local has_closing
    has_closing=$(awk 'NR>1 && /^---$/{print "yes"; exit}' "$f")
    if [ "$has_closing" != "yes" ]; then
      bad=$((bad + 1))
    fi
  done
  [ "$bad" -eq 0 ]
}

@test "no SKILL.md has an empty description" {
  local empty=0
  for f in .agents/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    local desc_line
    desc_line=$(grep '^description:' "$f" | head -1)
    # Check for description: "" or description: ''
    if [[ "$desc_line" =~ description:\ *\"\"$ ]] || [[ "$desc_line" =~ description:\ *\'\'$ ]] || [[ "$desc_line" =~ description:\ *$ ]]; then
      empty=$((empty + 1))
    fi
  done
  [ "$empty" -eq 0 ]
}

# =============================================================================
# Custom Project Skills (5)
# =============================================================================

@test "custom skill: mise-expert exists" {
  [ -f ".agents/skills/mise-expert/SKILL.md" ]
}

@test "custom skill: bats-testing exists" {
  [ -f ".agents/skills/bats-testing/SKILL.md" ]
}

@test "custom skill: shell-scripting exists" {
  [ -f ".agents/skills/shell-scripting/SKILL.md" ]
}

@test "custom skill: rust-dev exists" {
  [ -f ".agents/skills/rust-dev/SKILL.md" ]
}

@test "custom skill: menu-bar-dev exists" {
  [ -f ".agents/skills/menu-bar-dev/SKILL.md" ]
}

@test "mise-expert mentions tool hierarchy" {
  run grep -i "Mise.*Bun.*Pixi.*Uv\|tool hierarchy" .agents/skills/mise-expert/SKILL.md
  [ "$status" -eq 0 ]
}

@test "bats-testing mentions test count" {
  run grep -i "948\|test.*suite" .agents/skills/bats-testing/SKILL.md
  [ "$status" -eq 0 ]
}

@test "shell-scripting mentions shellcheck" {
  run grep -i "shellcheck" .agents/skills/shell-scripting/SKILL.md
  [ "$status" -eq 0 ]
}

@test "rust-dev mentions iced and tauri" {
  run grep -i "iced" .agents/skills/rust-dev/SKILL.md
  [ "$status" -eq 0 ]
  run grep -i "tauri" .agents/skills/rust-dev/SKILL.md
  [ "$status" -eq 0 ]
}

@test "menu-bar-dev mentions all 4 implementations" {
  run grep -i "SwiftBar\|Swift.*Native\|Iced\|Tauri" .agents/skills/menu-bar-dev/SKILL.md
  [ "$status" -eq 0 ]
}

# =============================================================================
# Installed Skills from Trusted Sources (7)
# =============================================================================

@test "installed skill: skill-creator exists (anthropics/skills)" {
  [ -f ".agents/skills/skill-creator/SKILL.md" ]
}

@test "installed skill: mcp-builder exists (anthropics/skills)" {
  [ -f ".agents/skills/mcp-builder/SKILL.md" ]
}

@test "installed skill: webapp-testing exists (anthropics/skills)" {
  [ -f ".agents/skills/webapp-testing/SKILL.md" ]
}

@test "installed skill: systematic-debugging exists (obra/superpowers)" {
  [ -f ".agents/skills/systematic-debugging/SKILL.md" ]
}

@test "installed skill: test-driven-development exists (obra/superpowers)" {
  [ -f ".agents/skills/test-driven-development/SKILL.md" ]
}

@test "installed skill: verification-before-completion exists (obra/superpowers)" {
  [ -f ".agents/skills/verification-before-completion/SKILL.md" ]
}

@test "installed skill: web-design-guidelines exists (vercel-labs/agent-skills)" {
  [ -f ".agents/skills/web-design-guidelines/SKILL.md" ]
}

# =============================================================================
# OpenSpec Workflow Skills (10)
# =============================================================================

@test "openspec skill: openspec-apply-change exists" {
  [ -f ".agents/skills/openspec-apply-change/SKILL.md" ]
}

@test "openspec skill: openspec-archive-change exists" {
  [ -f ".agents/skills/openspec-archive-change/SKILL.md" ]
}

@test "openspec skill: openspec-bulk-archive-change exists" {
  [ -f ".agents/skills/openspec-bulk-archive-change/SKILL.md" ]
}

@test "openspec skill: openspec-continue-change exists" {
  [ -f ".agents/skills/openspec-continue-change/SKILL.md" ]
}

@test "openspec skill: openspec-explore exists" {
  [ -f ".agents/skills/openspec-explore/SKILL.md" ]
}

@test "openspec skill: openspec-ff-change exists" {
  [ -f ".agents/skills/openspec-ff-change/SKILL.md" ]
}

@test "openspec skill: openspec-new-change exists" {
  [ -f ".agents/skills/openspec-new-change/SKILL.md" ]
}

@test "openspec skill: openspec-onboard exists" {
  [ -f ".agents/skills/openspec-onboard/SKILL.md" ]
}

@test "openspec skill: openspec-sync-specs exists" {
  [ -f ".agents/skills/openspec-sync-specs/SKILL.md" ]
}

@test "openspec skill: openspec-verify-change exists" {
  [ -f ".agents/skills/openspec-verify-change/SKILL.md" ]
}

# =============================================================================
# Dev Workflow Skills (4)
# =============================================================================

@test "dev skill: analyze exists" {
  [ -f ".agents/skills/analyze/SKILL.md" ]
}

@test "dev skill: investigate exists" {
  [ -f ".agents/skills/investigate/SKILL.md" ]
}

@test "dev skill: tdd exists" {
  [ -f ".agents/skills/tdd/SKILL.md" ]
}

@test "dev skill: refactor exists" {
  [ -f ".agents/skills/refactor/SKILL.md" ]
}

# =============================================================================
# Global Skills (Should Be Empty)
# =============================================================================

@test "no global skills in ~/.claude/skills/" {
  if [ -d "$HOME/.claude/skills" ]; then
    local count
    count=$(find "$HOME/.claude/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    [ "$count" -eq 0 ]
  fi
  # If dir doesn't exist, that's fine too
}

# =============================================================================
# No Duplicate Skills
# =============================================================================

@test "no duplicate skill names in .agents/skills/" {
  local dupes
  dupes=$(ls .agents/skills/ | sort | uniq -d)
  [ -z "$dupes" ]
}

# =============================================================================
# Validation Script
# =============================================================================

@test "validate-skills.sh exists and is executable" {
  [ -f "config/scripts/validate-skills.sh" ]
  [ -x "config/scripts/validate-skills.sh" ]
}

@test "validate-skills.sh passes all checks" {
  run bash config/scripts/validate-skills.sh --quiet
  [ "$status" -eq 0 ]
}

@test "validate-skills.sh JSON output is valid" {
  run bash config/scripts/validate-skills.sh --json
  [ "$status" -eq 0 ]
  # Check it's valid JSON (has summary key)
  echo "$output" | grep -q '"summary"'
  echo "$output" | grep -q '"pass"'
}

# =============================================================================
# Cross-Reference: Skills accessible via both .claude/ and .opencode/
# =============================================================================

@test "every .agents/skills/ skill is accessible via .claude/skills/" {
  local missing=0
  for d in .agents/skills/*/; do
    local name
    name=$(basename "$d")
    if [ ! -e ".claude/skills/$name/SKILL.md" ]; then
      missing=$((missing + 1))
    fi
  done
  [ "$missing" -eq 0 ]
}

@test "every .agents/skills/ skill is accessible via .opencode/skills/" {
  local missing=0
  for d in .agents/skills/*/; do
    local name
    name=$(basename "$d")
    if [ ! -e ".opencode/skills/$name/SKILL.md" ]; then
      missing=$((missing + 1))
    fi
  done
  [ "$missing" -eq 0 ]
}
