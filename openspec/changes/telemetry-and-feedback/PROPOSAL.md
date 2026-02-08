# Proposal: Telemetry and Visual Feedback System

## Why

The DevEnvManager-Tauri app and all CLI/TUI tools suffer from **silent operation syndrome**:

1. **No Visual Feedback**: User clicks "Update All" → nothing visible happens → user doesn't know if it worked
2. **Errors Swallowed**: Errors go to `console.error` → users never see them
3. **No Progress Tracking**: Long operations (update, install) show no progress indicator
4. **No Observability**: No way to monitor environment health over time across machines
5. **Fragmented Interfaces**: GUI, TUI, CLI, scripts all operate independently with no shared telemetry

### Evidence from Current Implementation

```typescript
// DevEnvManager-Tauri/src/hooks/useQuickActions.ts
const runUpdateAll = useCallback(async () => {
  setRunning(true);
  try {
    await runMiseUpdateAll();
    // SUCCESS: User sees NOTHING
  } catch (error) {
    console.error("Update all failed:", error);  // User sees NOTHING
  } finally {
    setRunning(false);
  }
}, []);
```

The Tauri notification plugin is registered but **never used**:
```rust
// src-tauri/src/lib.rs:14
.plugin(tauri_plugin_notification::init())
```

## What Changes

This change introduces a **unified feedback and telemetry system** that:

1. **Toast Notifications**: Immediate visual feedback for all user actions (success/error/progress)
2. **Progress Indicators**: Real-time progress bars for long-running operations
3. **Error Display**: User-visible error messages with actionable context
4. **Telemetry Collection**: Local event collection with optional remote sync
5. **Unified Integration**: All GUIs/TUIs/CLI/scripts emit standardized events

### Target Users

- Developers using DevEnvManager-Tauri menu bar app
- CLI users running mise tasks
- Teams monitoring environment health across machines
- AI agents needing operation feedback

### Success Criteria

| Metric | Target |
|--------|--------|
| User sees feedback for every action | 100% of operations |
| Error messages visible to user | 100% of errors |
| Progress shown for operations > 2s | 100% of long operations |
| Telemetry events captured locally | All significant operations |
| Remote sync latency | < 5s for critical events |

## Scope

### In Scope

1. **DevEnvManager-Tauri**:
   - Toast/notification component
   - Progress bar component
   - Error boundary with user-visible errors
   - Local telemetry collection

2. **CLI Integration**:
   - Standardized output format for scripts
   - Telemetry emit from bash scripts
   - mise task wrappers

3. **Remote Telemetry**:
   - Endpoint specification (Grafana/OpenList on AWS)
   - Event schema definition
   - Sync mechanism

### Out of Scope (Future)

- Historical dashboards in the app itself
- Alert/notification system (email, Slack)
- Cross-machine aggregation UI
- Custom metrics beyond operation events

## Risks

| Risk | Mitigation |
|------|------------|
| Performance overhead from telemetry | Async, batched events; local-first design |
| Privacy concerns with remote sync | Opt-in only; no PII in events |
| Complexity in CLI integration | Simple JSON event format; optional adoption |

## Dependencies

- Tauri notification plugin (already registered)
- AWS infrastructure for remote telemetry (optional)
- Grafana/OpenList deployment (optional)
