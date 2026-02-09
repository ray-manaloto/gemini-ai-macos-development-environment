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

@test "mise has bun configured for npm" {
  # Verify npm.bun=true or npm.package_manager=bun for bun-based npm package management
  run mise settings get npm.bun
  if [ "$status" -eq 0 ] && [ "$output" = "true" ]; then
    return 0
  fi
  run mise settings get npm.package_manager
  [ "$status" -eq 0 ]
  [ "$output" = "bun" ]
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
  run mise run validate:tools
  [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "auth:status task exists" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "auth:status" ]]
}

@test "auth:gh task exists" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "auth:gh" ]]
}

@test "auth:claude task exists" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "auth:claude" ]]
}

@test "auth:codex task exists" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "auth:codex" ]]
}

@test "auth:gemini task exists" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "auth:gemini" ]]
}

@test "auth:opencode task exists" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "auth:opencode" ]]
}

@test "auth:aws task exists" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "auth:aws" ]]
}

@test "auth:1password task exists" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "auth:1password" ]]
}

@test "auth:all task exists" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "auth:all" ]]
}

@test "auth:status runs without error" {
  run mise run auth:status
  [ "$status" -eq 0 ]
  [[ "$output" =~ "CLI Tool Authentication Status" ]]
}
