#!/usr/bin/env bats
# test_env_status.bats - Non-interactive verification for mise run env:status
# Run with: bats tests/test_env_status.bats

# Helper to skip if mise not installed
setup() {
  if ! command -v mise &> /dev/null; then
    skip "mise not installed"
  fi
}

# =============================================================================
# TOML Configuration Tests
# =============================================================================

@test "env:status has valid TOML syntax" {
  # Config should parse without errors
  run mise config
  [ "$status" -eq 0 ]
  # Should not contain parse errors
  [[ ! "$output" =~ "TOML parse error" ]]
  [[ ! "$output" =~ "invalid escape sequence" ]]
}

@test "env:status task is registered" {
  # Task should be available in mise tasks list
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "env:status" ]]
}

# =============================================================================
# Non-Interactive Execution Tests
# =============================================================================

@test "env:status completes within timeout" {
  # Should complete within 15 seconds (non-interactive)
  # Use perl for cross-platform timeout (works on macOS without coreutils)
  run bash -c 'perl -e "alarm 15; exec @ARGV" mise run env:status'
  [ "$status" -eq 0 ]
}

@test "env:status produces immediate output" {
  # First output should appear within 2 seconds
  # Use perl for cross-platform timeout
  run bash -c 'perl -e "alarm 2; exec @ARGV" -- bash -c "mise run env:status 2>&1 | head -3"'
  [ "$status" -eq 0 ]
  # Check for either the task header or the actual status output
  [[ "$output" =~ "env:status" ]] || [[ "$output" =~ "Environment Status" ]]
}

@test "env:status exits successfully" {
  # Command should exit with code 0
  run mise run env:status
  [ "$status" -eq 0 ]
}

# =============================================================================
# Output Content Tests
# =============================================================================

@test "env:status shows platform information" {
  run mise run env:status
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Platform:" ]]
}

@test "env:status shows mise version" {
  run mise run env:status
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Mise Status" ]]
}

@test "env:status shows installed tools" {
  run mise run env:status
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installed Tools" ]]
}

@test "env:status shows health check" {
  run mise run env:status
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Health Check" ]]
}

# =============================================================================
# Performance Tests
# =============================================================================

@test "env:status completes in reasonable time" {
  # Should complete in under 10 seconds for local checks
  # (AWS/SkyPilot may timeout but that's expected)
  start=$(date +%s)
  run mise run env:status
  end=$(date +%s)
  duration=$((end - start))
  [ "$status" -eq 0 ]
  [ "$duration" -lt 10 ]
}
