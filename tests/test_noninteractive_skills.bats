#!/usr/bin/env bats
# test_noninteractive_skills.bats - Verify non-interactive command skills
# Run with: bats tests/test_noninteractive_skills.bats

# =============================================================================
# Skill File Existence Tests
# =============================================================================

@test "analyze skill file exists" {
  [ -f ".opencode/skills/analyze/SKILL.md" ]
}

@test "investigate skill file exists" {
  [ -f ".opencode/skills/investigate/SKILL.md" ]
}

@test "refactor skill file exists" {
  [ -f ".opencode/skills/refactor/SKILL.md" ]
}

@test "tdd skill file exists" {
  [ -f ".opencode/skills/tdd/SKILL.md" ]
}

# =============================================================================
# Non-Interactive Pattern Tests
# =============================================================================

@test "analyze skill has NO question patterns" {
  run grep -i "would you like\|should I\|what would\|AskUserQuestion" .opencode/skills/analyze/SKILL.md
  [ "$status" -ne 0 ]  # grep should NOT find these patterns
}

@test "investigate skill has NO question patterns" {
  run grep -i "would you like\|should I\|what would\|AskUserQuestion" .opencode/skills/investigate/SKILL.md
  [ "$status" -ne 0 ]
}

@test "refactor skill has NO question patterns" {
  run grep -i "would you like\|should I\|what would\|AskUserQuestion" .opencode/skills/refactor/SKILL.md
  [ "$status" -ne 0 ]
}

@test "tdd skill has NO question patterns" {
  run grep -i "would you like\|should I\|what would\|AskUserQuestion" .opencode/skills/tdd/SKILL.md
  [ "$status" -ne 0 ]
}

# =============================================================================
# Continuous Stream Pattern Tests
# =============================================================================

@test "analyze skill has ASSUMPTION logging" {
  run grep -i "ASSUMPTION:" .opencode/skills/analyze/SKILL.md
  [ "$status" -eq 0 ]  # Should find ASSUMPTION pattern
}

@test "investigate skill has ASSUMPTION logging" {
  run grep -i "ASSUMPTION:" .opencode/skills/investigate/SKILL.md
  [ "$status" -eq 0 ]
}

@test "refactor skill has ASSUMPTION logging" {
  run grep -i "ASSUMPTION:" .opencode/skills/refactor/SKILL.md
  [ "$status" -eq 0 ]
}

@test "tdd skill has ASSUMPTION logging" {
  run grep -i "ASSUMPTION:" .opencode/skills/tdd/SKILL.md
  [ "$status" -eq 0 ]
}

# =============================================================================
# Error Handling Tests
# =============================================================================

@test "analyze skill has ERROR handling for missing args" {
  run grep -i "ERROR:.*missing\|ERROR:.*Usage" .opencode/skills/analyze/SKILL.md
  [ "$status" -eq 0 ]
}

@test "investigate skill has ERROR handling for missing args" {
  run grep -i "ERROR:.*missing\|ERROR:.*Usage" .opencode/skills/investigate/SKILL.md
  [ "$status" -eq 0 ]
}

@test "refactor skill has ERROR handling for missing args" {
  run grep -i "ERROR:.*missing\|ERROR:.*Usage" .opencode/skills/refactor/SKILL.md
  [ "$status" -eq 0 ]
}

@test "tdd skill has ERROR handling for missing args" {
  run grep -i "ERROR:.*missing\|ERROR:.*Usage" .opencode/skills/tdd/SKILL.md
  [ "$status" -eq 0 ]
}

# =============================================================================
# YAML Frontmatter Tests
# =============================================================================

@test "analyze skill has valid YAML frontmatter" {
  run head -1 .opencode/skills/analyze/SKILL.md
  [ "$output" = "---" ]
}

@test "analyze skill has mode: non-interactive in metadata" {
  run grep "mode: non-interactive" .opencode/skills/analyze/SKILL.md
  [ "$status" -eq 0 ]
}

@test "investigate skill has mode: non-interactive in metadata" {
  run grep "mode: non-interactive" .opencode/skills/investigate/SKILL.md
  [ "$status" -eq 0 ]
}

@test "refactor skill has mode: non-interactive in metadata" {
  run grep "mode: non-interactive" .opencode/skills/refactor/SKILL.md
  [ "$status" -eq 0 ]
}

@test "tdd skill has mode: non-interactive in metadata" {
  run grep "mode: non-interactive" .opencode/skills/tdd/SKILL.md
  [ "$status" -eq 0 ]
}

# =============================================================================
# Forbidden Pattern Tests (Comprehensive)
# =============================================================================

@test "analyze skill has NO Intent Gate pattern" {
  run grep -i "intent gate\|clarifying question\|Options I see" .opencode/skills/analyze/SKILL.md
  [ "$status" -ne 0 ]
}

@test "refactor skill has NO Intent Gate pattern" {
  run grep -i "intent gate\|clarifying question\|Options I see" .opencode/skills/refactor/SKILL.md
  [ "$status" -ne 0 ]
}

# =============================================================================
# Read-Only Enforcement Tests
# =============================================================================

@test "analyze skill declares read-only" {
  run grep -i "read-only\|NEVER modify\|do not write" .opencode/skills/analyze/SKILL.md
  [ "$status" -eq 0 ]
}

@test "investigate skill declares read-only" {
  run grep -i "read-only\|NEVER modify\|do not write" .opencode/skills/investigate/SKILL.md
  [ "$status" -eq 0 ]
}
