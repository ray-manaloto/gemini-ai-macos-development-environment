# Design: Telemetry and Visual Feedback System

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            USER INTERFACES                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │
│  │ DevEnvManager   │  │   CLI Scripts   │  │   mise tasks    │              │
│  │    (Tauri)      │  │   (bash/zsh)    │  │   (validate)    │              │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘              │
│           │                    │                    │                        │
│           ▼                    ▼                    ▼                        │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                     FEEDBACK LAYER                                    │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                │   │
│  │  │    Toast     │  │   Progress   │  │    Error     │                │   │
│  │  │  Component   │  │     Bar      │  │   Boundary   │                │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│                                    ▼                                         │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                     TELEMETRY LAYER                                   │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                │   │
│  │  │   Event      │  │    Local     │  │   Remote     │                │   │
│  │  │  Emitter     │  │   Storage    │  │    Sync      │                │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
└────────────────────────────────────┼─────────────────────────────────────────┘
                                     │
                                     ▼
                    ┌────────────────────────────────┐
                    │          AWS Cloud             │
                    │  ┌──────────┐  ┌──────────┐   │
                    │  │ Grafana  │  │ OpenList │   │
                    │  │          │  │          │   │
                    │  └──────────┘  └──────────┘   │
                    └────────────────────────────────┘
```

## Component Design

### 1. Toast Notification System (React)

**Location**: `DevEnvManager-Tauri/src/components/Toast.tsx`

```typescript
// Toast types
type ToastType = 'success' | 'error' | 'warning' | 'info' | 'progress';

interface Toast {
  id: string;
  type: ToastType;
  title: string;
  message?: string;
  progress?: number;  // 0-100 for progress type
  duration?: number;  // ms, null for persistent
  action?: {
    label: string;
    onClick: () => void;
  };
}

// Toast Context API
interface ToastContextValue {
  toasts: Toast[];
  addToast: (toast: Omit<Toast, 'id'>) => string;
  updateToast: (id: string, updates: Partial<Toast>) => void;
  removeToast: (id: string) => void;
  success: (title: string, message?: string) => void;
  error: (title: string, message?: string) => void;
  progress: (title: string, percent: number) => string;
}
```

**Visual Design**:
- Position: Bottom-right, stacked
- Animation: Slide in from right, fade out
- Duration: Success (3s), Error (5s), Progress (persistent)
- Style: Industrial-brutalist matching existing UI

### 2. Progress Tracking

**Location**: `DevEnvManager-Tauri/src/hooks/useProgressOperation.ts`

```typescript
interface ProgressOperation<T> {
  execute: () => Promise<T>;
  onProgress?: (percent: number, message: string) => void;
  onSuccess?: (result: T) => void;
  onError?: (error: Error) => void;
}

function useProgressOperation<T>(operation: ProgressOperation<T>) {
  const { progress: showProgress, success, error } = useToast();
  
  const run = async () => {
    const toastId = showProgress(operation.title, 0);
    try {
      // For Tauri commands that emit progress events
      const unlisten = await listen('operation-progress', (event) => {
        updateToast(toastId, { progress: event.payload.percent });
      });
      
      const result = await operation.execute();
      removeToast(toastId);
      success(`${operation.title} completed`);
      return result;
    } catch (e) {
      removeToast(toastId);
      error(`${operation.title} failed`, e.message);
      throw e;
    }
  };
  
  return { run };
}
```

**Rust Backend Progress Events**:

```rust
// src-tauri/src/commands/mise.rs

