# Mise Ecosystem Research

Research on mise-based development environment setups, UI/dashboard tools, alternatives, and community resources.

**Last Updated:** February 2026  
**Research Iterations:** 3

---

## Quick Links

### Official Documentation

| Page | URL | Notes |
|------|-----|-------|
| **Homepage** | https://mise.jdx.dev/ | Main docs entry |
| **Getting Started** | https://mise.jdx.dev/getting-started.html | Installation & setup |
| **Configuration** | https://mise.jdx.dev/configuration.html | mise.toml reference |
| **MCP Integration** | https://mise.jdx.dev/mcp.html | Model Context Protocol |
| **Tips & Tricks** | https://mise.jdx.dev/tips-and-tricks.html | Power user patterns |
| **External Resources** | https://mise.jdx.dev/external-resources.html | Community links |

### Dev Tools Documentation

| Page | URL | Notes |
|------|-----|-------|
| **Dev Tools Overview** | https://mise.jdx.dev/dev-tools/ | Core concept |
| **Backends Overview** | https://mise.jdx.dev/dev-tools/backends/ | aqua, asdf, cargo, etc. |
| **Shims** | https://mise.jdx.dev/dev-tools/shims.html | PATH vs shims |
| **Aliases** | https://mise.jdx.dev/dev-tools/aliases.html | Version aliases |
| **Comparison to asdf** | https://mise.jdx.dev/dev-tools/comparison-to-asdf.html | Migration guide |

### Environments Documentation

| Page | URL | Notes |
|------|-----|-------|
| **Environments Overview** | https://mise.jdx.dev/environments/ | Core concept |
| **Secrets** | https://mise.jdx.dev/environments/secrets.html | `mise secrets` |
| **Profiles** | https://mise.jdx.dev/environments/profiles.html | Development/production |
| **direnv** | https://mise.jdx.dev/environments/direnv.html | Compatibility |
| **Templates** | https://mise.jdx.dev/environments/templates.html | Tera templating |

### Tasks Documentation

| Page | URL | Notes |
|------|-----|-------|
| **Tasks Overview** | https://mise.jdx.dev/tasks/ | Core concept |
| **Running Tasks** | https://mise.jdx.dev/tasks/running-tasks.html | Execution |
| **TOML Tasks** | https://mise.jdx.dev/tasks/toml-tasks.html | Inline definition |
| **File Tasks** | https://mise.jdx.dev/tasks/file-tasks.html | Script files |
| **Task Dependencies** | https://mise.jdx.dev/tasks/task-dependencies.html | DAG execution |
| **Monorepo Tasks** | https://mise.jdx.dev/tasks/monorepo.html | `mise //path:task` |

### Reference Documentation

| Page | URL | Notes |
|------|-----|-------|
| **CLI Reference** | https://mise.jdx.dev/cli/ | All commands |
| **Settings** | https://mise.jdx.dev/configuration/settings.html | All settings |
| **IDE Integration** | https://mise.jdx.dev/ide-integration.html | VS Code, IntelliJ |
| **Hooks** | https://mise.jdx.dev/hooks.html | Lifecycle hooks |

---

## UI/Dashboard Ecosystem Status

### Key Finding: NO Official UI Tools

**Mise is CLI-only by design.** After comprehensive research, we found:

| Tool | Status | Notes |
|------|--------|-------|
| **Official GUI** | None | Not planned |
| **Official TUI** | None | CLI commands only |
| **Official Dashboard** | Planned | Web-based, 6-12 months (enterprise focus) |
| **mise-tui** | Active | Community Go project |
| **mise-gui** | Abandoned | Placeholder only |
| **xbar/SwiftBar plugins** | None found | Gap in ecosystem |

### mise-tui (Community Project)

**URL:** https://github.com/LeoHSRodrigues/mise-tui

A terminal UI for mise built with Go and Bubble Tea:
- Browse installed tools
- Install/uninstall tools
- View tool versions
- Active development (2024-2025)

```bash
# Installation
go install github.com/LeoHSRodrigues/mise-tui@latest
```

### mise-gui (Abandoned)

**URL:** https://github.com/mbenford/mise-gui

Status: Placeholder repository with no actual code. Appears abandoned.

### VSCode Extension (Community)

**URL:** https://marketplace.visualstudio.com/items?itemName=rgeraskin.mise

A community VSCode extension by Roman Geraskin:
- Run `mise install` from IDE
- Run mise tasks directly from VSCode workspace
- No need to switch to terminal for common operations

### Our SwiftBar Plugin Fills a Gap

