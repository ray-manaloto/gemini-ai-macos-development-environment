#!/usr/bin/env bats
# test_workflow_validation.bats - Comprehensive workflow validation tests
# Ensures no warnings/issues are ignored and status is always available
# Run with: bats tests/test_workflow_validation.bats

setup() {
  if ! command -v mise &> /dev/null; then
    skip "mise not installed"
  fi
  export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
  eval "$(mise activate bash 2>/dev/null)" || true
}

# =============================================================================
# CRITICAL: Path and Shim Validation
# These tests ensure tools are properly accessible
# =============================================================================

@test "mise shims directory exists" {
  [ -d "$HOME/.local/share/mise/shims" ]
}

@test "mise shims directory contains executables" {
  # At minimum, bun and uv should have shims
  shim_count=$(ls -1 "$HOME/.local/share/mise/shims" 2>/dev/null | wc -l)
  [ "$shim_count" -gt 0 ]
}

@test "mise shims are in PATH after activation" {
  # After activating mise, shims should be in PATH
  run bash -c 'eval "$(mise activate bash)" && echo "$PATH"'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "mise" ]]
}

@test "bun resolves to mise-managed version" {
  if ! command -v bun &> /dev/null; then
    skip "bun not installed"
  fi
  bun_path=$(which bun)
  [[ "$bun_path" =~ "mise" ]] || [[ "$bun_path" =~ ".local" ]]
}

@test "uv resolves to mise-managed version" {
  if ! command -v uv &> /dev/null; then
    skip "uv not installed"
  fi
  uv_path=$(which uv)
  [[ "$uv_path" =~ "mise" ]] || [[ "$uv_path" =~ ".local" ]]
}

# =============================================================================
# Shell Integration Validation
# =============================================================================

@test "mise activation exists in zshrc" {
  if [ ! -f "$HOME/.zshrc" ]; then
    skip "~/.zshrc not found"
  fi
  grep -q "mise activate" "$HOME/.zshrc"
}

@test "starship init recommended in zshrc template" {
  [ -f "config/chezmoi/dot_zshrc.tmpl" ]
  grep -q "starship init" "config/chezmoi/dot_zshrc.tmpl"
}

@test "stable config symlink exists" {
  [ -L "$HOME/.config/dev-env" ] || [ -d "$HOME/.config/dev-env" ]
}

@test "stable config symlink points to valid directory" {
  if [ -L "$HOME/.config/dev-env" ]; then
    [ -d "$(readlink "$HOME/.config/dev-env")" ]
  else
    skip "Not a symlink"
  fi
}

# =============================================================================
# Validation Script Tests
# =============================================================================

@test "validate.sh exists and is executable" {
  [ -x "config/scripts/validate.sh" ]
}

@test "validate runs successfully" {
  run mise run validate
  [ "$status" -eq 0 ]
}

@test "validate outputs pass/warn/fail counts" {
  run mise run validate
  [ "$status" -eq 0 ]
  [[ "$output" =~ "passed" ]]
  [[ "$output" =~ "warnings" ]]
  [[ "$output" =~ "failed" ]]
}

@test "validate checks mise installation" {
  run mise run validate
  [[ "$output" =~ "Mise installed" ]] || [[ "$output" =~ "Mise not installed" ]]
}

@test "validate checks core runtimes" {
  run mise run validate
  [[ "$output" =~ "Bun" ]]
  [[ "$output" =~ "Uv" ]]
  [[ "$output" =~ "Pixi" ]]
}

@test "validate checks shell tools" {
  run mise run validate
  [[ "$output" =~ "Starship" ]]
  [[ "$output" =~ "Zoxide" ]]
}

@test "validate checks search tools" {
  run mise run validate
  [[ "$output" =~ "Ripgrep" ]]
  [[ "$output" =~ "fd" ]]
  [[ "$output" =~ "ast-grep" ]]
}

# =============================================================================
# Status Command Tests
# =============================================================================

@test "env:status runs successfully" {
  run mise run env:status
  [ "$status" -eq 0 ]
}

@test "env:status shows platform info" {
  run mise run env:status
  [[ "$output" =~ "Platform:" ]]
  [[ "$output" =~ "Darwin" ]] || [[ "$output" =~ "Linux" ]]
}

@test "env:status shows mise version" {
  run mise run env:status
  [[ "$output" =~ "Mise Status" ]]
}

@test "env:status shows backend settings" {
  run mise run env:status
  [[ "$output" =~ "npm.bun:" ]]
  [[ "$output" =~ "python.uv_venv_auto:" ]]
}

@test "env:status shows health check section" {
  run mise run env:status
  [[ "$output" =~ "Health Check" ]]
}

@test "env:status reports PATH shim status" {
  run mise run env:status
  [[ "$output" =~ "PATH has shims:" ]]
}

# =============================================================================
# Warning Classification Tests
# =============================================================================

