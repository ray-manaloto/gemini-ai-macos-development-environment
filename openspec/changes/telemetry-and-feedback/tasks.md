# Tasks: Telemetry and Visual Feedback System

## Sprint 1: Toast Notification System (P0)

### T1.1: Create Toast Context and Provider
**Status**: pending  
**Estimate**: 2h  
**Files**: `src/contexts/ToastContext.tsx`

Create React context for toast state management:
- Toast state array
- addToast, updateToast, removeToast methods
- success, error, warning, info, progress shortcuts
- Auto-dismiss timers

### T1.2: Create Toast Component
**Status**: pending  
**Estimate**: 2h  
**Files**: `src/components/Toast.tsx`

Individual toast component:
- Type-based styling (success/error/warning/info/progress)
- Icon per type
- Title and optional message
- Dismiss button
- Optional action button
- Progress bar for progress type

### T1.3: Create Toast Container
**Status**: pending  
**Estimate**: 1h  
**Files**: `src/components/ToastContainer.tsx`

Fixed-position container:
- Bottom-right positioning
- Stack layout with gap
- Animation handling (enter/exit)
- Max 5 visible toasts

### T1.4: Toast CSS Styling
**Status**: pending  
**Estimate**: 1h  
**Files**: `src/styles/toast.css`

Industrial-brutalist styling:
- Monospace typography
- High contrast colors
- Sharp borders
- Slide-in/fade-out animations

### T1.5: Integrate ToastProvider in App
**Status**: pending  
**Estimate**: 30m  
**Files**: `src/App.tsx`

Wrap app with ToastProvider.

### T1.6: Update useQuickActions with Toasts
**Status**: pending  
**Estimate**: 1h  
**Files**: `src/hooks/useQuickActions.ts`

Replace console.error with toast notifications:
- Success toast on operation complete
- Error toast on operation failure

---

## Sprint 2: Progress Tracking (P0)

### T2.1: Define Progress Event Types
**Status**: pending  
**Estimate**: 30m  
**Files**: `src-tauri/src/commands/mod.rs`, `src/types/progress.ts`

Define ProgressEvent struct/interface:
- operation, status, percent, message, current, total

### T2.2: Create useProgressOperation Hook
**Status**: pending  
**Estimate**: 1h  
**Files**: `src/hooks/useProgressOperation.ts`

Hook for listening to Tauri progress events:
- Subscribe to 'operation-progress' events
- Update toast progress
- Handle completion/failure

### T2.3: Update run_mise_update_all with Progress
**Status**: pending  
**Estimate**: 2h  
**Files**: `src-tauri/src/commands/mise.rs`

Emit progress events during update:
- Count tools to update
- Emit progress after each tool
- Parse mise output for tool names

### T2.4: Connect Progress to Toast System
**Status**: pending  
**Estimate**: 1h  
**Files**: `src/hooks/useQuickActions.ts`

Use progress hook to update toast:
- Create progress toast on start
- Update progress bar in real-time
- Replace with success/error on completion

---

## Sprint 3: Telemetry Backend (P1)

### T3.1: Create Telemetry Module
**Status**: pending  
**Estimate**: 2h  
**Files**: `src-tauri/src/telemetry.rs`, `src-tauri/src/telemetry/mod.rs`

Core telemetry manager:
- TelemetryEvent struct
- TelemetryConfig loading
- emit() method for local storage

### T3.2: Create Telemetry Config
**Status**: pending  
**Estimate**: 1h  
**Files**: `src-tauri/src/telemetry/config.rs`

Config management:
- Load/save config.json
- Generate machine_id on first run
- Default values

### T3.3: Local Event Storage
**Status**: pending  
**Estimate**: 1h  
**Files**: `src-tauri/src/telemetry.rs`

JSONL file handling:
- Append events to events.jsonl
- File rotation when too large
- Retention cleanup

### T3.4: Integrate Telemetry in Commands
**Status**: pending  
**Estimate**: 2h  
**Files**: `src-tauri/src/commands/*.rs`

