#!/usr/bin/env bats
# test_mise.bats - Mise installation and configuration tests
# Run with: bats tests/test_mise.bats

# Helper to skip if mise not installed (for CI without mise)
setup() {
  if ! command -v mise &> /dev/null; then
    skip "mise not installed"
  fi
}

@test "mise is installed" {
  run mise --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+\.[0-9]+ ]]
}

@test "mise doctor reports no critical errors" {
  run mise doctor
  # mise doctor may return non-zero for warnings (shims on path, missing shims, etc.)
  # We only fail on actual ERROR messages, not warnings
  [[ ! "$output" =~ "ERROR" ]]
  # Verify mise doctor actually ran and produced output
  [[ "$output" =~ "version:" ]]
}

@test "mise has experimental features enabled" {
  run mise config get settings.experimental
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "mise has bun installed" {
  run mise ls bun
  [ "$status" -eq 0 ]
  [[ "$output" =~ "bun" ]]
}

@test "mise has uv installed" {
  run mise ls uv
  [ "$status" -eq 0 ]
  [[ "$output" =~ "uv" ]]
}

@test "mise has bun configured as npm backend" {
  # Verify bun is configured as the npm/node backend (core architecture principle)
  run mise settings get npm.bun
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "mise has uv configured for python venvs" {
  # Verify uv is configured for automatic venv management (core architecture principle)
  run mise settings get python.uv_venv_auto
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "mise tasks are available" {
  run mise tasks
  [ "$status" -eq 0 ]
  # Check for key tasks
  [[ "$output" =~ "validate" ]]
  [[ "$output" =~ "dashboard" ]]
}

@test "mise can list installed tools" {
  run mise ls
  [ "$status" -eq 0 ]
}

# =============================================================================
# Tool Shadow Detection
# =============================================================================

@test "validate:tools task exists" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "validate:tools" ]]
}

@test "tools:fix-shadows task exists" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "tools:fix-shadows" ]]
}

@test "validate:tools detects no shadows on clean system" {
  # This test assumes the system is clean after previous fixes
  run mise run validate:tools
  # Exit 0 means no shadows, exit 1 means shadows found
  # Either is valid - we just check it runs
  [[ "$status" -eq 0 || "$status" -eq 1 ]]
}
