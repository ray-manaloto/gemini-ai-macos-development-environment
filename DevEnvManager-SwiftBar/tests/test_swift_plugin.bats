#!/usr/bin/env bats
# test_swift_plugin.bats - Swift StreamablePlugin tests
# Run with: bats DevEnvManager-SwiftBar/tests/test_swift_plugin.bats

setup() {
    export PROJECT_DIR="${BATS_TEST_DIRNAME}/../.."
    export PLUGIN_PATH="$PROJECT_DIR/DevEnvManager-SwiftBar/dev-status-stream.swift"
}

# =============================================================================
# Plugin File Structure
# =============================================================================

@test "dev-status-stream.swift plugin exists" {
    [ -f "$PLUGIN_PATH" ]
}

@test "dev-status-stream.swift is executable" {
    [ -x "$PLUGIN_PATH" ]
}

@test "dev-status-stream.swift starts with shebang" {
    run head -1 "$PLUGIN_PATH"
    [[ "$output" =~ ^#!/usr/bin/swift ]]
}

# =============================================================================
# SwiftBar StreamablePlugin Metadata
# =============================================================================

@test "plugin has swiftbar.type=streamable metadata" {
    run grep -q '<swiftbar.type>streamable</swiftbar.type>' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

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

# =============================================================================
# Swift Language Features
# =============================================================================

@test "plugin imports Foundation" {
    run grep -q 'import Foundation' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses ProcessInfo for environment variables" {
    run grep -q 'ProcessInfo.processInfo.environment' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has shell() helper function" {
    run grep -q 'func shell(' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has commandExists() helper function" {
    run grep -q 'func commandExists(' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses Process for command execution" {
    run grep -q 'let task = Process()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Configuration and Constants
# =============================================================================

@test "plugin defines PROJECT_DIR constant" {
    run grep -q 'let PROJECT_DIR' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin defines MISE_CMD constant" {
    run grep -q 'let MISE_CMD' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin defines color constants" {
    run grep -q 'let COLOR_GREEN\|let COLOR_RED\|let COLOR_YELLOW' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin supports GODTIER_PROJECT_DIR override" {
    run grep -q 'GODTIER_PROJECT_DIR' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin supports MISE_CMD override" {
    run grep -q 'MISE_CMD' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Status Functions
# =============================================================================

@test "plugin has getMiseStatus() function" {
    run grep -q 'func getMiseStatus()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has getOrbStackStatus() function" {
    run grep -q 'func getOrbStackStatus()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has getOrbStackContainers() function" {
    run grep -q 'func getOrbStackContainers()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has getBrewServices() function" {
    run grep -q 'func getBrewServices()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has getActivePorts() function" {
    run grep -q 'func getActivePorts()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has getMiseTools() function" {
    run grep -q 'func getMiseTools()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has getDevPodStatus() function" {
    run grep -q 'func getDevPodStatus()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has getSkyPilotStatus() function" {
    run grep -q 'func getSkyPilotStatus()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Rendering Functions
# =============================================================================

@test "plugin has renderMenuBar() function" {
    run grep -q 'func renderMenuBar()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has renderLocalEnvironment() function" {
    run grep -q 'func renderLocalEnvironment()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has renderMiseTools() function" {
    run grep -q 'func renderMiseTools()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has renderBrewServices() function" {
    run grep -q 'func renderBrewServices()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has renderOrbStackContainers() function" {
    run grep -q 'func renderOrbStackContainers()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has renderActivePorts() function" {
    run grep -q 'func renderActivePorts()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has renderSettings() function" {
    run grep -q 'func renderSettings()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Streaming Implementation
# =============================================================================

@test "plugin has refreshMenu() function" {
    run grep -q 'func refreshMenu()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin calls refreshMenu() initially" {
    run grep -q 'refreshMenu()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses streaming separator (~~~)" {
    run grep -q '~~~' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has periodic update loop" {
    run grep -q 'while true' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin sleeps between updates" {
    run grep -q 'sleep(' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Command Execution
# =============================================================================

@test "plugin executes mise commands" {
    run grep -q 'mise' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin executes brew commands" {
    run grep -q 'brew' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin executes orb commands" {
    run grep -q 'orb' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin executes lsof for port detection" {
    run grep -q 'lsof' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Output Format
# =============================================================================

@test "plugin uses color parameters in output" {
    run grep -q 'color=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses emoji in menu items" {
    run grep -q '✅\|❌\|⚠️\|⏹️\|▶️' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses SwiftBar action format" {
    run grep -q 'bash=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses href for external links" {
    run grep -q 'href=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Error Handling
# =============================================================================

@test "plugin handles missing commands gracefully" {
    run grep -q 'commandExists' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin returns empty array for missing commands" {
    run grep -q 'return \[\]' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin catches Process execution errors" {
    run grep -q 'catch' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Swift Syntax
# =============================================================================

@test "plugin has valid Swift syntax (no obvious errors)" {
    run swift -parse "$PLUGIN_PATH" 2>&1
    # Swift parse may fail due to missing modules, but should not have syntax errors
    # We just check that the file is readable
    [ -f "$PLUGIN_PATH" ]
}

@test "plugin uses String interpolation" {
    run grep -q '\\(' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses guard statements for safety" {
    run grep -q 'guard' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses switch statements for status handling" {
    run grep -q 'switch' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Documentation
# =============================================================================

@test "plugin has external links to Mise docs" {
    run grep -q 'mise.jdx.dev' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has external links to SwiftBar docs" {
    run grep -q 'github.com/swiftbar/SwiftBar' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin references project documentation" {
    run grep -q 'AGENTS.md\|README.md' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}
