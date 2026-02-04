# CLAUDE.md - Project Context for Claude Code

This file provides context and guidelines for AI assistants working with this repository.

---

## FOR LLM AGENTS

**Read first:** `@AGENTS.md` for comprehensive project knowledge base.

| Quick Reference | |
|-----------------|---|
| **Project** | God-Tier macOS Development Environment |
| **Hierarchy** | Mise > Bun > Pixi > Uv |
| **Key Config** | `config/mise.toml` |
| **Tests** | `bats tests/` (402 tests) |
| **Validate** | `mise run validate` |

**Critical Rules:**
1. NEVER use sudo
2. NEVER install globally with npm/pip - use mise
3. ALWAYS use mise tasks
4. ALWAYS run tests before committing

**For full context, onboarding prompts, and agent-specific instructions, see:**
- `AGENTS.md` - Complete knowledge base
- `AI_ONBOARDING.md` - Copy-paste prompts for any LLM

---

## Project Overview

This is a **"God-Tier" macOS Development Environment** setup using a strict tool hierarchy:

```
Mise > Bun > Pixi > Uv
```

The entire stack lives in user-space (`~/.local`) with **zero system modifications**.

---

## Core Philosophy

1. **Mise is the orchestrator** - ALL tools are managed through mise
2. **Bun replaces Node/npm** - Forced via `node_backend = "bun"`
3. **Uv replaces pip** - Forced via `pip_backend = "uv"`
4. **Pixi handles binary/system dependencies** - Python, FFmpeg, CUDA, etc.
5. **Pitchfork manages daemons** - Auto-start/stop services per project
6. **User-space only** - No sudo, no Homebrew (except for GUI apps via mise)

---

## Tool Hierarchy

| Level | Tool | Purpose |
|-------|------|---------|
| 1 | **Mise** | Global tool version manager (orchestrator) |
| 2 | **Bun** | JavaScript/TypeScript runtime, replaces npm |
| 3 | **Pixi** | Conda-forge packages, binary isolation |
| 4 | **Uv** | Fast pip replacement (10x faster) |

---

## Mise: The Orchestrator

**Mise is the foundation of this environment.** All tools, versions, and tasks are managed through Mise.

### What Mise Does

1. **Tool Version Management** - Manages 20+ tools (bun, node, python, go, rust, etc.)
2. **Auto-Activation** - Automatically activates tools when you `cd` into directories
3. **Task Runner** - Provides 35+ custom tasks (`mise run <task>`)
4. **Environment Management** - Sets environment variables per directory
5. **MCP Integration** - Exposes tool state to AI assistants via Model Context Protocol

### Auto-Activation Behavior

**When you `cd` into this project:**
```bash
cd ~/dev/github/ray-manaloto/gemini-ai-macos-development-environment
```

Mise automatically:
1. Detects `config/mise.toml`
2. Activates tool versions (bun@1.3.8, node@25.5.0, python@3.14.2)
3. Prepends tool paths to PATH
4. Sets environment variables from `[env]` section
5. Runs hooks (if defined)

**When you `cd` out:**
```bash
cd ~
```

Mise automatically:
1. Removes tool paths from PATH
2. Restores original environment
3. Deactivates project-specific tools

### Querying Mise State

| Command | Purpose | Example Output |
|---------|---------|----------------|
| `mise ls` | List installed tools | `bun 1.3.8`, `node 25.5.0` |
| `mise current` | Show active versions | Shows versions in current directory |
| `mise which <tool>` | Show tool path | `~/.local/share/mise/installs/bun/1.3.8/bin/bun` |
| `mise env` | Show environment | All env vars set by Mise |
| `mise doctor` | Check health | Comprehensive diagnostics |
| `mise tasks ls` | List tasks | 35+ available tasks |

### Configuration

**Source of Truth**: `config/mise.toml` (~960 lines)

**Key Settings**:
```toml
[settings]
experimental = true              # Required for MCP
not_found_auto_install = true   # Auto-install missing tools

[settings.npm]
package_manager = "npm"          # npm backend uses npm (NOT Bun)

[settings.python]
uv_venv_auto = true             # Auto-create uv venvs

[tools]
bun = "latest"                  # JavaScript runtime
node = "latest"                 # Node.js runtime
python = "latest"               # Python runtime
# ... 20+ more tools

[tasks."task-name"]
description = "Description"
run = "#!/bin/bash\n# Task script"
```

### Important: npm vs Bun