Add telemetry.emit() calls:
- All mise commands
- All brew commands
- All container commands
- All cloud commands

### T3.5: App Lifecycle Events
**Status**: pending  
**Estimate**: 1h  
**Files**: `src-tauri/src/lib.rs`

Emit lifecycle events:
- app.opened on startup
- app.closed on exit

---

## Sprint 4: CLI Integration (P1)

### T4.1: Create Bash Telemetry Helper
**Status**: pending  
**Estimate**: 1h  
**Files**: `config/scripts/telemetry.sh`

Bash functions for telemetry:
- emit_telemetry()
- emit_timed()
- get_machine_id()

### T4.2: Integrate in validate.sh
**Status**: pending  
**Estimate**: 30m  
**Files**: `config/scripts/validate.sh`

Add telemetry to validation:
- Emit on start
- Emit on complete with check counts
- Emit on failure

### T4.3: Integrate in Other Scripts
**Status**: pending  
**Estimate**: 1h  
**Files**: `config/scripts/*.sh`

Add telemetry to:
- dashboard.py wrapper
- setup scripts
- mise task wrappers

---

## Sprint 5: Remote Sync (P2)

### T5.1: Create Sync Module
**Status**: pending  
**Estimate**: 2h  
**Files**: `src-tauri/src/telemetry/sync.rs`

Remote sync functionality:
- Queue events in pending/
- POST batches to endpoint
- Retry on failure
- Dead-letter after 3 failures

### T5.2: Background Sync Task
**Status**: pending  
**Estimate**: 1h  
**Files**: `src-tauri/src/telemetry/sync.rs`

Async background sync:
- Run every 5 minutes
- Check for pending batches
- Non-blocking

### T5.3: Config UI for Remote Sync
**Status**: pending  
**Estimate**: 2h  
**Files**: `src/components/Settings.tsx`

Settings panel for telemetry:
- Enable/disable telemetry
- Enable/disable remote sync
- Set endpoint URL
- Set API key

---

## Sprint 6: Testing & Polish (P1)

### T6.1: Toast Unit Tests
**Status**: pending  
**Estimate**: 1h  
**Files**: `src/__tests__/Toast.test.tsx`

Test toast functionality:
- Add/remove toasts
- Auto-dismiss timing
- Progress updates

### T6.2: Telemetry Unit Tests
**Status**: pending  
**Estimate**: 1h  
**Files**: `src-tauri/src/telemetry/tests.rs`

Test telemetry:
- Event serialization
- File append
- Config loading

### T6.3: E2E Tests
**Status**: pending  
**Estimate**: 2h  
**Files**: `tests/e2e/feedback.spec.ts`

Playwright tests:
- Toast appears on button click
- Progress updates during operation
- Error toast on failure

### T6.4: Documentation Update
**Status**: pending  
**Estimate**: 1h  
**Files**: `DevEnvManager-Tauri/README.md`, `AGENTS.md`

Update docs:
- Toast usage examples
- Telemetry configuration
- CLI integration guide

---

## Task Summary

| Sprint | Tasks | Estimate |
|--------|-------|----------|
| S1: Toast System | 6 | 8.5h |
| S2: Progress | 4 | 4.5h |
| S3: Telemetry Backend | 5 | 7h |
| S4: CLI Integration | 3 | 2.5h |
| S5: Remote Sync | 3 | 5h |
| S6: Testing | 4 | 5h |
| **Total** | **25** | **32.5h** |

## Dependencies

```
S1: Toast System (no deps)
    ↓
S2: Progress (depends on S1)
    ↓
S3: Telemetry Backend (can parallel with S2)
    ↓
S4: CLI Integration (depends on S3)
    ↓
S5: Remote Sync (depends on S3)
    ↓
S6: Testing (depends on all)
```

## Acceptance Criteria

- [ ] User sees toast for every button click (success or error)
- [ ] Progress bar shows during "Update All"
- [ ] Telemetry events written to ~/.config/dev-env/telemetry/events.jsonl
- [ ] CLI scripts emit telemetry via helper
- [ ] All tests pass
- [ ] Documentation updated
