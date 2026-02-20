# Menu Bar GUI Sync Plan

**Branch**: `feat/menu-bar-gui-sync`  
**Status**: Planning  
**Created**: 2026-02-09

## Overview

This change synchronizes GUI improvements across all 4 menu bar implementations to ensure consistent user experience, visual design, and functionality.

## Implementations

| Implementation | Technology | Status | Location |
|---|---|---|---|
| **A: DevEnvManager** | Swift/SwiftUI | Native macOS app | `DevEnvManager/` |
| **B: DevEnvManager-SwiftBar** | Bash/SwiftBar | Plugin | `DevEnvManager-SwiftBar/` |
| **C: DevEnvManager-Iced** | Rust/Iced | Standalone binary | `DevEnvManager-Iced/` |
| **D: DevEnvManager-Tauri** | Rust/React | Tauri 2 app | `DevEnvManager-Tauri/` |

## Planned Improvements

### 1. Visual Design Consistency
- [ ] Unified color palette across all implementations
- [ ] Consistent typography and spacing
- [ ] Standardized icon set
- [ ] Dark/light mode support

### 2. UI Components
- [ ] Status indicators (running, stopped, error)
- [ ] Action buttons (start, stop, restart, logs)
- [ ] Tool status display
- [ ] Service health indicators

### 3. Functionality Sync
- [ ] Mise tool management
- [ ] Homebrew service control
- [ ] OrbStack container management
- [ ] Port detection and management
- [ ] SkyPilot cloud agent control

### 4. User Experience
- [ ] Improved error messages
- [ ] Loading states and progress indicators
- [ ] Keyboard shortcuts
- [ ] Accessibility (WCAG 2.1 AA)

### 5. Performance
- [ ] Optimized menu rendering
- [ ] Reduced CPU usage
- [ ] Faster status updates
- [ ] Efficient caching

## Files to Update

### Swift (DevEnvManager)
- `DevEnvManager/Presentation/Views/MenuBarView.swift`
- `DevEnvManager/Presentation/Views/StatusView.swift`
- `DevEnvManager/Presentation/Views/ToolsView.swift`
- `DevEnvManager/Design/LayoutConstants.swift`

### Bash (DevEnvManager-SwiftBar)
- `DevEnvManager-SwiftBar/dev-status.5s.sh`
- `DevEnvManager-SwiftBar/tests/test_*.bats`

### Rust/Iced (DevEnvManager-Iced)
- `DevEnvManager-Iced/src/views/menu.rs`
- `DevEnvManager-Iced/src/views/status.rs`
- `DevEnvManager-Iced/src/app.rs`

### Rust/React (DevEnvManager-Tauri)
- `DevEnvManager-Tauri/src/components/StatusPanel.tsx`
- `DevEnvManager-Tauri/src/components/ToolsList.tsx`
- `DevEnvManager-Tauri/src/components/ActionButtons.tsx`
- `DevEnvManager-Tauri/src-tauri/src/commands/mod.rs`

### Documentation
- `research/MENUBAR_IMPLEMENTATION_SPECS.md`
- `research/MENUBAR_COMPARISON_REPORT.md`

## Testing Strategy

### Unit Tests
- Component rendering tests
- State management tests
- Command execution tests

### Integration Tests
- Mise integration
- Homebrew integration
- OrbStack integration

### Visual Tests
- Screenshot comparisons
- Responsive design tests
- Dark/light mode tests

## Success Criteria

- [ ] All 4 implementations have consistent visual design
- [ ] All implementations support the same features
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] No performance regressions
- [ ] Accessibility standards met

## Timeline

- **Phase 1**: Design and planning (current)
- **Phase 2**: Swift implementation
- **Phase 3**: Bash/SwiftBar implementation
- **Phase 4**: Iced implementation
- **Phase 5**: Tauri implementation
- **Phase 6**: Testing and refinement
- **Phase 7**: Documentation and release

## Related Issues

- Menu bar notch overflow handling
- Cross-platform consistency
- Performance optimization
- Accessibility compliance

## Notes

- Coordinate with DevEnvManager implementations
- Ensure backward compatibility
- Test on multiple macOS versions
- Consider user feedback from existing implementations