The `config/scripts/dev-status.1m.sh` SwiftBar plugin we created fills a genuine ecosystem gap:

- **No existing xbar/SwiftBar plugins** for mise were found
- **Unique multi-environment support**: Local, Containers, DevContainers, Cloud
- **Menu bar integration** provides at-a-glance environment status
- **Actionable items** for common operations

---

## mise-versions.jdx.dev API

### Overview

**URL:** https://mise-versions.jdx.dev/

The official version registry and analytics dashboard for mise:
- **991 tools** across 12 backend types
- **Real-time download statistics** (3.39M downloads/30 days, 807K MAU)
- **Version release tracking** (41.4 tools updated per day)

### API Endpoints

**Base URL:** `https://mise-versions.jdx.dev/api`

#### GET /api/tools

List all tools with metadata:

```bash
curl 'https://mise-versions.jdx.dev/api/tools'
curl 'https://mise-versions.jdx.dev/api/tools?limit=50&page=1'
```

**Response includes:**
- Tool name, latest version, version count
- GitHub repo, homepage, description
- Backend types (core, aqua, asdf, etc.)
- Security features (checksums, GPG, attestations)
- 30-day download counts

### Use Cases

```bash
# Find backends for a tool
curl -s 'https://mise-versions.jdx.dev/api/tools' | \
  jq '.tools[] | select(.name == "uv") | .backends'

# Get download stats
curl -s 'https://mise-versions.jdx.dev/api/tools' | \
  jq '.downloads | to_entries | sort_by(-.value) | .[0:10]'
```

---

## jdx Related Projects

Projects by jdx (mise author) that complement mise:

| Project | URL | Purpose |
|---------|-----|---------|
| **mise** | https://github.com/jdx/mise | Polyglot tool manager (main project) |
| **pitchfork** | https://pitchfork.jdx.dev | Process/daemon manager |
| **hk** | https://hk.jdx.dev | Git hook manager |
| **usage** | https://github.com/jdx/usage | CLI documentation generator |
| **mise-action** | https://github.com/jdx/mise-action | GitHub Actions integration |
| **mise-vscode** | https://github.com/jdx/mise-vscode | VS Code extension |

### Pitchfork Integration

Pitchfork manages development daemons (databases, servers) with automatic lifecycle:

```toml
# mise.toml
[tools]
pitchfork = "latest"

# .pitchfork.toml
[daemons.postgres]
run = "postgres -D ./data"
```

### hk Integration

hk manages git hooks with mise integration:

```bash
# Install
mise use -g hk

# Setup
hk init
```

---

## mise-plugins Organization

**URL:** https://github.com/mise-plugins

Community-maintained mise plugins for tools without native backend support:

| Plugin | Repository |
|--------|------------|
| erlang | mise-plugins/mise-erlang |
| elixir | mise-plugins/mise-elixir |
| cocoapods | mise-plugins/mise-cocoapods |
| postgres | mise-plugins/mise-postgres |
| mongodb | mise-plugins/mise-mongodb |

Most common tools have native backends; plugins are for edge cases.

---

## Notable Mise-Based Dotfiles Repositories

### 1. jasonraimondi/dotfiles
**URL**: https://github.com/jasonraimondi/dotfiles

A comprehensive macOS development environment setup featuring:
- Modular dotfiles with GNU Stow
- Mise integration for programming language versions
- Homebrew with categorized Brewfiles (Requirefile, Brewfile, Caskfile, Fontfile, Macfile)
- `.tool-versions` for consistent environments

### 2. webpro/dotfiles
**URL**: https://github.com/webpro/dotfiles

Cross-platform dotfiles (macOS, Ubuntu, Arch Linux):
- Makefile-based installation
- Homebrew + Caskroom + Node.js
- Latest Bash + GNU Utils
- Tested weekly on real machines via GitHub Actions (Ventura, Sonoma, Sequoia)

### 3. driesvints/dotfiles
**URL**: https://github.com/driesvints/dotfiles

Popular macOS dotfiles starter:
- One-command setup
- Comprehensive documentation
- Good starting point for beginners

### 4. joshukraine/dotfiles
**URL**: https://github.com/joshukraine/dotfiles

Modern dotfiles with AI integration:
- Claude Code integration for AI-assisted development
- Neovim, Zsh/Fish, Ghostty + Tmux
- AI assistance is optional

### 5. CodelyTV/dotfiles
**URL**: https://github.com/CodelyTV/dotfiles

Speed-focused macOS setup:
- Fine-tuned settings for performance
- Well-documented customizations

