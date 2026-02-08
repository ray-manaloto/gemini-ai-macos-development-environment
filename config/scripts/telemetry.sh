#!/usr/bin/env bash
# =============================================================================
# Telemetry Helper - God-Tier macOS Development Environment
# =============================================================================
# Provides functions for emitting telemetry events from CLI scripts.
# Events are stored in ~/.config/dev-env/telemetry/events.jsonl
#
# Usage:
#   source config/scripts/telemetry.sh
#   emit_telemetry "validate.start" "started"
#   emit_telemetry "validate.complete" "completed" '{"checks": 42}'
#   emit_timed "tools.update" mise run tools:update
#
# For AI Agents:
#   - All events are JSON formatted and stored locally
#   - Machine ID is hashed hostname (no PII)
#   - Events can optionally sync to remote Grafana/OpenList
# =============================================================================

set -euo pipefail

# Telemetry directory and file paths
TELEMETRY_DIR="${HOME}/.config/dev-env/telemetry"
TELEMETRY_FILE="${TELEMETRY_DIR}/events.jsonl"
TELEMETRY_CONFIG="${TELEMETRY_DIR}/config.json"

# Ensure telemetry directory exists
mkdir -p "${TELEMETRY_DIR}"

# =============================================================================
# Helper Functions
# =============================================================================

# Get or create machine ID (hashed hostname)
get_machine_id() {
    if [[ -f "${TELEMETRY_CONFIG}" ]]; then
        local machine_id
        machine_id=$(jq -r '.machine_id // empty' "${TELEMETRY_CONFIG}" 2>/dev/null || true)
        if [[ -n "${machine_id}" ]]; then
            echo "${machine_id}"
            return
        fi
    fi
    
    # Generate new machine ID from hashed hostname
    hostname | shasum -a 256 | cut -c1-16
}

# Get mise version
get_mise_version() {
    mise --version 2>/dev/null | head -1 || echo "unknown"
}

# Generate UUID v4
generate_uuid() {
    if command -v uuidgen &>/dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    else
        # Fallback: generate pseudo-UUID from /dev/urandom
        cat /dev/urandom | LC_ALL=C tr -dc 'a-f0-9' | fold -w 32 | head -n 1 | \
            sed 's/\(.\{8\}\)\(.\{4\}\)\(.\{4\}\)\(.\{4\}\)\(.\{12\}\)/\1-\2-\3-\4-\5/'
    fi
}

# Get ISO 8601 timestamp in UTC
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%S.000Z"
}

# Check if telemetry is enabled
is_telemetry_enabled() {
    if [[ -f "${TELEMETRY_CONFIG}" ]]; then
        local enabled
        enabled=$(jq -r '.enabled // true' "${TELEMETRY_CONFIG}" 2>/dev/null || echo "true")
        [[ "${enabled}" == "true" ]]
    else
        true  # Enabled by default
    fi
}

# =============================================================================
# Telemetry Emission Functions
# =============================================================================

# Emit a telemetry event
# Usage: emit_telemetry <name> <status> [payload]
# Example: emit_telemetry "validate.check" "completed" '{"checks": 42}'
emit_telemetry() {
    local name="$1"
    local status="$2"
    local payload="${3:-null}"
    
    # Skip if telemetry disabled
    if ! is_telemetry_enabled; then
        return 0
    fi
    
    local machine_id
    machine_id=$(get_machine_id)
    
    local mise_version
    mise_version=$(get_mise_version)
    
    local event
    event=$(jq -c -n \
        --arg id "$(generate_uuid)" \
        --arg timestamp "$(get_timestamp)" \
        --arg source "script" \
        --arg machine_id "${machine_id}" \
        --arg category "operation" \
        --arg name "${name}" \
        --arg status "${status}" \
        --arg mise_version "${mise_version}" \
        --argjson payload "${payload}" \
        '{
            id: $id,
            timestamp: $timestamp,
            source: $source,
            machine_id: $machine_id,
            category: $category,
            name: $name,
            status: $status,
            mise_version: $mise_version,
            payload: (if $payload == null then null else $payload end)
        } | with_entries(select(.value != null))')
    
    echo "${event}" >> "${TELEMETRY_FILE}"
}

# Emit an error event
# Usage: emit_error <name> <error_message>
emit_error() {
    local name="$1"
    local error_message="$2"
    
    emit_telemetry "${name}" "failed" "{\"error\": \"${error_message}\"}"
}

