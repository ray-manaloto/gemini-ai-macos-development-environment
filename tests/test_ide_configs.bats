#!/usr/bin/env bats
# test_ide_configs.bats - IDE and container configuration tests
# Run with: bats tests/test_ide_configs.bats

# =============================================================================
# VS Code Configuration Tests
# =============================================================================

@test ".vscode directory exists" {
  [ -d ".vscode" ]
}

@test ".vscode/settings.json exists and has content" {
  [ -f ".vscode/settings.json" ]
  [ -s ".vscode/settings.json" ]
}

@test ".vscode/settings.json contains editor settings" {
  grep -q '"editor.formatOnSave"' .vscode/settings.json
}

@test ".vscode/settings.json contains mise integration" {
  grep -q 'mise' .vscode/settings.json
}

@test ".vscode/extensions.json exists and has content" {
  [ -f ".vscode/extensions.json" ]
  [ -s ".vscode/extensions.json" ]
}

@test ".vscode/extensions.json contains recommendations" {
  grep -q '"recommendations"' .vscode/extensions.json
}

@test ".vscode/extensions.json includes essential extensions" {
  grep -q 'prettier-vscode' .vscode/extensions.json
  grep -q 'ms-python.python' .vscode/extensions.json
}

# =============================================================================
# Zed Configuration Tests
# =============================================================================

@test ".zed directory exists" {
  [ -d ".zed" ]
}

@test ".zed/settings.json exists and has content" {
  [ -f ".zed/settings.json" ]
  [ -s ".zed/settings.json" ]
}

@test ".zed/settings.json contains theme setting" {
  grep -q '"theme"' .zed/settings.json
}

@test ".zed/settings.json contains terminal configuration" {
  grep -q '"terminal"' .zed/settings.json
}

@test ".zed/settings.json contains language settings" {
  grep -q '"languages"' .zed/settings.json
}

# =============================================================================
# DevContainer Configuration Tests
# =============================================================================

@test ".devcontainer directory exists" {
  [ -d ".devcontainer" ]
}

@test ".devcontainer/devcontainer.json exists and has content" {
  [ -f ".devcontainer/devcontainer.json" ]
  [ -s ".devcontainer/devcontainer.json" ]
}

@test "devcontainer.json has name field" {
  grep -q '"name"' .devcontainer/devcontainer.json
}

@test "devcontainer.json has image field" {
  grep -q '"image"' .devcontainer/devcontainer.json
}

@test "devcontainer.json has features section" {
  grep -q '"features"' .devcontainer/devcontainer.json
}

@test "devcontainer.json has postCreateCommand" {
  grep -q '"postCreateCommand"' .devcontainer/devcontainer.json
}

@test "devcontainer.json has mise feature or installs mise" {
  # Either uses mise devcontainer feature or curl installer
  grep -q 'mise' .devcontainer/devcontainer.json
}

@test "devcontainer.json has VS Code extensions" {
  grep -q '"extensions"' .devcontainer/devcontainer.json
}

# =============================================================================
# Uninstall Script Tests
# =============================================================================

@test "uninstall.sh exists and is executable" {
  [ -f "uninstall.sh" ]
  [ -x "uninstall.sh" ]
}

@test "uninstall.sh has shebang" {
  head -1 uninstall.sh | grep -q '#!/bin/bash'
}

@test "uninstall.sh supports --help flag" {
  run ./uninstall.sh --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "uninstall.sh supports --dry-run flag" {
  run ./uninstall.sh --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" =~ "DRY RUN" ]]
}

# =============================================================================
# Documentation Tests
# =============================================================================

@test "SECRETS.md exists and has content" {
  [ -f "SECRETS.md" ]
  [ -s "SECRETS.md" ]
}

@test "SECRETS.md has required sections" {
  grep -q '## Option 1: 1Password' SECRETS.md
  grep -q '## Option 2: Infisical' SECRETS.md
  grep -q '## Option 3: Mise Native' SECRETS.md
}

@test "MIGRATION.md exists and has content" {
  [ -f "MIGRATION.md" ]
  [ -s "MIGRATION.md" ]
}

@test "MIGRATION.md covers nvm migration" {
  grep -q 'nvm' MIGRATION.md
}

@test "MIGRATION.md covers pyenv migration" {
  grep -q 'pyenv' MIGRATION.md
}

@test ".env.example exists" {
  [ -f ".env.example" ]
}

@test ".env.example has API key placeholders" {
  grep -q 'ANTHROPIC_API_KEY' .env.example
  grep -q 'AWS_ACCESS_KEY_ID' .env.example
}
