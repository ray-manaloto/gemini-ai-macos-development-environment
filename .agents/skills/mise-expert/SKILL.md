---
name: mise-expert
description: "Mise configuration, backends, tasks, and tool management for this project. Use when modifying config/mise.toml, adding/removing tools, creating mise tasks, debugging mise issues, or working with the Mise > Bun > Pixi > Uv tool hierarchy. Triggers on: tool installation, mise tasks, mise backends, mise settings, mise doctor, mise plugins, tool version management, environment variables, or any mise-related configuration changes."
---

# Mise Expert

This project uses Mise as the sole tool orchestrator. All tools are managed through mise — never install via npm/pip/brew directly.

## Tool Hierarchy (Strict)

```
Mise (orchestrator)
├── Bun (JS/TS runtime, npm backend) — replaces Node/npm, 3x faster
├── Pixi (conda-forge binary packages) — FFmpeg, CUDA, scientific
└── Uv (Python package manager) — 10x faster than pip
```

## Critical Settings

```toml
[settings]
experimental = true                    # Required for backends
not_found_auto_install = true          # Auto-install on first use

[settings.npm]
package_manager = "bun"                # npm packages install via bun

[settings.python]
uv_venv_auto = true                    # Auto-create venvs with uv
```

## Installation Patterns

| Backend | Syntax | Example |
|---------|--------|---------|
| Core | `mise use -g <tool>` | `mise use -g ripgrep` |
| npm→Bun | `mise use -g "npm:<pkg>"` | `mise use -g "npm:bats"` |
| Python→Uv | `mise use -g "pipx:<pkg>"` | `mise use -g "pipx:pre-commit"` |
| GitHub release | `mise use -g "ubi:<owner/repo>"` | `mise use -g "ubi:charmbracelet/gum"` |
| Cargo | `mise use -g "cargo:<pkg>"` | `mise use -g "cargo:bacon"` |
| Aqua | `mise use -g "aqua:<owner/repo>"` | `mise use -g "aqua:FiloSottile/age"` |

## FORBIDDEN Patterns

| Wrong | Why | Correct |
|-------|-----|---------|
| `npm install -g <pkg>` | Bypasses mise | `mise use -g "npm:<pkg>"` |
| `pip install <pkg>` | Pollutes system | `mise use -g "pipx:<pkg>"` |
| `brew install <cli>` | Wrong manager | `mise use -g <tool>` |
| `curl -fsSL ... \| sh` | Shadows mise | `mise use -g <tool>` |
| `sudo anything` | User-space only | Never use sudo |
| `npx <cmd>` | Not available | `bunx <cmd>` |

## Config Flow

```
config/main.pkl  →(pkl eval -f toml)→  config/mise.toml  →(cp)→  ~/.config/mise/config.toml
```

- `config/mise.toml` is the SOURCE OF TRUTH in the repo
- `~/.config/mise/config.toml` is the active config mise reads

## Mise Tasks

Tasks are defined in `config/mise.toml` under `[tasks.*]` sections. Run with `mise run <task>`.

Key tasks: `validate`, `dashboard`, `help`, `tools:status`, `tools:install`, `tools:update`, `autofix:fix`, `agent:ready`, `menubar:install`.

### Creating Tasks

```toml
[tasks.my-task]
description = "What this task does"
run = "command to execute"

# Multi-step task
[tasks.my-task]
run = """
step1
step2
"""

# Task with dependencies
[tasks.deploy]
depends = ["test", "build"]
run = "deploy.sh"
```

## Debugging

```bash
mise doctor          # Full health check
mise ls              # List installed tools with versions
mise which <tool>    # Show path to tool binary
mise settings        # Show all settings
mise config          # Show loaded config files
mise reshim          # Rebuild shims after changes
```

## Post-Change Verification

After any mise.toml change:
1. `cp config/mise.toml ~/.config/mise/config.toml`
2. `mise install` (install new tools)
3. `mise doctor` (verify health)
4. `bats tests/test_mise.bats` (run mise tests)
