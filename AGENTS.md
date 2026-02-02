# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-26
**Branch:** main

---

## FOR LLM AGENTS

### Quick Identity

| Field | Value |
|-------|-------|
| **Project** | God-Tier macOS Development Environment |
| **Core Principle** | Mise-first orchestration |
| **Hierarchy** | Mise > Bun > Pixi > Uv |
| **Location** | User-space only (~/.local, ~/.config) |
| **System Mods** | Zero sudo, zero Homebrew (except GUI apps) |

### Navigation Map

| I want to... | Go to... | Key info |
|--------------|----------|----------|
| Understand project philosophy | CLAUDE.md | Tool hierarchy, patterns, troubleshooting |
| Install everything | setup.sh | Run once, handles all tools |
| Add/modify tools | config/mise.toml | Tools, tasks, settings |
| Run tests | tests/*.bats | 254 BATS tests, `bats tests/` |
| Validate environment | `mise run validate` | Health check script |
| Configure dotfiles | config/chezmoi/ | Templates for .zshrc, .gitconfig |
| Configure shell prompt | config/starship.toml | Starship prompt modules |
| View system manual | `mise run help` | Opens MANUAL.md in pager |
| See project plan | PROJECT_PLAN.md | Sprints, user stories, backlog |
| Find research docs | research/ | 12 deep-dive documents |
| Use OpenSpec workflow | .claude/, .gemini/, .opencode/, .cursor/ | 10 commands each |
| Manage secrets | SECRETS.md, .env.example | 1Password, Infisical, mise secrets |
| Migrate from other tools | MIGRATION.md | nvm, pyenv, asdf migration guide |
| Use cloud agents | SKYPILOT.md, templates/agent.yaml | SkyPilot AWS spot instances |
| Uninstall environment | uninstall.sh | Interactive with --dry-run, --force |

### Critical Rules (NEVER BREAK)

1. **NEVER use sudo** - Everything is user-space
2. **NEVER install globally with npm/pip** - Use mise (`mise use -g`)
3. **NEVER modify system Python/Node** - Mise manages versions
4. **NEVER commit secrets** - Use op://, infisical, or mise secrets
5. **NEVER suppress type errors** - No `as any`, `@ts-ignore`
6. **ALWAYS use mise tasks** - Not raw commands (`mise run validate`)
7. **ALWAYS run tests before committing** - `bats tests/`
8. **ALWAYS check mise doctor after issues** - `mise doctor`
9. **PREFER existing patterns** - Check existing code first
10. **ASK if uncertain about scope** - Don't assume
11. **ALWAYS install CLI tools via mise** - Never `curl | sh`, `npm -g`, or direct downloads
    - Install: `mise use -g <tool>@latest`
    - Check: `mise which <tool>` should point to mise installs
    - Fix: `mise run validate:tools` to detect shadows

---

## OVERVIEW

A reproducible macOS development environment using Mise as the central orchestrator. The strict tool hierarchy ensures predictable package resolution:

```
MISE (Orchestrator)
├── Bun (JavaScript/TypeScript) - replaces Node/npm
├── Pixi (Binary packages) - conda-forge ecosystem
└── Uv (Python packages) - 10x faster than pip
```

All tools install to `~/.local` with zero system modifications.

---

## STRUCTURE

```
gemini-ai-macos-development-environment/
├── config/
│   ├── mise.toml              # Tool versions, tasks, settings (SOURCE OF TRUTH)
│   ├── main.pkl               # Pkl config (generates TOML)
│   ├── starship.toml          # Shell prompt configuration
│   ├── chezmoi/               # Dotfile templates
│   │   ├── dot_zshrc.tmpl     # Zsh config template
│   │   ├── dot_gitconfig.tmpl # Git config template
│   │   └── .chezmoi.toml.tmpl # Chezmoi config
│   └── scripts/               # Utility scripts
│       ├── validate.sh        # Environment health check
│       ├── dashboard.py       # TUI dashboard (requires pixi)
│       ├── macos-defaults.sh  # macOS system defaults
│       └── setup-mcp.sh       # MCP configuration
├── tests/                     # BATS test suite (254 tests)
│   ├── test_mise.bats         # Mise installation, backends
│   ├── test_tools.bats        # CLI tool availability
│   ├── test_chezmoi.bats      # Dotfile template validation
│   ├── test_starship.bats     # Prompt configuration
│   ├── test_integration.bats  # End-to-end tests
│   ├── test_ide_configs.bats  # IDE/editor configuration tests
│   └── test_skypilot.bats     # SkyPilot cloud agent tests
├── research/                  # 12 research documents
│   ├── CHATGPT_DEEP_RESEARCH.md
│   ├── GAPS_ANALYSIS.md
│   └── MISE_MCP_SETUP.md
├── openspec/                  # Specifications
│   ├── specs/                 # Active specs
│   │   └── tool-management/   # Tool requirements
│   └── changes/archive/       # Archived changes
├── templates/
│   └── agent.yaml             # SkyPilot AWS agent
├── .claude/                   # Claude Code config (10 commands, 25 skills, 24 agents)
├── .gemini/                   # Gemini CLI config (10 commands, 10 skills)
├── .opencode/                 # OpenCode config (10 commands, 25 skills, 24 agents)
├── .cursor/                   # Cursor config (10 commands)
├── .vscode/                   # VS Code settings, extensions
├── .zed/                      # Zed editor settings
├── .devcontainer/             # DevContainer for DevPod/Codespaces
├── setup.sh                   # Bootstrap script (run once)
├── uninstall.sh               # Interactive uninstall with backup
├── pixi.toml                  # Pixi project dependencies
├── .env.example               # Environment variables template
├── README.md                  # User documentation
├── CLAUDE.md                  # AI assistant context
├── AGENTS.md                  # This file
├── PROJECT_PLAN.md            # Agile project plan
├── MANUAL.md                  # System manual
├── SECRETS.md                 # Secrets management guide
├── MIGRATION.md               # Migration from nvm/pyenv/asdf
└── SKYPILOT.md                # Cloud agent documentation
```

---

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add new tool | config/mise.toml `[tools]` | Use `mise use -g <tool>` |
| Add npm package | config/mise.toml | `"npm:<package>" = "latest"` |
| Add pip package | config/mise.toml | `"pipx:<package>" = "latest"` |
| Add mise task | config/mise.toml `[tasks]` | Follow existing patterns |
| Fix environment | config/scripts/validate.sh | Health check |
| Debug issues | `mise doctor` | Comprehensive diagnostics |
| Add test | tests/test_*.bats | One test per feature |
| Add dotfile | config/chezmoi/ | Use .tmpl extension |
| Configure prompt | config/starship.toml | Module-based config |
| Read specs | openspec/specs/ | Gherkin-style requirements |
| Find research | research/*.md | Background documentation |

---

## TOOL HIERARCHY

### Level 1: Mise (Orchestrator)

Mise manages ALL tools through a unified interface:

```toml
[settings]
experimental = true
not_found_auto_install = true

[settings.npm]
bun = true
package_manager = "bun"

[settings.python]
uv_venv_auto = true
```

### Level 2: Bun (JavaScript/TypeScript)

Replaces Node.js and npm. Mise redirects automatically:
- `npm install` → `bun install`
- `node script.js` → `bun script.js`
- 3x faster package installation

### Level 3: Pixi (Binary Packages)

For conda-forge packages that need binary dependencies:
- FFmpeg, CUDA, scientific Python
- Isolated from system libraries
- Lockfile-based (`pixi.lock`)

### Level 4: Uv (Python Packages)

Fast pip replacement:
- 10x faster package resolution
- Deterministic lockfiles
- Mise redirects: `pip install` → `uv pip install`

---

## DEVELOPMENT COMMANDS

### Mise Tasks

| Command | Description |
|---------|-------------|
| `mise run dashboard` | Launch TUI manager |
| `mise run validate` | Check environment health |
| `mise run help` | Show system manual |
| `mise run agent:check` | Verify AWS credentials |
| `mise run agent:up` | Launch AWS cloud agent |
| `mise run agent:down` | Terminate cloud agent |
| `mise run agent:status` | Show cloud agent status |
| `mise run agent:stop` | Stop agent (preserves instance) - Note: Spot instances cannot be stopped |
| `mise run agent:start` | Start stopped agent - Note: Spot instances cannot be stopped/restarted |
| `mise run agent:restart` | Restart cloud agent - Note: Spot instances cannot be stopped |
| `mise run agent:ssh` | SSH into cloud agent |
| `mise run agent:logs` | View cloud agent logs |
| `mise run agent:exec` | Execute command on agent |
| `mise run setup-mac` | Configure macOS defaults |
| `mise run setup-mcp` | Configure mise MCP for Claude |
| `mise run setup-extensions` | Install GitHub Copilot extension |
| `mise run setup:auto` | Auto-detect platform, run appropriate setup |
| `mise run setup:macos` | macOS-specific setup |
| `mise run setup:container` | Container/DevPod setup |
| `mise run setup:linux` | Linux (non-container) setup |
| `mise run validate:rules` | Check for anti-patterns and rule violations |

### Tool Management Tasks

| Command | Description |
|---------|-------------|
| `mise run tools:status` | Show all tools and settings |
| `mise run tools:install` | Install all configured tools |
| `mise run tools:update` | Update all tools to latest |
| `mise run tools:uninstall -- <tool>` | Uninstall specific tool |
| `mise run tools:reinstall -- <tool>` | Reinstall specific tool |
| `mise run tools:doctor` | Full environment health check |

### DevContainer Tasks

| Command | Description |
|---------|-------------|
| `mise run devcontainer:status` | Show DevContainer status |
| `mise run devcontainer:up` | Start DevContainer (DevPod or Docker) |
| `mise run devcontainer:down` | Stop DevContainer |
| `mise run devcontainer:restart` | Restart DevContainer |
| `mise run devcontainer:ssh` | SSH into container |
| `mise run devcontainer:logs` | View container logs |
| `mise run devcontainer:exec -- <cmd>` | Execute command in container |
| `mise run devcontainer:build` | Build DevContainer image |
| `mise run devcontainer:rebuild` | Rebuild without cache |
| `mise run devcontainer:delete` | Delete container and volumes |

### Testing

```bash
bats tests/                    # Run all 254 tests
bats tests/test_mise.bats      # Run specific test file
mise run validate              # Quick health check
mise doctor                    # Mise diagnostics
```

---

## CONVENTIONS

### Tool Installation

```bash
mise use -g <tool>             # Install globally via mise
mise use -g "npm:<package>"    # npm package (via Bun)
mise use -g "pipx:<package>"   # pip package (via uv)
mise use -g "ubi:<owner/repo>" # GitHub release binary
mise use -g "cargo:<package>"  # Rust package
```

### File Patterns

| Pattern | Convention |
|---------|------------|
| Config files | TOML preferred (mise.toml, starship.toml) |
| Templates | `.tmpl` suffix (dot_zshrc.tmpl) |
| Tests | `test_*.bats` in tests/ |
| Scripts | `.sh` for bash, `.py` for Python |
| Documentation | `.md` in root or research/ |

### Code Style

- Shell scripts: POSIX-compatible when possible
- Python: Follow existing patterns in scripts/
- TOML: Use comments for sections, keep related items together
- Markdown: Follow existing heading structure

---

## ANTI-PATTERNS

| Category | Forbidden | Why |
|----------|-----------|-----|
| Package Management | `npm install -g`, `pip install` | Use mise, not direct installs |
| System Modification | `sudo`, `/usr/local/` | User-space only |
| Type Safety | `as any`, `@ts-ignore` | Fix the types properly |
| Error Handling | Empty catch blocks | Always handle errors |
| Testing | Deleting failing tests | Fix the code, not the tests |
| Secrets | Committing .env, API keys | Use op://, infisical, or mise secrets |
| Homebrew | `brew install` for CLI tools | mise manages CLI tools |

---

## TOOL INSTALLATION

### How to Install CLI Tools

| Method | Use For | Example |
|--------|---------|---------|
| `mise use -g <tool>` | CLI binaries | `mise use -g opencode@latest` |
| `mise use -g "npm:<pkg>"` | npm packages | `mise use -g "npm:typescript"` |
| `mise use -g "pipx:<pkg>"` | Python CLIs | `mise use -g "pipx:poetry"` |
| `mise use -g "ubi:<repo>"` | GitHub releases | `mise use -g "ubi:charmbracelet/gum"` |

### Common Mistakes (AI Agents: AVOID These)

| Wrong Way | Why It's Bad | Right Way |
|-----------|--------------|-----------|
| `curl -fsSL ... \| sh` | Installs to ~/.local/bin, shadows mise | `mise use -g <tool>` |
| `npm install -g <pkg>` | Bypasses mise, version conflicts | `mise use -g "npm:<pkg>"` |
| `pip install <pkg>` | System Python pollution | `mise use -g "pipx:<pkg>"` |

### Detecting Shadow Issues

```bash
mise run validate:tools    # Check for shadowing
mise which <tool>          # Should show mise path
which -a <tool>            # Shows all locations
```

---

## TESTING

### Test Files (254 tests total)

| File | Coverage |
|------|----------|
| test_mise.bats | Mise installation, backends, tasks |
| test_tools.bats | All CLI tool availability |
| test_chezmoi.bats | Dotfile template validation |
| test_starship.bats | Prompt configuration |
| test_integration.bats | End-to-end project structure |
| test_ide_configs.bats | VS Code, Zed, DevContainer, uninstall.sh |
| test_skypilot.bats | SkyPilot, AWS configuration, agent tasks |
| test_unified_setup.bats | Platform tasks, config_root, DevContainer |
| test_env_status.bats | env:status task output validation |
| test_noninteractive_skills.bats | OpenCode skill validation |
| test_setup.bats | Bootstrap script validation, spec compliance |

### Running Tests

```bash
# Ensure mise is activated
eval "$(mise activate bash --shims)"

# Run all tests
bats tests/

# Run specific file
bats tests/test_mise.bats
```

### Writing New Tests

When adding tests, follow these conventions:

```bash
#!/usr/bin/env bats
# test_<feature>.bats - Description of test file
# Run with: bats tests/test_<feature>.bats

# Setup runs before each test
setup() {
  if ! command -v <required_tool> &> /dev/null; then
    skip "<required_tool> not installed"
  fi
}

# Use section comments for organization
# =============================================================================
# Section Name
# =============================================================================

@test "descriptive test name in present tense" {
  run <command>
  [ "$status" -eq 0 ]
  [[ "$output" =~ "expected pattern" ]]
}
```

**BATS Conventions:**
| Convention | Example |
|------------|---------|
| File naming | `test_<feature>.bats` |
| Test naming | Present tense, descriptive (`"mise has bun installed"`) |
| Skip condition | Use `skip "reason"` in setup() |
| Status check | `[ "$status" -eq 0 ]` |
| Output check | `[[ "$output" =~ "pattern" ]]` |
| File exists | `[ -f "path/to/file" ]` |
| Dir exists | `[ -d "path/to/dir" ]` |
| Executable | `[ -x "path/to/script" ]` |
| Has content | `[ -s "path/to/file" ]` (non-empty) |

---

## CONFIGURATION

### Config Flow

```
config/main.pkl (Pkl source)
    ↓ pkl eval -f toml
config/mise.toml (Generated TOML)
    ↓ cp to ~/.config/mise/
~/.config/mise/config.toml (Active config)
```

### Key Settings

```toml
[settings]
experimental = true
not_found_auto_install = true

[settings.npm]
bun = true                    # npm → bun
package_manager = "bun"

[settings.python]
uv_venv_auto = true           # pip → uv
```

---

## AI AGENT COMMANDS

### Available Platforms

| Platform | Config Location | Command Prefix |
|----------|-----------------|----------------|
| Claude | .claude/commands/opsx/ | `/opsx:` |
| Gemini | .gemini/commands/opsx/ | `@opsx:` |
| OpenCode | .opencode/command/ | `/opsx-` |
| Cursor | .cursor/commands/opsx/ | `/opsx:` |

### OpenSpec Workflow Commands

Each platform has 10 commands for the OpenSpec workflow:

| Command | Purpose |
|---------|---------|
| explore | Think and investigate without making changes |
| new | Create a new OpenSpec change |
| ff | Fast-forward to tasks (skip proposal/design) |
| apply | Apply change to codebase |
| continue | Continue working on existing change |
| verify | Verify change completeness |
| archive | Archive completed change |
| bulk-archive | Archive multiple changes |
| sync | Sync specs with changes |
| onboard | Onboard new OpenSpec project |

---

## OPENSPEC WORKFLOW

### Creating a Change

```bash
openspec new change "feature-name" --description "Description"
```

### Change Structure

```
openspec/changes/<change-name>/
├── .openspec.yaml     # Change metadata
├── proposal.md        # WHY: Problem and solution
├── design.md          # HOW: Architecture
├── specs/             # WHAT: Requirements with scenarios
│   └── capability/
│       └── spec.md
└── tasks.md           # Backlog items
```

### Validation

```bash
openspec status --change <name>    # Check artifact completion
openspec validate <name>           # Validate format
openspec archive <name>            # Archive when complete
```

---

## SECRETS MANAGEMENT

### Options

1. **1Password** (Recommended)
   ```toml
   [env]
   ANTHROPIC_API_KEY = "op://Private/Anthropic/credential"
   ```

2. **Infisical**
   ```bash
   infisical run -- ./script.sh
   ```

3. **Mise Native**
   ```bash
   mise secrets set ANTHROPIC_API_KEY=sk-ant-...
   ```

---

## FOR HUMANS

### Quick Start

```bash
# Clone and setup
cd ~/dev/github/ray-manaloto/gemini-ai-macos-development-environment
./setup.sh

# Restart terminal, then verify
mise doctor
bats tests/
```

### Daily Usage

```bash
# Update tools
mise run tools:update

# Check health
mise run validate

# View manual
mise run help
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Command not found | `eval "$(mise activate zsh)"` then `mise reshim` |
| Wrong version | `mise ls` then `mise trust` |
| Config not loading | Copy config: `cp config/mise.toml ~/.config/mise/config.toml` |

---

## EXTERNAL SKILLS & AGENTS

This project includes external skills and agents from [samhvw8/dotfiles](https://github.com/samhvw8/dotfiles) for enhanced AI-assisted development.

### Skills (25 total)

Located in `.opencode/skills-external/` and `.claude/skills-external/`:

| Category | Skills |
|----------|--------|
| **Core/Meta** | `0-claude`, `0-planning`, `0-prompt-architect`, `0-research`, `0-sequential-thinking` |
| **Development** | `backend-development`, `frontend-development`, `databases`, `code-quality`, `git-workflow` |
| **Infrastructure** | `infra-engineer`, `mise-expert` |
| **Specialized** | `3d-graphics`, `ai-tools`, `browser-history`, `canvas-design`, `chrome-devtools`, `docs-discovery`, `media-processing`, `mobile-development`, `nextjs-turborepo`, `payment-integration`, `problem-solving`, `repomix`, `shopify` |

**Key Skill: `mise-expert`** - Directly relevant for this project. Provides expertise on:
- Tool & runtime management (node, python, go, ruby, rust)
- Project setup & onboarding with mise.toml
- Task runner & build systems
- Environment management
- CI/CD integration

### Agents (24 total)

Located in `.opencode/agents-external/` and `.claude/agents-external/`:

| Category | Agents |
|----------|--------|
| **Architecture** | `system-architect`, `react-next-architect`, `svelte-kit-architect`, `devops-architect` |
| **Code Quality** | `code-reviewer`, `refactoring-expert`, `quality-engineer`, `security-engineer` |
| **Development** | `python-expert`, `database-admin` |
| **Research/Planning** | `researcher`, `planner`, `requirements-analyst`, `brainstormer`, `scout` |
| **Documentation** | `docs-manager`, `copywriter`, `journal-writer` |
| **Testing** | `tester`, `debugger` |
| **Other** | `ui-ux-designer`, `project-manager`, `learning-guide`, `mcp-manager` |

### Project Configuration

The project-level config is at `.opencode/oh-my-opencode.json`:

```json
{
  "agents": {
    "explorer": { "model": "anthropic/claude-sonnet-4-20250514" },
    "reviewer": { "model": "anthropic/claude-sonnet-4-20250514" }
  },
  "categories": {
    "visual-engineering": { "model": "anthropic/claude-sonnet-4-20250514" },
    "ultrabrain": { "model": "anthropic/claude-opus-4-5-20250514" },
    "quick": { "model": "anthropic/claude-sonnet-4-20250514" }
  }
}
```

### Source Attribution

Skills and agents sourced from [samhvw8/dotfiles](https://github.com/samhvw8/dotfiles), which provides:
- Delegation Protocol (Task vs Skill distinction, DGE Loop)
- Model Routing with Gemini proxy
- MCP Integration (context7, chrome-mcp-server)
- Session management hooks

---

## NOTES

### Design Decisions

1. **Mise over asdf** - Rust-based (10x faster), native backends
2. **Bun over Node** - 3x faster installs, native TypeScript
3. **Uv over pip** - 10x faster resolution, deterministic
4. **BATS for testing** - Native bash, no dependencies
5. **Chezmoi over stow** - Better templating, encryption

### Dependencies

- macOS 14+ (Sonoma)
- Xcode Command Line Tools
- ~10GB disk space

### Resources

- [Mise Documentation](https://mise.jdx.dev/)
- [Bun Documentation](https://bun.sh/)
- [Uv Documentation](https://docs.astral.sh/uv/)
- [Pixi Documentation](https://pixi.sh/)
