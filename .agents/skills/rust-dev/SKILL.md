---
name: rust-dev
description: "Rust development for this project's Iced and Tauri menu bar applications. Use when modifying DevEnvManager-Iced/ or DevEnvManager-Tauri/ Rust code, debugging Rust compile errors, adding Rust features, or working with Cargo. Triggers on: Rust code, Cargo.toml, .rs files, iced framework, tauri framework, tray-icon crate, or Rust compile/test issues in these subdirectories."
---

# Rust Development

Two Rust-based menu bar implementations exist in this project.

## DevEnvManager-Iced (Spec C)

Pure Rust GUI using `iced 0.14` + `tray-icon 0.21`. Produces a 5.4 MB native binary.

```
DevEnvManager-Iced/
├── src/
│   ├── main.rs          # Entry point
│   ├── app.rs           # Iced Application impl
│   ├── tray.rs          # System tray integration
│   ├── config.rs        # Configuration
│   ├── domain/          # Business logic (mise, homebrew, orbstack, ports)
│   └── views/           # UI views
├── Cargo.toml           # iced 0.14, tray-icon 0.21
├── tests/               # 48 tests
└── target/release/      # Pre-built binary
```

### Build & Test

```bash
cd DevEnvManager-Iced
cargo build --release     # Build binary
cargo test                # Run 48 tests
./target/release/devenv-manager-iced &  # Run
```

### Key Dependencies

- `iced = "0.14"` — GPU-accelerated UI framework
- `tray-icon = "0.21"` — System tray (NSStatusItem on macOS)
- `tokio` — Async runtime
- `serde`, `serde_json` — Serialization

## DevEnvManager-Tauri (Spec D)

Tauri 2 app with React frontend and Rust backend.

```
DevEnvManager-Tauri/
├── src-tauri/
│   ├── src/
│   │   ├── lib.rs       # Tauri app setup
│   │   ├── tray.rs      # System tray
│   │   └── commands/    # Tauri IPC commands
│   ├── Cargo.toml       # tauri 2.x
│   └── tests/           # 42 tests
├── src/                 # React frontend
│   ├── App.tsx
│   ├── components/
│   └── hooks/
└── package.json         # bun + react + @tauri-apps/cli
```

### Build & Test

```bash
cd DevEnvManager-Tauri
bun install               # Install JS deps (NOT npm)
bun tauri dev             # Dev server with hot reload
bun tauri build           # Production build
cd src-tauri && cargo test  # Run 42 Rust tests
```

### Tauri IPC Pattern

```rust
#[tauri::command]
async fn get_tools() -> Result<Vec<Tool>, String> {
    // Called from React via invoke("get_tools")
}
```

```tsx
// React side
import { invoke } from '@tauri-apps/api/core';
const tools = await invoke<Tool[]>('get_tools');
```

## Common Patterns

### Domain Layer (Shared Concepts)

Both apps implement the same domain:
- **Mise tools**: Parse `mise ls --json` output
- **Homebrew services**: Parse `brew services list`
- **OrbStack containers**: Parse `orb list`
- **Port detection**: Parse `lsof -i -P -n`

### Error Handling

```rust
// Use thiserror for domain errors
#[derive(Debug, thiserror::Error)]
enum AppError {
    #[error("Mise not found")]
    MiseNotFound,
    #[error("Command failed: {0}")]
    CommandFailed(String),
}
```

### Testing

Both projects use standard Rust test patterns:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_mise_output() {
        let json = r#"[{"name":"bun","version":"1.2.0"}]"#;
        let tools: Vec<Tool> = serde_json::from_str(json).unwrap();
        assert_eq!(tools[0].name, "bun");
    }
}
```

## Constraints

- Mise manages Rust: `mise use -g rust` — never install via rustup directly
- No Xcode.app available — Swift (Spec B) cannot be recompiled
- Pre-built Iced binary exists at `DevEnvManager-Iced/target/release/`
- Tauri frontend uses Bun, NOT npm: `bun install`, `bun tauri dev`
