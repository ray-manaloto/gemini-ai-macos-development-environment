#!/usr/bin/env bats
# test_enhanced_plugin.bats - Enhanced SwiftBar bash plugin tests
# Run with: bats DevEnvManager-SwiftBar/tests/test_enhanced_plugin.bats

setup() {
    export PROJECT_DIR="${BATS_TEST_DIRNAME}/../.."
    export PLUGIN_PATH="$PROJECT_DIR/DevEnvManager-SwiftBar/dev-status.5s.sh"
}

# =============================================================================
# Plugin File Structure
# =============================================================================

@test "dev-status.5s.sh plugin exists" {
    [ -f "$PLUGIN_PATH" ]
}

@test "dev-status.5s.sh is executable" {
    [ -x "$PLUGIN_PATH" ]
}

@test "dev-status.5s.sh has correct naming convention (5s refresh)" {
    [[ "$PLUGIN_PATH" =~ \.5s\.sh$ ]]
}

@test "dev-status.5s.sh starts with shebang" {
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

@test "plugin version is v3.0 or higher" {
    run grep '<bitbar.version>' "$PLUGIN_PATH"
    [[ "$output" =~ v3\. ]] || [[ "$output" =~ v[4-9]\. ]]
}

@test "plugin has swiftbar-specific metadata" {
    run grep -q '<swiftbar.hideAbout>' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
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

@test "plugin output contains Homebrew Services section" {
    run bash "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Homebrew Services" ]]
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

@test "plugin output contains Port Detection section" {
    run bash "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Active Ports" ]]
}

@test "plugin output contains Settings section" {
    run bash "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Settings" ]]
}

# =============================================================================
# Homebrew Services Section
# =============================================================================

@test "plugin has get_brew_services function" {
    run grep -q 'get_brew_services()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin calls brew services list" {
    run grep -q 'brew services list' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has brew service start action" {
    run grep -q 'param1=services param2=start' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has brew service stop action" {
    run grep -q 'param1=services param2=stop' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has brew service restart action" {
    run grep -q 'param1=services param2=restart' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# OrbStack Containers Section
# =============================================================================

@test "plugin has get_orbstack_containers function" {
    run grep -q 'get_orbstack_containers()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin calls orb list for containers" {
    run grep -q 'orb list' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has container start action" {
    run grep -q 'param1=start param2=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has container stop action" {
    run grep -q 'param1=stop param2=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Port Detection Section
# =============================================================================

@test "plugin has get_active_ports function" {
    run grep -q 'get_active_ports()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses lsof for port detection" {
    run grep -q 'lsof -iTCP' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin filters listening ports correctly" {
    run grep -q 'sTCP:LISTEN' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin displays port information" {
    run grep -q 'Active Ports' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
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

@test "plugin defines all color constants" {
    run grep -q 'COLOR_GREEN\|COLOR_RED\|COLOR_YELLOW\|COLOR_BLUE\|COLOR_GRAY\|COLOR_PURPLE\|COLOR_ORANGE' "$PLUGIN_PATH"
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

# =============================================================================
# New Enhanced Features
# =============================================================================

@test "plugin has 5-second refresh interval in filename" {
    [[ "$PLUGIN_PATH" =~ \.5s\.sh$ ]]
}

@test "plugin includes Homebrew color constant" {
    run grep -q 'COLOR_ORANGE' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin includes Purple color for ports" {
    run grep -q 'COLOR_PURPLE' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin handles missing brew gracefully" {
    run grep -q 'cmd_exists brew' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin handles missing lsof gracefully" {
    run grep -q 'cmd_exists lsof' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin handles missing orb gracefully" {
    run grep -q 'cmd_exists orb' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}
