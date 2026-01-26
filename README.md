# God-Tier macOS Development Environment

A reproducible, user-space development environment powered by **Mise**, **Pkl**, and **OrbStack**.

## Philosophy

This environment follows a **mise-first philosophy** where all tools are orchestrated through mise. The strict tool hierarchy ensures consistency and reproducibility:

```
Mise > Bun > Pixi > Uv
```

| Level | Tool | Purpose |
|-------|------|---------|
| 1 | **Mise** | Global tool version manager & orchestrator |
| 2 | **Bun** | JavaScript/TypeScript runtime (replaces Node/npm) |
| 3 | **Pixi** | Conda-forge packages & binary isolation |
| 4 | **Uv** | Fast Python package manager (10x faster than pip) |

## Quick Start

### 1. Clone and Run Setup
```bash
git clone https://github.com/YOUR_USERNAME/gemini-ai-macos-development-environment.git
cd gemini-ai-macos-development-environment
./setup.sh
```

### 2. Restart Terminal
```bash
# Or reload your shell config
source ~/.zshrc
```

### 3. Apply Dotfile Templates (Optional)
```bash
chezmoi diff     # Preview changes
chezmoi apply    # Apply changes
```

### 4. Verify Installation
```bash
mise doctor                      # Check mise health
./config/scripts/validate.sh     # Run health check
bats tests/                      # Run test suite
```

### What Gets Installed
| Tool | Purpose |
|------|---------|
| mise | Tool version manager (orchestrator) |
| bun | JavaScript runtime (node backend) |
| uv | Python package manager (pip backend) |
| pixi | Conda-forge packages |
| starship | Cross-shell prompt |
| chezmoi | Dotfile manager |
| zoxide, fd, ripgrep, bat, eza, fzf, jq, yq, delta | Modern CLI utilities |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        MISE (Orchestrator)                       │
│  • Manages all tool versions                                     │
│  • Provides mise tasks (CLI commands)                            │
│  • Handles environment variables per directory                   │
│  • Integrates with AI via MCP (Model Context Protocol)           │
├─────────────────────────────────────────────────────────────────┤
│     Bun (JS)     │     Pixi (Binary)     │     Uv (Python)       │
│  npm packages    │  conda-forge packages │  pip packages         │
│  TypeScript      │  FFmpeg, CUDA, etc.   │  virtualenvs          │
├─────────────────────────────────────────────────────────────────┤
│                     PITCHFORK (Daemons)                          │
│  • Auto-start services when entering project directories         │
│  • Auto-stop when the last terminal session leaves               │
│  • Perfect for databases, dev servers, watchers                  │
└─────────────────────────────────────────────────────────────────┘
```

## Key Features

### Directory-Based Automation

When you `cd` into a project directory, mise automatically:
- Activates the correct tool versions
- Sets environment variables from `mise.toml`
- Runs any configured hooks

Combined with **Pitchfork**, this enables fully automatic service lifecycle management.

### AI Integration (MCP)

The environment includes mise MCP integration for Claude Desktop and Claude Code:

```bash
# Setup MCP
mise run setup-mcp

