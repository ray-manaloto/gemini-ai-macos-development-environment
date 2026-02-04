#!/usr/bin/env bats
# test_swiftbar.bats - SwiftBar menu bar plugin tests
# Run with: bats tests/test_swiftbar.bats

setup() {
    export PROJECT_DIR="${BATS_TEST_DIRNAME}/.."
    export PLUGIN_PATH="$PROJECT_DIR/config/scripts/dev-status.1m.sh"
}

# =============================================================================
# Plugin File Structure
# =============================================================================

@test "dev-status.1m.sh plugin exists" {
    [ -f "$PLUGIN_PATH" ]
}

@test "dev-status.1m.sh is executable" {
    [ -x "$PLUGIN_PATH" ]
}

@test "dev-status.1m.sh has correct naming convention (1m refresh)" {
    [[ "$PLUGIN_PATH" =~ \.1m\.sh$ ]]
}

@test "dev-status.1m.sh starts with shebang" {
    run head -1 "$PLUGIN_PATH"
    [[ "$output" =~ ^#!/bin/bash ]]
}

# =============================================================================
# BitBar/SwiftBar Metadata
# =============================================================================

@test "plugin has bitbar.title metadata" {
    run grep -q '<bitbar.title>' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has bitbar.version metadata" {
    run grep -q '<bitbar.version>' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has bitbar.author metadata" {
    run grep -q '<bitbar.author>' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has bitbar.desc metadata" {
    run grep -q '<bitbar.desc>' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has bitbar.dependencies metadata" {
    run grep -q '<bitbar.dependencies>' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin version is v2.0 or higher" {
    run grep '<bitbar.version>' "$PLUGIN_PATH"
    [[ "$output" =~ v2\. ]] || [[ "$output" =~ v[3-9]\. ]]
}

# =============================================================================
# Plugin Output Format
# =============================================================================

@test "plugin produces valid SwiftBar output" {
    run bash "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "plugin output starts with menu bar icon" {
    run bash "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" =~ ^[🟢🔴🟡⚪] ]]
}

@test "plugin output contains separator (---)" {
    run bash "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "---" ]]
}

@test "plugin output contains Local Environment section" {
    run bash "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Local Environment" ]]
}

@test "plugin output contains Containers section" {
    run bash "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Containers" ]]
}

@test "plugin output contains DevContainers section" {
    run bash "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DevContainers" ]]
}

@test "plugin output contains Cloud Agents section" {
    run bash "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Cloud Agents" ]]
}

@test "plugin output contains Settings section" {
    run bash "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Settings" ]]
}

# =============================================================================
# Plugin Actions (bash= parameters)
# =============================================================================

@test "plugin has mise doctor action" {
    run grep -q 'param1=doctor' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has tools:update action" {
    run grep -q 'tools:update' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has dashboard action" {
    run grep -q 'dashboard' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has validate action" {
    run grep -q 'validate' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has agent-readiness check" {
    run grep -q 'agent-readiness' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has autofix check" {
    run grep -q 'autofix' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has refresh action" {
    run grep -q 'refresh=true' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Mise Tasks for SwiftBar
# =============================================================================

@test "mise task menubar:install is defined" {
    run grep -q '\[tasks."menubar:install"\]' "$PROJECT_DIR/config/mise.toml"
    [ "$status" -eq 0 ]
}

@test "mise task menubar:uninstall is defined" {
    run grep -q '\[tasks."menubar:uninstall"\]' "$PROJECT_DIR/config/mise.toml"
    [ "$status" -eq 0 ]
}

@test "mise task menubar:status is defined" {
    run grep -q '\[tasks."menubar:status"\]' "$PROJECT_DIR/config/mise.toml"
    [ "$status" -eq 0 ]
}

@test "mise task menubar:refresh is defined" {
    run grep -q '\[tasks."menubar:refresh"\]' "$PROJECT_DIR/config/mise.toml"
    [ "$status" -eq 0 ]
}

@test "mise task menubar:open is defined" {
    run grep -q '\[tasks."menubar:open"\]' "$PROJECT_DIR/config/mise.toml"
    [ "$status" -eq 0 ]
}

@test "mise task menubar:edit is defined" {
    run grep -q '\[tasks."menubar:edit"\]' "$PROJECT_DIR/config/mise.toml"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Plugin Script Quality
# =============================================================================

@test "plugin does not use sudo" {
    run grep -q 'sudo' "$PLUGIN_PATH"
    [ "$status" -ne 0 ]
}

@test "plugin handles missing commands gracefully" {
    run grep -q 'command -v\|cmd_exists' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has helper functions" {
    run grep -q 'get_mise_status\|get_orbstack_status' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses color parameters" {
    run grep -q 'color=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses terminal=false for non-blocking actions" {
    run grep -q 'terminal=false' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses terminal=true for interactive actions" {
    run grep -q 'terminal=true' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Environment Support
# =============================================================================

@test "plugin supports GODTIER_PROJECT_DIR override" {
    run grep -q 'GODTIER_PROJECT_DIR' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin supports MISE_CMD override" {
    run grep -q 'MISE_CMD' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin defines color constants" {
    run grep -q 'COLOR_GREEN\|COLOR_RED\|COLOR_YELLOW' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# External Links
# =============================================================================

@test "plugin has link to Mise docs" {
    run grep -q 'mise.jdx.dev' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has link to SwiftBar docs" {
    run grep -q 'swiftbar/SwiftBar\|swiftbar.app' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has link to SkyPilot docs" {
    run grep -q 'skypilot' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}
