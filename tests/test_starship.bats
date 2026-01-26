#!/usr/bin/env bats
# test_starship.bats - Starship configuration tests
# Run with: bats tests/test_starship.bats

@test "starship.toml exists" {
  [ -f "config/starship.toml" ]
}

@test "starship.toml is valid TOML" {
  if ! command -v starship &> /dev/null; then
    skip "starship not installed"
  fi
  # Starship validates config on init
  STARSHIP_CONFIG="config/starship.toml" run starship prompt
  [ "$status" -eq 0 ]
}

@test "starship config has character module" {
  run grep -q "\[character\]" config/starship.toml
  [ "$status" -eq 0 ]
}

@test "starship config has git_branch module" {
  run grep -q "\[git_branch\]" config/starship.toml
  [ "$status" -eq 0 ]
}

@test "starship config has python module" {
  run grep -q "\[python\]" config/starship.toml
  [ "$status" -eq 0 ]
}

@test "starship config has nodejs module" {
  run grep -q "\[nodejs\]" config/starship.toml
  [ "$status" -eq 0 ]
}

@test "starship config has bun module" {
  run grep -q "\[bun\]" config/starship.toml
  [ "$status" -eq 0 ]
}

@test "starship config has aws module" {
  run grep -q "\[aws\]" config/starship.toml
  [ "$status" -eq 0 ]
}

@test "starship config has docker module" {
  run grep -q "\[docker_context\]" config/starship.toml
  [ "$status" -eq 0 ]
}

@test "starship config has mise custom module" {
  run grep -q "\[custom.mise\]" config/starship.toml
  [ "$status" -eq 0 ]
}
