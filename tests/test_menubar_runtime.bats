#!/usr/bin/env bats
# test_menubar_runtime.bats - Launch each GUI app one at a time and validate
#
# Each test group:
#   1. Ensures the app is NOT already running
#   2. Launches the app
#   3. Waits for the process to appear
#   4. Validates it is alive (kill -0)
#   5. Stops the app
#   6. Validates it is gone
#
# Run with: bats tests/test_menubar_runtime.bats

setup() {
    export PROJECT_ROOT="${BATS_TEST_DIRNAME}/.."

    # Binary paths
    export SWIFTBAR_APP="/Applications/SwiftBar.app"
    export SWIFTBAR_BIN="${SWIFTBAR_APP}/Contents/MacOS/SwiftBar"

    export DEVENVMANAGER_APP="${HOME}/Applications/DevEnvManager.app"
    export DEVENVMANAGER_BIN="${DEVENVMANAGER_APP}/Contents/MacOS/DevEnvManager"

    export ICED_BIN="${PROJECT_ROOT}/DevEnvManager-Iced/target/release/devenv-manager-iced"

    export TAURI_BIN="${PROJECT_ROOT}/DevEnvManager-Tauri/src-tauri/target/debug/devenv-manager-tauri"

    # How long to wait for a process to appear after launch (seconds)
    export LAUNCH_WAIT=4
    # How long to wait for a process to disappear after kill (seconds)
    export KILL_WAIT=3
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

wait_for_process() {
    local pattern="$1"
    local timeout="${2:-$LAUNCH_WAIT}"
    local elapsed=0
    while [ "$elapsed" -lt "$timeout" ]; do
        if pgrep -f "$pattern" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    return 1
}

wait_for_no_process() {
    local pattern="$1"
    local timeout="${2:-$KILL_WAIT}"
    local elapsed=0
    while [ "$elapsed" -lt "$timeout" ]; do
        if ! pgrep -f "$pattern" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    return 1
}

kill_pattern() {
    local pattern="$1"
    pkill -f "$pattern" 2>/dev/null || true
}

# =============================================================================
# Spec A — SwiftBar
# =============================================================================

@test "RUNTIME: [Spec A] SwiftBar binary exists" {
    [ -x "$SWIFTBAR_BIN" ]
}

@test "RUNTIME: [Spec A] SwiftBar is not already running" {
    kill_pattern "SwiftBar"
    wait_for_no_process "SwiftBar"
    run pgrep -x SwiftBar
    [ "$status" -ne 0 ]
}

@test "RUNTIME: [Spec A] SwiftBar launches successfully" {
    open -a "$SWIFTBAR_APP"
    wait_for_process "SwiftBar" "$LAUNCH_WAIT"
    run pgrep -x SwiftBar
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "RUNTIME: [Spec A] SwiftBar process is alive" {
    run pgrep -x SwiftBar
    [ "$status" -eq 0 ]
    local pid="$output"
    run kill -0 "$pid"
    [ "$status" -eq 0 ]
}

@test "RUNTIME: [Spec A] SwiftBar plugin output is valid" {
    run bash "${PROJECT_ROOT}/DevEnvManager-SwiftBar/dev-status.5s.sh" 2>/dev/null
    [ "$status" -eq 0 ]
    [[ "$output" == *"---"* ]]
}

@test "RUNTIME: [Spec A] SwiftBar stops cleanly" {
    killall SwiftBar 2>/dev/null || true
    wait_for_no_process "SwiftBar"
    run pgrep -x SwiftBar
    [ "$status" -ne 0 ]
}

# =============================================================================
# Spec B — DevEnvManager (Native Swift)
# =============================================================================

@test "RUNTIME: [Spec B] DevEnvManager binary exists" {
    [ -x "$DEVENVMANAGER_BIN" ]
}

@test "RUNTIME: [Spec B] DevEnvManager is not already running" {
    kill_pattern "DevEnvManager"
    wait_for_no_process "DevEnvManager"
    run pgrep -x DevEnvManager
    [ "$status" -ne 0 ]
}

@test "RUNTIME: [Spec B] DevEnvManager launches successfully" {
    open -a "$DEVENVMANAGER_APP"
    wait_for_process "DevEnvManager" "$LAUNCH_WAIT"
    run pgrep -x DevEnvManager
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "RUNTIME: [Spec B] DevEnvManager process is alive" {
    run pgrep -x DevEnvManager
    [ "$status" -eq 0 ]
    local pid="$output"
    run kill -0 "$pid"
    [ "$status" -eq 0 ]
}

@test "RUNTIME: [Spec B] DevEnvManager appears in system process list" {
    run ps aux
    [[ "$output" == *"DevEnvManager"* ]]
}

@test "RUNTIME: [Spec B] DevEnvManager stops cleanly" {
    killall DevEnvManager 2>/dev/null || true
    wait_for_no_process "DevEnvManager"
    run pgrep -x DevEnvManager
    [ "$status" -ne 0 ]
}

# =============================================================================
# Spec C — Iced (Rust)
# =============================================================================

@test "RUNTIME: [Spec C] Iced binary exists" {
    [ -x "$ICED_BIN" ]
}

@test "RUNTIME: [Spec C] Iced is not already running" {
    kill_pattern "devenv-manager-iced"
    wait_for_no_process "devenv-manager-iced"
    run pgrep -f "devenv-manager-iced"
    [ "$status" -ne 0 ]
}

@test "RUNTIME: [Spec C] Iced launches successfully" {
    "$ICED_BIN" &
    ICED_PID=$!
    # Store PID for later tests
    echo "$ICED_PID" > "${BATS_TEST_TMPDIR}/iced_pid"
    wait_for_process "devenv-manager-iced" "$LAUNCH_WAIT"
    run pgrep -f "devenv-manager-iced"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "RUNTIME: [Spec C] Iced process is alive" {
    run pgrep -f "devenv-manager-iced"
    [ "$status" -eq 0 ]
    local pid
    pid=$(echo "$output" | head -1)
    run kill -0 "$pid"
    [ "$status" -eq 0 ]
}

@test "RUNTIME: [Spec C] Iced binary is release build" {
    [[ "$ICED_BIN" == *"/release/"* ]]
    local size
    size=$(stat -f%z "$ICED_BIN")
    [ "$size" -gt 1000000 ]
    [ "$size" -lt 20000000 ]
}

@test "RUNTIME: [Spec C] Iced stops cleanly" {
    pkill -f "devenv-manager-iced" 2>/dev/null || true
    wait_for_no_process "devenv-manager-iced"
    run pgrep -f "devenv-manager-iced"
    [ "$status" -ne 0 ]
}

# =============================================================================
# Spec D — Tauri (Rust + React)
# =============================================================================

@test "RUNTIME: [Spec D] Tauri binary exists" {
    [ -x "$TAURI_BIN" ]
}

@test "RUNTIME: [Spec D] Tauri is not already running" {
    kill_pattern "devenv-manager-tauri"
    wait_for_no_process "devenv-manager-tauri"
    run pgrep -f "devenv-manager-tauri"
    [ "$status" -ne 0 ]
}

@test "RUNTIME: [Spec D] Tauri launches successfully" {
    "$TAURI_BIN" &
    TAURI_PID=$!
    echo "$TAURI_PID" > "${BATS_TEST_TMPDIR}/tauri_pid"
    wait_for_process "devenv-manager-tauri" "$LAUNCH_WAIT"
    run pgrep -f "devenv-manager-tauri"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "RUNTIME: [Spec D] Tauri process is alive" {
    run pgrep -f "devenv-manager-tauri"
    [ "$status" -eq 0 ]
    local pid
    pid=$(echo "$output" | head -1)
    run kill -0 "$pid"
    [ "$status" -eq 0 ]
}

@test "RUNTIME: [Spec D] Tauri binary is a valid Mach-O executable" {
    run file "$TAURI_BIN"
    [[ "$output" == *"Mach-O"* ]]
    [[ "$output" == *"executable"* ]]
}

@test "RUNTIME: [Spec D] Tauri stops cleanly" {
    pkill -f "devenv-manager-tauri" 2>/dev/null || true
    wait_for_no_process "devenv-manager-tauri"
    run pgrep -f "devenv-manager-tauri"
    [ "$status" -ne 0 ]
}

# =============================================================================
# Final Cleanup — Ensure nothing is left running
# =============================================================================

@test "RUNTIME: [Cleanup] no GUI apps left running" {
    kill_pattern "SwiftBar"
    kill_pattern "DevEnvManager"
    kill_pattern "devenv-manager-iced"
    kill_pattern "devenv-manager-tauri"
    sleep 2

    run pgrep -x SwiftBar
    [ "$status" -ne 0 ]

    run pgrep -x DevEnvManager
    [ "$status" -ne 0 ]

    run pgrep -f "devenv-manager-iced"
    [ "$status" -ne 0 ]

    run pgrep -f "devenv-manager-tauri"
    [ "$status" -ne 0 ]
}