---

## Mise vs asdf Comparison

### Performance

| Aspect | asdf (bash) | asdf (go 0.16+) | mise |
|--------|-------------|-----------------|------|
| Shim overhead | ~120ms | Faster | ~0ms (no shims) |
| Startup time | Slow | Moderate | Fast |
| Written in | Bash | Go | Rust |

> "asdf's shims have terrible performance, adding ~120ms to every runtime call. mise activate does not use shims and instead updates PATH."

### Key Differences

1. **No Shims**: mise updates PATH directly, eliminating shim overhead
2. **Built-in Language Support**: Native support for major languages (no plugins needed)
3. **Additional Features**:
   - Environment variable management (replaces direnv)
   - Task runner (replaces make)
   - Secrets management
4. **Plugin Compatibility**: Can use asdf plugins when needed

### References
- [Mise vs asdf Comparison (Better Stack)](https://betterstack.com/community/guides/scaling-nodejs/mise-vs-asdf/)
- [Official Comparison to asdf](https://mise.jdx.dev/dev-tools/comparison-to-asdf.html)
- [Why I Switched from asdf to mise (Medium)](https://medium.com/@nidhivya18_77320/why-i-switched-from-asdf-to-mise-and-you-should-too-8962bf6a6308)

---

## Actionable Tips & Patterns

### Template Variables

Use mise template variables for portable configurations:

```toml
[env]
PROJECT_ROOT = "{{ config_root }}"
DATA_DIR = "{{ config_root }}/data"
```

Available variables:
- `{{ config_root }}` - Directory containing mise.toml
- `{{ cwd }}` - Current working directory
- `{{ env.VAR }}` - Environment variable

### External Env Loading

Load environment from .env files:

```toml
[env]
_.file = ".env"              # Load .env
_.file = [".env", ".env.local"]  # Multiple files
```

### Task Namespacing

Organize tasks with namespacing:

```toml
[tasks."test"]
description = "Run all tests"
depends = ["test:unit", "test:integration"]

[tasks."test:unit"]
run = "bats tests/unit/"

[tasks."test:integration"]
run = "bats tests/integration/"
```

### Secrets Pattern

Use `.mise.local.toml` for local secrets (add to `.gitignore`):

```toml
# .mise.local.toml (gitignored)
[env]
DATABASE_URL = "postgres://localhost/dev"
API_KEY = "sk-local-only"
```

### Interactive Tasks

For tasks requiring user input:

```toml
[tasks.repl]
run = "python"
raw = true  # Allows interactive input
```

### Shell Aliases

Recommended shell aliases:

```bash
alias mr="mise run"
alias mx="mise exec"
alias mt="mise tasks"
alias ml="mise ls"
alias mu="mise use"
```

### Task Dependency Visualization

Generate task dependency graphs:

```bash
mise tasks deps --dot | dot -Tpng > task-graph.png
mise tasks deps --dot | dot -Tsvg > task-graph.svg
```

### Monorepo Tasks (Experimental)

Run tasks across monorepo projects:

```bash
mise //projects/frontend:build          # Specific project
mise //...:test                          # All projects
mise //projects/*:lint                   # Wildcard
```

---

## Other Version Managers

### Alternative Tools

| Tool | Description | Windows Support |
|------|-------------|-----------------|
| **proto** | Pluggable version manager, unified toolchain | Yes |
| **vfox** | Cross-platform, extensible | Yes |
| **asdf** | Original polyglot manager | No |
| **mise** | Modern asdf alternative | Limited |

### References
- [Awesome Version Managers](https://github.com/bernardoduarte/awesome-version-managers)
- [asdf Alternatives (AlternativeTo)](https://alternativeto.net/software/asdf-1/)
- [asdf Alternatives (LibHunt)](https://www.libhunt.com/r/asdf)

---

## Community Resources

### GitHub Discussions to Monitor

| Topic | URL | Notes |
|-------|-----|-------|
| Feature Requests | https://github.com/jdx/mise/discussions/categories/ideas | New feature proposals |
| Q&A | https://github.com/jdx/mise/discussions/categories/q-a | Community support |
| Show and Tell | https://github.com/jdx/mise/discussions/categories/show-and-tell | Community projects |
| Monorepo Tasks | https://github.com/jdx/mise/discussions/6564 | Experimental feature |

### Third-Party Guides

| Guide | URL | Notes |
|-------|-----|-------|
| Better Stack - Getting Started | https://betterstack.com/community/guides/scaling-nodejs/mise-explained/ | Comprehensive intro |
| Better Stack - mise vs asdf | https://betterstack.com/community/guides/scaling-nodejs/mise-vs-asdf/ | Comparison |
| TowardsAI - mise Article | https://towardsai.net/p/machine-learning/mise | ML perspective |
| Field Notes | https://www.stuartellis.name/articles/mise-en-place/ | In-depth walkthrough |
| Coumets Dev | https://coumets.dev/mise/setup/ | Setup guide |
| Swift Toolkit | https://www.swifttoolkit.dev/posts/mise-swift | Swift integration |

### Forums

| Forum | URL | Notes |
|-------|-----|-------|
| Erlang Forums | https://erlangforums.com/t/asdf-vs-mise-your-thoughts/5201 | asdf vs mise discussion |
| DEV Community | https://dev.to/binbingoloo/2025-macos-development-environment-setup-guide-4jj0 | 2025 setup guide |

### GitHub Topics to Watch

- https://github.com/topics/dotfiles-macos
- https://github.com/topics/mise
- https://github.com/topics/version-manager
- https://github.com/topics/dev-environment

---

## Installation Methods

### macOS

```bash
# Via curl (recommended)
curl https://mise.run | sh

# Via Homebrew
brew install mise

# Via MacPorts
sudo port install mise
```

### Post-Installation

```bash
# Add to ~/.zshrc
eval "$(mise activate zsh)"

# Verify installation
mise doctor
```

---

## Research Iteration Checklist

Track research iterations to ensure comprehensive coverage:

### Iteration 1: Foundation (January 2026)
- [x] Official documentation review
- [x] Dotfiles repository survey
- [x] asdf comparison research
- [x] Alternative version managers

### Iteration 2: UI/Dashboard Research (February 2026)
- [x] Search for official mise UI tools
- [x] Search for community TUI/GUI projects
- [x] Search for xbar/SwiftBar plugins
- [x] Confirm ecosystem gap for menu bar tools
- [x] Document mise-tui and mise-gui status

### Iteration 3: jdx Ecosystem & Tips (February 2026)
- [x] Catalog all jdx repositories
- [x] Review mise-plugins organization
- [x] Extract actionable tips from documentation
- [x] Review external articles (TowardsAI, Medium, Better Stack)
- [x] Document monorepo tasks feature
- [x] GitHub discussions review

### Iteration 4: Parallel Subagent Deep Dive (February 2026)
- [x] Launch 11 parallel librarian agents for comprehensive review
- [x] Confirm NO official UI/dashboard tools in jdx repos (40+ repos reviewed)
- [x] Confirm NO UI plugins in mise-plugins org (104 plugins reviewed)
- [x] Document mise-versions.jdx.dev API endpoints
- [x] Discover VSCode extension by rgeraskin
- [x] Verify Discussion #6564 is about monorepo tasks (not UI)
- [x] Extract actionable tips from tips-and-tricks page
- [x] Review TowardsAI, Medium, BetterStack articles

### Future Iterations
- [ ] Monitor mise releases for GUI/dashboard updates
- [ ] Track mise-tui development
- [ ] Review new community projects quarterly
- [ ] Update when mise web dashboard releases

---

## Key Takeaways

1. **mise is the clear successor to asdf** for most use cases
2. **Performance is significantly better** due to PATH manipulation vs shims
3. **Additional features** (env vars, tasks, secrets) reduce tool sprawl
4. **Plugin compatibility** means easy migration from asdf
5. **Active community** with many dotfiles repos adopting mise
6. **No official UI tools** - CLI-only by design
7. **Our SwiftBar plugin is unique** in the ecosystem
8. **jdx ecosystem** (pitchfork, hk, usage) provides complementary tools

---

## Suggestions for Future Research

### Automated Monitoring

Add mise tasks to monitor ecosystem updates:

```toml
[tasks."research:mise-releases"]
description = "Check mise releases"
run = "gh release view --repo jdx/mise"

[tasks."research:mise-discussions"]
description = "Check recent discussions"
run = "gh api repos/jdx/mise/discussions --jq '.[0:5] | .[] | \"- \" + .title'"

[tasks."research:mise-tui"]
description = "Check mise-tui updates"
run = "gh release list --repo LeoHSRodrigues/mise-tui --limit 3"
```

### RSS Feeds

Track updates via RSS:
- Mise releases: `https://github.com/jdx/mise/releases.atom`
- Mise discussions: Subscribe on GitHub
- mise-tui releases: `https://github.com/LeoHSRodrigues/mise-tui/releases.atom`

---

*Research conducted: January-February 2026*
