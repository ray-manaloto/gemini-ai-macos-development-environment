#!/usr/bin/env bats
# test_setup.bats - Bootstrap script validation tests
# Run with: bats tests/test_setup.bats

# These tests verify the setup.sh script structure and behavior
# without actually running the full destructive setup

setup() {
  # Change to project directory
  cd "$BATS_TEST_DIRNAME/.." || exit 1
}

# =============================================================================
# Script Structure and Metadata
# =============================================================================

@test "setup.sh exists and is executable" {
  [ -f "setup.sh" ]
  [ -x "setup.sh" ]
}

@test "setup.sh has proper shebang" {
  head -1 setup.sh | grep -q "#!/bin/bash"
}

@test "setup.sh uses strict error handling (set -e)" {
  grep -q "^set -e" setup.sh
}

@test "setup.sh defines REPO_DIR variable" {
  grep -q 'REPO_DIR=' setup.sh
}

@test "setup.sh defines STABLE_DIR variable" {
  grep -q 'STABLE_DIR=.*config/dev-env' setup.sh
}

# =============================================================================
# Prerequisites Validation
# =============================================================================

@test "setup.sh checks for existing mise installation" {
  grep -q 'command -v mise' setup.sh
}

@test "setup.sh installs mise from official URL" {
  grep -q 'curl https://mise.run' setup.sh
}

@test "setup.sh adds mise to PATH" {
  grep -q 'PATH=.*\.local/bin' setup.sh
}

@test "setup.sh adds mise activation to zshrc" {
  grep -q 'mise activate zsh' setup.sh
}

@test "setup.sh checks for existing mise activation before adding" {
  grep -q "grep -q 'mise activate'" setup.sh
}

# =============================================================================
# Stable Path Configuration
# =============================================================================

@test "setup.sh creates stable configuration symlink" {
  grep -q 'ln -sfn.*STABLE_DIR' setup.sh
}

@test "setup.sh checks if symlink already exists" {
  grep -q '\[ -L.*STABLE_DIR' setup.sh
}

# =============================================================================
# Core Tool Installation Steps
# =============================================================================

@test "setup.sh installs pkl via mise" {
  grep -q 'mise use -g pkl' setup.sh
}

@test "setup.sh installs pixi via mise" {
  grep -q 'mise use -g.*pixi' setup.sh
}

@test "setup.sh installs gum via mise" {
  grep -q 'mise use -g.*gum' setup.sh
}

@test "setup.sh installs bun via mise" {
  grep -q 'mise use -g bun' setup.sh
}

@test "setup.sh installs uv via mise" {
  grep -q 'mise use -g uv' setup.sh
}

@test "setup.sh installs starship via mise" {
  grep -q 'mise use -g starship' setup.sh
}

@test "setup.sh installs chezmoi via mise" {
  grep -q 'mise use -g chezmoi' setup.sh
}

@test "setup.sh installs CLI utilities (zoxide, fd, ripgrep, etc.)" {
  grep -q 'mise use -g zoxide fd ripgrep bat eza fzf jq yq delta' setup.sh
}

# =============================================================================
# Configuration Deployment
# =============================================================================

@test "setup.sh copies starship.toml to user config" {
  grep -q 'cp.*starship.toml.*\.config/starship.toml' setup.sh
}

@test "setup.sh copies mise.toml to user config" {
  grep -q 'cp.*mise.toml.*\.config/mise/config.toml' setup.sh
}

@test "setup.sh creates ~/.config/mise directory" {
  grep -q 'mkdir -p.*\.config/mise' setup.sh
}

@test "setup.sh runs mise install" {
  grep -q 'mise install' setup.sh
}

# =============================================================================
# Chezmoi Setup
# =============================================================================

@test "setup.sh initializes chezmoi if not done" {
  grep -q 'chezmoi init' setup.sh
}

@test "setup.sh copies chezmoi templates" {
  grep -q 'cp.*chezmoi' setup.sh
}

# =============================================================================
# Dashboard/Pixi Setup
# =============================================================================

@test "setup.sh runs pixi install if pixi.toml exists" {
  grep -q 'pixi install' setup.sh
}

@test "setup.sh checks for pixi.toml before installing" {
  grep -q '\[ -f.*pixi.toml' setup.sh
}

# =============================================================================
# Optional SwiftBar Integration
# =============================================================================

@test "setup.sh checks for SwiftBar.app" {
  grep -q 'SwiftBar.app' setup.sh
}

# =============================================================================
# Post-Installation Output
# =============================================================================

@test "setup.sh displays completion message" {
  grep -q 'Setup Complete' setup.sh
}

@test "setup.sh provides next steps instructions" {
  grep -q 'Restart your terminal' setup.sh
  grep -q 'chezmoi apply' setup.sh
  grep -q 'mise doctor' setup.sh
}

@test "setup.sh displays installed versions" {
  grep -q 'mise --version' setup.sh
  grep -q 'bun --version' setup.sh
  grep -q 'uv --version' setup.sh
}

# =============================================================================
# Idempotency Checks
# =============================================================================

@test "setup.sh checks for existing starship installation" {
  grep -q 'command -v starship' setup.sh
}

@test "setup.sh checks for existing chezmoi installation" {
  grep -q 'command -v chezmoi' setup.sh
}

@test "setup.sh has idempotent symlink creation" {
  # Should check if symlink already points to correct target
  grep -q 'readlink.*STABLE_DIR.*REPO_DIR' setup.sh
}

# =============================================================================
# Error Handling
# =============================================================================

@test "setup.sh has colored output helpers" {
  grep -q 'RED=' setup.sh
  grep -q 'GREEN=' setup.sh
  grep -q 'YELLOW=' setup.sh
  grep -q 'BLUE=' setup.sh
}

@test "setup.sh has logging functions" {
  grep -q 'log_info()' setup.sh
  grep -q 'log_success()' setup.sh
  grep -q 'log_warn()' setup.sh
  grep -q 'log_error()' setup.sh
}

# =============================================================================
# Step Organization
# =============================================================================

@test "setup.sh has clear step markers" {
  # Count step markers (STEP 1, STEP 2, etc.)
  local step_count
  step_count=$(grep -c "STEP [0-9]" setup.sh)
  [ "$step_count" -ge 10 ]
}

@test "setup.sh has section separators" {
  grep -q "====" setup.sh
}

# =============================================================================
# Configuration File Dependencies
# =============================================================================

@test "config/mise.toml exists for setup to copy" {
  [ -f "config/mise.toml" ]
}

@test "config/starship.toml exists for setup to copy" {
  [ -f "config/starship.toml" ]
}

@test "config/chezmoi directory exists for setup to copy" {
  [ -d "config/chezmoi" ]
}

@test "pixi.toml exists for dashboard setup" {
  [ -f "pixi.toml" ]
}

# =============================================================================
# Spec Compliance
# =============================================================================

@test "setup spec exists" {
  [ -f "openspec/specs/setup/spec.md" ]
}

@test "setup spec has Gherkin scenarios" {
  grep -q "Given" openspec/specs/setup/spec.md
  grep -q "When" openspec/specs/setup/spec.md
  grep -q "Then" openspec/specs/setup/spec.md
}

@test "validation spec exists" {
  [ -f "openspec/specs/validation/spec.md" ]
}

@test "validation spec has Gherkin scenarios" {
  grep -q "Given" openspec/specs/validation/spec.md
  grep -q "When" openspec/specs/validation/spec.md
  grep -q "Then" openspec/specs/validation/spec.md
}