#[tauri::command]
async fn run_mise_update_all(window: tauri::Window) -> Result<String, String> {
    let mut child = Command::new("mise")
        .args(["run", "tools:update"])
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| e.to_string())?;
    
    // Emit progress events based on output parsing
    let stdout = child.stdout.take().unwrap();
    let reader = BufReader::new(stdout);
    
    for (i, line) in reader.lines().enumerate() {
        if let Ok(line) = line {
            // Parse tool update progress
            let percent = calculate_progress(&line, total_tools);
            window.emit("operation-progress", json!({
                "operation": "update_all",
                "percent": percent,
                "message": line
            })).ok();
        }
    }
    
    let status = child.wait().map_err(|e| e.to_string())?;
    if status.success() {
        Ok("All tools updated".to_string())
    } else {
        Err("Update failed".to_string())
    }
}
```

### 3. Telemetry Event Schema

**Event Structure**:

```typescript
interface TelemetryEvent {
  id: string;           // UUID
  timestamp: string;    // ISO 8601
  source: 'tauri' | 'cli' | 'tui' | 'script';
  category: 'operation' | 'error' | 'metric';
  
  // Event details
  name: string;         // e.g., 'mise.update_all'
  status: 'started' | 'progress' | 'completed' | 'failed';
  duration_ms?: number;
  
  // Context
  machine_id: string;   // Hashed hostname
  mise_version: string;
  
  // Payload (varies by event)
  payload?: Record<string, unknown>;
}
```

**Example Events**:

```json
// Operation start
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-02-07T02:30:00.000Z",
  "source": "tauri",
  "category": "operation",
  "name": "mise.update_all",
  "status": "started",
  "machine_id": "abc123",
  "mise_version": "2025.2.0"
}

// Operation complete
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "timestamp": "2026-02-07T02:30:45.000Z",
  "source": "tauri",
  "category": "operation",
  "name": "mise.update_all",
  "status": "completed",
  "duration_ms": 45000,
  "machine_id": "abc123",
  "mise_version": "2025.2.0",
  "payload": {
    "tools_updated": 12,
    "tools_skipped": 3
  }
}

// Error event
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "timestamp": "2026-02-07T02:31:00.000Z",
  "source": "tauri",
  "category": "error",
  "name": "mise.install_tool",
  "status": "failed",
  "machine_id": "abc123",
  "mise_version": "2025.2.0",
  "payload": {
    "tool": "python",
    "version": "3.12.0",
    "error": "Network timeout"
  }
}
```

### 4. Local Telemetry Storage

**Location**: `~/.config/dev-env/telemetry/`

```
~/.config/dev-env/telemetry/
├── events.jsonl          # Append-only event log (JSONL format)
├── pending_sync.jsonl    # Events pending remote sync
└── config.json           # Telemetry settings
```

**Config Structure**:

```json
{
  "enabled": true,
  "remote_sync": false,
  "remote_endpoint": null,
  "retention_days": 30,
  "machine_id": "sha256(hostname)"
}
```

**Rust Implementation**:

```rust
// src-tauri/src/telemetry.rs

pub struct TelemetryManager {
    config_path: PathBuf,
    events_path: PathBuf,
}

impl TelemetryManager {
    pub fn emit(&self, event: TelemetryEvent) -> Result<(), Error> {
        // Append to local JSONL file
        let mut file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.events_path)?;
        
        writeln!(file, "{}", serde_json::to_string(&event)?)?;
        
        // Queue for remote sync if enabled
        if self.config.remote_sync {
            self.queue_for_sync(event)?;
        }
        
        Ok(())
    }
    
    pub async fn sync_pending(&self) -> Result<usize, Error> {
        // Read pending events
        // POST to remote endpoint
        // Clear pending on success
    }
}
```

### 5. CLI/Script Integration

**Bash Helper Function** (added to scripts):

```bash
# config/scripts/telemetry.sh

emit_telemetry() {
    local name="$1"
    local status="$2"
    local payload="${3:-{}}"
    
    local event=$(cat <<EOF
{
  "id": "$(uuidgen)",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
  "source": "script",
  "category": "operation",
  "name": "$name",
  "status": "$status",
  "machine_id": "$(hostname | shasum -a 256 | cut -c1-16)",
  "mise_version": "$(mise --version 2>/dev/null | head -1)",
  "payload": $payload
}
EOF
)
    
    echo "$event" >> ~/.config/dev-env/telemetry/events.jsonl
}

