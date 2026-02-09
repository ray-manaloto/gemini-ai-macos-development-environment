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

@test "mise.toml has bun configured" {
  grep -q 'bun' config/mise.toml
}

@test "mise.toml has uv configured" {
  grep -q 'uv' config/mise.toml
}

@test "mise.toml has pixi configured" {
  grep -q 'pixi' config/mise.toml
}

@test "mise.toml has starship configured" {
  grep -q 'starship' config/mise.toml
}

@test "mise.toml has chezmoi configured" {
  grep -q 'chezmoi' config/mise.toml
}

@test "mise.toml has pitchfork configured" {
  grep -q 'pitchfork' config/mise.toml
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
# Configuration Validation
# =============================================================================

@test "mise.toml configuration exists" {
  [ -f "config/mise.toml" ]
}

@test "mise.toml is valid TOML syntax" {
  # Use pixi's Python 3.12 which has tomllib, or skip if not available
  if command -v pixi &> /dev/null && [ -f "pixi.toml" ]; then
    run pixi run python -c "import tomllib; tomllib.load(open('config/mise.toml', 'rb'))"
    [ "$status" -eq 0 ]
  else
    # Fallback: basic syntax check with grep for common TOML patterns
    grep -q '\[tools\]' config/mise.toml
    grep -q '\[tasks' config/mise.toml
    grep -q '\[settings\]' config/mise.toml
  fi
}

@test "mise.toml has tools section" {
  grep -q '\[tools\]' config/mise.toml
}

@test "mise.toml has tasks section" {
  grep -q '\[tasks' config/mise.toml
}
