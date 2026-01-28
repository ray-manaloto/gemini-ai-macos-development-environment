# Specification: Mise Tasks

## Overview

This specification defines all mise tasks (CLI commands) available in the environment.

## Task Definitions

### Core Tasks

#### `mise run dashboard`

**Purpose**: Launch unified TUI dashboard for environment management.

**Implementation**:
```toml
[tasks.dashboard]
run = "cd ~/.config/dev-env && pixi run python scripts/dashboard.py"
description = "Launch unified TUI dashboard"
```

**Dependencies**:
- Pixi installed
- `~/.config/dev-env/pixi.toml` exists
- Textual Python package installed via Pixi

**Acceptance Criteria**:
- [ ] TUI launches without errors
- [ ] Shows tool versions
- [ ] Allows navigation with keyboard

---

#### `mise run validate`

**Purpose**: Check environment health and report issues.

**Implementation**:
```toml
[tasks.validate]
run = "./config/scripts/validate.sh"
description = "Check environment health"
```

**Dependencies**:
- `config/scripts/validate.sh` exists and is executable

**Exit Codes**:
- `0`: All checks pass
- `1`: Critical failure
- `2`: Warnings present

**Acceptance Criteria**:
- [ ] Checks all required tools
- [ ] Reports missing tools with install commands
- [ ] Colored output (green=pass, red=fail, yellow=warn)

---

#### `mise run help`

**Purpose**: Display system manual in pager.

**Implementation**:
```toml
[tasks.help]
run = "gum pager < MANUAL.md"
description = "Show system manual"
```

**Dependencies**:
- `gum` installed
- `MANUAL.md` exists in project root

**Acceptance Criteria**:
- [ ] Opens MANUAL.md in interactive pager
- [ ] Supports scrolling and search

---

### Cloud Tasks

#### `mise run agent:up`

**Purpose**: Launch ephemeral AWS cloud agent via SkyPilot.

**Implementation**:
```toml
[tasks."agent:up"]
run = "sky launch templates/agent.yaml --yes"
description = "Launch cloud agent on AWS"
```

**Dependencies**:
- SkyPilot installed
- AWS credentials configured
- `templates/agent.yaml` exists

**Acceptance Criteria**:
- [ ] Launches spot instance on AWS
- [ ] Returns instance IP/hostname
- [ ] SSH accessible after launch

---

#### `mise run agent:down`

**Purpose**: Terminate all cloud agents.

**Implementation**:
```toml
[tasks."agent:down"]
run = "sky down --all --yes"
description = "Terminate cloud agents"
```

**Acceptance Criteria**:
- [ ] Terminates all SkyPilot instances
- [ ] Confirms termination

---

### Setup Tasks

#### `mise run setup-mcp`

**Purpose**: Configure mise MCP for Claude Desktop/CLI.

**Implementation**:
```toml
[tasks.setup-mcp]
run = "./config/scripts/setup-mcp.sh"
description = "Configure mise MCP for Claude"
```

**Output**:
- Updates `~/.config/claude/claude_desktop_config.json`
- Updates `~/.claude/settings.json`

**Acceptance Criteria**:
- [ ] MCP configuration written
- [ ] Claude can query mise tools/tasks

---

#### `mise run setup-extensions`

**Purpose**: Install GitHub Copilot CLI extension.

**Implementation**:
```toml
[tasks.setup-extensions]
run = "gh extension install github/gh-copilot"
description = "Install GitHub Copilot extension"
```

**Dependencies**:
- `gh` CLI installed and authenticated

**Acceptance Criteria**:
- [ ] `gh copilot --help` works after installation

---

#### `mise run setup-mac`

**Purpose**: Apply macOS system defaults (Finder, Dock, etc.).

**Implementation**:
```toml
[tasks.setup-mac]
run = "./config/scripts/macos-defaults.sh"
description = "Configure macOS defaults"
```

**Changes Applied**:
- Finder: Show hidden files, path bar, extensions
- Dock: Auto-hide, minimize to app icon
- Keyboard: Fast key repeat, disable auto-correct
- Screenshots: Save to ~/Screenshots

**Acceptance Criteria**:
- [ ] Script runs without errors
- [ ] Changes visible after Dock/Finder restart

---

## Task Namespace Convention

| Prefix | Purpose | Example |
|--------|---------|---------|
| (none) | Core functionality | `dashboard`, `validate`, `help` |
| `agent:` | Cloud agent management | `agent:up`, `agent:down` |
| `setup-` | One-time setup actions | `setup-mcp`, `setup-mac` |

## Testing Tasks

```bash
# tests/test_mise.bats

@test "mise task list includes dashboard" {
  run mise task ls
  [[ "$output" == *"dashboard"* ]]
}

@test "mise run validate succeeds" {
  run mise run validate
  [ "$status" -eq 0 ]
}

@test "mise run help displays manual" {
  run timeout 2 mise run help || true
  # Task should start (timeout is expected for interactive pager)
  [ "$status" -eq 124 ] || [ "$status" -eq 0 ]
}
```
