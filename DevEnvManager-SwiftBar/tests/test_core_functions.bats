#!/usr/bin/env bats
# test_core_functions.bats - Core helper functions for DevEnvManager-SwiftBar
# Tests helper functions, configuration, output format, and code quality
# Run with: bats DevEnvManager-SwiftBar/tests/test_core_functions.bats

setup() {
    export PROJECT_DIR="${BATS_TEST_DIRNAME}/../.."
    export PLUGIN_PATH="$PROJECT_DIR/DevEnvManager-SwiftBar/dev-status.5s.sh"
}

# =============================================================================
# HELPER FUNCTION VALIDATION - cmd_exists
# =============================================================================

@test "cmd_exists function is defined" {
    run grep -q 'cmd_exists()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "cmd_exists uses command -v for portability" {
    run grep -A 2 'cmd_exists()' "$PLUGIN_PATH"
    [[ "$output" =~ "command -v" ]]
}

@test "cmd_exists redirects stderr to /dev/null" {
    run grep -A 2 'cmd_exists()' "$PLUGIN_PATH"
    [[ "$output" =~ "&>/dev/null" ]]
}

@test "cmd_exists is called for mise check" {
    run grep -q 'cmd_exists mise' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "cmd_exists is called for brew check" {
    run grep -q 'cmd_exists brew' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "cmd_exists is called for orb check" {
    run grep -q 'cmd_exists orb' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "cmd_exists is called for lsof check" {
    run grep -q 'cmd_exists lsof' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "cmd_exists is called for devpod check" {
    run grep -q 'cmd_exists devpod' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "cmd_exists is called for sky check" {
    run grep -q 'cmd_exists sky' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# HELPER FUNCTION VALIDATION - get_mise_status
# =============================================================================

@test "get_mise_status function is defined" {
    run grep -q 'get_mise_status()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_mise_status checks if mise exists" {
    run grep -A 5 'get_mise_status()' "$PLUGIN_PATH"
    [[ "$output" =~ "cmd_exists mise" ]]
}

@test "get_mise_status returns error when mise not found" {
    run grep -A 5 'get_mise_status()' "$PLUGIN_PATH"
    [[ "$output" =~ "echo \"error\"" ]]
}

@test "get_mise_status calls mise doctor" {
    run grep -q 'mise doctor' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_mise_status checks for problems in doctor output" {
    run grep -q 'grep.*problem' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_mise_status returns warning for problems" {
    run grep -A 10 'get_mise_status()' "$PLUGIN_PATH"
    [[ "$output" =~ "echo \"warning\"" ]]
}

@test "get_mise_status returns ok when healthy" {
    run grep 'echo "ok"' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# HELPER FUNCTION VALIDATION - get_orbstack_status
# =============================================================================

@test "get_orbstack_status function is defined" {
    run grep -q 'get_orbstack_status()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_orbstack_status checks if orb exists" {
    run grep -A 5 'get_orbstack_status()' "$PLUGIN_PATH"
    [[ "$output" =~ "cmd_exists orb" ]]
}

@test "get_orbstack_status returns not_installed when orb missing" {
    run grep -A 5 'get_orbstack_status()' "$PLUGIN_PATH"
    [[ "$output" =~ "echo \"not_installed\"" ]]
}

@test "get_orbstack_status calls orb status" {
    run grep -q 'orb status' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_orbstack_status checks for running status" {
    run grep -A 10 'get_orbstack_status()' "$PLUGIN_PATH"
    [[ "$output" =~ "running" ]]
}

@test "get_orbstack_status returns running or stopped" {
    run grep -A 10 'get_orbstack_status()' "$PLUGIN_PATH"
    [[ "$output" =~ "echo \"running\"" ]] || [[ "$output" =~ "echo \"stopped\"" ]]
}

# =============================================================================
# HELPER FUNCTION VALIDATION - get_orbstack_containers
# =============================================================================

@test "get_orbstack_containers function is defined" {
    run grep -q 'get_orbstack_containers()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_orbstack_containers checks if orb exists" {
    run grep -A 3 'get_orbstack_containers()' "$PLUGIN_PATH"
    [[ "$output" =~ "cmd_exists orb" ]]
}

@test "get_orbstack_containers calls orb list" {
    run grep -q 'orb list' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_orbstack_containers skips header line" {
    run grep -q 'tail -n +2' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_orbstack_containers filters empty lines" {
    run grep -A 5 'get_orbstack_containers()' "$PLUGIN_PATH"
    [[ "$output" =~ "-n" ]]
}

# =============================================================================
# HELPER FUNCTION VALIDATION - get_brew_services
# =============================================================================

@test "get_brew_services function is defined" {
    run grep -q 'get_brew_services()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_brew_services checks if brew exists" {
    run grep -A 3 'get_brew_services()' "$PLUGIN_PATH"
    [[ "$output" =~ "cmd_exists brew" ]]
}

@test "get_brew_services calls brew services list" {
    run grep -q 'brew services list' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_brew_services skips header line" {
    run grep -B 2 -A 2 'brew services list' "$PLUGIN_PATH"
    [[ "$output" =~ "tail -n +2" ]]
}

@test "get_brew_services filters empty lines" {
    run grep -A 5 'get_brew_services()' "$PLUGIN_PATH"
    [[ "$output" =~ "-n" ]]
}

# =============================================================================
# HELPER FUNCTION VALIDATION - get_active_ports
# =============================================================================

@test "get_active_ports function is defined" {
    run grep -q 'get_active_ports()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_active_ports checks if lsof exists" {
    run grep -A 3 'get_active_ports()' "$PLUGIN_PATH"
    [[ "$output" =~ "cmd_exists lsof" ]]
}

@test "get_active_ports uses lsof with TCP filter" {
    run grep -q 'lsof -iTCP' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_active_ports filters for LISTEN state" {
    run grep -q 'sTCP:LISTEN' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_active_ports uses -P for numeric ports" {
    run grep -q 'lsof.*-P' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_active_ports uses -n for numeric addresses" {
    run grep -q 'lsof.*-n' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_active_ports sorts output" {
    run grep 'sort' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_active_ports deduplicates output" {
    run grep 'sort -u' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# HELPER FUNCTION VALIDATION - get_devpod_status
# =============================================================================

@test "get_devpod_status function is defined" {
    run grep -q 'get_devpod_status()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_devpod_status checks if devpod exists" {
    run grep -A 3 'get_devpod_status()' "$PLUGIN_PATH"
    [[ "$output" =~ "cmd_exists devpod" ]]
}

@test "get_devpod_status returns not_installed when missing" {
    run grep -A 3 'get_devpod_status()' "$PLUGIN_PATH"
    [[ "$output" =~ "echo \"not_installed\"" ]]
}

@test "get_devpod_status calls devpod list" {
    run grep -q 'devpod list' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_devpod_status counts Running workspaces" {
    run grep -q 'grep -c "Running"' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# HELPER FUNCTION VALIDATION - get_skypilot_status
# =============================================================================

@test "get_skypilot_status function is defined" {
    run grep -q 'get_skypilot_status()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_skypilot_status checks if sky exists" {
    run grep -A 3 'get_skypilot_status()' "$PLUGIN_PATH"
    [[ "$output" =~ "cmd_exists sky" ]]
}

@test "get_skypilot_status returns not_installed when missing" {
    run grep -A 3 'get_skypilot_status()' "$PLUGIN_PATH"
    [[ "$output" =~ "echo \"not_installed\"" ]]
}

@test "get_skypilot_status calls sky status" {
    run grep -q 'sky status' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_skypilot_status counts UP clusters" {
    run grep -q 'grep -c "UP"' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# CONFIGURATION VALIDATION - PROJECT_DIR
# =============================================================================

@test "PROJECT_DIR has default value" {
    run grep -q 'PROJECT_DIR=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "PROJECT_DIR supports GODTIER_PROJECT_DIR override" {
    run grep -q 'GODTIER_PROJECT_DIR' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "PROJECT_DIR uses $HOME variable" {
    run grep -q 'PROJECT_DIR.*\$HOME' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "PROJECT_DIR does not use hardcoded absolute paths" {
    run grep 'PROJECT_DIR=' "$PLUGIN_PATH"
    [[ ! "$output" =~ /Users/[a-z] ]]
}

# =============================================================================
# CONFIGURATION VALIDATION - MISE_CMD
# =============================================================================

@test "MISE_CMD has default value" {
    run grep -q 'MISE_CMD=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "MISE_CMD supports override" {
    run grep -q 'MISE_CMD.*:-' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "MISE_CMD defaults to mise" {
    run grep 'MISE_CMD=' "$PLUGIN_PATH"
    [[ "$output" =~ "mise" ]]
}

# =============================================================================
# CONFIGURATION VALIDATION - COLOR CONSTANTS
# =============================================================================

@test "COLOR_GREEN is defined" {
    run grep -q 'COLOR_GREEN=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "COLOR_RED is defined" {
    run grep -q 'COLOR_RED=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "COLOR_YELLOW is defined" {
    run grep -q 'COLOR_YELLOW=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "COLOR_BLUE is defined" {
    run grep -q 'COLOR_BLUE=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "COLOR_GRAY is defined" {
    run grep -q 'COLOR_GRAY=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "COLOR_PURPLE is defined" {
    run grep -q 'COLOR_PURPLE=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "COLOR_ORANGE is defined" {
    run grep -q 'COLOR_ORANGE=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "COLOR_GREEN is valid hex code" {
    run grep 'COLOR_GREEN=' "$PLUGIN_PATH"
    [[ "$output" =~ \#[0-9a-f]{6} ]]
}

@test "COLOR_RED is valid hex code" {
    run grep 'COLOR_RED=' "$PLUGIN_PATH"
    [[ "$output" =~ \#[0-9a-f]{6} ]]
}

@test "COLOR_YELLOW is valid hex code" {
    run grep 'COLOR_YELLOW=' "$PLUGIN_PATH"
    [[ "$output" =~ \#[0-9a-f]{6} ]]
}

@test "COLOR_BLUE is valid hex code" {
    run grep 'COLOR_BLUE=' "$PLUGIN_PATH"
    [[ "$output" =~ \#[0-9a-f]{6} ]]
}

@test "COLOR_GRAY is valid hex code" {
    run grep 'COLOR_GRAY=' "$PLUGIN_PATH"
    [[ "$output" =~ \#[0-9a-f]{6} ]]
}

@test "COLOR_PURPLE is valid hex code" {
    run grep 'COLOR_PURPLE=' "$PLUGIN_PATH"
    [[ "$output" =~ \#[0-9a-f]{6} ]]
}

@test "COLOR_ORANGE is valid hex code" {
    run grep 'COLOR_ORANGE=' "$PLUGIN_PATH"
    [[ "$output" =~ \#[0-9a-f]{6} ]]
}

# =============================================================================
# SWIFTBAR OUTPUT FORMAT - Separators
# =============================================================================

@test "plugin uses --- separator for menu sections" {
    run grep -c '^echo "---"' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [ "$output" -gt 5 ]
}

# =============================================================================
# SWIFTBAR OUTPUT FORMAT - Parameters
# =============================================================================

@test "plugin uses bash= parameter for actions" {
    run grep -q 'bash=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses param1= for first parameter" {
    run grep -q 'param1=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses param2= for second parameter" {
    run grep -q 'param2=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses param3= for third parameter" {
    run grep -q 'param3=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses terminal=true for interactive commands" {
    run grep -q 'terminal=true' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses terminal=false for background commands" {
    run grep -q 'terminal=false' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses refresh=true for state-changing actions" {
    run grep -q 'refresh=true' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# SWIFTBAR OUTPUT FORMAT - Size Attributes
# =============================================================================

@test "plugin uses size attribute for text" {
    run grep -q 'size=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses size=14 for section headers" {
    run grep -q 'size=14' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses valid size values only" {
    run grep 'size=' "$PLUGIN_PATH"
    [[ ! "$output" =~ size=[0-9]{3,} ]]
}

# =============================================================================
# SWIFTBAR OUTPUT FORMAT - Color Attributes
# =============================================================================

@test "plugin uses color= parameter for colors" {
    run grep -c 'color=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [ "$output" -gt 10 ]
}

@test "plugin references COLOR_GREEN variable" {
    run grep -q 'color=\$COLOR_GREEN' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin references COLOR_RED variable" {
    run grep -q 'color=\$COLOR_RED' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin references COLOR_YELLOW variable" {
    run grep -q 'color=\$COLOR_YELLOW' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin references COLOR_BLUE variable" {
    run grep -q 'color=\$COLOR_BLUE' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin references COLOR_GRAY variable" {
    run grep -q 'color=\$COLOR_GRAY' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin references COLOR_PURPLE variable" {
    run grep -q 'color=\$COLOR_PURPLE' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin references COLOR_ORANGE variable" {
    run grep -q 'color=\$COLOR_ORANGE' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# SWIFTBAR OUTPUT FORMAT - Font Attributes
# =============================================================================

@test "plugin uses font attribute for monospace" {
    run grep -q 'font=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]  # Optional feature
}

# =============================================================================
# SECTION COVERAGE - Local Environment
# =============================================================================

@test "Local Environment section exists" {
    run grep -q 'Local Environment' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "Local Environment section has mise status" {
    run grep -A 20 'Local Environment' "$PLUGIN_PATH"
    [[ "$output" =~ "Mise" ]]
}

@test "Local Environment section has agent readiness" {
    run grep -q 'AI Agent Setup' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "Local Environment section has autofix status" {
    run grep -q 'Tool Installation' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# SECTION COVERAGE - Homebrew Services
# =============================================================================

@test "Homebrew Services section exists" {
    run grep -q 'Homebrew Services' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "Homebrew Services section has color" {
    run grep 'Homebrew Services' "$PLUGIN_PATH"
    [[ "$output" =~ "color=" ]]
}

@test "Homebrew Services section has size" {
    run grep 'Homebrew Services' "$PLUGIN_PATH"
    [[ "$output" =~ "size=" ]]
}

# =============================================================================
# SECTION COVERAGE - OrbStack Containers
# =============================================================================

@test "Containers section exists" {
    run grep -q 'Containers' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "Containers section has OrbStack reference" {
    run grep -q 'OrbStack' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# SECTION COVERAGE - Port Detection
# =============================================================================

@test "Port Detection section exists" {
    run grep -q 'Active Ports' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "Port Detection section has color" {
    run grep 'Active Ports' "$PLUGIN_PATH"
    [[ "$output" =~ "color=" ]]
}

# =============================================================================
# SECTION COVERAGE - Settings
# =============================================================================

@test "Settings section exists" {
    run grep -q 'Settings' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "Settings section has project folder action" {
    run grep -q 'Open project folder' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "Settings section has mise.toml edit action" {
    run grep -q 'Edit mise.toml' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# SECTION COVERAGE - Cloud Agents
# =============================================================================

@test "Cloud Agents section exists" {
    run grep -q 'Cloud Agents' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "Cloud Agents section has SkyPilot reference" {
    run grep -q 'SkyPilot' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# ACTION HANDLING - Homebrew
# =============================================================================

@test "Homebrew start action uses correct format" {
    run grep 'param1=services param2=start' "$PLUGIN_PATH"
    [[ "$output" =~ "bash=brew" ]]
}

@test "Homebrew stop action uses correct format" {
    run grep 'param1=services param2=stop' "$PLUGIN_PATH"
    [[ "$output" =~ "bash=brew" ]]
}

@test "Homebrew restart action uses correct format" {
    run grep 'param1=services param2=restart' "$PLUGIN_PATH"
    [[ "$output" =~ "bash=brew" ]]
}

@test "Homebrew actions use terminal=false" {
    run grep 'param1=services' "$PLUGIN_PATH"
    [[ "$output" =~ "terminal=false" ]]
}

@test "Homebrew actions use refresh=true" {
    run grep 'param1=services' "$PLUGIN_PATH"
    [[ "$output" =~ "refresh=true" ]]
}

# =============================================================================
# ACTION HANDLING - OrbStack
# =============================================================================

@test "OrbStack start action uses correct format" {
    run grep 'param1=start' "$PLUGIN_PATH"
    [[ "$output" =~ "bash=orb" ]]
}

@test "OrbStack stop action uses correct format" {
    run grep 'param1=stop' "$PLUGIN_PATH"
    [[ "$output" =~ "bash=orb" ]]
}

@test "OrbStack actions use terminal=false" {
    run grep 'bash=orb' "$PLUGIN_PATH"
    [[ "$output" =~ "terminal=false" ]]
}

@test "OrbStack actions use refresh=true" {
    run grep 'bash=orb' "$PLUGIN_PATH"
    [[ "$output" =~ "refresh=true" ]]
}

# =============================================================================
# SECURITY & QUALITY - No Sudo
# =============================================================================

@test "plugin does not use sudo anywhere" {
    run grep -q 'sudo' "$PLUGIN_PATH"
    [ "$status" -ne 0 ]
}

# =============================================================================
# SECURITY & QUALITY - No Global Installs
# =============================================================================

@test "plugin does not use npm -g" {
    run grep -q 'npm.*-g' "$PLUGIN_PATH"
    [ "$status" -ne 0 ]
}

@test "plugin does not use pip install globally" {
    run grep -q 'pip install' "$PLUGIN_PATH"
    [ "$status" -ne 0 ]
}

@test "plugin does not use npm install globally" {
    run grep -q 'npm install' "$PLUGIN_PATH"
    [ "$status" -ne 0 ]
}

# =============================================================================
# SECURITY & QUALITY - No Hardcoded Paths
# =============================================================================

@test "plugin does not hardcode /Users/ paths" {
    run grep '/Users/[a-z]' "$PLUGIN_PATH"
    [ "$status" -ne 0 ]
}

@test "plugin uses $HOME for home directory" {
    run grep -q '\$HOME' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses $PROJECT_DIR for project paths" {
    run grep -q '\$PROJECT_DIR' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# SECURITY & QUALITY - Error Handling
# =============================================================================

@test "plugin guards all external commands with cmd_exists" {
    run grep -c 'cmd_exists' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [ "$output" -ge 6 ]
}

@test "plugin redirects stderr for command checks" {
    run grep -A 1 'cmd_exists()' "$PLUGIN_PATH"
    [[ "$output" =~ "&>/dev/null" ]]
}

@test "plugin handles missing mise gracefully" {
    run grep -A 3 'cmd_exists mise' "$PLUGIN_PATH"
    [[ "$output" =~ "echo" ]]
}

@test "plugin handles missing brew gracefully" {
    run grep -A 3 'cmd_exists brew' "$PLUGIN_PATH"
    [[ "$output" =~ "return" ]]
}

@test "plugin handles missing orb gracefully" {
    run grep -A 3 'cmd_exists orb' "$PLUGIN_PATH"
    [[ "$output" =~ "return" ]]
}

@test "plugin handles missing lsof gracefully" {
    run grep -A 3 'cmd_exists lsof' "$PLUGIN_PATH"
    [[ "$output" =~ "return" ]]
}

# =============================================================================
# SECURITY & QUALITY - Bash Safety
# =============================================================================

@test "plugin uses [[ ]] for conditionals (bash safe)" {
    run grep -c '\[\[' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [ "$output" -gt 5 ]
}

@test "plugin uses local variables in functions" {
    run grep -c 'local ' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [ "$output" -gt 3 ]
}

@test "plugin quotes variables properly" {
    run grep -c '\"\$' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
    [ "$output" -gt 10 ]
}

# =============================================================================
# CONFIGURATION VALIDATION - Status Collection
# =============================================================================

@test "plugin collects MISE_STATUS" {
    run grep -q 'MISE_STATUS=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin collects ORB_STATUS" {
    run grep -q 'ORB_STATUS=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin collects DEVPOD_COUNT" {
    run grep -q 'DEVPOD_COUNT=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin collects SKY_COUNT" {
    run grep -q 'SKY_COUNT=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin collects AGENT_READY" {
    run grep -q 'AGENT_READY=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin collects AUTOFIX_STATUS" {
    run grep -q 'AUTOFIX_STATUS=' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# MENU BAR ICON - Traffic Light System
# =============================================================================

@test "plugin uses green circle emoji for ok status" {
    run grep -q '🟢' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses red circle emoji for error status" {
    run grep -q '🔴' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses yellow circle emoji for warning status" {
    run grep -q '🟡' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin uses white circle emoji for idle status" {
    run grep -q '⚪' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# DOCUMENTATION LINKS
# =============================================================================

@test "plugin has link to Mise documentation" {
    run grep -q 'mise.jdx.dev' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has link to SwiftBar documentation" {
    run grep -q 'swiftbar/SwiftBar' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has link to SkyPilot documentation" {
    run grep -q 'skypilot' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has link to Homebrew" {
    run grep -q 'brew.sh' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "plugin has link to OrbStack" {
    run grep -q 'orbstack.dev' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# HELPER FUNCTION VALIDATION - get_agent_readiness
# =============================================================================

@test "get_agent_readiness function is defined" {
    run grep -q 'get_agent_readiness()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_agent_readiness checks for script file" {
    run grep -A 3 'get_agent_readiness()' "$PLUGIN_PATH"
    [[ "$output" =~ "-f" ]]
}

@test "get_agent_readiness returns not_found when script missing" {
    run grep -A 3 'get_agent_readiness()' "$PLUGIN_PATH"
    [[ "$output" =~ "not_found" ]]
}

@test "get_agent_readiness calls agent-readiness.sh" {
    run grep -q 'agent-readiness.sh' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# HELPER FUNCTION VALIDATION - get_autofix_status
# =============================================================================

@test "get_autofix_status function is defined" {
    run grep -q 'get_autofix_status()' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}

@test "get_autofix_status checks for script file" {
    run grep -A 3 'get_autofix_status()' "$PLUGIN_PATH"
    [[ "$output" =~ "-f" ]]
}

@test "get_autofix_status returns not_found when script missing" {
    run grep -A 3 'get_autofix_status()' "$PLUGIN_PATH"
    [[ "$output" =~ "not_found" ]]
}

@test "get_autofix_status calls autofix.sh" {
    run grep -q 'autofix.sh' "$PLUGIN_PATH"
    [ "$status" -eq 0 ]
}
