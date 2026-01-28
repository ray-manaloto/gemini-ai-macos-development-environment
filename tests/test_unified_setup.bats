#!/usr/bin/env bats

setup() {
  if ! command -v mise &> /dev/null; then
    skip "mise not installed"
  fi
}

@test "mise.toml uses config_root template for dashboard task" {
  grep -q '{{config_root}}' config/mise.toml
  grep -q 'dir = "{{config_root}}"' config/mise.toml
}

@test "mise.toml uses config_root template for validate task" {
  grep -q 'sh {{config_root}}/config/scripts/validate.sh' config/mise.toml
}

@test "mise.toml uses config_root template for help task" {
  grep -q '{{config_root}}/MANUAL.md' config/mise.toml
}

@test "mise.toml uses config_root template for agent:up task" {
  grep -q '{{config_root}}/templates/agent.yaml' config/mise.toml
}

@test "mise.toml has no hardcoded ~/.config/dev-env paths" {
  ! grep -q '\~/.config/dev-env' config/mise.toml
  ! grep -q '\$HOME/.config/dev-env' config/mise.toml
}

@test "setup:common task exists" {
  grep -q '\[tasks."setup:common"\]' config/mise.toml
}

@test "setup:macos task exists" {
  grep -q '\[tasks."setup:macos"\]' config/mise.toml
}

@test "setup:container task exists" {
  grep -q '\[tasks."setup:container"\]' config/mise.toml
}

@test "setup:linux task exists" {
  grep -q '\[tasks."setup:linux"\]' config/mise.toml
}

@test "setup:auto task exists" {
  grep -q '\[tasks."setup:auto"\]' config/mise.toml
}

@test "setup:macos depends on setup:common" {
  grep -A3 '\[tasks."setup:macos"\]' config/mise.toml | grep -q 'depends = \["setup:common"\]'
}

@test "setup:container depends on setup:common" {
  grep -A3 '\[tasks."setup:container"\]' config/mise.toml | grep -q 'depends = \["setup:common"\]'
}

@test "setup:linux depends on setup:common" {
  grep -A3 '\[tasks."setup:linux"\]' config/mise.toml | grep -q 'depends = \["setup:common"\]'
}

@test "devcontainer.json has MISE_TRUSTED_CONFIG_PATHS" {
  grep -q 'MISE_TRUSTED_CONFIG_PATHS' .devcontainer/devcontainer.json
  grep -q '/workspaces' .devcontainer/devcontainer.json
}

@test "devcontainer.json uses mise DevContainer feature" {
  grep -q 'devcontainers-extra/features/mise' .devcontainer/devcontainer.json
}

@test "devcontainer.json runs setup:container task" {
  grep -q 'setup:container' .devcontainer/devcontainer.json
}

@test "devcontainer.json copies mise.toml to config directory" {
  grep -q 'cp config/mise.toml ~/.config/mise/config.toml' .devcontainer/devcontainer.json
}

@test "mise tasks list includes setup tasks" {
  if [ ! -f "$HOME/.config/mise/config.toml" ]; then
    skip "mise config not installed globally"
  fi
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup:common" ]]
  [[ "$output" =~ "setup:auto" ]]
}

@test "validate:rules task exists" {
  grep -q '\[tasks."validate:rules"\]' config/mise.toml
}

@test "validate:rules checks for hardcoded paths" {
  grep -A15 '\[tasks."validate:rules"\]' config/mise.toml | grep -q 'hardcoded'
}

@test "validate:rules checks for sudo usage" {
  grep -A20 '\[tasks."validate:rules"\]' config/mise.toml | grep -q 'sudo'
}

@test "validate:rules checks for secrets" {
  grep -A30 '\[tasks."validate:rules"\]' config/mise.toml | grep -q 'secrets'
}