# Emit with duration tracking - wraps a command
# Usage: emit_timed <name> <command...>
# Example: emit_timed "tools.update" mise run tools:update
emit_timed() {
    local name="$1"
    shift
    
    local start_time
    start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    emit_telemetry "${name}" "started"
    
    local exit_code=0
    if "$@"; then
        exit_code=0
    else
        exit_code=$?
    fi
    
    local end_time
    end_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    local duration=$((end_time - start_time))
    
    if [[ ${exit_code} -eq 0 ]]; then
        emit_telemetry "${name}" "completed" "{\"duration_ms\": ${duration}}"
    else
        emit_telemetry "${name}" "failed" "{\"duration_ms\": ${duration}, \"exit_code\": ${exit_code}}"
    fi
    
    return ${exit_code}
}

# Emit a metric event
# Usage: emit_metric <name> <payload>
emit_metric() {
    local name="$1"
    local payload="$2"
    
    if ! is_telemetry_enabled; then
        return 0
    fi
    
    local machine_id
    machine_id=$(get_machine_id)
    
    local event
    event=$(jq -c -n \
        --arg id "$(generate_uuid)" \
        --arg timestamp "$(get_timestamp)" \
        --arg source "script" \
        --arg machine_id "${machine_id}" \
        --arg category "metric" \
        --arg name "${name}" \
        --arg status "recorded" \
        --argjson payload "${payload}" \
        '{
            id: $id,
            timestamp: $timestamp,
            source: $source,
            machine_id: $machine_id,
            category: $category,
            name: $name,
            status: $status,
            payload: $payload
        }')
    
    echo "${event}" >> "${TELEMETRY_FILE}"
}

# =============================================================================
# Telemetry Management
# =============================================================================

# View recent telemetry events
telemetry_tail() {
    local count="${1:-10}"
    tail -n "${count}" "${TELEMETRY_FILE}" 2>/dev/null | jq -r '"\(.timestamp) [\(.status)] \(.name)"'
}

# Count events by status
telemetry_stats() {
    if [[ ! -f "${TELEMETRY_FILE}" ]]; then
        echo "No telemetry events recorded yet."
        return
    fi
    
    echo "=== Telemetry Statistics ==="
    echo "Total events: $(wc -l < "${TELEMETRY_FILE}" | tr -d ' ')"
    echo ""
    echo "By status:"
    jq -r '.status' "${TELEMETRY_FILE}" | sort | uniq -c | sort -rn
    echo ""
    echo "By category:"
    jq -r '.category' "${TELEMETRY_FILE}" | sort | uniq -c | sort -rn
}

# Clear old telemetry events (older than N days)
telemetry_cleanup() {
    local days="${1:-30}"
    local cutoff_date
    cutoff_date=$(date -v-"${days}"d +%Y-%m-%d 2>/dev/null || date -d "${days} days ago" +%Y-%m-%d)
    
    if [[ -f "${TELEMETRY_FILE}" ]]; then
        local temp_file="${TELEMETRY_FILE}.tmp"
        jq -c "select(.timestamp >= \"${cutoff_date}\")" "${TELEMETRY_FILE}" > "${temp_file}" 2>/dev/null || true
        mv "${temp_file}" "${TELEMETRY_FILE}"
        echo "Cleaned up events older than ${days} days"
    fi
}

# =============================================================================
# CLI Interface (when run directly)
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        emit)
            shift
            emit_telemetry "$@"
            ;;
        error)
            shift
            emit_error "$@"
            ;;
        timed)
            shift
            emit_timed "$@"
            ;;
        metric)
            shift
            emit_metric "$@"
            ;;
        tail)
            telemetry_tail "${2:-10}"
            ;;
        stats)
            telemetry_stats
            ;;
        cleanup)
            telemetry_cleanup "${2:-30}"
            ;;
        help|--help|-h)
            cat <<EOF
Telemetry Helper - God-Tier macOS Development Environment

Usage:
  telemetry.sh <command> [args...]

Commands:
  emit <name> <status> [payload]  Emit a telemetry event
  error <name> <message>          Emit an error event
  timed <name> <command...>       Emit with duration tracking
  metric <name> <payload>         Emit a metric event
  tail [count]                    View recent events (default: 10)
  stats                           Show telemetry statistics
  cleanup [days]                  Remove old events (default: 30 days)
  help                            Show this help

Examples:
  telemetry.sh emit "validate.start" "started"
  telemetry.sh emit "validate.complete" "completed" '{"checks": 42}'
  telemetry.sh error "build.failed" "Missing dependency: foo"
  telemetry.sh timed "tools.update" mise run tools:update
  telemetry.sh metric "env.health" '{"tools": 25, "services": 3}'
  telemetry.sh tail 20
  telemetry.sh stats
  telemetry.sh cleanup 7

Environment:
  TELEMETRY_DIR: ${TELEMETRY_DIR}
  TELEMETRY_FILE: ${TELEMETRY_FILE}

For AI Agents:
  Source this script and use emit_telemetry, emit_error, emit_timed functions.
  Events are JSON formatted and stored locally in JSONL format.
EOF
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run 'telemetry.sh help' for usage"
            exit 1
            ;;
    esac
fi
