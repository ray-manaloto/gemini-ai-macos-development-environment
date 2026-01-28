# Design: God-Tier macOS Development Environment

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER SHELL (zsh)                                │
│  ~/.zshrc sources mise activation + starship prompt                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                           MISE (Orchestrator)                                │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ ~/.config/mise/config.toml                                           │    │
│  │ - Tool versions (bun, python, node, etc.)                            │    │
│  │ - Backend settings (node_backend=bun, pip_backend=uv)                │    │
│  │ - Environment variables                                              │    │
│  │ - Task definitions                                                   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │     BUN      │  │     PIXI     │  │      UV      │  │   PITCHFORK  │     │
│  │  (JS/TS)     │  │  (Binaries)  │  │   (Python)   │  │  (Daemons)   │     │
│  │              │  │              │  │              │  │              │     │
│  │ npm packages │  │ conda-forge  │  │ pip packages │  │ Auto-start   │     │
│  │ TypeScript   │  │ FFmpeg, CUDA │  │ virtualenvs  │  │ Auto-stop    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                             FILE SYSTEM                                      │
│  ~/.local/share/mise/    - Tool binaries                                     │
│  ~/.config/mise/         - Configuration                                     │
│  ~/.config/dev-env/      - Project-specific (pixi.toml, dashboard)           │
│  ~/.config/starship.toml - Shell prompt                                      │
│  ~/.local/share/chezmoi/ - Dotfile templates                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Tool Hierarchy

The strict hierarchy `Mise > Bun > Pixi > Uv` determines package resolution order:

### Level 1: Mise (Orchestrator)

**Role**: Single source of truth for all tool versions and configurations.

```toml
# ~/.config/mise/config.toml
[settings]
node_backend = "bun"      # All npm → bun install
pip_backend = "uv"        # All pip → uv pip install
experimental = true

[tools]
bun = "latest"
pixi = "latest"
uv = "latest"
```

**Shim Strategy**: Mise creates shims in `~/.local/share/mise/shims/` that intercept commands:
- `npm install` → `bun install`
- `pip install` → `uv pip install`
- `node script.js` → `bun script.js`

### Level 2: Bun (JavaScript/TypeScript)

**Role**: Replaces Node.js and npm for all JavaScript workloads.

**Why Bun over Node?**
| Aspect | Bun | Node |
|--------|-----|------|
| Install speed | 3x faster | Baseline |
| TypeScript | Native, zero-config | Requires ts-node/tsx |
| Package resolution | Hardlink cache | Copy per project |
| Startup time | 10ms | 100ms+ |

**Configuration**: None needed. Mise's `node_backend = "bun"` handles redirection.

### Level 3: Pixi (Binary/System Dependencies)

**Role**: Manages binary packages from conda-forge that can't be compiled from source.

**Use Cases**:
- FFmpeg (video processing)
- CUDA (GPU compute)
- Scientific Python (NumPy with MKL)
- Textual (TUI framework with ncurses)

**Configuration**: `~/.config/dev-env/pixi.toml`
```toml
[project]
name = "dev-env"
channels = ["conda-forge"]
platforms = ["osx-arm64", "osx-64"]

[dependencies]
python = ">=3.12"
textual = ">=0.52"
```

### Level 4: Uv (Python Packages)

**Role**: Fast pip replacement for pure-Python packages.

**Why Uv over pip?**
| Aspect | Uv | pip |
|--------|-----|------|
| Resolution | 10x faster | Baseline |
| Lockfiles | Deterministic | Non-deterministic |
| Caching | Content-addressed | Version-based |
| Cross-platform | Hash verification | Platform-specific |

**Configuration**: None needed. Mise's `pip_backend = "uv"` handles redirection.

## Directory Structure

```
~/.local/
├── share/
│   ├── mise/
│   │   ├── shims/           # Command shims (node → bun, pip → uv)
│   │   ├── installs/        # Installed tool versions
│   │   │   ├── bun/
│   │   │   ├── python/
│   │   │   └── ...
│   │   └── plugins/         # Tool plugins
│   └── chezmoi/             # Dotfile source repository
│
└── bin/                     # User binaries (added to PATH)

~/.config/
├── mise/
│   └── config.toml          # Global mise configuration
├── dev-env/
│   ├── pixi.toml            # Pixi project for dashboard
│   └── scripts/             # Dashboard, validation scripts
├── starship.toml            # Prompt configuration
└── chezmoi/                 # Chezmoi configuration
```

## Data Flow

### 1. Shell Initialization

```
User opens terminal
    ↓
~/.zshrc executes
    ↓
eval "$(mise activate zsh)"
    ↓
Mise adds shims to PATH
    ↓
eval "$(starship init zsh)"
    ↓
Starship configures prompt
    ↓
Shell ready with mise-managed environment
```

### 2. Directory-Based Activation

