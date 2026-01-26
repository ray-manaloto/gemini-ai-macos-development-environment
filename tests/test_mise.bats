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

@test "mise doctor reports no critical issues" {
  run mise doctor
  [ "$status" -eq 0 ]
  # Should not contain "ERROR" (warnings are OK)
  [[ ! "$output" =~ "ERROR" ]]
}

@test "mise has experimental features enabled" {
  run mise config get settings.experimental
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "mise has bun as node backend" {
  run mise config get settings.node_backend
  [ "$status" -eq 0 ]
  [ "$output" = "bun" ]
}

@test "mise has uv as pip backend" {
  run mise config get settings.pip_backend
  [ "$status" -eq 0 ]
  [ "$output" = "uv" ]
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