**Configuration is CORRECT**:
- `npm.package_manager = "npm"` - npm backend uses npm to install npm packages as tools
- `bun = "latest"` - Bun is installed as a JavaScript runtime
- When you run `bun install` in projects, you're using Bun directly
- When Mise installs npm packages as tools (e.g., `npm:gemini-cli`), it uses npm

This is the recommended configuration for maximum compatibility.

### For AI Agents

**Before suggesting tool installations, check Mise state:**
```bash
mise ls | grep <tool>
```

**Use Mise tasks instead of raw commands:**
```bash
# Good
mise run validate

# Bad
python config/scripts/validate.sh
```

**Respect tool hierarchy:**
```bash
# Good
mise use -g npm:typescript

# Bad
npm install -g typescript
```

**For comprehensive AI/LLM integration guide, see:**
`.sisyphus/drafts/mise-ai-integration.md` (complete guide with examples)

---

## Key Files

| File | Purpose |
|------|---------|
| `config/main.pkl` | Pkl configuration → generates mise TOML |
| `setup.sh` | Bootstrap script (run once on new machine) |
| `pixi.toml` | Pixi project dependencies |
| `templates/agent.yaml` | SkyPilot AWS agent template |

---

## Mise Tasks (CLI Commands)

Run these with `mise run <task>`:

| Task | Description |
|------|-------------|
| `mise run dashboard` | Launch unified TUI |
| `mise run validate` | Check environment health |
| `mise run help` | Show system manual |
| `mise run agent:up` | Launch AWS cloud agent |
| `mise run agent:down` | Stop cloud agent |
| `mise run setup-extensions` | Install GitHub Copilot extension |
| `mise run setup-mcp` | Configure mise MCP for Claude |
| `mise run setup-mac` | Configure macOS defaults (optional) |

---

## Installed Tools

### Core Runtimes
- `bun` - JavaScript/TypeScript runtime
- `pixi` - Conda-forge package manager
- `uv` - Fast pip replacement
- `chezmoi` - Dotfile manager
- `usage` - AI-powered CLI completions
- `pitchfork` - Development daemon manager

### Modern Rust Utilities
- `starship` - Cross-shell prompt
- `ripgrep` - Fast grep (rg)
- `fd-find` - Fast find (fd)
- `zoxide` - Smarter cd (z)
- `ast-grep` - Structural code search (AST-based)

### AI-Assisted Code Search
- `mgrep` - Semantic code search (2x fewer tokens for AI agents)

### AI Agents
- `claude-code` - Claude Code CLI
- `opencode-ai` - OpenCode terminal agent
- `gemini-cli` - Google Gemini CLI
- `github-cli` - GitHub CLI + Copilot

### Infrastructure
- `orbstack` - Docker replacement (<1% CPU)
- `skypilot` - AWS spot instance orchestrator
- `devpod` - DevContainer runner
- `infisical` / `1password-cli` - Secrets management

---

## Directory Automation

### Mise Hooks (Built-in)

Mise automatically activates environment and tools when entering directories:

```toml
# In project mise.toml
[hooks]
enter = "echo 'Entering project...'"
leave = "echo 'Leaving project...'"
```

### Pitchfork (Daemon Lifecycle)

For long-running services, use Pitchfork:

```toml
# In mise.toml
[tasks.dev]
run = "pitchfork start db redis"
```

| Feature | Behavior |
|---------|----------|
| **Start** | Auto-launches daemon when entering directory |
| **Stop** | Auto-stops when the *last* terminal session leaves |

---

## Development Patterns

### Installing a New Tool
```bash
# Always use mise, not brew/npm/pip directly
mise use -g <tool>

# For npm packages (uses Bun backend)
mise use -g "npm:<package>"

# For pip packages (via uv)
mise use -g "uv:<package>"

# For Homebrew casks (GUI apps only)
mise use -g "brew:<app>"

# For Cargo packages
mise use -g "cargo:<package>"
```

### Project-Level Tools
```bash
# In project directory
mise use python@3.12
mise use node@20
```

### Running Commands
```bash
# Prefer mise tasks
mise run validate
mise run dashboard

# Or use installed tools directly (mise shims them)
rg "pattern"
fd "filename"
z project-dir
sg "pattern"
```

---

## Secrets Management

### Option A: 1Password (Recommended)
```toml
# In mise config, use op:// URIs
[env]
ANTHROPIC_API_KEY = "op://Private/Anthropic/credential"
```