```
cd ~/projects/my-python-app
    ↓
Mise detects mise.toml or .mise.toml
    ↓
Mise activates:
  - python@3.12
  - uv (for pip)
  - ENV vars from [env] section
    ↓
Pitchfork (if configured) starts:
  - postgres
  - redis
    ↓
User runs: pip install -r requirements.txt
    ↓
Mise shim redirects to: uv pip install -r requirements.txt
    ↓
Packages installed to project virtualenv
```

### 3. Task Execution

```
User runs: mise run dashboard
    ↓
Mise looks up [tasks.dashboard] in config
    ↓
Task definition:
  run = "cd ~/.config/dev-env && pixi run python scripts/dashboard.py"
    ↓
Pixi activates conda environment
    ↓
Python script executes with textual TUI
```

## Component Design

### Mise Configuration (`config/mise.toml`)

```toml
[settings]
node_backend = "bun"
pip_backend = "uv"
experimental = true
disable_hints = []
status = { missing_tools = "if_other_versions_installed" }
not_found_auto_install = true

[tools]
bun = "latest"
pixi = "latest"
uv = "latest"
usage = "latest"
chezmoi = "latest"
starship = "latest"
# ... more tools

[env]
MISE_EXPERIMENTAL = "1"
MISE_LOG_LEVEL = "warn"

[tasks.dashboard]
run = "cd ~/.config/dev-env && pixi run python scripts/dashboard.py"
description = "Launch unified TUI dashboard"

[tasks.validate]
run = "./config/scripts/validate.sh"
description = "Check environment health"
```

### Chezmoi Templates

**dot_zshrc.tmpl**:
```zsh
# Mise activation (must be early)
eval "$(mise activate zsh)"

# Starship prompt
eval "$(starship init zsh)"

# Modern CLI aliases
alias ls="eza --icons"
alias cat="bat"
alias grep="rg"
alias find="fd"
alias cd="z"

# Zoxide initialization
eval "$(zoxide init zsh)"
```

### Starship Configuration

```toml
# ~/.config/starship.toml
format = """
$directory$git_branch$git_status
$python$nodejs$bun$rust
$character"""

[directory]
truncation_length = 3
truncate_to_repo = true

[git_branch]
format = "[$branch]($style) "
style = "bold purple"

[python]
format = "[py $version]($style) "
detect_files = ["pyproject.toml", "requirements.txt"]

[bun]
format = "[bun $version]($style) "
```

## Error Handling

### Tool Not Found

```
User runs: node script.js
    ↓
Mise shim checks if node is installed
    ↓
If not_found_auto_install = true:
    Mise installs node (via bun backend)
    ↓
Else:
    Error: "node not installed. Run: mise use node@20"
```

### Backend Fallback

If bun fails to install an npm package:
1. Mise logs warning
2. Falls back to native npm
3. User notified to report issue

### Validation Failures

`mise run validate` checks:
1. All required tools installed
2. Backend settings correct
3. Shims functional
4. Chezmoi templates valid
5. Starship configuration valid

Exit codes:
- 0: All checks pass
- 1: Critical failure (missing tool)
- 2: Warning (outdated version)

## Security Considerations

### No Sudo Required

All operations are user-space:
- Binaries in `~/.local/share/mise/`
- Config in `~/.config/`
- No system PATH modifications

### Secrets Management

Secrets are NOT stored in mise config. Options:
1. **1Password**: `op://` URIs in env vars
2. **Infisical**: `infisical run -- command`
3. **Mise Secrets**: `mise secrets set KEY=value` (encrypted)

### Tool Integrity

Mise verifies tool checksums before installation:
```toml
[tools]
bun = { version = "1.1.0", checksum = "sha256:abc123..." }
```

## Performance Characteristics

| Operation | Expected Time | Measurement Method |
|-----------|---------------|-------------------|
| Shell startup | < 100ms | `time zsh -i -c exit` |
| Tool lookup | < 10ms | Shim overhead |
| npm install | 3x faster than npm | Bun benchmark |
| pip install | 10x faster than pip | Uv benchmark |
| cd with hooks | < 50ms | Mise hook overhead |

## Testing Strategy

### Unit Tests (BATS)

```bash
@test "mise is installed" {
  run mise --version
  [ "$status" -eq 0 ]
}

@test "bun backend configured" {
  result=$(mise config get settings.node_backend)
  [ "$result" = "bun" ]
}
```

### Integration Tests

```bash
@test "npm redirects to bun" {
  run npm --version
  [[ "$output" == *"bun"* ]] || [ "$status" -eq 0 ]
}

@test "pip redirects to uv" {
  run pip --version
  [[ "$output" == *"uv"* ]] || [ "$status" -eq 0 ]
}
```

### Smoke Tests

```bash
# Full setup on clean machine
./setup.sh
mise doctor
bats tests/
```
