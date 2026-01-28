# Specification: Tools

## Overview

This specification defines all tools managed by the God-Tier macOS Development Environment.

## Tool Categories

### 1. Core Runtimes

| Tool | Version | Source | Purpose |
|------|---------|--------|---------|
| `bun` | latest | mise | JavaScript/TypeScript runtime, npm replacement |
| `pixi` | latest | mise | Conda-forge package manager |
| `uv` | latest | mise | Fast pip replacement |
| `usage` | latest | mise | AI-powered CLI completions |
| `pitchfork` | latest | mise | Development daemon manager |

**Acceptance Criteria**:
- [ ] Each tool is installed via mise
- [ ] `mise ls` shows all tools with correct versions
- [ ] `which <tool>` returns `~/.local/share/mise/shims/<tool>`

### 2. Modern CLI Utilities

| Tool | Version | Source | Purpose | Replaces |
|------|---------|--------|---------|----------|
| `starship` | latest | mise | Cross-shell prompt | PS1 |
| `ripgrep` | latest | mise | Fast grep | grep |
| `fd-find` | latest | mise | Fast find | find |
| `zoxide` | latest | mise | Smart cd | cd |
| `bat` | latest | mise | Cat with syntax highlighting | cat |
| `eza` | latest | mise | Modern ls | ls |
| `fzf` | latest | mise | Fuzzy finder | - |
| `jq` | latest | mise | JSON processor | - |
| `yq` | latest | mise | YAML processor | - |
| `delta` | latest | mise | Git diff viewer | diff |
| `ast-grep` | latest | mise | Structural code search | grep (AST) |
| `mgrep` | latest | mise | Semantic code search (AI) | grep (semantic) |

**Acceptance Criteria**:
- [ ] Each tool responds to `--version` or `--help`
- [ ] Shell aliases configured in `.zshrc` template

### 3. Configuration Management

| Tool | Version | Source | Purpose |
|------|---------|--------|---------|
| `chezmoi` | latest | mise | Dotfile manager |

**Acceptance Criteria**:
- [ ] `chezmoi source-path` returns valid path
- [ ] Templates exist for `.zshrc`, `.gitconfig`
- [ ] `chezmoi diff` shows no errors

### 4. Cloud & Containers

| Tool | Version | Source | Purpose |
|------|---------|--------|---------|
| `orbstack` | latest | brew cask | Docker replacement |
| `skypilot` | latest | uv | AWS spot instance orchestrator |
| `devpod` | latest | mise | DevContainer runner |

**Acceptance Criteria**:
- [ ] OrbStack running with Docker CLI available
- [ ] `sky --help` returns usage info
- [ ] `devpod --help` returns usage info

### 5. AI Agents

| Tool | Version | Source | Purpose |
|------|---------|--------|---------|
| `claude-code` | latest | npm | Claude Code CLI |
| `opencode-ai` | latest | npm | OpenCode CLI |
| `gemini-cli` | latest | npm | Google Gemini CLI |
| `github-cli` | latest | mise | GitHub CLI + Copilot |

**Acceptance Criteria**:
- [ ] Each CLI responds to `--help`
- [ ] MCP integration configured for Claude
- [ ] `gh copilot --help` returns usage info

### 6. Secrets Management

| Tool | Version | Source | Purpose |
|------|---------|--------|---------|
| `1password-cli` | latest | brew cask | 1Password CLI (`op`) |
| `infisical` | latest | mise | Infisical secrets CLI |

**Acceptance Criteria**:
- [ ] `op --version` returns version
- [ ] `infisical --help` returns usage info

### 7. GUI Applications

| Tool | Version | Source | Purpose |
|------|---------|--------|---------|
| `swiftbar` | latest | brew cask | Menu bar customization |
| `zed` | latest | brew cask | Code editor |

**Acceptance Criteria**:
- [ ] Applications present in `/Applications`

## Backend Configuration

### Node Backend: Bun

```toml
[settings]
node_backend = "bun"
```

**Behavior**:
- `npm install` → `bun install`
- `npx <pkg>` → `bunx <pkg>`
- `node script.js` → `bun script.js`

### Pip Backend: Uv

```toml
[settings]
pip_backend = "uv"
```

**Behavior**:
- `pip install` → `uv pip install`
- `pip freeze` → `uv pip freeze`
- Virtualenvs created with `uv venv`

## Installation Order

Tools must be installed in this order to satisfy dependencies:

1. **mise** (bootstrap, installed by setup.sh)
2. **bun** (needed for npm packages)
3. **uv** (needed for pip packages)
4. **pixi** (needed for binary packages)
5. **All other tools** (parallel installation OK)

## Verification Tests

```bash
# tests/test_tools.bats

@test "bun is installed" {
  run bun --version
  [ "$status" -eq 0 ]
}

@test "uv is installed" {
  run uv --version
  [ "$status" -eq 0 ]
}

@test "pixi is installed" {
  run pixi --version
  [ "$status" -eq 0 ]
}

@test "starship is installed" {
  run starship --version
  [ "$status" -eq 0 ]
}

# ... tests for all tools
```
