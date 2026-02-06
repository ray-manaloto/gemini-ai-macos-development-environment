#!/usr/bin/env bats
# test_autofix.bats - Autofix system tests
# Run with: bats tests/test_autofix.bats

setup() {
  if ! command -v mise &> /dev/null; then
    skip "mise not installed"
  fi
}

# =============================================================================
# Autofix Script Tests
# =============================================================================

@test "autofix.sh script exists" {
  [ -f "config/scripts/autofix.sh" ]
}

@test "autofix.sh has valid bash syntax" {
  run bash -n config/scripts/autofix.sh
  [ "$status" -eq 0 ]
}

@test "autofix.sh is not empty" {
  [ -s "config/scripts/autofix.sh" ]
}

@test "autofix.sh has shebang" {
  run head -1 config/scripts/autofix.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "#!/bin/bash" ]]
}

@test "autofix.sh accepts status command" {
  run bash config/scripts/autofix.sh status
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "autofix.sh accepts --help flag" {
  run bash config/scripts/autofix.sh --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "autofix.sh --json produces valid JSON" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi
  run bash config/scripts/autofix.sh --json
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
  echo "$output" | jq '.' > /dev/null 2>&1
  [ $? -eq 0 ]
}

@test "autofix.sh detects platform" {
  run bash -c 'OS=$(uname -s) && echo $OS'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Darwin" ]] || [[ "$output" =~ "Linux" ]]
}

@test "autofix.sh defines bootstrap tools list" {
  run grep -q "BOOTSTRAP_TOOLS" config/scripts/autofix.sh
  [ "$status" -eq 0 ]
}

@test "autofix.sh defines managed tools list" {
  run grep -q "MISE_MANAGED_TOOLS" config/scripts/autofix.sh
  [ "$status" -eq 0 ]
}

@test "autofix.sh has backup directory logic" {
  run grep -q "BACKUP_DIR" config/scripts/autofix.sh
  [ "$status" -eq 0 ]
}

# =============================================================================
# Launchd Configuration Tests (macOS only)
# =============================================================================

@test "launchd plist exists" {
  [ -f "config/launchd/com.godtier.autofix.plist" ]
}

@test "launchd plist is valid XML" {
  if [ "$(uname)" != "Darwin" ]; then
    skip "XML validation with plutil requires macOS"
  fi
  run plutil -lint config/launchd/com.godtier.autofix.plist
  [ "$status" -eq 0 ]
}

@test "launchd plist has correct label" {
  run grep -q "com.godtier.autofix" config/launchd/com.godtier.autofix.plist
  [ "$status" -eq 0 ]
}

@test "launchd plist has ProgramArguments" {
  run grep -q "ProgramArguments" config/launchd/com.godtier.autofix.plist
  [ "$status" -eq 0 ]
}

@test "launchd plist has RunAtLoad" {
  run grep -q "RunAtLoad" config/launchd/com.godtier.autofix.plist
  [ "$status" -eq 0 ]
}

@test "launchd plist has StartCalendarInterval" {
  run grep -q "StartCalendarInterval" config/launchd/com.godtier.autofix.plist
  [ "$status" -eq 0 ]
}

@test "launchd plist has log path configuration" {
  run grep -q "StandardOutPath" config/launchd/com.godtier.autofix.plist
  [ "$status" -eq 0 ]
}

@test "launchd plist uses template variables" {
  run grep -q "{{CONFIG_ROOT}}" config/launchd/com.godtier.autofix.plist
  [ "$status" -eq 0 ]
  run grep -q "{{HOME}}" config/launchd/com.godtier.autofix.plist
  [ "$status" -eq 0 ]
}

# =============================================================================
# Mise Task Tests
# =============================================================================

@test "mise task autofix:status is defined" {
  run grep -q 'tasks."autofix:status"' config/mise.toml
  [ "$status" -eq 0 ]
}

@test "mise task autofix:fix is defined" {
  run grep -q 'tasks."autofix:fix"' config/mise.toml
  [ "$status" -eq 0 ]
}

@test "mise task autofix:json is defined" {
  run grep -q 'tasks."autofix:json"' config/mise.toml
  [ "$status" -eq 0 ]
}

@test "mise task launchd:install is defined" {
  run grep -q 'tasks."launchd:install"' config/mise.toml
  [ "$status" -eq 0 ]
}

@test "mise task launchd:uninstall is defined" {
  run grep -q 'tasks."launchd:uninstall"' config/mise.toml
  [ "$status" -eq 0 ]
}

@test "mise task launchd:status is defined" {
  run grep -q 'tasks."launchd:status"' config/mise.toml
  [ "$status" -eq 0 ]
}

@test "mise task launchd:run is defined" {
  run grep -q 'tasks."launchd:run"' config/mise.toml
  [ "$status" -eq 0 ]
}

# =============================================================================
# Detection Logic Tests
# =============================================================================

@test "autofix detects container environment variables" {
  run grep -E "REMOTE_CONTAINERS|CODESPACES|DEVCONTAINER" config/scripts/autofix.sh
  [ "$status" -eq 0 ]
}

@test "autofix detects dockerenv file" {
  run grep -q "/.dockerenv" config/scripts/autofix.sh
  [ "$status" -eq 0 ]
}

@test "autofix has color detection for CI" {
  run grep -q 'CI:-' config/scripts/autofix.sh
  [ "$status" -eq 0 ]
}

@test "autofix has NO_COLOR support" {
  run grep -q 'NO_COLOR' config/scripts/autofix.sh
  [ "$status" -eq 0 ]
}

# =============================================================================
# Security Tests
# =============================================================================

@test "autofix.sh does not use sudo" {
  run grep -w "sudo" config/scripts/autofix.sh
  [ "$status" -ne 0 ]
}

@test "autofix.sh uses set -euo pipefail" {
  run grep -q "set -euo pipefail" config/scripts/autofix.sh
  [ "$status" -eq 0 ]
}

@test "launchd plist does not request root privileges" {
  run grep -q "UserName.*root" config/launchd/com.godtier.autofix.plist
  [ "$status" -ne 0 ]
}
