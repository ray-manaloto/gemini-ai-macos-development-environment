#!/usr/bin/env bats
# test_tools.bats - Tool availability tests
# Run with: bats tests/test_tools.bats

# Helper function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Skip tests if mise not installed
setup() {
  if ! command -v mise &> /dev/null; then
    skip "mise not installed - run setup.sh first"
  fi
}

# =============================================================================
# Core Runtimes
# =============================================================================

@test "bun is installed" {
  if ! command_exists bun; then
    skip "bun not yet installed"
  fi
  run bun --version
  [ "$status" -eq 0 ]
}

@test "uv is installed" {
  if ! command_exists uv; then
    skip "uv not yet installed"
  fi
  run uv --version
  [ "$status" -eq 0 ]
}

@test "pixi is installed" {
  if ! command_exists pixi; then
    skip "pixi not yet installed"
  fi
  run pixi --version
  [ "$status" -eq 0 ]
}

# =============================================================================
# Shell Tools
# =============================================================================

@test "starship is installed" {
  if ! command_exists starship; then
    skip "starship not yet installed"
  fi
  run starship --version
  [ "$status" -eq 0 ]
}

@test "zoxide is installed" {
  if ! command_exists zoxide; then
    skip "zoxide not yet installed"
  fi
  run zoxide --version
  [ "$status" -eq 0 ]
}

@test "atuin is installed" {
  if ! command_exists atuin; then
    skip "atuin not yet installed"
  fi
  run atuin --version
  [ "$status" -eq 0 ]
}

@test "age is installed" {
  if ! command_exists age; then
    skip "age not yet installed"
  fi
  run age --version
  [ "$status" -eq 0 ]
}

# =============================================================================
# Search Tools
# =============================================================================

@test "ripgrep (rg) is installed" {
  if ! command_exists rg; then
    skip "ripgrep not yet installed"
  fi
  run rg --version
  [ "$status" -eq 0 ]
}

@test "fd is installed" {
  if ! command_exists fd; then
    skip "fd not yet installed"
  fi
  run fd --version
  [ "$status" -eq 0 ]
}

@test "ast-grep (sg) is installed" {
  if ! command_exists sg; then
    skip "ast-grep not yet installed"
  fi
  run sg --version
  [ "$status" -eq 0 ]
}

# =============================================================================
# Dotfile Management
# =============================================================================

@test "chezmoi is installed" {
  if ! command_exists chezmoi; then
    skip "chezmoi not yet installed"
  fi
  run chezmoi --version
  [ "$status" -eq 0 ]
}

# =============================================================================
# AI Tools
# =============================================================================

@test "github cli (gh) is installed" {
  if ! command_exists gh; then
    skip "github-cli not yet installed"
  fi
  run gh --version
  [ "$status" -eq 0 ]
}

# =============================================================================
# Integration Tests
# =============================================================================

@test "bun can run a simple script" {
  if ! command_exists bun; then
    skip "bun not yet installed"
  fi
  run bun -e "console.log('hello')"
  [ "$status" -eq 0 ]
  [ "$output" = "hello" ]
}

@test "uv can show python versions" {
  if ! command_exists uv; then
    skip "uv not yet installed"
  fi
  run uv python list
  [ "$status" -eq 0 ]
}

@test "starship can render prompt" {
  if ! command_exists starship; then
    skip "starship not yet installed"
  fi
  run starship prompt
  [ "$status" -eq 0 ]
}
