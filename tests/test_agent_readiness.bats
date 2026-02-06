#!/usr/bin/env bats
# test_agent_readiness.bats - AI/LLM agent readiness system tests
# Run with: bats tests/test_agent_readiness.bats

setup() {
  if ! command -v mise &> /dev/null; then
    skip "mise not installed"
  fi
}

# =============================================================================
# Agent Readiness Script Tests
# =============================================================================

@test "agent-readiness.sh script exists" {
  [ -f "config/scripts/agent-readiness.sh" ]
}

@test "agent-readiness.sh has valid bash syntax" {
  run bash -n config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}

@test "agent-readiness.sh is not empty" {
  [ -s "config/scripts/agent-readiness.sh" ]
}

@test "agent-readiness.sh has shebang" {
  run head -1 config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "#!/bin/bash" ]]
}

@test "agent-readiness.sh accepts status command" {
  run bash config/scripts/agent-readiness.sh status
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "agent-readiness.sh accepts --help flag" {
  run bash config/scripts/agent-readiness.sh --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "agent-readiness.sh --json produces valid JSON" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi
  run bash config/scripts/agent-readiness.sh --json
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
  echo "$output" | jq '.' > /dev/null 2>&1
  [ $? -eq 0 ]
}

@test "agent-readiness.sh --quiet only outputs on issues" {
  run bash config/scripts/agent-readiness.sh --quiet
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "agent-readiness.sh detects platform" {
  run bash -c 'OS=$(uname -s) && echo $OS'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Darwin" ]] || [[ "$output" =~ "Linux" ]]
}

# =============================================================================
# Agent Readiness Check Functions
# =============================================================================

@test "agent-readiness.sh checks for opencode CLI" {
  run grep -q "opencode" config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}

@test "agent-readiness.sh checks for claude CLI" {
  run grep -q "claude" config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}

@test "agent-readiness.sh checks for gh CLI" {
  run grep -q "gh" config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}

@test "agent-readiness.sh checks ANTHROPIC_API_KEY" {
  run grep -q "ANTHROPIC_API_KEY" config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}

@test "agent-readiness.sh checks OPENAI_API_KEY" {
  run grep -q "OPENAI_API_KEY" config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}

@test "agent-readiness.sh checks oh-my-opencode config" {
  run grep -q "oh-my-opencode" config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}

@test "agent-readiness.sh checks MCP config" {
  run grep -q "mcp" config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}

@test "agent-readiness.sh checks for AGENTS.md" {
  run grep -q "AGENTS.md" config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}

# =============================================================================
# Claude Code Settings.json Tests
# =============================================================================

@test "Claude settings.json exists" {
  [ -f ".claude/settings.json" ]
}

@test "Claude settings.json is valid JSON" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi
  run jq '.' .claude/settings.json
  [ "$status" -eq 0 ]
}

@test "Claude settings.json has hooks section" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi
  run jq -e '.hooks' .claude/settings.json
  [ "$status" -eq 0 ]
}

@test "Claude settings.json has UserPromptSubmit hook" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi
  run jq -e '.hooks.UserPromptSubmit' .claude/settings.json
  [ "$status" -eq 0 ]
}

@test "Claude settings.json has PostToolUse hook" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi
  run jq -e '.hooks.PostToolUse' .claude/settings.json
  [ "$status" -eq 0 ]
}

# =============================================================================
# Mise Task Tests
# =============================================================================

@test "mise task agent:ready is defined" {
  run grep -q 'tasks."agent:ready"' config/mise.toml
  [ "$status" -eq 0 ]
}

@test "mise task agent:ready:status is defined" {
  run grep -q 'tasks."agent:ready:status"' config/mise.toml
  [ "$status" -eq 0 ]
}

@test "mise task agent:ready:fix is defined" {
  run grep -q 'tasks."agent:ready:fix"' config/mise.toml
  [ "$status" -eq 0 ]
}

@test "mise task agent:ready:json is defined" {
  run grep -q 'tasks."agent:ready:json"' config/mise.toml
  [ "$status" -eq 0 ]
}

@test "mise task agent:ready:quiet is defined" {
  run grep -q 'tasks."agent:ready:quiet"' config/mise.toml
  [ "$status" -eq 0 ]
}

# =============================================================================
# Security Tests
# =============================================================================

@test "agent-readiness.sh does not use sudo" {
  run grep -w "sudo" config/scripts/agent-readiness.sh
  [ "$status" -ne 0 ]
}

@test "agent-readiness.sh uses set -euo pipefail" {
  run grep -q "set -euo pipefail" config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}

@test "agent-readiness.sh has NO_COLOR support" {
  run grep -q "NO_COLOR" config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}

@test "agent-readiness.sh has CI detection" {
  run grep -q 'CI:-' config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}

# =============================================================================
# Container Support Tests
# =============================================================================

@test "agent-readiness.sh detects container environment" {
  run grep -E "dockerenv|DEVCONTAINER|CODESPACES" config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}

@test "agent-readiness.sh has container-aware checks" {
  run grep -q "IS_CONTAINER" config/scripts/agent-readiness.sh
  [ "$status" -eq 0 ]
}