# Now Claude can query your environment:
# "What version of Python is installed?"
# "What mise tasks are available?"
```

### Cloud Agents (SkyPilot)

Launch ephemeral cloud agents on AWS for heavy workloads:

```bash
mise run agent:up    # Launch cloud agent
mise run agent:down  # Terminate when done
```

## Configuration

The `config/main.pkl` file is the source of truth. It compiles to `~/.config/mise/config.toml`.

### Tools Included

| Category | Tools |
|----------|-------|
| **Core Runtimes** | bun, pixi, uv, usage, pitchfork |
| **Modern CLI** | starship, ripgrep, fd-find, zoxide, ast-grep, mgrep |
| **Cloud & Containers** | orbstack, skypilot, devpod |
| **AI Agents** | claude-code, opencode-ai, gemini-cli, github-cli |
| **Secrets** | 1password-cli, infisical |
| **GUI** | swiftbar, zed |

### Mise Tasks

| Command | Description |
|---------|-------------|
| `mise run dashboard` | Launch TUI manager |
| `mise run validate` | Check environment health |
| `mise run help` | Show system manual |
| `mise run agent:up` | Launch cloud agent on AWS |
| `mise run agent:down` | Terminate cloud agents |
| `mise run setup-mcp` | Configure mise MCP for Claude |
| `mise run setup-extensions` | Install GitHub Copilot extension |

## Project Structure

```
gemini-ai-macos-development-environment/
├── config/
│   ├── main.pkl              # Pkl configuration → generates mise TOML
│   └── scripts/              # Task scripts (dashboard, validate, etc.)
├── templates/
│   └── agent.yaml            # SkyPilot AWS agent template
├── research/
│   ├── CHATGPT_DEEP_RESEARCH.md    # ChatGPT deep research report
│   ├── DEEP_RESEARCH_FINDINGS.md   # YouTube/NotebookLM findings
│   ├── GAPS_ANALYSIS.md            # Gap analysis
│   └── ...                         # Additional research docs
├── .github/
│   └── workflows/
│       └── validate.yml      # CI validation
├── setup.sh                  # Bootstrap script
├── pixi.toml                 # Pixi dependencies
├── README.md                 # This file
├── CLAUDE.md                 # AI assistant context
├── MANUAL.md                 # System manual
└── PREFLIGHT_CHECKLIST.md    # Pre-installation checklist
```

## Installation Requirements

Before running `setup.sh`, ensure you have:

1. **macOS 14+** (Sonoma or later recommended)
2. **Xcode Command Line Tools**: `xcode-select --install`
3. **~10GB free disk space** for tools and caches

See `PREFLIGHT_CHECKLIST.md` for a detailed pre-installation checklist.

## Staying Updated

Track mise and ecosystem releases:

- **RSS Feed**: `https://github.com/jdx/mise/releases.atom`
- **GitHub Watch**: mise, pitchfork, uv, bun repos
- **Community**: GitHub Discussions, Reddit, Hacker News

## Rollback

To return your Mac to stock:

1. Delete `~/.local/share/mise` (Binaries)
2. Delete `~/.config/mise` and `~/.config/dev-env` (Config)
3. Uninstall OrbStack: `brew uninstall --cask orbstack` (or drag to Trash)
4. Remove shell activation from `~/.zshrc`

## Testing

### Run Full Test Suite
```bash
# Install BATS if needed
mise use -g npm:bats

# Run all tests
bats tests/
```

### Test Files
| File | Tests |
|------|-------|
| `tests/test_mise.bats` | Mise installation, backends, tasks |
| `tests/test_tools.bats` | CLI tool availability |
| `tests/test_chezmoi.bats` | Dotfile template validation |
| `tests/test_starship.bats` | Prompt configuration |
| `tests/test_integration.bats` | End-to-end project structure |

### Health Check
```bash
# Quick validation
./config/scripts/validate.sh

# Mise diagnostics
mise doctor
mise ls
```

---

## Documentation

| Document | Purpose |
|----------|---------|
| `CLAUDE.md` | AI assistant context and development patterns |
| `PROJECT_PLAN.md` | Agile project plan and sprint status |
| `OPENCODE_PROMPTS.md` | OpenCode + oh-my-opencode usage guide |
| `OPENCODE_SETUP.md` | Automated setup with ultrawork mode |
| `MANUAL.md` | System manual (accessible via `mise run help`) |
| `PREFLIGHT_CHECKLIST.md` | Pre-installation requirements |
| `research/` | Research documentation and findings |

## Related Projects

- [Mise](https://mise.jdx.dev/) - Polyglot tool version manager
- [Pitchfork](https://github.com/jdx/pitchfork) - Development daemon manager
- [Pixi](https://pixi.sh/) - Conda-forge package manager
- [Uv](https://docs.astral.sh/uv/) - Fast Python package manager
- [Bun](https://bun.sh/) - Fast JavaScript runtime

---

*Last updated: January 2026*
