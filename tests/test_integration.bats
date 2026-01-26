#!/usr/bin/env bats
# test_integration.bats - End-to-end integration tests
# Run with: bats tests/test_integration.bats

# These tests verify the complete setup works together

setup() {
  # Change to project directory
  cd "$BATS_TEST_DIRNAME/.." || exit 1
}

# =============================================================================
# Configuration Files
# =============================================================================

@test "main.pkl configuration file exists" {
  [ -f "config/main.pkl" ]
}

@test "starship.toml configuration file exists" {
  [ -f "config/starship.toml" ]
}

@test "setup.sh is executable" {
  [ -x "setup.sh" ]
}

@test "validate.sh is executable" {
  [ -x "config/scripts/validate.sh" ]
}

# =============================================================================
# Chezmoi Templates
# =============================================================================

@test "chezmoi directory structure exists" {
  [ -d "config/chezmoi" ]
}

@test "zshrc template exists and has content" {
  [ -f "config/chezmoi/dot_zshrc.tmpl" ]
  [ -s "config/chezmoi/dot_zshrc.tmpl" ]
}

@test "gitconfig template exists and has content" {
  [ -f "config/chezmoi/dot_gitconfig.tmpl" ]
  [ -s "config/chezmoi/dot_gitconfig.tmpl" ]
}

# =============================================================================
# Test Directory
# =============================================================================

@test "tests directory exists" {
  [ -d "tests" ]
}

@test "all test files are executable or bats files" {
  for f in tests/*.bats; do
    [ -f "$f" ]
  done
}

# =============================================================================
# Documentation
# =============================================================================

@test "README.md exists" {
  [ -f "README.md" ]
}

@test "CLAUDE.md exists" {
  [ -f "CLAUDE.md" ]
}

@test "PROJECT_PLAN.md exists" {
  [ -f "PROJECT_PLAN.md" ]
}

# =============================================================================
# Key Content Checks
# =============================================================================

@test "main.pkl has bun configured" {
  grep -q 'bun' config/main.pkl
}

@test "main.pkl has uv configured" {
  grep -q 'uv' config/main.pkl
}

@test "main.pkl has pixi configured" {
  grep -q 'pixi' config/main.pkl
}

@test "main.pkl has starship configured" {
  grep -q 'starship' config/main.pkl
}

@test "main.pkl has chezmoi configured" {
  grep -q 'chezmoi' config/main.pkl
}

@test "main.pkl has pitchfork configured" {
  grep -q 'pitchfork' config/main.pkl
}

@test "setup.sh references mise" {
  grep -q 'mise' setup.sh
}

@test "zshrc template sources mise" {
  grep -q 'mise activate' config/chezmoi/dot_zshrc.tmpl
}

@test "zshrc template sources starship" {
  grep -q 'starship init' config/chezmoi/dot_zshrc.tmpl
}

# =============================================================================
# Pkl Compilation (if pkl available)
# =============================================================================

@test "main.pkl is valid Pkl syntax" {
  if ! command -v pkl &> /dev/null; then
    skip "pkl not installed"
  fi
  run pkl eval config/main.pkl
  [ "$status" -eq 0 ]
}

@test "main.pkl can generate TOML" {
  if ! command -v pkl &> /dev/null; then
    skip "pkl not installed"
  fi
  run pkl eval -f toml config/main.pkl
  [ "$status" -eq 0 ]
  [[ "$output" =~ "[tools]" ]]
}