# Usage in scripts:
emit_telemetry "validate.start" "started"
# ... do work ...
emit_telemetry "validate.complete" "completed" '{"checks_passed": 42}'
```

### 6. Remote Sync (Optional)

**Endpoint Specification**:

```
POST https://telemetry.{your-domain}/v1/events
Authorization: Bearer {api_key}
Content-Type: application/json

{
  "events": [
    { ... event 1 ... },
    { ... event 2 ... }
  ]
}
```

**Grafana/OpenList Integration**:
- Events stored in InfluxDB/Loki
- Dashboards for:
  - Operation frequency and duration
  - Error rates by tool/machine
  - Environment health over time

## Data Flow

### 1. User Action → Toast

```
User clicks "Update All"
    ↓
useQuickActions.runUpdateAll()
    ↓
Toast shows: "Updating all tools..."
    ↓
Tauri invoke: run_mise_update_all
    ↓
Rust emits progress events
    ↓
React updates toast progress bar
    ↓
On success: Toast shows "✓ All tools updated"
On error: Toast shows "✗ Update failed: {message}"
```

### 2. Operation → Telemetry

```
Operation starts
    ↓
TelemetryManager.emit({status: "started"})
    ↓
Append to events.jsonl
    ↓
If remote_sync enabled:
    Queue in pending_sync.jsonl
    ↓
Background sync task
    ↓
POST to remote endpoint
    ↓
Clear pending on success
```

## File Changes

### New Files

| File | Purpose |
|------|---------|
| `src/components/Toast.tsx` | Toast notification component |
| `src/components/ToastContainer.tsx` | Toast stack container |
| `src/contexts/ToastContext.tsx` | Toast state management |
| `src/hooks/useProgressOperation.ts` | Progress tracking hook |
| `src/styles/toast.css` | Toast styling |
| `src-tauri/src/telemetry.rs` | Telemetry manager |
| `config/scripts/telemetry.sh` | CLI telemetry helper |

### Modified Files

| File | Changes |
|------|---------|
| `src/App.tsx` | Wrap with ToastProvider |
| `src/hooks/useQuickActions.ts` | Add toast notifications |
| `src/hooks/usePackageManagers.ts` | Add toast notifications |
| `src/hooks/useCloudStatus.ts` | Add toast notifications |
| `src-tauri/src/lib.rs` | Register telemetry manager |
| `src-tauri/src/commands/mise.rs` | Emit progress events |
| `config/scripts/validate.sh` | Emit telemetry events |

## Testing Strategy

### Unit Tests

```typescript
// Toast context tests
describe('ToastContext', () => {
  it('adds toast to stack', () => { ... });
  it('removes toast after duration', () => { ... });
  it('updates progress toast', () => { ... });
});
```

### Integration Tests

```rust
// Rust telemetry tests
#[test]
fn test_emit_appends_to_file() { ... }

#[test]
fn test_sync_clears_pending() { ... }
```

### E2E Tests (Playwright)

```typescript
test('Update All shows progress toast', async ({ page }) => {
  await page.click('[data-testid="update-all-btn"]');
  await expect(page.locator('.toast-progress')).toBeVisible();
  await expect(page.locator('.toast-success')).toBeVisible({ timeout: 60000 });
});
```

## Performance Considerations

1. **Async Event Emission**: Never block UI thread for telemetry
2. **Batched Sync**: Sync events in batches, not individually
3. **Local-First**: Always write locally first, sync later
4. **Retention Policy**: Auto-cleanup events older than N days
5. **Bounded Queue**: Max pending events before oldest dropped

## Security Considerations

1. **No PII**: Events contain no personal information
2. **Hashed Machine ID**: Hostname is SHA256 hashed
3. **Opt-In Remote**: Remote sync disabled by default
4. **HTTPS Only**: Remote endpoint requires HTTPS
5. **API Key Auth**: Bearer token for remote sync
