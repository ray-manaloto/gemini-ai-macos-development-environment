# Architecture - God-Tier macOS Development Environment

**Last Updated**: 2026-01-31  
**Version**: 1.0  
**Status**: Active

---

## Table of Contents

1. [Overview](#overview)
2. [System Context](#system-context)
3. [Tool Hierarchy](#tool-hierarchy)
4. [Component Architecture](#component-architecture)
5. [Data Flow](#data-flow)
6. [Design Decisions](#design-decisions)
7. [Integration Points](#integration-points)
8. [Security Model](#security-model)
9. [Scalability Considerations](#scalability-considerations)

---

## Overview

This project implements a **mise-first development environment** for macOS with strict tool hierarchy, user-space isolation, and AI-first tooling. The architecture follows these core principles:

- **Single Orchestrator**: Mise manages ALL tools and versions
- **Strict Hierarchy**: Mise > Bun > Pixi > Uv (no exceptions)
- **User-Space Only**: Zero system modifications, everything in `~/.local`
- **Reproducible**: Pkl → TOML configuration pipeline
- **AI-Optimized**: MCP integration, 24 agents, 35 skills

### Key Characteristics

| Aspect | Implementation |
|--------|----------------|
| **Package Manager** | Mise (polyglot tool version manager) |
| **JavaScript Runtime** | Bun (replaces Node.js/npm) |
| **Binary Packages** | Pixi (conda-forge ecosystem) |
| **Python Packages** | Uv (10x faster than pip) |
| **Configuration** | Pkl → TOML (type-safe, compiled) |
| **Secrets** | 1Password CLI, Infisical, mise secrets |
| **Testing** | BATS (254 tests) |
| **AI Integration** | MCP servers, Claude Code, OpenCode |

---

## System Context

### C4 Level 1: System Context Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         macOS System                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                                                             │  │
│  │              God-Tier Development Environment               │  │
│  │                                                             │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │                                                       │  │  │
│  │  │                  MISE (Orchestrator)                  │  │  │
│  │  │                                                       │  │  │
│  │  │  • Manages all tool versions                         │  │  │
│  │  │  • Provides mise tasks (CLI commands)                │  │  │
│  │  │  • Handles environment variables per directory       │  │  │
│  │  │  • Integrates with AI via MCP                        │  │  │
│  │  │                                                       │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                                                             │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  External Systems:                                               │
│  • 1Password (secrets)                                           │
│  • Infisical (secrets)                                           │
│  • GitHub (code, releases)                                       │
│  • AWS (SkyPilot cloud agents)                                   │
│  • Claude Desktop (MCP client)                                   │
│  • VS Code / Zed / Cursor (editors)                              │
└─────────────────────────────────────────────────────────────────┘
```

### External Dependencies

| System | Purpose | Integration Method |
|--------|---------|-------------------|
| **1Password** | Secrets management | `op://` references in env vars |
| **Infisical** | Secrets management | `infisical run --` wrapper |
| **GitHub** | Tool releases, code hosting | `gh` CLI, `ubi:` backend |
| **AWS** | Cloud compute (SkyPilot) | AWS SDK, boto3 |
| **Claude Desktop** | AI assistance | MCP protocol |
| **Editors** | Development | LSP, extensions |

---

## Tool Hierarchy

### C4 Level 2: Container Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    MISE (Level 1: Orchestrator)                  │
│  • Rust-based, 10x faster than asdf                              │
│  • Native backends: npm, pip, cargo, ubi, pipx                   │
│  • Directory-based activation (.mise.toml, mise.toml)            │
│  • Task runner (mise tasks)                                      │
│  • MCP server for AI integration                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  Bun (Level 2)  │  │ Pixi (Level 3)  │  │  Uv (Level 4)   │ │
│  │                 │  │                 │  │                 │ │
│  │  JavaScript/TS  │  │ Binary Packages │  │ Python Packages │ │
│  │  Runtime        │  │ (conda-forge)   │  │ (pip compat)    │ │
│  │                 │  │                 │  │                 │ │
│  │  • 3x faster    │  │  • FFmpeg       │  │  • 10x faster   │ │
│  │  • Native TS    │  │  • CUDA         │  │  • Lockfiles    │ │
│  │  • npm compat   │  │  • Scientific   │  │  • Deterministic│ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                   │
│  Delegation Flow:                                                │
│  mise use -g "npm:pkg"  → Bun installs package                   │
│  mise use -g "pipx:pkg" → Uv installs in isolated venv           │
│  pixi add pkg           → Pixi installs from conda-forge         │
└─────────────────────────────────────────────────────────────────┘
```

### Hierarchy Rules

1. **Mise is the ONLY entry point** - Never bypass with `npm -g`, `pip install`, `brew install`
2. **Bun handles JavaScript** - Mise redirects `npm` → `bun` automatically
3. **Pixi handles binaries** - For packages needing compiled dependencies
4. **Uv handles Python** - Mise redirects `pip` → `uv` automatically

### Backend Selection Logic

```
User runs: mise use -g <tool>
                ↓
Mise determines backend:
  • "npm:<pkg>"   → npm backend → Bun
  • "pipx:<pkg>"  → pipx backend → Uv
  • "ubi:<repo>"  → ubi backend → GitHub releases
  • "cargo:<pkg>" → cargo backend → Rust crates
  • "<tool>"      → core backend → Mise registry
                ↓
Tool installed to: ~/.local/share/mise/installs/<backend>/<tool>/<version>
                ↓
Symlinked to: ~/.local/share/mise/shims/<tool>
                ↓
Available in PATH via: eval "$(mise activate zsh)"
```

---

## Component Architecture

### C4 Level 3: Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Mise Core                                │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Registry   │  │   Backends   │  │    Tasks     │          │
│  │              │  │              │  │              │          │
│  │  • Tools DB  │  │  • npm       │  │  • validate  │          │
│  │  • Versions  │  │  • pipx      │  │  • dashboard │          │
│  │  • Metadata  │  │  • cargo     │  │  • agent:*   │          │
│  └──────────────┘  │  • ubi       │  │  • setup-*   │          │
│                    │  • core      │  └──────────────┘          │
│                    └──────────────┘                             │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Config     │  │   Shims      │  │     MCP      │          │
│  │              │  │              │  │              │          │
│  │  • mise.toml │  │  • PATH      │  │  • Server    │          │
│  │  • .env      │  │  • Symlinks  │  │  • Tools     │          │
│  │  • Secrets   │  │  • Activation│  │  • Resources │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      Supporting Components                        │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Chezmoi    │  │  Starship    │  │  Pitchfork   │          │
│  │              │  │              │  │              │          │
│  │  • Dotfiles  │  │  • Prompt    │  │  • Daemons   │          │
│  │  • Templates │  │  • Modules   │  │  • Auto-start│          │
│  │  • Encryption│  │  • Git info  │  │  • Auto-stop │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │     Pkl      │  │     BATS     │  │   SkyPilot   │          │
│  │              │  │              │  │              │          │
│  │  • Config    │  │  • Tests     │  │  • Cloud     │          │
│  │  • Type-safe │  │  • 254 tests │  │  • AWS Spot  │          │
│  │  • Generate  │  │  • CI/CD     │  │  • Agents    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Key Files |
|-----------|----------------|-----------|
| **Mise Registry** | Tool discovery, version resolution | `~/.local/share/mise/registry.toml` |
| **Mise Backends** | Tool installation delegation | `~/.local/share/mise/installs/` |
| **Mise Tasks** | CLI command orchestration | `config/mise.toml` `[tasks]` |
| **Mise Config** | Tool versions, env vars, settings | `config/mise.toml`, `.mise.toml` |
| **Mise Shims** | PATH management, activation | `~/.local/share/mise/shims/` |
| **Mise MCP** | AI integration (Claude Desktop) | `config/scripts/setup-mcp.sh` |
| **Chezmoi** | Dotfile management | `config/chezmoi/` |
| **Starship** | Shell prompt | `config/starship.toml` |
| **Pitchfork** | Development daemon manager | `.pitchfork.toml` |
| **Pkl** | Type-safe config generation | `config/main.pkl` |
| **BATS** | Test suite | `tests/*.bats` |
| **SkyPilot** | Cloud agent orchestration | `templates/agent.yaml` |

---

## Data Flow

### Tool Installation Flow

```
1. User Request
   mise use -g "npm:typescript"
        ↓
2. Mise Core
   • Parse backend: "npm"
   • Resolve version: "latest" → "5.3.3"
   • Check cache: ~/.local/share/mise/downloads/
        ↓
3. Backend Delegation
   npm backend → Bun
   • bun install -g typescript@5.3.3
   • Install to: ~/.local/share/mise/installs/npm/typescript/5.3.3/
        ↓
4. Shim Creation
   • Create symlink: ~/.local/share/mise/shims/tsc
   • Points to: ~/.local/share/mise/installs/npm/typescript/5.3.3/bin/tsc
        ↓
5. Activation
   • eval "$(mise activate zsh)"
   • Adds ~/.local/share/mise/shims to PATH
        ↓
6. Usage
   tsc --version
   → Executes via shim → Actual binary
```

### Configuration Flow

```
1. Source Configuration (Pkl)
   config/main.pkl
        ↓
2. Compilation
   pkl eval -f toml config/main.pkl > config/mise.toml
        ↓
3. Deployment
   cp config/mise.toml ~/.config/mise/config.toml
        ↓
4. Activation
   cd <project-dir>
   → Mise detects .mise.toml or mise.toml
   → Loads tools, env vars, tasks
        ↓
5. Runtime
   mise run validate
   → Executes task from [tasks.validate]
```

### MCP Integration Flow

```
1. Claude Desktop Startup
   Reads: ~/Library/Application Support/Claude/claude_desktop_config.json
        ↓
2. MCP Server Launch
   Starts: mise mcp
   • Exposes tools: mise_list, mise_install, mise_run
   • Exposes resources: mise.toml, installed tools
        ↓
3. AI Query
   "What version of Python is installed?"
        ↓
4. MCP Request
   Claude → mise_list tool → Mise
        ↓
5. Response
   Mise → Python 3.12.1 → Claude
        ↓
6. AI Response
   "You have Python 3.12.1 installed via mise."
```

---

## Design Decisions

### Why Mise over asdf?

| Criterion | Mise | asdf |
|-----------|------|------|
| **Performance** | Rust-based, 10x faster | Shell-based, slow |
| **Backends** | Native (npm, pip, cargo, ubi) | Plugins (inconsistent) |
| **Tasks** | Built-in task runner | Requires external tools |
| **MCP** | Native MCP server | No AI integration |
| **Maintenance** | Single binary | 100+ plugins to maintain |

**Decision**: Mise provides superior performance, native backends, and AI integration.

### Why Bun over Node.js?

| Criterion | Bun | Node.js |
|-----------|-----|---------|
| **Install Speed** | 3x faster | Baseline |
| **TypeScript** | Native support | Requires ts-node |
| **npm Compatibility** | 100% compatible | N/A |
| **Bundle Size** | Single binary | Multiple binaries |
| **Performance** | Faster startup | Slower |

**Decision**: Bun offers faster installs, native TypeScript, and full npm compatibility.

### Why Uv over pip?

| Criterion | Uv | pip |
|-----------|-----|-----|
| **Resolution Speed** | 10x faster | Baseline |
| **Lockfiles** | Deterministic | Requires pip-tools |
| **Compatibility** | 100% pip-compatible | N/A |
| **Caching** | Aggressive caching | Limited caching |

**Decision**: Uv provides 10x faster resolution with deterministic lockfiles.

### Why Pixi for Binary Packages?

| Criterion | Pixi | Homebrew |
|-----------|------|----------|
| **Isolation** | Per-project environments | Global installs |
| **Reproducibility** | Lockfiles (pixi.lock) | No lockfiles |
| **Ecosystem** | conda-forge (20K+ packages) | Homebrew (6K+ packages) |
| **User-space** | ~/.pixi | /usr/local (requires sudo) |

**Decision**: Pixi provides isolated, reproducible binary packages without sudo.

### Why User-Space Only?

**Rationale**:
1. **Reproducibility**: No system state dependencies
2. **Safety**: No risk of breaking system tools
3. **Portability**: Works on any macOS without admin access
4. **Isolation**: Multiple environments on same machine
5. **Cleanup**: `rm -rf ~/.local` removes everything

**Trade-off**: Larger disk usage (~10GB) vs. system-wide installs.

### Why Pkl for Configuration?

| Criterion | Pkl | TOML | YAML |
|-----------|-----|------|------|
| **Type Safety** | ✅ Compile-time | ❌ Runtime | ❌ Runtime |
| **Validation** | ✅ Built-in | ❌ Manual | ❌ Manual |
| **Generation** | ✅ Multiple formats | ❌ Static | ❌ Static |
| **IDE Support** | ✅ LSP | ✅ Basic | ✅ Basic |

**Decision**: Pkl provides type-safe configuration with compile-time validation.

---

## Integration Points

### MCP (Model Context Protocol)

**Purpose**: Enable AI assistants to query and control the development environment.

**Architecture**:
```
Claude Desktop
    ↓ (stdio)
Mise MCP Server
    ↓ (CLI)
Mise Core
    ↓
Tools, Tasks, Config
```

**Capabilities**:
- Query installed tools: `mise_list`
- Install tools: `mise_install`
- Run tasks: `mise_run`
- Read config: `mise.toml` resource

**Setup**: `mise run setup-mcp`

### Pitchfork (Development Daemons)

**Purpose**: Auto-start/stop services when entering/leaving project directories.

**Architecture**:
```
cd <project-dir>
    ↓
Mise activation hook
    ↓
Pitchfork detects .pitchfork.toml
    ↓
Starts daemons (postgres, redis, etc.)
    ↓
cd ~
    ↓
Pitchfork stops daemons (if no other sessions)
```

**Use Cases**:
- Database servers (PostgreSQL, MySQL)
- Cache servers (Redis, Memcached)
- Dev servers (Vite, Next.js)
- File watchers (Tailwind, TypeScript)

### Chezmoi (Dotfile Management)

**Purpose**: Manage dotfiles with templates and encryption.

**Architecture**:
```
config/chezmoi/*.tmpl
    ↓
chezmoi apply
    ↓
~/.zshrc, ~/.gitconfig, etc.
```

**Features**:
- Templates with variables
- Encryption for secrets
- Cross-machine sync
- Conditional sections

### SkyPilot (Cloud Agents)

**Purpose**: Launch ephemeral cloud agents on AWS for heavy workloads.

**Architecture**:
```
mise run agent:up
    ↓
SkyPilot
    ↓
AWS EC2 Spot Instance
    ↓
Agent runs tasks
    ↓
mise run agent:down
    ↓
Instance terminated
```

**Use Cases**:
- Large model training
- Batch processing
- CI/CD runners
- Parallel testing

---

## Security Model

### Secrets Management

**Hierarchy** (in order of preference):
1. **1Password CLI**: `op://Private/Service/credential`
2. **Infisical**: `infisical run -- command`
3. **Mise Secrets**: `mise secrets set KEY=value`
4. **Environment Variables**: `.env` (gitignored)

**Never Commit**:
- `.env` files
- API keys
- Credentials
- Private keys

### User-Space Isolation

**Principle**: All tools install to `~/.local`, never `/usr/local` or `/opt`.

**Benefits**:
- No sudo required
- No system modification
- Easy cleanup (`rm -rf ~/.local`)
- Multiple environments per user

**Directories**:
```
~/.local/
├── bin/           # Symlinks to mise shims
├── share/mise/    # Mise data
│   ├── installs/  # Tool installations
│   ├── shims/     # Tool shims
│   └── downloads/ # Download cache
└── state/         # Runtime state
```

### Network Security

**Outbound Connections**:
- GitHub (tool downloads)
- npm registry (Bun packages)
- PyPI (Uv packages)
- conda-forge (Pixi packages)
- AWS (SkyPilot)

**No Inbound Connections**: All tools run locally, no exposed ports.

---

## Scalability Considerations

### Tool Count

**Current**: ~50 tools  
**Capacity**: 500+ tools (mise registry has 1000+)  
**Bottleneck**: Disk space (~200MB per tool average)

### Task Complexity

**Current**: 20 mise tasks  
**Capacity**: Unlimited (tasks are just shell scripts)  
**Bottleneck**: Task interdependencies (use `depends = [...]`)

### Multi-Project Support

**Strategy**: Directory-based activation with `.mise.toml`

```
~/projects/
├── project-a/
│   └── .mise.toml  # Python 3.11, Node 18
├── project-b/
│   └── .mise.toml  # Python 3.12, Node 20
└── project-c/
    └── .mise.toml  # Python 3.10, Bun latest
```

**Isolation**: Each project has independent tool versions.

### Cloud Scaling

**SkyPilot** enables horizontal scaling:
- Launch multiple agents in parallel
- Distribute workloads across instances
- Auto-terminate when done

**Cost Optimization**:
- Use spot instances (70% cheaper)
- Auto-stop after idle timeout
- Regional selection for lowest cost

---

## Appendix

### Key Files Reference

| File | Purpose |
|------|---------|
| `config/mise.toml` | Tool versions, tasks, settings (SOURCE OF TRUTH) |
| `config/main.pkl` | Pkl source for mise.toml |
| `config/starship.toml` | Shell prompt configuration |
| `config/chezmoi/` | Dotfile templates |
| `tests/*.bats` | Test suite (254 tests) |
| `setup.sh` | Bootstrap script |
| `AGENTS.md` | Project knowledge base |
| `CLAUDE.md` | AI assistant context |
| `README.md` | User documentation |

### External Resources

- [Mise Documentation](https://mise.jdx.dev/)
- [Bun Documentation](https://bun.sh/)
- [Uv Documentation](https://docs.astral.sh/uv/)
- [Pixi Documentation](https://pixi.sh/)
- [Pkl Documentation](https://pkl-lang.org/)
- [SkyPilot Documentation](https://skypilot.readthedocs.io/)

---

**Document Version**: 1.0  
**Last Review**: 2026-01-31  
**Next Review**: 2026-04-30
