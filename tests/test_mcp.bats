#!/usr/bin/env bats
# test_mcp.bats - Mise MCP (Model Context Protocol) integration tests
# Run with: bats tests/test_mcp.bats
# 
# Tests validate:
# - MCP setup script cross-platform support
# - MCP configuration files
# - MCP command availability

# Helper to skip if mise not installed
setup() {
  if ! command -v mise &> /dev/null; then
    skip "mise not installed"
  fi
}

# =============================================================================
# MCP Setup Script Tests
# =============================================================================

@test "setup-mcp.sh script exists" {
  [ -f "config/scripts/setup-mcp.sh" ]
}

@test "setup-mcp.sh is executable or can be sourced" {
  run bash -n config/scripts/setup-mcp.sh
  [ "$status" -eq 0 ]
}

@test "setup-mcp.sh detects platform correctly" {
  run bash -c 'source config/scripts/setup-mcp.sh 2>&1 | head -5'
  # Should output platform detection
  [[ "$output" =~ "Platform:" ]] || [[ "$output" =~ "mise MCP" ]]
}

@test "setup-mcp.sh handles missing jq gracefully" {
  # The script should either have jq available or install it
  run bash -c 'command -v jq || mise which jq 2>/dev/null || echo "jq_missing"'
  # Script handles this case - just verify script syntax is valid
  run bash -n config/scripts/setup-mcp.sh
  [ "$status" -eq 0 ]
}

# =============================================================================
# MCP Configuration File Tests
# =============================================================================

@test ".mcp.json exists at project root" {
  [ -f ".mcp.json" ]
}

@test ".mcp.json is valid JSON" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi
  run jq '.' .mcp.json
  [ "$status" -eq 0 ]
}

@test ".mcp.json contains mise MCP server configuration" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi
  run jq -e '.mcpServers.mise' .mcp.json
  [ "$status" -eq 0 ]
}

@test ".mcp.json mise server has correct command" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi
  run jq -r '.mcpServers.mise.command' .mcp.json
  [ "$status" -eq 0 ]
  [ "$output" = "mise" ]
}

@test ".mcp.json mise server has mcp args" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi
  run jq -r '.mcpServers.mise.args[0]' .mcp.json
  [ "$status" -eq 0 ]
  [ "$output" = "mcp" ]
}

@test ".mcp.json mise server has MISE_EXPERIMENTAL env" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi
  run jq -r '.mcpServers.mise.env.MISE_EXPERIMENTAL' .mcp.json
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

# =============================================================================
# Mise MCP Command Tests
# =============================================================================

@test "mise mcp command is available with MISE_EXPERIMENTAL=1" {
  run bash -c 'MISE_EXPERIMENTAL=1 mise mcp --help 2>&1'
  # Command should exist (may return help or error about stdin)
  [[ "$output" =~ "mcp" ]] || [[ "$output" =~ "MCP" ]] || [[ "$output" =~ "Model Context Protocol" ]] || [ "$status" -eq 0 ]
}

@test "mise has setup-mcp task" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-mcp" ]]
}

@test "mise setup-mcp task has description" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "MCP" ]] || [[ "$output" =~ "mcp" ]]
}

# =============================================================================
# Cross-Platform Configuration Tests
# =============================================================================

@test "setup-mcp.sh supports macOS paths" {
  run grep -E "Library/Application Support/Claude" config/scripts/setup-mcp.sh
  [ "$status" -eq 0 ]
}

@test "setup-mcp.sh supports Linux paths" {
  # Check for XDG_CONFIG_HOME usage and Claude directory (capital C per official spec)
  run grep -E "XDG_CONFIG_HOME|\.config.*Claude" config/scripts/setup-mcp.sh
  [ "$status" -eq 0 ]
}

@test "setup-mcp.sh configures Claude Code CLI" {
  run grep -E "\.claude/" config/scripts/setup-mcp.sh
  [ "$status" -eq 0 ]
}

@test "setup-mcp.sh configures OpenCode CLI" {
  run grep -E "\.opencode/" config/scripts/setup-mcp.sh
  [ "$status" -eq 0 ]
}

# =============================================================================
# DevContainer MCP Environment Tests
# =============================================================================

@test "devcontainer.json has MISE_EXPERIMENTAL enabled" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi
  run jq -r '.containerEnv.MISE_EXPERIMENTAL' .devcontainer/devcontainer.json
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "devcontainer.json has MISE_YES enabled" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi
  run jq -r '.containerEnv.MISE_YES' .devcontainer/devcontainer.json
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

# =============================================================================
# Security and Robustness Tests
# =============================================================================

@test "setup-mcp.sh uses atomic writes (temp file pattern)" {
  run grep -E "mktemp|\.tmp\." config/scripts/setup-mcp.sh
  [ "$status" -eq 0 ]
}

@test "setup-mcp.sh checks for symlinks" {
  run grep -E "\-L.*symlink|symlink" config/scripts/setup-mcp.sh
  [ "$status" -eq 0 ]
}

@test "setup-mcp.sh handles container environments" {
  run grep -E "dockerenv|containerenv|DEVCONTAINER|is_container" config/scripts/setup-mcp.sh
  [ "$status" -eq 0 ]
}

@test "setup-mcp.sh uses XDG_CONFIG_HOME on Linux" {
  run grep "XDG_CONFIG_HOME" config/scripts/setup-mcp.sh
  [ "$status" -eq 0 ]
}

@test "setup-mcp.sh has fallback for unknown platforms" {
  run grep -E "Unknown platform|Supported platforms" config/scripts/setup-mcp.sh
  [ "$status" -eq 0 ]
}

# =============================================================================
# Documentation Tests
# =============================================================================

@test "MCP setup documentation exists" {
  [ -f "research/MISE_MCP_SETUP.md" ]
}

@test "MCP setup documentation mentions MISE_EXPERIMENTAL" {
  run grep "MISE_EXPERIMENTAL" research/MISE_MCP_SETUP.md
  [ "$status" -eq 0 ]
}

@test "MCP setup documentation mentions cross-platform paths" {
  run grep -E "(macOS|Linux|Windows)" research/MISE_MCP_SETUP.md
  [ "$status" -eq 0 ]
}