### Option B: Infisical
```bash
infisical run -- ./script.sh
```

### Option C: Mise Native Secrets
```bash
mise secrets set ANTHROPIC_API_KEY=sk-ant-...
```

---

## MCP Integration

This project includes mise MCP integration for Claude Desktop and Claude Code CLI.

### Setup
```bash
mise run setup-mcp
```

### What MCP Provides
- Query installed tools: "What version of Python is installed?"
- List tasks: "What mise tasks are available?"
- View env vars: "What environment variables are set?"
- Config info: "Show the mise configuration"

### AI Context Export
```bash
# Export environment context for AI agents
mise dump-context > mise-context.json
```

---

## Cloud Integration (SkyPilot)

Launch ephemeral AWS agents for heavy workloads:

```bash
# Launch cloud agent
mise run agent:up

# Check status
sky status

# Terminate
mise run agent:down
```

---

## Directory Structure

```
gemini-ai-macos-development-environment/
├── config/
│   ├── main.pkl           # Pkl configuration (generates TOML)
│   └── scripts/           # Task scripts
├── templates/
│   └── agent.yaml         # SkyPilot agent template
├── research/
│   ├── CHATGPT_DEEP_RESEARCH.md    # ChatGPT research report
│   ├── DEEP_RESEARCH_FINDINGS.md   # NotebookLM findings
│   ├── GAPS_ANALYSIS.md            # Gap analysis
│   └── ...                         # Additional research
├── .github/
│   └── workflows/
│       └── validate.yml   # CI validation
├── setup.sh               # Bootstrap script
├── pixi.toml              # Pixi dependencies
├── README.md              # User documentation
├── MANUAL.md              # System manual
├── PREFLIGHT_CHECKLIST.md # Pre-installation checklist
└── CLAUDE.md              # This file
```

---

## Best Practices

1. **Never use `sudo`** - Everything is user-space
2. **Never install globally with npm/pip** - Use mise
3. **Use mise tasks** - Instead of raw commands
4. **Check with `mise doctor`** - After any issues
5. **Run `mise run validate`** - Before reporting problems
6. **Use Pitchfork for daemons** - Not manual start/stop

---

## Troubleshooting

### "Command not found"
```bash
# Ensure mise is activated
eval "$(mise activate zsh)"

# Refresh shims
mise reshim
```

### "Wrong version being used"
```bash
# Check what mise sees
mise ls
mise where <tool>

# Trust the config
mise trust
```

### "Config not loading"
```bash
# Regenerate from Pkl
pkl eval -f toml config/main.pkl > ~/.config/mise/config.toml
mise install
```

### "Tool shows wrong version"
```bash
# Check for shadowing issues
mise run validate:tools

# Fix shadows (dry-run first)
mise run tools:fix-shadows

# Apply fixes
mise run tools:fix-shadows --force
```

| Issue | Cause | Solution |
|-------|-------|----------|
| Tool shows wrong version | Old binary in ~/.local/bin shadows mise | `mise run validate:tools` then `mise run tools:fix-shadows --force` |
| `mise which <tool>` says "not active" | Tool not in mise.toml or not in current dir | `mise use -g <tool>@latest` |
| Command not found after install | Shell needs refresh | `source ~/.zshrc` or restart terminal |

---

## Research Documentation

The `research/` directory contains deep research findings:

| Document | Description |
|----------|-------------|
| `CHATGPT_DEEP_RESEARCH.md` | Comprehensive ChatGPT research report |
| `DEEP_RESEARCH_FINDINGS.md` | NotebookLM analysis + YouTube findings |
| `GAPS_ANALYSIS.md` | Gap analysis and recommendations |
| `MISE_MCP_SETUP.md` | MCP integration guide |
| `AUTOMATION_DOCUMENTATION.md` | Automation patterns |

---

## Staying Updated

Track mise ecosystem releases:

- **RSS**: `https://github.com/jdx/mise/releases.atom`
- **Watch**: mise, pitchfork, uv, bun repos on GitHub
- **Community**: GitHub Discussions, Reddit, Hacker News

---

## Related Documentation

- [Mise Documentation](https://mise.jdx.dev/)
- [Mise MCP](https://mise.jdx.dev/mcp.html)
- [Pitchfork](https://github.com/jdx/pitchfork)
- [Pixi Documentation](https://pixi.sh/)
- [Uv Documentation](https://docs.astral.sh/uv/)
- [Bun Documentation](https://bun.sh/docs)

---

*Last updated: January 2026*
