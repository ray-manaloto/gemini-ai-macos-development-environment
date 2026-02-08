# Spec: Telemetry System

## Overview

Local-first telemetry collection with optional remote sync to Grafana/OpenList on AWS. All GUIs, TUIs, CLI tools, and scripts emit standardized events.

## Requirements

### Functional

| ID | Requirement |
|----|-------------|
| TS-1 | Emit events for all significant operations |
| TS-2 | Store events locally in JSONL format |
| TS-3 | Optional remote sync to AWS endpoint |
| TS-4 | Auto-retry failed syncs |
| TS-5 | Configurable retention period |
| TS-6 | Machine ID is hashed (no PII) |
| TS-7 | CLI helper for bash scripts |

### Non-Functional

| ID | Requirement |
|----|-------------|
| TS-NF-1 | Event emission < 5ms |
| TS-NF-2 | No blocking on remote sync |
| TS-NF-3 | Graceful degradation if storage full |
| TS-NF-4 | Max 100MB local storage |

## Event Schema

```typescript
interface TelemetryEvent {
  // Identity
  id: string;              // UUID v4
  timestamp: string;       // ISO 8601 UTC
  
  // Source
  source: 'tauri' | 'cli' | 'tui' | 'script';
  machine_id: string;      // SHA256(hostname)[0:16]
  
  // Classification
  category: 'operation' | 'error' | 'metric' | 'lifecycle';
  name: string;            // e.g., "mise.update_all", "brew.start_service"
  status: 'started' | 'progress' | 'completed' | 'failed' | 'cancelled';
  
  // Metrics
  duration_ms?: number;    // For completed/failed
  
  // Context
  mise_version?: string;
  environment?: Record<string, string>;  // Selected env vars
  
  // Payload
  payload?: Record<string, unknown>;
}
```

## Event Categories

### Operation Events

```json
{"category": "operation", "name": "mise.update_all", "status": "started"}
{"category": "operation", "name": "mise.update_all", "status": "completed", "duration_ms": 45000}
{"category": "operation", "name": "brew.start_service", "status": "completed", "payload": {"service": "postgres"}}
```

### Error Events

```json
{"category": "error", "name": "mise.install_tool", "status": "failed", "payload": {"tool": "python", "error": "Network timeout"}}
```

### Metric Events

```json
{"category": "metric", "name": "env.health", "payload": {"tools_installed": 25, "services_running": 3}}
```

### Lifecycle Events

```json
{"category": "lifecycle", "name": "app.opened", "status": "completed"}
{"category": "lifecycle", "name": "app.closed", "status": "completed"}
```

## Local Storage

### Directory Structure

```
~/.config/dev-env/telemetry/
├── config.json           # Settings
├── events.jsonl          # Event log (append-only)
└── pending/              # Pending sync batches
    ├── batch_001.jsonl
    └── batch_002.jsonl
```

### Config File

```json
{
  "enabled": true,
  "remote_sync": false,
  "remote_endpoint": null,
  "api_key": null,
  "retention_days": 30,
  "max_storage_mb": 100,
  "machine_id": "a1b2c3d4e5f67890",
  "batch_size": 100,
  "sync_interval_seconds": 300
}
```

## Rust Implementation

```rust
// src-tauri/src/telemetry.rs

use serde::{Deserialize, Serialize};
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::PathBuf;
use uuid::Uuid;

#[derive(Serialize, Deserialize)]
pub struct TelemetryEvent {
    pub id: String,
    pub timestamp: String,
    pub source: String,
    pub machine_id: String,
    pub category: String,
    pub name: String,
    pub status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub duration_ms: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mise_version: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub payload: Option<serde_json::Value>,
}

pub struct TelemetryManager {
    config: TelemetryConfig,
    base_path: PathBuf,
}

impl TelemetryManager {
    pub fn new() -> Self {
        let base_path = dirs::config_dir()
            .unwrap()
            .join("dev-env")
            .join("telemetry");
        fs::create_dir_all(&base_path).ok();
        
        Self {
            config: TelemetryConfig::load(&base_path),
            base_path,
        }
    }
    
    pub fn emit(&self, event: TelemetryEvent) -> Result<(), String> {
        if !self.config.enabled {
            return Ok(());
        }
        
        let events_path = self.base_path.join("events.jsonl");
        let mut file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&events_path)
            .map_err(|e| e.to_string())?;
        
        let json = serde_json::to_string(&event).map_err(|e| e.to_string())?;
        writeln!(file, "{}", json).map_err(|e| e.to_string())?;
        
        Ok(())
    }
    
    pub fn emit_operation(&self, name: &str, status: &str, payload: Option<serde_json::Value>) {
        let event = TelemetryEvent {
            id: Uuid::new_v4().to_string(),
            timestamp: chrono::Utc::now().to_rfc3339(),
            source: "tauri".to_string(),
            machine_id: self.config.machine_id.clone(),
            category: "operation".to_string(),
            name: name.to_string(),
            status: status.to_string(),
            duration_ms: None,
            mise_version: get_mise_version(),
            payload,
        };
        self.emit(event).ok();
    }
}
```

