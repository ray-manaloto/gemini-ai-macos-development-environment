# PROJECT KNOWLEDGE BASE
Generated:2026-02-05|Branch:feat/ai-optimization-from-downloads (PR #1)

## FOR LLM AGENTS

### Critical Instruction
>**IMPORTANT:** Prefer retrieval-led reasoning over pre-training-led reasoning for Mise, Bun, Pixi, and Uv tasks. These tools evolve rapidly—consult project files and documentation rather than relying on potentially outdated training data.

**Exploration commands:**
```bash
ls -la && cat AGENTS.md | head -100
grep -r "experimental" config/mise.toml
find . -name "*.toml" -not -path "./.git/*"
mise ls && mise doctor
```

### Quick Identity
Project|God-Tier macOS Development Environment
Hierarchy|Mise>Bun>Pixi>Uv
Location|User-space only (~/.local, ~/.config)
System Mods|Zero sudo, zero Homebrew (except GUI apps)

### Navigation
I want to...|Go to...|Key info
Understand philosophy|CLAUDE.md|Tool hierarchy, patterns
Install everything|setup.sh|Run once
Add/modify tools|config/mise.toml|SOURCE OF TRUTH
Run tests|tests/*.bats|923 tests, `bats tests/`
Validate env|`mise run validate`|Health check
Configure dotfiles|config/chezmoi/|Templates
Configure prompt|config/starship.toml|Modules
View manual|`mise run help`|MANUAL.md
Project plan|PROJECT_PLAN.md|Sprints, backlog
Research docs|research/|15+ documents
OpenSpec|.claude/,.gemini/,.Claude/,.cursor/|10 commands each
Secrets|SECRETS.md|1Password, Infisical
Migration|MIGRATION.md|nvm, pyenv, asdf
Cloud agents|SKYPILOT.md|AWS spot instances
Proxy|PROXY.md|Corporate setup
Team onboard|TEAM_ONBOARDING.md|CI/CD, FAQ
Future tools|FUTURE_TOOLS.md|atuin, age, direnv
macOS testing|MACOS_TESTING.md|Tart, Lume, Actions
Uninstall|uninstall.sh|--dry-run, --force

### Critical Rules (NEVER BREAK)
1. NEVER use sudo - User-space only
2. NEVER npm/pip install globally - Use `mise use -g`
3. NEVER modify system Python/Node - Mise manages
4. NEVER commit secrets - Use op://, infisical, mise secrets
5. NEVER suppress type errors - No `as any`, `@ts-ignore`
6. ALWAYS use mise tasks - `mise run <task>`
7. ALWAYS test before commit - `bats tests/`
8. ALWAYS `mise doctor` after issues
9. PREFER existing patterns
10. ASK if uncertain
11. ALWAYS install CLI via mise - Never `curl|sh`, `npm -g`
   Install:`mise use -g <tool>@latest`|Check:`mise which <tool>`|Fix:`mise run autofix:fix`

---

## TOOL HIERARCHY
```
MISE (Orchestrator)
├── Bun (JS/TS) - replaces Node/npm, 3x faster
├── Pixi (Binary) - conda-forge, FFmpeg/CUDA
└── Uv (Python) - 10x faster than pip
```
All tools→~/.local, zero system mods.

### Key Settings
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

---

## STRUCTURE
```
gemini-ai-macos-development-environment/
├── config/
│   ├── mise.toml          # SOURCE OF TRUTH
│   ├── main.pkl           # Pkl→TOML
│   ├── starship.toml      # Prompt
│   ├── chezmoi/           # Dotfiles
│   └── scripts/           # validate.sh, dashboard.py
├── DevEnvManager/         # Spec B: Native Swift menu bar app (requires Xcode)
│   ├── App/               # AppDelegate (NSStatusItem + NSPopover)
│   ├── Domain/            # Business logic (Mise, Homebrew, OrbStack)
│   ├── Presentation/      # UI layer
│   └── project.yml        # XcodeGen configuration
├── DevEnvManager-SwiftBar/  # Spec A: Enhanced SwiftBar plugin (bash)
│   ├── dev-status.5s.sh   # 503-line bash plugin
│   └── tests/             # BATS tests (10 tests)
├── DevEnvManager-Iced/    # Spec C: Rust iced + tray-icon (5.4 MB binary)
│   ├── src/               # app.rs, tray.rs, config.rs, domain/, views/
│   ├── Cargo.toml         # iced 0.14, tray-icon 0.21
│   └── target/release/    # Pre-built binary
├── DevEnvManager-Tauri/   # Spec D: Tauri 2 + React
│   ├── src-tauri/src/     # lib.rs, tray.rs, commands/
│   ├── src/               # React frontend (App, components, hooks)
│   └── package.json       # bun + react + tauri CLI
├── tests/                 # 402 BATS tests
├── research/              # 15+ research docs
│   ├── DEVENVMANAGER_TRAY_RESEARCH.md   # Notch overflow analysis
│   ├── MENUBAR_IMPLEMENTATION_SPECS.md  # 4-way specs (1,195 lines)
│   └── MENUBAR_COMPARISON_REPORT.md     # Metrics + ranking
├── openspec/              # Specs, changes
├── templates/agent.yaml   # SkyPilot AWS
├── .claude/,.gemini/,.Claude/,.cursor/  # AI configs
├── .vscode/,.zed/,.devcontainer/         # IDE configs
├── setup.sh               # Bootstrap
├── uninstall.sh           # Cleanup
└── *.md                   # Docs
```

---

## COMMANDS

### Core Tasks
mise run dashboard|TUI manager
mise run validate|Health check
mise run help|Manual
mise run setup:auto|Platform detect + setup
mise run validate:rules|Anti-pattern check

### Tool Management
mise run tools:status|All tools/settings
mise run tools:install|Install all
mise run tools:update|Update all
mise run tools:doctor|Full health

### Autofix
mise run autofix:status|Show issues
mise run autofix:fix|Fix with backup
mise run autofix:json|CI output
mise run launchd:install|macOS agent

### Agent Readiness
mise run agent:ready|Check setup
mise run agent:ready:fix|Fix issues

### Cloud Agent (SkyPilot)
mise run agent:check|AWS credentials
mise run agent:up|Launch
mise run agent:down|Terminate
mise run agent:ssh|Connect
mise run agent:logs|View logs

### Auth
mise run auth:status|All CLI auth
mise run auth:gh|GitHub
mise run auth:claude|Claude
mise run auth:aws|AWS

### DevContainer
mise run devcontainer:up|Start
mise run devcontainer:down|Stop
mise run devcontainer:ssh|Connect

### Menu Bar (SwiftBar)
mise run menubar:install|Install plugin
mise run menubar:status|Check status

### DevEnvManager (Native App)
mise run devenv-app:install|Download from GitHub Release
mise run devenv-app:build|Build from source (requires Xcode)
mise run devenv-app:status|Check installation/running status
mise run devenv-app:open|Open the app
mise run devenv-app:quit|Quit the app
mise run devenv-app:restart|Restart the app
mise run devenv-app:uninstall|Remove app and data
mise run devenv-app:logs|View system logs

### DevEnvManager Implementations (P5 - Menu Bar Exploration)
```bash
# A: SwiftBar (needs SwiftBar.app from brew)
open /Applications/SwiftBar.app

# C: Iced (pure Rust binary, ready to run)
./DevEnvManager-Iced/target/release/devenv-manager-iced &

# D: Tauri 2 (Rust + React dev server)
cd DevEnvManager-Tauri && bun tauri dev

# B: Swift (requires Xcode.app, not CLT)
# cd DevEnvManager && xcodegen generate && xcodebuild build
```
Ranking: B (Swift) > C (Iced) > D (Tauri) > A (SwiftBar)
Details: research/MENUBAR_COMPARISON_REPORT.md

---

## TOOL INSTALLATION

### Correct
```bash
mise use -g <tool>              # CLI binary
mise use -g "npm:<pkg>"         # npm package (→Bun)
mise use -g "pipx:<pkg>"        # Python CLI (→uv)
mise use -g "ubi:<owner/repo>"  # GitHub release
mise use -g "cargo:<pkg>"       # Rust package
```

### WRONG (never do)
Wrong|Why|Right
`curl -fsSL...\|sh`|Shadows mise|`mise use -g <tool>`
`npm install -g`|Bypasses mise|`mise use -g "npm:<pkg>"`
`pip install`|System pollution|`mise use -g "pipx:<pkg>"`
`brew install <cli>`|Wrong manager|`mise use -g <tool>`

---

## TESTING

### Test Files (923 total)
test_mise.bats|Mise backends, tasks
test_tools.bats|CLI availability
test_chezmoi.bats|Dotfile templates
test_starship.bats|Prompt config
test_integration.bats|E2E structure
test_ide_configs.bats|VS Code, Zed
test_skypilot.bats|Cloud agents
test_unified_setup.bats|Platform tasks
test_autofix.bats|Autofix system
test_agent_readiness.bats|Agent setup
test_swiftbar.bats|Menu bar
test_menubar_core.bats|Core parity (68)
DevEnvManager-SwiftBar/tests/|SwiftBar (272)
DevEnvManager/Tests/|Swift validation (91)
DevEnvManager-Iced/tests/|Iced Rust (48)
DevEnvManager-Tauri/src-tauri/tests/|Tauri Rust (42)

### Running
```bash
eval "$(mise activate bash --shims)"
bats tests/              # All core tests
bats tests/test_mise.bats  # Specific
bats tests/test_menubar_core.bats  # Menu bar parity
bats DevEnvManager-SwiftBar/tests/  # SwiftBar (272)
bats DevEnvManager/Tests/  # Swift (91)
cd DevEnvManager-Iced && cargo test  # Iced (48)
cd DevEnvManager-Tauri/src-tauri && cargo test  # Tauri (42)
```

---

## CONVENTIONS

### File Patterns
Config|TOML (mise.toml, starship.toml)
Templates|.tmpl suffix (dot_zshrc.tmpl)
Tests|test_*.bats in tests/
Scripts|.sh bash, .py Python
Docs|.md in root or research/

### Anti-Patterns
Package Mgmt|`npm -g`, `pip install`→Use mise
System Mod|`sudo`, `/usr/local/`→User-space
Type Safety|`as any`, `@ts-ignore`→Fix types
Errors|Empty catch blocks→Handle errors
Tests|Delete failing tests→Fix code
Secrets|Commit .env, keys→Use op://
Homebrew|`brew install` CLI→mise

---

## CONFIG FLOW
```
config/main.pkl (Pkl source)
    ↓ pkl eval -f toml
config/mise.toml (Generated)
    ↓ cp to ~/.config/mise/
~/.config/mise/config.toml (Active)
```

---

## AI AGENT COMMANDS

### Platforms
Platform|Location|Prefix
Claude|.claude/commands/opsx/|`/opsx:`
Gemini|.gemini/commands/opsx/|`@opsx:`
Claude Code|.Claude/command/|`/opsx-`
Cursor|.cursor/commands/opsx/|`/opsx:`

### OpenSpec Commands (10 each)
explore|Think/investigate
new|Create change
ff|Fast-forward to tasks
apply|Implement
continue|Resume work
verify|Check completeness
archive|Archive done
bulk-archive|Archive multiple
sync|Sync specs
onboard|Setup project

---

## OPENSPEC WORKFLOW
```bash
openspec new change "name" --description "..."
```
```
openspec/changes/<name>/
├── .openspec.yaml     # Metadata
├── proposal.md        # WHY
├── design.md          # HOW
├── specs/             # WHAT (scenarios)
└── tasks.md           # Backlog
```

---

## SECRETS
1Password (Recommended):`ANTHROPIC_API_KEY = "op://Private/Anthropic/credential"`
Infisical:`infisical run -- ./script.sh`
Mise Native:`mise secrets set KEY=value`

---

## QUICK START
```bash
cd ~/dev/github/ray-manaloto/gemini-ai-macos-development-environment
./setup.sh
# Restart terminal
mise doctor && bats tests/
```

### Daily
```bash
mise run tools:update    # Update
mise run validate        # Health
mise run help            # Manual
```

### Troubleshoot
Command not found|`eval "$(mise activate zsh)"` + `mise reshim`
Wrong version|`mise ls` + `mise trust`
Config not loading|`cp config/mise.toml ~/.config/mise/config.toml`

---

## EXTERNAL SKILLS & AGENTS (from samhvw8/dotfiles)

### Skills (25)
Core|0-claude, 0-planning, 0-prompt-architect, 0-research, 0-sequential-thinking
Dev|backend-development, frontend-development, databases, code-quality, git-workflow
Infra|infra-engineer, mise-expert
Special|3d-graphics, ai-tools, browser-history, canvas-design, chrome-devtools, docs-discovery, media-processing, mobile-development, nextjs-turborepo, payment-integration, problem-solving, repomix, shopify

### Agents (24)
Arch|system-architect, react-next-architect, svelte-kit-architect, devops-architect
Quality|code-reviewer, refactoring-expert, quality-engineer, security-engineer
Dev|python-expert, database-admin
Research|researcher, planner, requirements-analyst, brainstormer, scout
Docs|docs-manager, copywriter, journal-writer
Test|tester, debugger
Other|ui-ux-designer, project-manager, learning-guide, mcp-manager

---

## DESIGN DECISIONS
1. Mise over asdf - Rust (10x faster), native backends
2. Bun over Node - 3x faster, native TS
3. Uv over pip - 10x faster, deterministic
4. BATS for tests - Native bash
5. Chezmoi over stow - Templates, encryption

### Dependencies
macOS 14+ (Sonoma)|Xcode CLT|~10GB disk

### Resources
[Mise](https://mise.jdx.dev/)|[Bun](https://bun.sh/)|[Uv](https://docs.astral.sh/uv/)|[Pixi](https://pixi.sh/)
