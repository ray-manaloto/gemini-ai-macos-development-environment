# Spec: Progress Tracking

## Overview

Real-time progress tracking for long-running operations in DevEnvManager-Tauri, using Tauri event system for backend-to-frontend communication.

## Requirements

### Functional

| ID | Requirement |
|----|-------------|
| PT-1 | Show progress for operations > 2 seconds |
| PT-2 | Display percentage complete (0-100%) |
| PT-3 | Display current step/item being processed |
| PT-4 | Update progress in real-time (< 500ms lag) |
| PT-5 | Support indeterminate progress (spinner) |
| PT-6 | Cancel button for cancellable operations |

### Non-Functional

| ID | Requirement |
|----|-------------|
| PT-NF-1 | Progress updates don't block UI |
| PT-NF-2 | Smooth progress bar animation |
| PT-NF-3 | Memory efficient (no event accumulation) |

## Scenarios

### Scenario: Update All Progress

**Given** the user clicks "Update All"  
**And** 15 tools need updating  
**When** each tool finishes updating  
**Then** the progress bar advances (e.g., 1/15 = 6.67%)  
**And** the current tool name is displayed  
**And** on completion, success toast appears

### Scenario: Indeterminate Progress

**Given** the user clicks "Validate"  
**And** validation duration is unknown  
**When** validation is in progress  
**Then** an animated spinner/pulse shows activity  
**And** no percentage is displayed

### Scenario: Cancel Operation

**Given** "Update All" is in progress  
**When** the user clicks Cancel  
**Then** the operation stops  
**And** a warning toast shows "Update cancelled"

## Event Protocol

### Rust → Frontend Events

```rust
// Progress event payload
#[derive(Serialize)]
struct ProgressEvent {
    operation: String,     // "update_all", "install_tool", etc.
    status: String,        // "started", "progress", "completed", "failed"
    percent: Option<u8>,   // 0-100, None for indeterminate
    message: String,       // Current step description
    current: Option<u32>,  // Current item index (1-based)
    total: Option<u32>,    // Total items
}

// Emit from Rust command
window.emit("operation-progress", ProgressEvent {
    operation: "update_all".to_string(),
    status: "progress".to_string(),
    percent: Some(35),
    message: "Installing bun@1.2.0...".to_string(),
    current: Some(5),
    total: Some(15),
})?;
```

### Frontend Listener

```typescript
// useProgressOperation.ts
import { listen } from '@tauri-apps/api/event';

function useProgressOperation() {
  const [progress, setProgress] = useState<ProgressState | null>(null);
  
  useEffect(() => {
    const unlisten = listen<ProgressEvent>('operation-progress', (event) => {
      setProgress(event.payload);
      
      if (event.payload.status === 'completed') {
        showSuccessToast(event.payload.message);
        setProgress(null);
      } else if (event.payload.status === 'failed') {
        showErrorToast(event.payload.message);
        setProgress(null);
      }
    });
    
    return () => { unlisten.then(fn => fn()); };
  }, []);
  
  return progress;
}
```

## Operations with Progress

| Operation | Progress Type | Can Cancel |
|-----------|---------------|------------|
| Update All | Determinate (by tool count) | Yes |
| Install Tool | Indeterminate | No |
| Validate | Indeterminate | No |
| Doctor | Indeterminate | No |
| Dashboard | N/A (opens separate window) | N/A |

## Rust Command Changes

### run_mise_update_all

```rust
#[tauri::command]
async fn run_mise_update_all(window: tauri::Window) -> Result<String, String> {
    // Emit start event
    window.emit("operation-progress", json!({
        "operation": "update_all",
        "status": "started",
        "message": "Starting update..."
    })).ok();
    
    // Get tool list first
    let tools = get_outdated_tools()?;
    let total = tools.len();
    
    for (i, tool) in tools.iter().enumerate() {
        // Emit progress
        window.emit("operation-progress", json!({
            "operation": "update_all",
            "status": "progress",
            "percent": ((i + 1) * 100 / total) as u8,
            "message": format!("Updating {}...", tool.name),
            "current": i + 1,
            "total": total
        })).ok();
        
        // Update the tool
        update_tool(&tool.name)?;
    }
    
    // Emit completion
    window.emit("operation-progress", json!({
        "operation": "update_all",
        "status": "completed",
        "percent": 100,
        "message": format!("Updated {} tools", total)
    })).ok();
    
    Ok(format!("Updated {} tools", total))
}
```

## UI Integration

Progress state flows into the toast system:

```typescript
// QuickActionsBar.tsx
function QuickActionsBar() {
  const { running, runUpdateAll } = useQuickActions();
  const progress = useProgressOperation('update_all');
  
  return (
    <div className="quick-actions">
      <button 
        onClick={runUpdateAll}
        disabled={running}
      >
        {progress ? `${progress.percent}%` : 'Update All'}
      </button>
    </div>
  );
}
```

## Files

| File | Purpose |
|------|---------|
| `src/hooks/useProgressOperation.ts` | Progress event listener hook |
| `src-tauri/src/commands/mise.rs` | Updated with progress events |
| `src-tauri/src/commands/mod.rs` | ProgressEvent struct |

## Test Cases

| ID | Test |
|----|------|
| PT-T1 | Progress event updates state |
| PT-T2 | Completed event clears progress |
| PT-T3 | Failed event shows error |
| PT-T4 | Indeterminate shows spinner |
| PT-T5 | Cancel stops operation |
| PT-T6 | Multiple operations don't conflict |
