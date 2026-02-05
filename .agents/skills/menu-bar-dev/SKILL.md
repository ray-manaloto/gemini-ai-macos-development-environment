---
name: menu-bar-dev
description: "macOS menu bar app development across all 4 implementations (Swift, SwiftBar, Iced, Tauri). Use when working on any DevEnvManager variant, modifying menu bar UI, system tray integration, NSStatusItem behavior, or cross-implementation feature parity. Triggers on: menu bar, system tray, NSStatusItem, SwiftBar, DevEnvManager, notch, tray icon, menu bar app, or status bar development."
---

# Menu Bar Development

4 implementations of the same menu bar app exist in this project. Each shows real-time dev environment status (mise tools, Homebrew services, OrbStack containers, ports).

## Implementations

| Spec | Name | Stack | Location | Tests | Rank |
|------|------|-------|----------|-------|------|
| A | SwiftBar | Bash plugin | `DevEnvManager-SwiftBar/` | 272 | 4th |
| B | Swift | Native SwiftUI | `DevEnvManager/` | 91 | 1st |
| C | Iced | Rust iced+tray-icon | `DevEnvManager-Iced/` | 48 | 2nd |
| D | Tauri | Rust+React | `DevEnvManager-Tauri/` | 42 | 3rd |

Ranking: B (Swift) > C (Iced) > D (Tauri) > A (SwiftBar)

## Feature Parity (68 Core Tests)

`tests/test_menubar_core.bats` defines 68 core feature parity tests that ALL implementations must satisfy:

1. **Mise tools display** — show name, version, status, update available
2. **Homebrew services** — show name, status (running/stopped), actions
3. **OrbStack containers** — show name, status, resource usage
4. **Port monitoring** — show port, process, PID
5. **Status icon** — green/yellow/red based on health
6. **Quick actions** — update tool, restart service, open terminal
7. **Refresh** — auto-refresh interval, manual refresh

## macOS Menu Bar Constraints

### Hardware Notch (M2 Max)

- MacBook Pro M2 Max has a camera notch that clips the menu bar center
- NSStatusItems overflow BEHIND the notch, becoming invisible
- ~45 apps compete for menu bar space
- No public API to programmatically reposition NSStatusItems
- Only fix: `Cmd-drag` to reorder, or use Ice.app/Bartender to manage

### Menu Bar API

```
NSStatusBar.system.statusItem(withLength: .variable)
    → NSStatusItem
        → .button (NSStatusBarButton) — icon/text
        → .menu (NSMenu) — dropdown content
```

### SwiftBar Output Format

```bash
echo "🟢 dev:OK"        # Status bar title (first line before ---)
echo "---"                # Separator
echo "Mise Tools | size=14 color=white"
echo "--bun 1.2.0 | color=green"
echo "--node 22.0.0 | color=green"
echo "---"
echo "Refresh | refresh=true"
```

## Development Workflows

### A: SwiftBar (Bash)
```bash
# Plugin at DevEnvManager-SwiftBar/dev-status.5s.sh
# Symlinked to ~/dev/swiftbar/ (custom plugin dir)
open /Applications/SwiftBar.app
bats DevEnvManager-SwiftBar/tests/
```

### B: Swift (Requires Xcode.app — NOT available)
```bash
# Cannot compile without Xcode.app (only Xcode CLT installed)
# cd DevEnvManager && xcodegen generate && xcodebuild build
bats DevEnvManager/Tests/   # Validation tests still work
```

### C: Iced (Rust)
```bash
cd DevEnvManager-Iced
cargo build --release
cargo test
./target/release/devenv-manager-iced &
```

### D: Tauri (Rust + React)
```bash
cd DevEnvManager-Tauri
bun install            # NOT npm install
bun tauri dev          # Dev with hot reload
bun tauri build        # Production
cd src-tauri && cargo test
```

## Cross-Implementation Concerns

### Shared Domain Logic

All 4 apps parse the same CLI outputs:
- `mise ls --json` → tool list
- `brew services list` → Homebrew services
- `orb list` → OrbStack containers
- `lsof -i -P -n` → port usage

### Adding a New Feature

When adding a feature to any implementation:
1. Check if `test_menubar_core.bats` has a parity test for it
2. If not, add the parity test first
3. Implement in the target implementation
4. Consider implementing in other specs for parity

### Research Documents

- `research/MENUBAR_IMPLEMENTATION_SPECS.md` — 4-way specs (1,195 lines)
- `research/MENUBAR_COMPARISON_REPORT.md` — Metrics + ranking
- `research/DEVENVMANAGER_TRAY_RESEARCH.md` — Notch overflow analysis
