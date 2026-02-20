# DevEnvManager: Notch Overflow, Tray Testing & Rewrite Research

> **Date:** February 2026
> **Status:** Research complete, decision pending
> **Context:** Menu bar icon visibility issues (do NOT assume notch overflow without verification)

---

## Table of Contents

1. [The Notch Overflow Problem](#1-the-notch-overflow-problem)
2. [Automated GUI Testing for System Tray Apps](#2-automated-gui-testing-for-system-tray-apps)
3. [Framework Comparison: Rewrite Options](#3-framework-comparison-rewrite-options)
4. [Recommendations](#4-recommendations)

---

## 1. The Notch Overflow Problem

### What Happened

DevEnvManager's menu bar icon is registered and running but **invisible** -- hidden behind the MacBook Pro notch. Confirmed via macOS Accessibility APIs:

> **Note:** Always verify process status and actual visibility (Mission Control, menu bar managers, Space focus) before attributing invisibility to notch overflow.

- Status item named `"terminal"` exists at position **X=781**
- Notch spans approximately **X=772-956** on 1728pt-wide display (3456x2234 native)
- **15+ status items** compete for space (LastPass, 1Password, Zoom, Creative Cloud, Chrome, Cursor, Claude, Google Drive, Docker, OrbStack, rekordbox, plus system items)

### Why This Happens

**macOS has NO native overflow mechanism for menu bar items.** When icons exceed available space:

| Behavior | macOS | Windows |
|----------|-------|---------|
| Overflow indicator | None | Chevron (^) icon |
| Overflow menu | None | Click chevron to see hidden icons |
| User control | Must manually drag items | Drag items in/out of overflow |
| Visual feedback | Icons silently disappear | Clear indication of hidden items |

On notched MacBook Pros (14" and 16"), the notch consumes **~30-40%** of the right side of the menu bar compared to pre-2021 models.

### Apple's Position

- **Apple Feedback FB7087526** (filed August 2019, before the notch existed) requested an API to detect when NSStatusItems are force-hidden. **No response after 6+ years.**
- Apple Community Support: *"it's expected for the excess menu bar items to be hidden"*
- Apple HIG: *"Avoid relying on the presence of menu bar extras. Users, and not apps, place menu bar extras in the menu bar."*
- **Irony:** Apple's own apps (FaceTime, Control Center) force their icons to always be visible, pushing user-installed items behind the notch.

### NSStatusItem.isVisible API

Available since macOS 10.12. Returns `false` when the icon is hidden, but **cannot distinguish** between:
1. User explicitly set it to `false`
2. System hid it due to overflow/notch

```swift
// Detection pattern (used by Ice, iGlance)
statusItem.publisher(for: \.isVisible)
    .sink { isVisible in
        if !isVisible {
            // Hidden - but why? Unknown.
        }
    }
```

### Existing Workarounds

| Tool | Approach | License | Status |
|------|----------|---------|--------|
| **Ice** (25.5k stars) | Secondary "Ice Bar" below menu bar | GPL-3.0 | Active, free |
| **Bartender 5** | Secondary bar + triggers/rules | Proprietary ($18) | Active, ownership changed 2024 |
| **Hidden Bar** | Manual separator icon | MIT | Active, free, minimal |
| **Dozer** (8.6k stars) | Two separator dots | MPL-2.0 | Stalled since 2021 |

**All tools** use the same limited `NSStatusItem.isVisible` API. None can prevent system overflow.

### Impact on DevEnvManager

Our current code uses `MenuBarExtra` (SwiftUI) which does NOT expose `isVisible`:

```swift
// DevEnvManagerApp.swift - current implementation
MenuBarExtra {
    MenuBarRootView()
} label: {
    Label("DevEnv Manager", systemImage: menuBarIcon)
}
```

`MenuBarExtra` wraps `NSStatusItem` internally but does **not** expose visibility state. To detect overflow, we'd need to switch to `NSStatusItem` directly via `AppDelegate`.

---

## 2. Automated GUI Testing for System Tray Apps

### The Hard Truth

**No framework can reliably automate system tray icon interactions in CI.** This is an unsolved industry-wide problem.

### What We Tested

| Framework | Can Test Tray? | Platform | Notes |
|-----------|---------------|----------|-------|
| **XCUITest** | No | macOS | Cannot access NSStatusBar/MenuBarExtra |
| **Tauri WebDriver** | No | Win/Linux only | macOS has no WKWebView driver; WebDriver can't touch native tray |
| **Playwright** | No | Web only | Cannot interact with native OS elements |
| **Selenium** | No | Web only | Same limitation |
| **Appium** | No (tray) | Mobile | Can test mobile apps but not desktop tray |
| **pywinauto** | No (macOS) | Windows only | Windows-only library |
| **pytest-qt** | No (tray) | Cross-platform | Can test Qt windows, NOT QSystemTrayIcon |
| **Avalonia Headless** | Partial | Cross-platform | Can test most UI headlessly, NOT tray icon |
| **atomacos** | Partial | macOS only | Uses Accessibility APIs, fragile, complex setup |

### What Production Apps Actually Do

Every major tray app uses **manual QA** for tray interactions:

| App | Stars | Tray Testing Approach |
|-----|-------|----------------------|
| **Ice** | 25.5k | Manual QA |
| **Sniffnet** | 32k | Manual QA |
| **RustDesk** | 80k | Manual QA |
| **VS Code** | 170k | Manual QA for tray |
| **Slack** | - | Manual QA for tray |
| **Discord** | - | Manual QA for tray |

### What CAN Be Tested Automatically

| Layer | Testable? | How |
|-------|-----------|-----|
| **Business logic** (Mise/Homebrew/OrbStack clients) | Yes | Unit tests, mock protocols |
| **State management** (stores, models) | Yes | Unit tests |
| **UI layout** (views, components) | Partially | SwiftUI previews, XCUITest for windows |
| **Tray menu content** | Yes | Unit test menu model, not rendering |
| **Tray icon click/visibility** | **No** | Manual QA only |
| **Tray icon appearance** | **No** | Manual QA only |

### Best Practice (2026)

```
1. Unit test ALL business logic (actors, clients, models)
2. Unit test state management (stores) with mock protocols
3. Integration test CLI interactions (Mise, Homebrew, OrbStack)
4. Snapshot/preview test UI components (SwiftUI Previews)
5. Manual QA for tray icon behavior on each platform
6. Consider Accessibility API smoke tests (macOS only, fragile)
```

---

## 3. Framework Comparison: Rewrite Options

### Option A: Keep Swift, Fix Visibility (Recommended)

**Effort:** 1-2 days | **Risk:** Low | **Cross-platform:** No

Fix the actual problem without rewriting:

1. Switch from `MenuBarExtra` to `NSStatusItem` for `isVisible` access
2. Monitor `isVisible` -- if hidden, fall back to Dock icon
3. Pattern from iGlance (GPL-3.0):

```swift
// AppDelegate.swift
func setupStatusItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    // Monitor visibility
    statusItem.publisher(for: \.isVisible)
        .sink { [weak self] isVisible in
            if !isVisible {
                // Fallback: show in Dock
                NSApp.setActivationPolicy(.regular)
                self?.showNotification("Menu bar icon hidden. Using Dock icon instead.")
            } else {
                NSApp.setActivationPolicy(.accessory)
            }
        }
        .store(in: &cancellables)
}
```

**Pros:**
- Fixes the user's actual problem (invisible icon)
- No rewrite, minimal risk
- Keeps native macOS feel
- Existing 5000 LOC preserved

**Cons:**
- macOS only
- No automated tray testing (but no framework solves this)
- Requires dropping `MenuBarExtra` for `NSStatusItem`

### Option B: Tauri 2 Rewrite

**Effort:** 6-8 weeks | **Risk:** Medium | **Cross-platform:** Yes (Win/Mac/Linux)

| Aspect | Details |
|--------|---------|
| **Release status** | Stable v2.9.5 (since Oct 2024) |
| **Tray support** | Production-ready via `tray-icon` feature |
| **Bundle size** | 3-8 MB |
| **Frontend** | React, Svelte, Vue, Solid, etc. |
| **Backend** | Rust |
| **Build tooling** | No Xcode required |
| **WebDriver testing** | Windows + Linux only (NOT macOS -- no WKWebView driver) |
| **Tray testing** | Manual QA on all platforms |

**Production examples:** RustDesk (80k stars), Kftray (1.3k stars), Firezone, Codewhisperer

**Architecture:**
```
Tauri 2 App
├── src-tauri/          # Rust backend
│   ├── src/
│   │   ├── lib.rs      # Commands, tray setup
│   │   └── tray.rs     # Tray icon + menu
│   ├── Cargo.toml
│   └── tauri.conf.json
├── src/                # Web frontend (React/Svelte)
│   ├── App.tsx
│   └── components/
├── package.json
└── vite.config.ts
```

**Tray code pattern:**
```rust
use tauri::{
    tray::{TrayIconBuilder, MouseButton, MouseButtonState, TrayIconEvent},
    Manager,
};

fn setup_tray(app: &tauri::App) -> Result<(), Box<dyn std::error::Error>> {
    let tray = TrayIconBuilder::new()
        .icon(app.default_window_icon().unwrap().clone())
        .tooltip("DevEnv Manager")
        .menu(&menu)
        .on_tray_icon_event(|tray, event| {
            match event {
                TrayIconEvent::Click { button: MouseButton::Left, .. } => {
                    let app = tray.app_handle();
                    if let Some(window) = app.get_webview_window("main") {
                        window.show().unwrap();
                        window.set_focus().unwrap();
                    }
                }
                _ => {}
            }
        })
        .build(app)?;
    Ok(())
}
```

**Testing approach:**
```
1. Rust unit tests for tray logic (#[cfg(test)])
2. Mock runtime integration tests (no native UI)
3. WebDriver for frontend UI (Windows/Linux only)
4. Manual QA for tray behavior (all platforms)
```

**Pros:**
- Cross-platform (Win/Mac/Linux)
- No Xcode required
- Rust backend (type-safe, fast)
- Web frontend (React/Svelte -- fast iteration)
- Small bundles (3-8 MB)
- Active ecosystem (production-proven)

**Cons:**
- 6-8 week rewrite
- macOS WebDriver not supported
- Tray testing still manual
- Web frontend in native menu bar feels slightly foreign
- Must maintain Rust + JS toolchains

### Option C: Rust + tray-icon + Iced

**Effort:** 10-15 weeks | **Risk:** High | **Cross-platform:** Yes

**Critical finding (updated Feb 2026):** Iced does NOT have native tray support, but **tray-rs** library provides production-ready integration.

| Aspect | Details |
|--------|---------|
| **Iced tray status** | Issue #124 open since Dec 2019, "end game" phase (May 2025) |
| **tray-rs** | Production-ready, official Iced example, v0.1.2 (Dec 2025) |
| **tray-icon crate** | Maintained by Tauri team, 529k downloads/month, v0.21.3 |
| **Cross-platform** | Linux (X11), Windows, macOS |

**Working pattern with tray-rs:**
```rust
use tray::{TrayIconBuilder, TrayIconEvent, MouseButton};
use iced::daemon;

pub fn main() -> iced::Result {
    // Create tray icon
    let _tray = TrayIconBuilder::new()
        .with_tooltip("DevEnv Manager")
        .build()
        .unwrap();

    // Run as daemon (no default window)
    iced::daemon(
        |state: &App, window_id| state.title(window_id),
        App::update,
        App::view,
    )
    .subscription(App::subscription)
    .run_with(App::new)
}

impl App {
    fn subscription(&self) -> Subscription<Message> {
        iced::time::every(Duration::from_millis(50))
            .map(|_| Message::PollTray)
    }

    fn update(&mut self, message: Message) -> Task<Message> {
        match message {
            Message::PollTray => {
                while let Ok(event) = TrayIconEvent::receiver().try_recv() {
                    if let TrayIconEvent::Click { button: MouseButton::Left, position, .. } = event {
                        // Open popup window at click position
                        let (id, open) = window::open(window::Settings {
                            size: Size::new(350.0, 500.0),
                            position: window::Position::Specific(Point::new(
                                position.x as f32, position.y as f32,
                            )),
                            decorations: false,
                            level: window::Level::AlwaysOnTop,
                            ..Default::default()
                        });
                        return open.map(Message::WindowOpened);
                    }
                }
                Task::none()
            }
        }
    }
}
```

**Real-world examples using tray-icon + Iced:**
- **fan-control** (wiiznokes) -- Iced app with tray via tray-icon
- **tray-rs examples** -- Official iced-popup example

**Pros:**
- Pure Rust (no JS, no web layer)
- Native rendering (not WebView)
- Type-safe, memory-safe
- Cross-platform
- tray-rs provides clean integration

**Cons:**
- **10-15 week effort** (Iced learning curve + full rewrite)
- Iced ecosystem less mature than web frameworks
- tray-rs is relatively new (v0.1.2)
- No native tray testing (same industry limitation)
- Polling pattern for tray events (50ms timer)
- Iced doesn't match macOS native look without significant styling

### Option D: Qt/PySide6

**Effort:** 4-6 weeks | **Risk:** Low | **Cross-platform:** Yes

| Aspect | Details |
|--------|---------|
| **QSystemTrayIcon** | 20+ years battle-tested |
| **pytest-qt** | Best GUI testing story (but NOT for tray) |
| **Headless testing** | Yes, for QWidget/QML windows |
| **Bundle size** | 30-50 MB |
| **Language** | Python |

**Pros:**
- Fastest rewrite (Python, no compile times)
- Best testing story for non-tray UI (pytest-qt)
- QSystemTrayIcon is rock-solid
- Cross-platform

**Cons:**
- Python runtime dependency
- 30-50 MB bundle
- Doesn't feel native on macOS
- pytest-qt still cannot test QSystemTrayIcon interactions

### Option E: Avalonia (.NET)

**Effort:** 6-8 weeks | **Risk:** Medium | **Cross-platform:** Yes

| Aspect | Details |
|--------|---------|
| **TrayIcon control** | Built-in, cross-platform |
| **Headless testing** | 90% of Avalonia's own tests use headless platform |
| **Language** | C# |
| **Bundle size** | 15-30 MB |

**Pros:**
- Best headless testing story (can test ~90% of UI without display)
- Built-in TrayIcon control
- Cross-platform
- .NET ecosystem

**Cons:**
- .NET runtime
- Smaller community than Tauri/Qt
- Doesn't feel native on macOS

---

## 4. Recommendations

### Decision Matrix

| Criteria | Weight | Swift Fix | Tauri 2 | Iced+tray | Qt | Avalonia |
|----------|--------|-----------|---------|-----------|-----|----------|
| Solves notch problem | 25% | 10 | 7 | 7 | 7 | 7 |
| Automated tray testing | 20% | 0 | 0 | 0 | 0 | 0 |
| Cross-platform | 15% | 0 | 10 | 10 | 10 | 10 |
| Native feel (macOS) | 15% | 10 | 6 | 5 | 4 | 5 |
| Development effort | 15% | 10 | 5 | 2 | 6 | 5 |
| Ecosystem maturity | 10% | 8 | 9 | 4 | 10 | 6 |
| **Weighted Score** | | **6.25** | **5.40** | **4.15** | **5.30** | **5.05** |

### Key Insight

**No framework scores above 0 on "automated tray testing"** because this is an unsolved industry problem. The notch overflow problem also **affects all frameworks equally** -- it's a macOS limitation, not a Swift limitation.

### Recommended Path

**If primary goal is "fix the invisible icon":**
> **Option A (Swift fix)** -- 1-2 days, lowest risk, highest ROI

**If primary goal is "cross-platform + Rust":**
> **Option B (Tauri 2)** -- 6-8 weeks, production-proven, web frontend

**If primary goal is "pure Rust, native rendering":**
> **Option C (Iced + tray-rs)** -- 10-15 weeks, higher risk, newest ecosystem

### What Would NOT Change With a Rewrite

Regardless of framework choice:
1. Tray icon testing remains manual
2. Notch overflow affects all frameworks on macOS
3. macOS WebDriver support doesn't exist (for any WebView framework)
4. Business logic (Mise, Homebrew, OrbStack integration) must be reimplemented

---

## Sources

- [Apple FB7087526](https://github.com/feedback-assistant/reports/issues/37) -- NSStatusItem visibility feedback
- [iced-rs/iced#124](https://github.com/iced-rs/iced/issues/124) -- Iced tray support issue
- [nobane/tray-rs](https://github.com/nobane/tray-rs) -- Rust tray library with Iced support
- [tauri-apps/tray-icon](https://github.com/tauri-apps/tray-icon) -- Tauri tray-icon crate
- [jordanbaird/Ice](https://github.com/jordanbaird/Ice) -- Open source menu bar manager
- [Tauri v2 docs](https://v2.tauri.app/) -- Tauri 2 documentation
- [iGlance](https://github.com/iglance/iGlance) -- NSStatusItem.isVisible pattern
- [wiiznokes/fan-control](https://github.com/wiiznokes/fan-control) -- Iced + tray-icon example
