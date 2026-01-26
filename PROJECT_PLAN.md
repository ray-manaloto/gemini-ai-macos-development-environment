# Project Plan: God-Tier macOS Development Environment

**Last Updated**: 2026-01-26
**Status**: P1 Complete - Ready for Setup
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

### Test Coverage
| Test File | Coverage |
|-----------|----------|
| `test_mise.bats` | Mise installation, backends, tasks |
| `test_tools.bats` | All CLI tool availability |
| `test_chezmoi.bats` | Template validation |
| `test_starship.bats` | Prompt configuration |
| `test_integration.bats` | End-to-end project structure |

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
1..61
ok 1 mise is installed
ok 2 mise doctor reports no critical issues
...
ok 61 starship can render prompt

61 tests, 0 failures
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

### P2 - Enterprise Ready
| ID | Story | Status |
|----|-------|--------|
| US-4 | DevContainer support | ⏳ Backlog |
| US-5 | Secrets integration docs | ⏳ Backlog |
| US-6 | Uninstall script | ⏳ Backlog |

### P3 - Polish
| ID | Story | Status |
|----|-------|--------|
| US-7 | IDE configurations (Zed/VS Code) | ⏳ Backlog |
| US-8 | macOS defaults script | ⏳ Backlog |
| US-9 | Migration guide from nvm/pyenv | ⏳ Backlog |

### P4 - Nice to Have
| ID | Story | Status |
|----|-------|--------|
| US-10 | Proxy configuration | ⏳ Backlog |
| US-11 | Team onboarding docs | ⏳ Backlog |

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
