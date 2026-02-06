# DevEnvManager-Iced

Rust menu bar app using `tray-icon` for the tray icon and `iced::daemon` for the popup UI.

## Build

```bash
cargo build --release
```

## Run

```bash
cargo run
```

## Package

```bash
cargo install cargo-packager --locked
cargo packager --release
```

## Architecture

```
TrayIcon (tray.rs)
        │
        ▼
 iced::daemon (main.rs)
        │
        ▼
   App state (app.rs)
   ├─ views/ (popup + settings)
   └─ domain/ (mise, brew, orb, ports)
```

Key modules:
- `src/main.rs` bootstraps the tray icon and `iced::daemon`.
- `src/app.rs` holds app state and window routing with `BTreeMap<window::Id, WindowKind>`.
- `src/tray.rs` creates the menu bar icon and forwards tray events.
- `src/domain/*` runs CLI commands via `tokio::process::Command`.
- `src/views/*` renders the popup and settings windows.

## Dependencies

- `iced` 0.14 (multi-window, tokio, image)
- `tray-icon` 0.21
- `muda` 0.16
- `image` 0.25 (png)
- `tokio` 1
- `serde` 1, `serde_json` 1, `toml` 0.8

## Configuration

Default config path:
`~/.config/dev-env/DevEnvManager-Iced/config.toml`

Override for tests or custom setups:
- `DEVENV_MANAGER_ICED_CONFIG_DIR`

Fields:
- `refresh_interval_secs`
- `launch_at_login`
- `show_notifications`
