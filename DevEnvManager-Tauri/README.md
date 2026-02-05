# DevEnvManager-Tauri

Tauri 2 menu bar app for managing development tools (Mise, Homebrew services, OrbStack containers, active ports).

## Requirements

- macOS 14+
- Rust toolchain
- Bun

## Development

```bash
bun install
bun tauri dev
```

## Build

```bash
bun run build
bun tauri build
```

Build output: `DevEnvManager-Tauri/src-tauri/target/release/bundle/macos/DevEnvManager.app`

## Architecture

- `src-tauri/` — Rust backend, tray icon, CLI integrations
- `src/` — React frontend for menu bar popup UI
- `src-tauri/capabilities/` — Tauri 2 permissions

## Features

- Tray icon with left-click popup and right-click menu
- Mise tools list with install/update actions
- Homebrew service status and start/stop/restart
- OrbStack container list with start/stop
- Active port detection via lsof
```
