# DevEnvManager: 4-Way Menubar Implementation Specs

> **Date:** February 2026
> **Purpose:** Detailed specs for parallel agent execution -- plan, build, code review, QA
> **Goal:** Build 4 implementations side-by-side for comparison

---

## Table of Contents

1. [Overview & Shared Requirements](#1-overview--shared-requirements)
2. [Spec A: SwiftBar Plugin (Enhanced)](#2-spec-a-swiftbar-plugin-enhanced)
3. [Spec B: Native Swift (NSStatusItem Fix)](#3-spec-b-native-swift-nsstatusitem-fix)
4. [Spec C: Rust + tray-icon + Iced](#4-spec-c-rust--tray-icon--iced)
5. [Spec D: Tauri 2 (Rust + Web)](#5-spec-d-tauri-2-rust--web)
6. [Additional Contenders](#6-additional-contenders)
7. [Comparison Criteria](#7-comparison-criteria)
8. [Parallel Agent Plan](#8-parallel-agent-plan)

---

## 1. Overview & Shared Requirements

### What We're Building

A **macOS menu bar app** that shows development environment status:
- Mise tool versions and health
- Homebrew service status (start/stop/restart)
- OrbStack containers (running/stopped)
- Port detection (which ports are in use)
- Quick actions (run mise tasks, open dashboards)

### Functional Requirements (ALL implementations)

| ID | Requirement | Priority |
|----|-------------|----------|
| F1 | Menu bar icon with status indicator (green/yellow/red/gray) | P0 |
| F2 | Click icon to show popup/dropdown with environment status | P0 |
| F3 | Mise tools: list, install, update, uninstall | P0 |
| F4 | Homebrew services: list, start, stop, restart | P1 |
| F5 | OrbStack containers: list, start, stop | P1 |
| F6 | Port detection: show active ports | P2 |
| F7 | Settings panel (launch at login, refresh interval) | P1 |
| F8 | Click-outside-to-dismiss popup | P0 |
| F9 | Notch overflow detection/fallback | P0 |
| F10 | Auto-refresh on interval (30s/60s/5m) | P1 |

### Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NF1 | Startup time | < 1s to icon visible |
| NF2 | Memory usage | < 50MB |
| NF3 | CPU idle usage | < 1% |
| NF4 | Bundle size | < 20MB |
| NF5 | macOS 14+ (Sonoma) | Required |
| NF6 | Universal binary (arm64 + x86_64) | Required |
| NF7 | No Xcode.app required to install | Required |
| NF8 | Automated tests (non-GUI) | > 80% logic coverage |

### Shared CLI Integration

All implementations call the SAME underlying tools:
```bash
mise ls --json              # List tools
mise use -g <tool>@latest   # Install/update tool
mise doctor                 # Health check
brew services list          # Homebrew services
brew services start <svc>   # Start service
orb list                    # OrbStack containers
lsof -iTCP -sTCP:LISTEN     # Port detection
```

### Project Layout Convention

Each implementation lives in its own directory:
```
DevEnvManager/              # Existing native Swift app
DevEnvManager-SwiftBar/     # Enhanced SwiftBar plugin
DevEnvManager-Iced/         # Rust + tray-icon + Iced
DevEnvManager-Tauri/        # Tauri 2 + React
```

---

## 2. Spec A: SwiftBar Plugin (Enhanced)

### Summary

Enhance the existing `dev-status.1m.sh` SwiftBar plugin with richer features and a companion Swift plugin for advanced capabilities.

### Current State

- **Existing plugin:** `config/scripts/dev-status.1m.sh` (386 lines, bash)
- **Existing tests:** `tests/test_swiftbar.bats` (261 lines, 43 tests)
- **Existing tasks:** 6 mise tasks (menubar:install/uninstall/status/refresh/open/edit)

### What to Build

#### A1. Enhanced Bash Plugin (`dev-status.5s.sh`)
- Switch to **5-second refresh** for near-real-time (or use StreamablePlugin)
- Add **Homebrew services** section with start/stop/restart actions
- Add **OrbStack containers** section
- Add **port detection** section
- Improve **status indicators** with SF Symbols (`sfimage=` parameter)

#### A2. Swift StreamablePlugin (`dev-status-stream.swift`)
- New **Swift-based plugin** using SwiftBar's StreamablePlugin protocol
- Real-time updates via `~~~` separator
- Uses Foundation for JSON parsing (mise --json output)
- No Xcode required (runs as `#!/usr/bin/swift` script)

### File Structure
```
DevEnvManager-SwiftBar/
├── dev-status.5s.sh              # Enhanced bash plugin
├── dev-status-stream.swift       # Swift streaming plugin
├── tests/
│   ├── test_core_functions.bats  # Core functions (126 tests)
│   ├── test_enhanced_plugin.bats # BATS tests for bash plugin
│   └── test_swift_plugin.bats    # BATS tests for swift plugin
└── README.md
```

### SwiftBar StreamablePlugin Pattern
```swift
#!/usr/bin/swift
// <swiftbar.type>streamable</swiftbar.type>
// <swiftbar.hideAbout>true</swiftbar.hideAbout>

import Foundation

func refreshMenu() {
    // Collect status
    let miseOutput = shell("mise ls --json")
    let brewOutput = shell("brew services list")
    
    // Print menu bar icon
    print("🟢 dev | sfimage=terminal.fill")
    print("---")
    print("Mise Tools | color=#3b82f6 size=14")
    // ... menu items
    
    // Signal update complete
    print("~~~")
}

// Initial render
refreshMenu()

// Periodic refresh
while true {
    Thread.sleep(forTimeInterval: 30)
    refreshMenu()
}
```

### Testing Strategy
```
Layer 1: BATS tests (existing pattern)
  - Plugin output format validation
  - Section presence checks
  - Action parameter validation
  - Metadata validation

Layer 2: Swift plugin unit tests
  - JSON parsing (mise output)
  - Status determination logic
  - Shell command mocking (via env vars)

Layer 3: Integration tests
  - Full plugin execution
  - Output format compliance
  - Performance (< 2s execution time)
```

### Build & Install
```bash
# No build needed - script-based
chmod +x DevEnvManager-SwiftBar/*.sh DevEnvManager-SwiftBar/*.swift
cp DevEnvManager-SwiftBar/* ~/Library/Application\ Support/SwiftBar/Plugins/
```

### Mise Tasks (New)
```toml
[tasks."menubar:enhanced:install"]
description = "Install enhanced SwiftBar plugins"
run = "cp DevEnvManager-SwiftBar/*.{sh,swift} $(defaults read com.ameba.SwiftBar PluginDirectory)/"

[tasks."menubar:enhanced:test"]
description = "Test enhanced SwiftBar plugins"
run = "bats DevEnvManager-SwiftBar/tests/"
```

### Notch Overflow Handling
- **SwiftBar manages placement** -- no programmatic control
- **Fallback:** If SwiftBar issue #442 (icon not showing), user uses `Cmd+drag` to reorder
- **Limitation:** Cannot detect overflow programmatically in plugin context

### Pros/Cons
| Pros | Cons |
|------|------|
| Zero build step | Text-only UI (no custom views) |
| Instant iteration | Process spawn per refresh |
| Existing 30 tests | No notch overflow detection |
| Any language (bash/swift/python) | Depends on SwiftBar app |
| StreamablePlugin for real-time | Limited interactivity |

### Estimated Effort: 1-2 days

---

## 3. Spec B: Native Swift (NSStatusItem Fix)

### Summary

Fix the existing DevEnvManager app by switching from `MenuBarExtra` to `NSStatusItem` for `isVisible` API access, adding notch overflow detection with Dock icon fallback.

### Current State

- **App:** `DevEnvManager/` (29 files, ~5000 LOC)
- **Architecture:** SwiftUI `MenuBarExtra` + `@Observable` stores + Actor clients
- **Problem:** Icon hidden behind notch (X=781, notch starts ~X=772)
- **Root Cause:** `MenuBarExtra` doesn't expose `NSStatusItem.isVisible`

### What to Build

#### B1. NSStatusItem Migration
Replace `MenuBarExtra` with direct `NSStatusItem` + `NSPopover` for visibility detection.

#### B2. Notch Overflow Detection
Monitor `isVisible` and fall back to Dock icon when hidden.

#### B3. NSPopover for Popup
Use `NSPopover` attached to status item for the main UI (matches macOS native feel).

### Key Code Changes

**AppDelegate.swift (replace current):**
```swift
import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellables = Set<AnyCancellable>()
    
    // Stores
    private var toolsStore = ToolsStore()
    private var servicesStore = ServicesStore()
    private var containersStore = ContainersStore()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "DevEnv Manager")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover with SwiftUI content
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .transient  // Click-outside-to-dismiss
        popover.contentViewController = NSHostingController(
            rootView: MenuBarRootView()
                .environment(toolsStore)
                .environment(servicesStore)
                .environment(containersStore)
        )
        
        // CRITICAL: Monitor visibility for notch overflow
        statusItem.publisher(for: \.isVisible)
            .removeDuplicates()
            .sink { [weak self] isVisible in
                self?.handleVisibilityChange(isVisible)
            }
            .store(in: &cancellables)
        
        // Start as accessory (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
    }
    
    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    private func handleVisibilityChange(_ isVisible: Bool) {
        if !isVisible {
            // Notch overflow detected -- show in Dock
            NSApp.setActivationPolicy(.regular)
            
            // Send notification
            let notification = NSUserNotification()
            notification.title = "DevEnvManager"
            notification.informativeText = "Menu bar icon hidden (too many items). Using Dock icon."
            NSUserNotificationCenter.default.deliver(notification)
        } else {
            // Visible again -- hide from Dock
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
```

**DevEnvManagerApp.swift (simplified):**
```swift
import SwiftUI

@main
struct DevEnvManagerApp: App {
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate
    
    var body: some Scene {
        Settings {
            AppSettingsView()
        }
    }
}
```

### File Changes

| File | Action | Description |
|------|--------|-------------|
| `App/AppDelegate.swift` | **Rewrite** | NSStatusItem + NSPopover + isVisible monitoring |
| `App/DevEnvManagerApp.swift` | **Simplify** | Remove MenuBarExtra, keep Settings scene |
| `Tests/VisibilityTests.swift` | **New** | Test visibility detection logic |
| `Tests/PopoverTests.swift` | **New** | Test popover show/hide behavior |

### Testing Strategy
```
Layer 1: Unit tests (XCTest)
  - ToolsStore state transitions
  - ServicesStore state transitions
  - ContainersStore state transitions
  - MiseClient JSON parsing
  - HomebrewClient output parsing

Layer 2: Integration tests
  - NSStatusItem creation
  - Popover lifecycle (show/hide)
  - Visibility change handler
  - Activation policy switching

Layer 3: Manual QA
  - Icon visible in menu bar
  - Popover positioning
  - Notch overflow fallback to Dock
  - Click-outside-to-dismiss
```

### Build & Install
```bash
# Requires Xcode.app for building
mise run devenv-app:build

# Or install prebuilt from GitHub Release
mise run devenv-app:install
```

### Notch Overflow Handling
- **NSStatusItem.isVisible** KVO observation
- **Fallback:** Switch to `.regular` activation policy (Dock icon)
- **Notification:** Alert user their icon is behind the notch
- **Recovery:** Auto-switch back to `.accessory` when visible again

### Pros/Cons
| Pros | Cons |
|------|------|
| Fixes actual problem (notch) | macOS only |
| Preserves existing 5000 LOC | Requires Xcode to build |
| Native macOS feel | No cross-platform |
| Fast (no process spawning) | MenuBarExtra -> NSStatusItem migration |
| isVisible API | NSPopover vs MenuBarExtra behavior differences |

### Estimated Effort: 2-3 days

---

## 4. Spec C: Rust + tray-icon + Iced

### Summary

Build a pure Rust menu bar app using `tray-icon` (Tauri ecosystem, 529k downloads/month) for the tray icon and `iced::daemon` for the GUI popup.

### Reference Architecture
- **tray-icon:** [tauri-apps/tray-icon](https://github.com/tauri-apps/tray-icon) (production, 351 stars)
- **Iced daemon:** [iced-rs/iced multi_window example](https://github.com/iced-rs/iced/tree/master/examples/multi_window)
- **Real-world:** [squidowl/halloy](https://github.com/squidowl/halloy) (3.7k stars, IRC client with iced::daemon)
- **Tray example:** [nobane/tray-rs iced-popup.rs](https://github.com/nobane/tray-rs/blob/main/crates/tray/examples/iced-popup.rs)

### Project Structure
```
DevEnvManager-Iced/
├── src/
│   ├── main.rs             # Entry point, tray setup, iced::daemon
│   ├── app.rs              # App state, update, view dispatching
│   ├── tray.rs             # Tray icon creation + event handling
│   ├── views/
│   │   ├── popup.rs        # Main popup view (tools, services, containers)
│   │   ├── settings.rs     # Settings window
│   │   └── components/
│   │       ├── tool_row.rs
│   │       ├── service_row.rs
│   │       └── container_row.rs
│   ├── domain/
│   │   ├── mise.rs         # Mise CLI integration (async)
│   │   ├── homebrew.rs     # Homebrew services integration
│   │   ├── orbstack.rs     # OrbStack integration
│   │   └── ports.rs        # Port detection (lsof)
│   ├── models/
│   │   ├── tool.rs         # Tool model
│   │   ├── service.rs      # Homebrew service model
│   │   └── container.rs    # Container model
│   └── config.rs           # App configuration (serde)
├── icons/
│   ├── icon.png            # 22x22 menu bar icon
│   └── icon@2x.png         # 44x44 retina
├── Cargo.toml
├── build.rs                # Embed icon resources
├── Packager.toml           # cargo-packager config
├── tests/
│   ├── mise_tests.rs       # Mise integration tests
│   ├── homebrew_tests.rs   # Homebrew integration tests
│   └── model_tests.rs      # Model unit tests
└── README.md
```

### Cargo.toml
```toml
[package]
name = "devenv-manager-iced"
version = "0.1.0"
edition = "2021"

[dependencies]
# GUI
iced = { version = "0.14", features = ["multi-window", "tokio", "image"] }

# Tray
tray-icon = "0.21"
muda = "0.16"              # Native menus

# Image
image = { version = "0.25", default-features = false, features = ["png"] }

# Async
tokio = { version = "1", features = ["full"] }

# System
sysinfo = "0.32"

# Serialization
serde = { version = "1", features = ["derive"] }
serde_json = "1"
toml = "0.8"

# CLI execution
tokio-process = "0.2"

[dev-dependencies]
insta = "1"                # Snapshot testing

[profile.release]
opt-level = "z"            # Optimize for size
lto = true
strip = true
```

### Core Architecture

**main.rs:**
```rust
use iced::daemon;
use tray_icon::{TrayIconBuilder, TrayIconEvent, Icon};
use muda::{Menu, MenuItem, PredefinedMenuItem};

mod app;
mod tray;
mod views;
mod domain;
mod models;
mod config;

fn main() -> iced::Result {
    // Create tray icon on main thread (required for macOS)
    let _tray = tray::create_tray_icon();
    
    // Run iced daemon (no default window)
    daemon(
        |state: &app::App, window_id| state.title(window_id),
        app::App::update,
        app::App::view,
    )
    .subscription(app::App::subscription)
    .theme(app::App::theme)
    .run_with(app::App::new)
}
```

**app.rs (skeleton):**
```rust
use std::collections::BTreeMap;
use iced::{window, Task, Element, Subscription, Size, Point};
use tray_icon::TrayIconEvent;
use std::time::Duration;

pub struct App {
    windows: BTreeMap<window::Id, WindowKind>,
    mise_tools: Vec<models::Tool>,
    brew_services: Vec<models::Service>,
    containers: Vec<models::Container>,
    config: config::AppConfig,
}

enum WindowKind {
    Popup,
    Settings,
}

#[derive(Debug, Clone)]
pub enum Message {
    // Tray
    PollTray,
    // Window
    WindowOpened(window::Id),
    WindowClosed(window::Id),
    // Data
    ToolsLoaded(Vec<models::Tool>),
    ServicesLoaded(Vec<models::Service>),
    ContainersLoaded(Vec<models::Container>),
    // Actions
    InstallTool(String),
    UpdateTool(String),
    StartService(String),
    StopService(String),
    // Settings
    OpenSettings,
    RefreshAll,
    Tick,
}

impl App {
    pub fn new() -> (Self, Task<Message>) {
        let app = Self {
            windows: BTreeMap::new(),
            mise_tools: vec![],
            brew_services: vec![],
            containers: vec![],
            config: config::AppConfig::load(),
        };
        (app, Task::perform(domain::mise::list_tools(), Message::ToolsLoaded))
    }
    
    pub fn update(&mut self, message: Message) -> Task<Message> {
        match message {
            Message::PollTray => {
                while let Ok(event) = TrayIconEvent::receiver().try_recv() {
                    if let TrayIconEvent::Click { position, .. } = event {
                        if self.windows.values().any(|w| matches!(w, WindowKind::Popup)) {
                            // Close existing popup
                            // ...
                        } else {
                            // Open popup at cursor
                            let (id, open) = window::open(window::Settings {
                                size: Size::new(400.0, 500.0),
                                position: window::Position::Specific(Point::new(
                                    position.x as f32 - 200.0,
                                    position.y as f32 + 5.0,
                                )),
                                decorations: false,
                                resizable: false,
                                level: window::Level::AlwaysOnTop,
                                ..Default::default()
                            });
                            self.windows.insert(id, WindowKind::Popup);
                            return open.map(Message::WindowOpened);
                        }
                    }
                }
                Task::none()
            }
            // ... other message handlers
            _ => Task::none()
        }
    }
    
    pub fn subscription(&self) -> Subscription<Message> {
        Subscription::batch([
            iced::time::every(Duration::from_millis(50)).map(|_| Message::PollTray),
            iced::time::every(Duration::from_secs(
                self.config.refresh_interval_secs
            )).map(|_| Message::Tick),
        ])
    }
}
```

### Build & Install
```bash
# Development
cargo run

# Release build
cargo build --release

# Package as .app bundle
cargo install cargo-packager --locked
cargo packager --release

# Install
cp -R target/release/bundle/macos/DevEnvManager-Iced.app ~/Applications/
```

### Testing Strategy
```
Layer 1: Unit tests (cargo test)
  - models/ - Tool, Service, Container serialization
  - domain/mise.rs - JSON parsing, command building
  - domain/homebrew.rs - Output parsing
  - config.rs - Config load/save
  
Layer 2: Integration tests
  - domain/mise.rs - Execute real mise commands (skip in CI)
  - domain/homebrew.rs - Execute real brew commands
  
Layer 3: Snapshot tests (insta)
  - View rendering snapshots
  - Model serialization snapshots

Layer 4: Manual QA
  - Tray icon appearance
  - Popup positioning
  - Window show/hide
  - Cross-platform (if applicable)
```

### Notch Overflow Handling
- **tray-icon does NOT expose NSStatusItem.isVisible**
- **Workaround:** Use `objc2` crate to access NSStatusItem directly via Objective-C runtime
- **Alternative:** Accept limitation, document workaround (use Ice/Bartender)

### Pros/Cons
| Pros | Cons |
|------|------|
| Pure Rust (type-safe, memory-safe) | Steep learning curve |
| Native rendering (wgpu) | No hot reload |
| Small binary (~5MB) | Iced UI doesn't match macOS native style |
| Cross-platform potential | tray-icon doesn't expose isVisible |
| cargo test for logic | No automated GUI tests |
| cargo-packager distribution | Newer ecosystem |

### Estimated Effort: 2-3 weeks

---

## 5. Spec D: Tauri 2 (Rust + Web)

### Summary

Build a Tauri 2 menu bar app with Rust backend and React frontend. Reference architecture: [ahkohd/tauri-macos-menubar-app-example](https://github.com/ahkohd/tauri-macos-menubar-app-example/tree/v2-popover) (Tauri 2.5.1).

### Reference Architecture
- **Template:** ahkohd/tauri-macos-menubar-app-example (v2-popover branch)
- **System monitor:** JackpotMachine777/tauri-system-monitor
- **Production apps:** Pake (30k stars), Clash Verge Rev (40k stars), midday
- **Testing:** tauri-apps/smoke-tests patterns
- **Plugins:** tauri-apps/plugins-workspace (positioner, shell, notification, store)

### Project Structure
```
DevEnvManager-Tauri/
├── src/                          # React frontend
│   ├── App.tsx                   # Main component
│   ├── main.tsx                  # Entry point
│   ├── components/
│   │   ├── MenuBarPopup.tsx      # Main popup layout
│   │   ├── ToolsList.tsx         # Mise tools section
│   │   ├── ServicesList.tsx      # Homebrew services section
│   │   ├── ContainersList.tsx    # OrbStack containers section
│   │   ├── PortsList.tsx         # Active ports section
│   │   ├── StatusBadge.tsx       # Status indicator component
│   │   └── ActionButton.tsx      # Action button component
│   ├── hooks/
│   │   ├── useMiseTools.ts       # Hook for Mise data
│   │   ├── useBrewServices.ts    # Hook for Homebrew data
│   │   ├── useContainers.ts      # Hook for OrbStack data
│   │   └── usePorts.ts           # Hook for port detection
│   ├── lib/
│   │   └── tauri.ts              # Tauri invoke wrappers
│   └── styles/
│       ├── global.css            # Global styles
│       └── menubar.css           # Menubar-specific (arrow, popup)
├── src-tauri/
│   ├── src/
│   │   ├── lib.rs               # Main setup, tray creation
│   │   ├── tray.rs              # Tray icon + event handling
│   │   ├── commands/
│   │   │   ├── mise.rs          # Mise CLI commands
│   │   │   ├── homebrew.rs      # Homebrew commands
│   │   │   ├── orbstack.rs      # OrbStack commands
│   │   │   └── ports.rs         # Port detection
│   │   └── models.rs            # Shared models
│   ├── Cargo.toml
│   ├── tauri.conf.json
│   ├── icons/
│   │   ├── icon.png             # Menu bar icon
│   │   └── icon.icns            # macOS app icon
│   └── capabilities/
│       └── default.json         # Permission capabilities
├── package.json
├── vite.config.ts
├── tsconfig.json
├── tests/
│   ├── rust/
│   │   ├── mise_test.rs         # Rust unit tests
│   │   └── commands_test.rs     # Command tests
│   └── e2e/
│       ├── wdio.conf.js         # WebDriverIO config
│       └── specs/
│           └── popup.spec.js    # E2E tests (Linux/Windows)
└── README.md
```

### Cargo.toml (src-tauri/)
```toml
[package]
name = "devenv-manager-tauri"
version = "0.1.0"
edition = "2021"

[lib]
name = "devenv_manager_tauri_lib"
crate-type = ["staticlib", "cdylib", "rlib"]

[dependencies]
tauri = { version = "2", features = ["tray-icon", "macos-private-api", "image-png"] }
tauri-plugin-positioner = { version = "2", features = ["tray-icon"] }
tauri-plugin-shell = "2"
tauri-plugin-notification = "2"
tauri-plugin-store = "2"
tauri-plugin-single-instance = "2"
tauri-plugin-autostart = "2"

serde = { version = "1", features = ["derive"] }
serde_json = "1"
tokio = { version = "1", features = ["full"] }

[build-dependencies]
tauri-build = { version = "2", features = [] }
```

### tauri.conf.json
```json
{
  "productName": "DevEnvManager",
  "version": "0.1.0",
  "identifier": "com.devenvmanager.tauri",
  "build": {
    "beforeDevCommand": "bun run dev",
    "beforeBuildCommand": "bun run build",
    "devUrl": "http://localhost:5173",
    "frontendDist": "../dist"
  },
  "bundle": {
    "active": true,
    "targets": ["dmg", "app"],
    "icon": ["icons/icon.icns", "icons/icon.png"],
    "macOS": {
      "minimumSystemVersion": "14.0"
    }
  },
  "app": {
    "windows": [{
      "title": "DevEnvManager",
      "width": 400,
      "height": 500,
      "visible": false,
      "decorations": false,
      "transparent": true,
      "skipTaskbar": true,
      "alwaysOnTop": true,
      "resizable": false
    }],
    "macOSPrivateApi": true,
    "security": {
      "csp": "default-src 'self'; style-src 'self' 'unsafe-inline'"
    }
  }
}
```

### Tray Setup (src-tauri/src/tray.rs)
```rust
use tauri::{
    image::Image,
    menu::{MenuBuilder, MenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, Manager,
};
use tauri_plugin_positioner::{Position, WindowExt};

pub fn create(app: &AppHandle) -> tauri::Result<()> {
    let icon = Image::from_bytes(include_bytes!("../icons/icon.png"))?;
    let quit = MenuItem::with_id(app, "quit", "Quit DevEnvManager", true, None::<&str>)?;
    let settings = MenuItem::with_id(app, "settings", "Settings...", true, None::<&str>)?;
    let menu = MenuBuilder::new(app)
        .item(&settings)
        .separator()
        .item(&quit)
        .build()?;

    TrayIconBuilder::with_id("main")
        .icon(icon)
        .icon_as_template(true)
        .tooltip("DevEnvManager")
        .menu(&menu)
        .show_menu_on_left_click(false)
        .on_menu_event(|app, event| match event.id().as_ref() {
            "quit" => app.exit(0),
            "settings" => {
                // Emit to frontend
                app.emit("open-settings", ()).ok();
            }
            _ => {}
        })
        .on_tray_icon_event(|tray, event| {
            let app = tray.app_handle();
            tauri_plugin_positioner::on_tray_event(app, &event);
            
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            } = event {
                if let Some(window) = app.get_webview_window("main") {
                    let _ = window.as_ref().window().move_window(Position::TrayCenter);
                    if window.is_visible().unwrap_or(false) {
                        let _ = window.hide();
                    } else {
                        let _ = window.show();
                        let _ = window.set_focus();
                    }
                }
            }
        })
        .build(app)?;

    Ok(())
}
```

### Tauri Commands (src-tauri/src/commands/mise.rs)
```rust
use serde::{Deserialize, Serialize};
use std::process::Command;

#[derive(Debug, Serialize, Deserialize)]
pub struct MiseTool {
    pub name: String,
    pub version: String,
    pub requested_version: String,
    pub source: String,
    pub installed: bool,
}

#[tauri::command]
pub async fn list_mise_tools() -> Result<Vec<MiseTool>, String> {
    let output = Command::new("mise")
        .args(["ls", "--json"])
        .output()
        .map_err(|e| format!("Failed to run mise: {}", e))?;
    
    let stdout = String::from_utf8_lossy(&output.stdout);
    serde_json::from_str(&stdout)
        .map_err(|e| format!("Failed to parse mise output: {}", e))
}

#[tauri::command]
pub async fn install_tool(name: String) -> Result<String, String> {
    let output = Command::new("mise")
        .args(["use", "-g", &format!("{}@latest", name)])
        .output()
        .map_err(|e| format!("Failed to install: {}", e))?;
    
    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}
```

### React Frontend (src/components/MenuBarPopup.tsx)
```tsx
import { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { ToolsList } from './ToolsList';
import { ServicesList } from './ServicesList';
import { ContainersList } from './ContainersList';
import './menubar.css';

export function MenuBarPopup() {
  const [tools, setTools] = useState([]);
  const [services, setServices] = useState([]);
  const [activeTab, setActiveTab] = useState('tools');

  useEffect(() => {
    invoke('list_mise_tools').then(setTools);
    invoke('list_brew_services').then(setServices);
  }, []);

  return (
    <div className="menubar-popup">
      <div className="arrow" />
      <div className="tabs">
        <button onClick={() => setActiveTab('tools')}>Tools</button>
        <button onClick={() => setActiveTab('services')}>Services</button>
        <button onClick={() => setActiveTab('containers')}>Containers</button>
      </div>
      <div className="content">
        {activeTab === 'tools' && <ToolsList tools={tools} />}
        {activeTab === 'services' && <ServicesList services={services} />}
        {activeTab === 'containers' && <ContainersList />}
      </div>
    </div>
  );
}
```

### Build & Install
```bash
# Development
bun install
bun tauri dev

# Production build (creates .app + .dmg)
bun tauri build

# Install
cp -R src-tauri/target/release/bundle/macos/DevEnvManager.app ~/Applications/
```

### Testing Strategy
```
Layer 1: Rust unit tests (cargo test)
  - commands/mise.rs - JSON parsing, command building
  - commands/homebrew.rs - Output parsing
  - models.rs - Serialization

Layer 2: Frontend tests (vitest)
  - Component rendering
  - Hook behavior
  - State management

Layer 3: WebDriver E2E (Linux/Windows only)
  - Popup show/hide
  - Tab navigation
  - Action execution
  Note: macOS NOT supported (no WKWebView driver)

Layer 4: Manual QA (macOS)
  - Tray icon appearance
  - Popup positioning
  - Click-outside-to-dismiss
  - Tool actions
```

### Notch Overflow Handling
- **Tauri tray-icon wraps NSStatusItem** but does NOT expose `isVisible`
- **Workaround:** Same as Iced -- use `objc2` FFI or accept limitation
- **tauri-plugin-positioner** handles window positioning relative to tray

### Pros/Cons
| Pros | Cons |
|------|------|
| Rust backend (safe, fast) | WebView overhead (~10MB) |
| Web frontend (fast iteration, React/Svelte) | macOS WebDriver NOT supported |
| Cross-platform (Win/Mac/Linux) | Not fully native look |
| Rich plugin ecosystem (30 plugins) | Two toolchains (Rust + JS) |
| Production-proven (Pake 30k, Clash 40k stars) | Slightly larger bundle (8-15MB) |
| Hot reload for frontend | Tray testing still manual |
| No Xcode required | Notch overflow not detectable |

### Estimated Effort: 2-3 weeks

---

## 6. Additional Contenders

Research identified these as worth considering. Including for completeness but NOT building in this round.

### Tier 1: Strong Alternatives

| Framework | Lang | Tray Maturity | Bundle | Stars | Verdict |
|-----------|------|---------------|--------|-------|---------|
| **Wails v3** | Go+Web | Excellent | 10-20MB | 21.4k | Best Go option, v3 still alpha |
| **Fyne** | Go | Good (v2.2+) | 15-25MB | Active | Pure Go, mobile support |
| **egui + tray-icon** | Rust | Good (manual) | 2-5MB | 27.9k | Immediate mode, smallest binary |

### Tier 2: Niche but Viable

| Framework | Lang | Tray Maturity | Notes |
|-----------|------|---------------|-------|
| **wxWidgets** | C++ | Good (20+ yrs) | Battle-tested but legacy feel |
| **FLTK-rs** | Rust | Good | Lightweight, SysMenuBar on macOS |
| **Slint** | Rust/C++ | No tray yet | Declarative UI, needs tray-icon |
| **Objective-C/AppKit** | ObjC | Perfect | macOS only, zero overhead |

### Tier 3: Not Recommended

| Framework | Why Not |
|-----------|---------|
| **Druid** | Archived (2021), dead |
| **gtk-rs/GTK4** | No tray support in GTK4 |
| **Zig + tray** | Ecosystem too young (12 stars) |
| **Neutralino.js** | Less mature than Tauri |

### Proposed for Future Round

If we want a 5th or 6th implementation:
1. **egui + tray-icon** (smallest possible Rust binary, ~2MB)
2. **Wails v3** (when v3 stabilizes, best Go option)

---

## 7. Comparison Criteria

### Evaluation Matrix

Each implementation will be scored 1-10 on:

| Criteria | Weight | Description |
|----------|--------|-------------|
| **Build complexity** | 15% | How easy to build from source |
| **Bundle size** | 10% | Final .app size |
| **Startup time** | 10% | Time to icon visible |
| **Memory usage** | 10% | Idle memory footprint |
| **CPU usage** | 5% | Idle CPU consumption |
| **Native feel** | 15% | How macOS-native it looks/feels |
| **Test coverage** | 15% | Automated test quality and coverage |
| **Notch handling** | 10% | Can it detect/handle overflow |
| **Cross-platform** | 5% | Win/Linux potential |
| **Iteration speed** | 5% | How fast to add features |

### Benchmark Suite

```bash
# Build time
time cargo build --release  # or xcodebuild

# Bundle size
du -sh target/release/bundle/macos/*.app

# Startup time (measure with hyperfine)
hyperfine --warmup 3 'open -a DevEnvManager-Iced'

# Memory usage (after 60s idle)
ps aux | grep DevEnvManager | awk '{print $6}'

# CPU usage (5-minute average)
top -pid $(pgrep DevEnvManager) -l 1 | tail -1
```

---

## 8. Parallel Agent Plan

### Agent Assignments

Each implementation gets its own agent team:

#### Team A: SwiftBar Plugin (1 agent, `quick` category)
```
TASK: Enhance existing SwiftBar plugin
SKILLS: ["git-master"]
EFFORT: 1-2 days
DELIVERABLES:
  1. Enhanced dev-status.5s.sh with Homebrew/OrbStack sections
  2. Swift StreamablePlugin dev-status-stream.swift
  3. BATS tests for both plugins
  4. Updated mise tasks
```

#### Team B: Native Swift Fix (1 agent, `quick` category)
```
TASK: Migrate MenuBarExtra to NSStatusItem + NSPopover
SKILLS: ["git-master"]
EFFORT: 2-3 days
DELIVERABLES:
  1. Rewritten AppDelegate.swift with NSStatusItem
  2. isVisible KVO observation + Dock fallback
  3. NSPopover for popup UI
  4. Unit tests for visibility logic
```

#### Team C: Rust + Iced (1 agent, `deep` category)
```
TASK: Build new Rust menu bar app
SKILLS: ["git-master"]
EFFORT: 2-3 weeks
DELIVERABLES:
  1. Full project scaffold (Cargo.toml, src/)
  2. tray-icon integration with iced::daemon
  3. Domain layer (Mise, Homebrew, OrbStack CLIs)
  4. Popup view with tool/service/container lists
  5. Settings window
  6. cargo test suite
  7. cargo-packager config
  8. README with build instructions
```

#### Team D: Tauri 2 (1 agent, `deep` category)
```
TASK: Build new Tauri 2 menu bar app
SKILLS: ["git-master"]
EFFORT: 2-3 weeks
DELIVERABLES:
  1. Full project scaffold (Cargo.toml, package.json, tauri.conf.json)
  2. Tray icon with left-click popup
  3. Tauri commands for Mise, Homebrew, OrbStack
  4. React frontend with popup UI
  5. Click-outside-to-dismiss
  6. Rust unit tests
  7. Frontend tests (vitest)
  8. README with build instructions
```

#### Team E: QA & Comparison (1 agent, `unspecified-high` category)
```
TASK: Build automated benchmarks and comparison report
SKILLS: ["git-master"]
EFFORT: After builds complete
DELIVERABLES:
  1. Benchmark scripts (build time, size, memory, CPU)
  2. Comparison matrix with scores
  3. Screenshot comparison
  4. Recommendation report
```

### Execution Order

```
Phase 1 (Parallel): Teams A + B start immediately
  - SwiftBar: 1-2 days
  - Native Swift: 2-3 days

Phase 2 (Parallel): Teams C + D start immediately  
  - Iced: 2-3 weeks
  - Tauri: 2-3 weeks

Phase 3 (Sequential): Team E after Phase 1 + 2
  - QA & Comparison: 2-3 days

Total: ~3 weeks wall clock (parallel execution)
```

### Code Review Checklist

Each implementation must pass:
- [ ] Builds from source without errors
- [ ] All tests pass
- [ ] Icon appears in menu bar
- [ ] Popup shows and dismisses correctly
- [ ] Mise tools listed correctly
- [ ] At least one action works (install/update/start/stop)
- [ ] Memory < 50MB idle
- [ ] Bundle < 20MB
- [ ] README has build instructions
- [ ] No `as any`, `@ts-ignore`, empty catch blocks, unsafe unwrap

---

## Appendix: Key Research Sources

| Source | URL | Findings |
|--------|-----|----------|
| SwiftBar repo | https://github.com/swiftbar/SwiftBar | StreamablePlugin, 3.7k stars |
| xbar plugins | https://github.com/matryer/xbar-plugins | 400+ plugins, Docker examples |
| tray-icon | https://github.com/tauri-apps/tray-icon | 529k downloads/month |
| tray-rs | https://github.com/nobane/tray-rs | Iced example, v0.1.2 |
| ahkohd menubar | https://github.com/ahkohd/tauri-macos-menubar-app-example | Tauri 2 reference |
| Halloy | https://github.com/squidowl/halloy | Iced daemon reference |
| Tauri plugins | https://github.com/tauri-apps/plugins-workspace | 30 plugins |
| Tauri smoke-tests | https://github.com/tauri-apps/smoke-tests | Framework examples |
| Ice | https://github.com/jordanbaird/Ice | NSStatusItem.isVisible pattern |
| tauri-menubar-app | https://github.com/4gray/tauri-menubar-app | Tauri 1 template (outdated) |
| Pake | https://github.com/tw93/Pake | Production Tauri 2 tray |
| Clash Verge Rev | https://github.com/clash-verge-rev/clash-verge-rev | Dynamic tray updates |