## CLI Helper (Bash)

```bash
# config/scripts/telemetry.sh

TELEMETRY_DIR="${HOME}/.config/dev-env/telemetry"
TELEMETRY_FILE="${TELEMETRY_DIR}/events.jsonl"

# Ensure directory exists
mkdir -p "${TELEMETRY_DIR}"

# Get or create machine ID
get_machine_id() {
    local config_file="${TELEMETRY_DIR}/config.json"
    if [[ -f "${config_file}" ]]; then
        jq -r '.machine_id // empty' "${config_file}" 2>/dev/null
    fi
    
    # Generate if not exists
    if [[ -z "${machine_id}" ]]; then
        hostname | shasum -a 256 | cut -c1-16
    fi
}

# Emit telemetry event
emit_telemetry() {
    local name="$1"
    local status="$2"
    local payload="${3:-null}"
    
    local machine_id
    machine_id=$(get_machine_id)
    
    local mise_version
    mise_version=$(mise --version 2>/dev/null | head -1 || echo "unknown")
    
    local event
    event=$(jq -n \
        --arg id "$(uuidgen | tr '[:upper:]' '[:lower:]')" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)" \
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
            payload: $payload
        }')
    
    echo "${event}" >> "${TELEMETRY_FILE}"
}

# Emit with duration tracking
emit_timed() {
    local name="$1"
    shift
    local start_time
    start_time=$(date +%s%3N)
    
    emit_telemetry "${name}" "started"
    
    if "$@"; then
        local end_time
        end_time=$(date +%s%3N)
        local duration=$((end_time - start_time))
        emit_telemetry "${name}" "completed" "{\"duration_ms\": ${duration}}"
        return 0
    else
        local exit_code=$?
        emit_telemetry "${name}" "failed" "{\"exit_code\": ${exit_code}}"
        return ${exit_code}
    fi
}

# Usage examples:
# emit_telemetry "validate.check" "completed" '{"checks": 42}'
# emit_timed "tools.update" mise run tools:update
```

## Remote Sync

### Endpoint Specification

```
POST https://telemetry.example.com/v1/events
Authorization: Bearer {api_key}
Content-Type: application/json

Request:
{
  "events": [
    { ... event 1 ... },
    { ... event 2 ... }
  ]
}

Response (200 OK):
{
  "accepted": 100,
  "rejected": 0
}
```

### Sync Process

1. Check if remote_sync enabled
2. Read pending batches
3. POST to endpoint (batch of 100)
4. On success: delete batch file
5. On failure: increment retry count
6. After 3 failures: move to dead-letter

## Grafana Dashboard

### Panels

| Panel | Metric |
|-------|--------|
| Operations/Hour | Count by name |
| Error Rate | Errors / Total |
| Avg Duration | By operation name |
| Tool Updates | By tool name |
| Active Machines | Unique machine_ids |

### Queries (InfluxDB)

```sql
-- Operations per hour
SELECT count(*) FROM events 
WHERE category = 'operation' AND status = 'completed'
GROUP BY time(1h), name

-- Error rate
SELECT count(*) FROM events 
WHERE category = 'error'
GROUP BY time(1h)
```

## Files

| File | Purpose |
|------|---------|
| `src-tauri/src/telemetry.rs` | Rust telemetry manager |
| `src-tauri/src/telemetry/config.rs` | Config handling |
| `src-tauri/src/telemetry/sync.rs` | Remote sync |
| `config/scripts/telemetry.sh` | Bash helper |

## Test Cases

| ID | Test |
|----|------|
| TS-T1 | Event appends to JSONL file |
| TS-T2 | Machine ID is consistent |
| TS-T3 | Disabled telemetry emits nothing |
| TS-T4 | Bash helper produces valid JSON |
| TS-T5 | Remote sync batches correctly |
| TS-T6 | Failed sync retries |
| TS-T7 | Retention cleanup works |
