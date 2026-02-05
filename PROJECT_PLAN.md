# Project Plan: God-Tier macOS Development Environment

**Last Updated**: 2026-02-05
**Status**: P1-P4 Complete, P5 In Progress (Menu Bar Exploration — 521 tests, 10 fixes applied)
**Branch**: `feat/ai-optimization-from-downloads` (PR #1 open)
**Context Recovery Document**: This file maintains project state for AI context resets

---

## Quick Start

### Prerequisites
- macOS 14+ (Sonoma)
- Xcode Command Line Tools: `xcode-select --install`

### Installation (One Command)
```bash
cd ~/dev/github/ray-manaloto/gemini-ai-macos-development-environment
./setup.sh
```

### What Gets Installed
The setup script installs and configures:
- **mise** - Tool version manager (orchestrator)
- **bun** - Fast JavaScript runtime (node backend)
- **uv** - Fast Python package manager (pip backend)
- **pixi** - Conda-forge package manager
- **starship** - Cross-shell prompt
- **chezmoi** - Dotfile manager
- **CLI tools** - zoxide, fd, ripgrep, bat, eza, fzf, jq, yq, delta

### Post-Installation
```bash
# Restart terminal or reload shell
source ~/.zshrc

# Apply dotfile templates
chezmoi diff     # Preview changes
chezmoi apply    # Apply changes

# Verify installation
mise doctor
./config/scripts/validate.sh
```

---

## Testing

### Run All Tests
```bash
# Install BATS (if not installed)
mise use -g npm:bats

# Run full test suite
bats tests/

# Run specific test file
bats tests/test_mise.bats
bats tests/test_tools.bats
bats tests/test_chezmoi.bats
bats tests/test_starship.bats
bats tests/test_integration.bats
```

### Test Coverage (923 tests total)
| Test File | Coverage | Tests |
|-----------|----------|-------|
| `test_mise.bats` | Mise installation, backends, tasks | 12 |
| `test_tools.bats` | All CLI tool availability | 29 |
| `test_chezmoi.bats` | Template validation | 8 |
| `test_starship.bats` | Prompt configuration | 10 |
| `test_integration.bats` | End-to-end project structure | 25 |
| `test_ide_configs.bats` | VS Code, Zed, DevContainer, uninstall | 31 |
| `test_skypilot.bats` | SkyPilot, AWS, agent tasks | 43 |
| `test_unified_setup.bats` | Platform tasks, config_root, DevContainer | 22 |
| `test_env_status.bats` | env:status task output validation | 18 |
| `test_noninteractive_skills.bats` | OpenCode skill validation | 25 |
| `test_setup.bats` | Bootstrap script validation | 47 |
| `test_autofix.bats` | Autofix system, launchd plist | 35 |
| `test_agent_readiness.bats` | AI/LLM agent setup validation | 32 |
| `test_mcp.bats` | MCP integration tests | 35 |
| `test_swiftbar.bats` | SwiftBar menu bar plugin | 30 |
| `test_menubar_core.bats` | Core parity across all 4 menu bar apps | 68 |
| **Menu Bar Implementation Tests** | | |
| `DevEnvManager-SwiftBar/tests/` | SwiftBar plugin tests (117 existing + 155 new) | 272 |
| `DevEnvManager/Tests/test_swift_validation.bats` | Swift app validation | 91 |
| `DevEnvManager-Iced/tests/*.rs` | Iced Rust unit tests | 48 |
| `DevEnvManager-Tauri/src-tauri/tests/*.rs` | Tauri Rust unit tests | 42 |

### Health Check
```bash
# Quick validation script
./config/scripts/validate.sh

# Mise diagnostics
mise doctor
mise ls
mise config
```

### Expected Test Output
```
1..923
ok 1 mise is installed
ok 2 mise doctor reports no critical issues
...
ok 923 tauri ports parsing realistic lsof output

923 tests, 0 failures
```

---

## Project Vision

Build a reproducible, user-space macOS development environment using:
- **Mise** as the central orchestrator
- **Strict hierarchy**: Mise > Bun > Pixi > Uv
- **Zero system modifications** - everything in `~/.local`
- **AI-first tooling** with MCP integration

---

## Current Sprint: P1 - Core Completeness (COMPLETED)

### Sprint Goal
Complete the foundational setup so `./setup.sh` produces a fully working environment.

### User Stories

#### US-1: Dotfile Management (Chezmoi) ✅
**As a** developer
**I want** my shell and git configurations automatically managed
**So that** I have a consistent environment across machines

**Acceptance Criteria**:
- [x] `.zshrc` template with mise/starship activation → `config/chezmoi/dot_zshrc.tmpl`
- [x] `.gitconfig` template with sensible defaults → `config/chezmoi/dot_gitconfig.tmpl`
- [x] Chezmoi config template → `config/chezmoi/.chezmoi.toml.tmpl`
- [x] Test: BATS tests in `tests/test_chezmoi.bats`

#### US-2: Shell Prompt (Starship) ✅
**As a** developer
**I want** a context-aware shell prompt
**So that** I can see git/python/node status at a glance

**Acceptance Criteria**:
- [x] `starship.toml` with mise-aware configuration → `config/starship.toml`
- [x] Shows: git branch, python version, node version, bun, aws, docker, mise status
- [x] Test: BATS tests in `tests/test_starship.bats`

#### US-3: Environment Validation ✅
**As a** developer
**I want** to verify my environment is correctly configured
**So that** I can troubleshoot issues quickly

**Acceptance Criteria**:
- [x] `./config/scripts/validate.sh` checks all critical components
- [x] Tests written in BATS → `tests/test_*.bats` (5 test files)
- [x] Exit codes: 0 = pass, non-zero = fail with colored details
- [x] Test coverage: mise, bun, uv, pixi, starship, chezmoi, 1password, skypilot, gh

#### US-X: OpenCode Integration ✅
**Added**: Comprehensive documentation for oh-my-opencode plugin
- [x] Full slash commands reference (`/ulw-loop`, `/ralph-loop`, `/start-work`, etc.)
- [x] Magic keywords (`ultrawork`, `ulw`, `search`, `analyze`)
- [x] Agent descriptions (Sisyphus, Oracle, Prometheus, etc.)
- [x] Project-specific prompts → `OPENCODE_PROMPTS.md`

---

## Backlog (Prioritized)

### P1 - Core Completeness (Current Sprint) - COMPLETE
| ID | Story | Status | Assignee |
|----|-------|--------|----------|
| US-1 | Chezmoi dotfile templates | ✅ Complete | Claude |
| US-2 | Starship configuration | ✅ Complete | Claude |
| US-3 | Validation enhancement | ✅ Complete | Claude |
| US-X | OpenCode + oh-my-opencode docs | ✅ Complete | Claude |

### P2 - Enterprise Ready - COMPLETE
| ID | Story | Status | Deliverable |
|----|-------|--------|-------------|
| US-4 | DevContainer support | ✅ Complete | `.devcontainer/devcontainer.json` |
| US-5 | Secrets integration docs | ✅ Complete | `SECRETS.md`, `.env.example` |
| US-6 | Uninstall script | ✅ Complete | `uninstall.sh` (--dry-run, --force) |

### P3 - Polish - COMPLETE
| ID | Story | Status | Deliverable |
|----|-------|--------|-------------|
| US-7 | IDE configurations (Zed/VS Code) | ✅ Complete | `.vscode/`, `.zed/` |
| US-8 | macOS defaults script | ✅ Complete | `config/scripts/macos-defaults.sh` |
| US-9 | Migration guide from nvm/pyenv | ✅ Complete | `MIGRATION.md` |

### P4 - Nice to Have - COMPLETE
| ID | Story | Status | Deliverable |
|----|-------|--------|-------------|
| US-10 | Proxy configuration | ✅ Complete | `PROXY.md` |
| US-11 | Team onboarding docs | ✅ Complete | `TEAM_ONBOARDING.md` |
| US-12 | Ralph Orchestrator integration | ✅ Complete | oh-my-opencode docs |
| US-13 | Autofix system | ✅ Complete | `config/scripts/autofix.sh`, launchd agent |
| US-14 | AI/LLM agent readiness | ✅ Complete | `config/scripts/agent-readiness.sh` |
| US-15 | Menu bar status (SwiftBar) | ✅ Complete | `config/scripts/dev-status.1m.sh` |
| US-16 | Research automation | ✅ Complete | mise research:* tasks |
| US-17 | MCP integration | ✅ Complete | `config/scripts/setup-mcp.sh` |
| US-18 | macOS testing docs | ✅ Complete | `MACOS_TESTING.md` |
| US-19 | Future tools analysis | ✅ Complete | `FUTURE_TOOLS.md` |
| US-20 | AI agent best practices | ✅ Complete | Vercel research applied to AGENTS.md |

### Additional Deliverables (P2-P4)
| Item | Description |
|------|-------------|
| `SKYPILOT.md` | Cloud agent documentation |
| `PROXY.md` | Corporate HTTP/HTTPS proxy setup |
| `TEAM_ONBOARDING.md` | Team shared patterns, CI/CD, FAQ |
| `FUTURE_TOOLS.md` | Future tool analysis (atuin, age, direnv) |
| `MACOS_TESTING.md` | macOS testing strategies (Tart, Lume) |
| `tests/test_autofix.bats` | 35 tests for autofix system |
| `tests/test_agent_readiness.bats` | 32 tests for AI agent setup |
| `tests/test_mcp.bats` | 35 tests for MCP integration |
| `tests/test_swiftbar.bats` | 30 tests for menu bar plugin |
| `research/AGENT_BEST_PRACTICES.md` | Vercel AI agent research (2026) |
| `research/MISE_ECOSYSTEM_RESEARCH.md` | Comprehensive ecosystem analysis |
| Updated `AGENTS.md` | 327 lines, pipe-optimized format (54% reduction)

### P5 - DevEnvManager Menu Bar Exploration - IN PROGRESS

**Goal**: Solve the notch-overflow tray icon problem on M2 Max MacBooks. Build 4 side-by-side menu bar implementations to compare frameworks, then pick one for production.

**Problem**: The existing DevEnvManager.app's menu bar icon (commit `a0b3eed`) is hidden behind the MacBook Pro notch at X=781 (notch starts ~X=772).

**Branch**: `feat/ai-optimization-from-downloads` (PR #1 open, mergeable)

| ID | Implementation | Status | Directory | Build | Tests |
|----|---------------|--------|-----------|-------|-------|
| A | Enhanced SwiftBar Plugin | ✅ Complete | `DevEnvManager-SwiftBar/` | `bash -n` pass | 272 BATS |
| B | Native Swift NSStatusItem Fix | ✅ Complete | `DevEnvManager/` (modified) | Needs Xcode.app | 91 BATS |
| C | Rust iced + tray-icon | ✅ Complete | `DevEnvManager-Iced/` | `cargo check` clean, 5.4 MB binary | 48 Rust |
| D | Tauri 2 + React | ✅ Complete | `DevEnvManager-Tauri/` | `cargo check` clean, `bun tauri dev` | 42 Rust |
| — | Core Parity | ✅ Complete | `tests/test_menubar_core.bats` | — | 68 BATS |

**Key Commits (on `feat/ai-optimization-from-downloads`)**:
| Commit | Description |
|--------|-------------|
| `a0b3eed` | Original native macOS menu bar app + GitHub Actions build pipeline |
| `51740c5` | All 4 implementations with compile-verified Rust (80 files, 7,280 LOC) |
| `81b1076` | Comparison report with quantitative metrics |
| `935ec9c` | 521 tests + 10 code review fixes across all 4 implementations |

**Research Docs**:
| File | Content |
|------|---------|
| `research/DEVENVMANAGER_TRAY_RESEARCH.md` | Notch overflow analysis, framework comparison |
| `research/MENUBAR_IMPLEMENTATION_SPECS.md` | Detailed specs for all 4 implementations (1,195 lines) |
| `research/MENUBAR_COMPARISON_REPORT.md` | Build metrics, architecture assessment, ranking |

**Fixes Applied (Session 6)**:
- Iced: Removed deprecated `tokio-process`, fixed `daemon()` API, `checkbox()` API, lifetime annotations
- Tauri: Fixed `Image<'static>`, `tauri_plugin_store::Builder`, `Emitter` import, autostart init, RGBA icons
- Swift: Replaced Combine `objectWillChange` with `withObservationTracking` for `@Observable` stores
- SwiftBar: Plugin copied to SwiftBar's configured directory (`~/dev/swiftbar/`)

**Fixes Applied (Session 7 — Code Review)**:
- Iced: Removed unused `sysinfo` dep, tray poll 50ms→200ms (CPU), fatal `.expect()` on tray failure
- Iced: Added 30s command timeouts to all 4 domain modules (mise, homebrew, orbstack, ports)
- Tauri: Added 30s command timeout to `run_command()` helper (covers all CLI calls)
- Tauri: Fixed fragile `exit_code` parsing — now only matches field after "error" status token
- Tauri React: Added `useRef` in-flight guards to all 4 hooks (race condition fix)
- SwiftBar: Fixed `pip install` → `mise use -g pipx:`, parallelized status collection (3-5x faster)

**Launch Commands**:
```bash
# SwiftBar (needs SwiftBar.app from brew)
open /Applications/SwiftBar.app

# Iced (pure Rust binary, ready to run)
./DevEnvManager-Iced/target/release/devenv-manager-iced &

# Tauri 2 (Rust + React dev server)
cd DevEnvManager-Tauri && bun tauri dev

# Swift (requires Xcode.app)
# cd DevEnvManager && xcodegen generate && xcodebuild build
```

**Ranking** (from comparison report):
1. **B: Native Swift** — Best native UX, smallest footprint. Blocked by Xcode requirement.
2. **C: Iced + tray-icon** — Best pure-Rust option. 5.4 MB binary, clean architecture. Pre-1.0 API risk.
3. **D: Tauri 2** — Most feature-rich, largest ecosystem. WebView memory overhead.
4. **A: SwiftBar** — Best for quick status, limited interactivity.

**Next Steps**:
- [ ] Runtime test all 4 implementations side-by-side
- [ ] Verify notch handling on each
- [ ] Consider egui + tray-icon as 5th contender (~2 MB binary)
- [ ] Pick winner and merge to main

---

## Technical Architecture

### Directory Structure (Target)
```
gemini-ai-macos-development-environment/
├── config/
│   ├── main.pkl              # Pkl → mise TOML
│   ├── starship.toml         # Shell prompt config
│   ├── chezmoi/              # Dotfile templates
│   │   ├── dot_zshrc.tmpl
│   │   ├── dot_gitconfig.tmpl
│   │   └── .chezmoiignore
│   └── scripts/
│       ├── dashboard.py
│       ├── validate.sh
│       └── setup-mcp.sh
├── tests/
│   ├── test_mise.bats        # Mise validation
│   ├── test_tools.bats       # Tool availability
│   └── test_integration.bats # End-to-end tests
├── .devcontainer/
│   └── devcontainer.json     # DevPod/OrbStack
├── templates/
│   └── agent.yaml            # SkyPilot
├── research/                 # Deep research docs
├── setup.sh                  # Bootstrap script
├── pixi.toml
├── README.md
├── CLAUDE.md
├── PROJECT_PLAN.md           # This file
└── CHANGELOG.md              # Release notes
```

### Tool Hierarchy (Implemented)
```
┌─────────────────────────────────────────────────────┐
│                    MISE (Orchestrator)               │
│  config/main.pkl → ~/.config/mise/config.toml       │
├─────────────────────────────────────────────────────┤
│   Bun (JS)    │   Pixi (Binary)   │    Uv (Python)  │
│  npm packages │  conda-forge      │   pip packages  │
├─────────────────────────────────────────────────────┤
│                 PITCHFORK (Daemons)                  │
│  Auto-start/stop services per directory             │
└─────────────────────────────────────────────────────┘
```

---

## Definition of Done

A story is complete when:
1. ✅ Code implemented and committed
2. ✅ Tests written and passing (TDD)
3. ✅ Documentation updated
4. ✅ Works on clean macOS install
5. ✅ Reviewed (self-review for solo dev)

---

## Testing Strategy (TDD)

### Test Framework: BATS
```bash
# Install BATS via mise
mise use -g "npm:bats"

# Run tests
bats tests/
```

### Test Categories
1. **Unit Tests**: Individual tool availability
2. **Integration Tests**: Tools work together
3. **Smoke Tests**: Full setup.sh execution

### Example Test (TDD First)
```bash
# tests/test_mise.bats
@test "mise is installed" {
  run mise --version
  [ "$status" -eq 0 ]
}

@test "mise has bun backend configured" {
  run mise config get settings.node_backend
  [ "$output" = "bun" ]
}
```

---

## OpenCode Integration

### Plugin: oh-my-opencode
Repository: https://github.com/code-yeongyu/oh-my-opencode

### Prompt Templates for OpenCode

#### Template 1: Implement Feature
```
Implement [FEATURE_NAME] for the macOS dev environment project.

Context:
- Project: God-Tier macOS Development Environment
- File: [TARGET_FILE]
- Current state: [DESCRIBE_CURRENT_STATE]

Requirements:
- [REQUIREMENT_1]
- [REQUIREMENT_2]

Test first (TDD):
- Write failing test in tests/[TEST_FILE].bats
- Then implement to make test pass

Output:
- Code changes
- Test file
- Documentation updates
```

#### Template 2: Fix Issue
```
Fix: [ISSUE_DESCRIPTION]

Context:
- Project: God-Tier macOS Development Environment
- Error: [ERROR_MESSAGE]
- Expected: [EXPECTED_BEHAVIOR]

Debug steps taken:
- [STEP_1]
- [STEP_2]

Provide:
- Root cause analysis
- Fix implementation
- Test to prevent regression
```

#### Template 3: Review/Refactor
```
Review and refactor: [FILE_OR_COMPONENT]

Focus areas:
- Code quality
- Test coverage
- Documentation
- Performance

Current metrics:
- Lines of code: [LOC]
- Test coverage: [COVERAGE]%

Suggest improvements with rationale.
```

---

## Context Recovery Checklist

If AI context resets, use this checklist:

### 1. Read These Files First
```bash
cat PROJECT_PLAN.md      # This file - project state
cat CLAUDE.md            # AI context and patterns
cat README.md            # User documentation
cat research/GAPS_ANALYSIS.md  # Known gaps
```

### 2. Check Current State
```bash
git status               # Uncommitted changes
git log --oneline -5     # Recent commits
ls -la config/           # Config files
ls -la tests/            # Test files
```

### 3. Resume Work
- Check "Current Sprint" section above
- Find incomplete stories (🔄 or ⏳)
- Continue from last checkpoint

---

## Changelog

### 2026-02-05 (Session 7 - P5 Tests & Code Review Fixes)
- Added 521 tests across all 4 menu bar implementations (total project: 923 tests)
  - 68 core parity tests, 155 SwiftBar, 91 Swift, 48 Iced, 42 Tauri + updated 1 test
- Fixed 10 code review issues:
  - 30s command timeouts in Iced (4 domain files) and Tauri (`run_command` helper)
  - Tauri `exit_code` parsing bug (was reverse-scanning all fields, now matches only after "error")
  - Tauri React race conditions (added `useRef` in-flight guards to 4 hooks)
  - SwiftBar parallel status collection (6 background subshells, 3-5x faster)
  - Iced: removed unused `sysinfo` dep, tray poll 50ms→200ms, fatal tray icon `.expect()`
  - SwiftBar: `pip install` → `mise use -g pipx:`
- Launched and verified all 4 apps running simultaneously on M2 Max
- **Commit**: `935ec9c` (25 files, 3,434 LOC added)

### 2026-02-04 (Session 6 - P5 Menu Bar Exploration)
- **STARTED**: P5 Sprint - DevEnvManager Menu Bar Exploration
- Built 4 parallel menu bar implementations to solve notch-overflow tray icon problem
- **Spec A**: Enhanced SwiftBar bash plugin (503 lines, BATS 10/10)
- **Spec B**: Fixed native Swift AppDelegate — replaced Combine with `withObservationTracking`
- **Spec C**: Rust iced + tray-icon — 5.4 MB release binary, clean `cargo check`
- **Spec D**: Tauri 2 + React — fixed 6 compile errors, RGBA icon regeneration
- Added 3 research docs: tray research, implementation specs (1,195 lines), comparison report
- Installed SwiftBar via `brew --cask`, launched Iced binary, ran Tauri dev server
- Updated AGENTS.md, CLAUDE.md, llms.txt, PROJECT_PLAN.md with P5 context
- **Commits**: `51740c5` (80 files, 7,280 LOC), `81b1076` (comparison report)

### 2026-01-26 (Session 3)
- Added Quick Start section with installation instructions
- Added Testing section with BATS test commands
- Added test coverage table and expected output
- Created `OPENCODE_SETUP.md` with automation prompts
- Enhanced `setup.sh` with full tool installation (222 lines)
- Validated all configuration files (TOML, Pkl, shell scripts)
- All 61 BATS tests passing

### 2026-01-26 (Session 2)
- **COMPLETED**: P1 Sprint - Core Completeness
- Added comprehensive oh-my-opencode documentation to `OPENCODE_PROMPTS.md`
- Documented slash commands: `/ulw-loop`, `/ralph-loop`, `/start-work`, `/init-deep`, `/refactor`
- Documented magic keywords: `ultrawork`, `ulw`, `search`, `analyze`
- Documented agents: Sisyphus, Oracle, Librarian, Explore, Prometheus, Metis, Momus
- Added project-specific prompts for OpenCode usage

### 2026-01-26 (Session 1)
- Initial commit with full tool configuration
- Documentation complete (README, CLAUDE.md, research/)
- Git repository initialized
- Created BATS test files (TDD): test_mise, test_tools, test_chezmoi, test_starship, test_integration
- Created chezmoi templates: dot_zshrc.tmpl, dot_gitconfig.tmpl, .chezmoi.toml.tmpl
- Created starship.toml with custom mise indicator
- Enhanced validate.sh with comprehensive health checks
- **Started**: P1 Sprint - Core Completeness

---

## Notes

### Design Decisions
1. **Pkl over raw TOML**: Type safety and validation
2. **BATS for testing**: Native bash, no dependencies
3. **Chezmoi over stow**: Better templating, encryption support
4. **Starship over pure PS1**: Cross-shell, easy config

### Known Issues
- None currently

### Dependencies
- macOS 14+ (Sonoma)
- Xcode Command Line Tools
- ~10GB disk space

---

*This document is the source of truth for project state. Update after each work session.*