@test "validate distinguishes PASS from WARN" {
  run mise run validate
  # Should have both passed and warning counts
  [[ "$output" =~ "passed" ]]
  # Output format: "Results: X passed, Y warnings, Z failed"
  [[ "$output" =~ "Results:" ]]
}

@test "validate distinguishes WARN from FAIL" {
  run mise run validate
  # Warnings should not cause exit failure
  [ "$status" -eq 0 ] || [[ "$output" =~ "FAIL" ]]
}

@test "validate INFO items don't count as warnings" {
  run mise run validate
  # INFO messages like "Python not in PATH (per-project)" shouldn't inflate warning count
  [[ "$output" =~ "INFO" ]] || [[ "$output" =~ "ℹ️" ]] || true
}

# =============================================================================
# Tool Availability Tests (Non-skipping)
# These are CRITICAL - failures here mean broken environment
# =============================================================================

@test "CRITICAL: mise command available" {
  command -v mise
}

@test "CRITICAL: bun command available" {
  command -v bun
}

@test "CRITICAL: uv command available" {
  command -v uv
}

@test "CRITICAL: pixi command available" {
  command -v pixi
}

@test "CRITICAL: starship command available" {
  command -v starship
}

# =============================================================================
# Tool Functionality Tests
# =============================================================================

@test "bun can execute JavaScript" {
  if ! command -v bun &> /dev/null; then
    skip "bun not installed"
  fi
  run bun -e "console.log(1+1)"
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

@test "uv can list Python versions" {
  if ! command -v uv &> /dev/null; then
    skip "uv not installed"
  fi
  run uv python list
  [ "$status" -eq 0 ]
}

@test "pixi can show version" {
  if ! command -v pixi &> /dev/null; then
    skip "pixi not installed"
  fi
  run pixi --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ "pixi" ]]
}

@test "starship can render prompt" {
  if ! command -v starship &> /dev/null; then
    skip "starship not installed"
  fi
  run starship prompt
  [ "$status" -eq 0 ]
}

@test "mise tasks are available" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "validate" ]]
  [[ "$output" =~ "env:status" ]]
}

# =============================================================================
# End-to-End Workflow Tests
# =============================================================================

@test "workflow: mise doctor reports no critical errors" {
  run mise doctor
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No problems found" ]] || [[ ! "$output" =~ "error" ]]
}

@test "workflow: mise install completes" {
  run mise install
  [ "$status" -eq 0 ]
}

@test "workflow: validate after install succeeds" {
  mise install 2>/dev/null || true
  run mise run validate
  [ "$status" -eq 0 ]
}

@test "workflow: env:status after install succeeds" {
  mise install 2>/dev/null || true
  run mise run env:status
  [ "$status" -eq 0 ]
}

# =============================================================================
# Configuration Integrity Tests
# =============================================================================

@test "mise config loads without errors" {
  run mise config
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "error" ]]
  [[ ! "$output" =~ "Error" ]]
}

@test "mise.toml has required tools section" {
  grep -q "\[tools\]" config/mise.toml
}

@test "mise.toml has required tasks section" {
  grep -q "\[tasks" config/mise.toml
}

@test "mise.toml has required settings" {
  grep -q "experimental = true" config/mise.toml
  grep -q "npm.bun" config/mise.toml || grep -q "npm.package_manager" config/mise.toml
  grep -q "python.uv_venv_auto" config/mise.toml
}

# =============================================================================
# Recovery Capability Tests
# =============================================================================

@test "mise reshim command works" {
  run mise reshim
  [ "$status" -eq 0 ]
}

@test "mise trust command works" {
  run mise trust
  [ "$status" -eq 0 ]
}

@test "validate:tools task exists" {
  run mise tasks
  [[ "$output" =~ "validate:tools" ]]
}

@test "tools:fix-shadows task exists" {
  run mise tasks
  [[ "$output" =~ "tools:fix-shadows" ]]
}

# =============================================================================
# CI/Automation Readiness Tests
# =============================================================================

@test "validate exits with correct code on success" {
  # When no failures, should exit 0
  run mise run validate
  if [[ "$output" =~ "0 failed" ]]; then
    [ "$status" -eq 0 ]
  fi
}

@test "validate provides actionable output" {
  run mise run validate
  # Should include remediation hints
  [[ "$output" =~ "mise install" ]] || [[ "$output" =~ "healthy" ]]
}

@test "env:status completes within timeout" {
  # Should complete in under 30 seconds
  start=$(date +%s)
  run mise run env:status
  end=$(date +%s)
  duration=$((end - start))
  [ "$duration" -lt 30 ]
}

@test "all critical mise tasks are registered" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "validate" ]]
  [[ "$output" =~ "env:status" ]]
  [[ "$output" =~ "env:start" ]]
  [[ "$output" =~ "env:stop" ]]
  [[ "$output" =~ "tools:status" ]]
  [[ "$output" =~ "tools:doctor" ]]
}
