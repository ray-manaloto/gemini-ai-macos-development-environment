# Documentation Index

Complete index of all documentation and research for the God-Tier macOS Development Environment.

---

## Quick Reference

| Document | Purpose | Status |
|----------|---------|--------|
| [README.md](README.md) | User-facing setup guide | ✅ Complete |
| [CLAUDE.md](CLAUDE.md) | AI assistant context | ✅ Complete |
| [PROJECT_PLAN.md](PROJECT_PLAN.md) | Agile project plan & sprints | ✅ Complete |
| [SETUP_ISSUES.md](SETUP_ISSUES.md) | Known issues & fixes | ✅ Complete |

---

## Core Documentation

### README.md
- Quick Start guide
- Architecture diagram
- Tool hierarchy explanation
- Installation commands
- Testing instructions

### CLAUDE.md
- Development patterns
- Tool hierarchy rules (Mise > Bun > Pixi > Uv)
- Troubleshooting guide
- AI context for development

### PROJECT_PLAN.md
- Sprint status (P1 Complete)
- User stories and acceptance criteria
- Testing strategy (BATS/TDD)
- Changelog by session
- Context recovery checklist

### MANUAL.md
- System manual (accessible via `mise run help`)

### PREFLIGHT_CHECKLIST.md
- Pre-installation requirements
- macOS version check
- Xcode CLI tools
- Disk space requirements

---

## OpenCode Integration

### OPENCODE_PROMPTS.md
- Full oh-my-opencode documentation
- Slash commands: `/ulw-loop`, `/ralph-loop`, `/start-work`, `/init-deep`, `/refactor`
- Magic keywords: `ultrawork`, `ulw`, `search`, `analyze`
- Agent descriptions: Sisyphus, Oracle, Prometheus, Librarian, Explore
- Project-specific prompts

### OPENCODE_SETUP.md
- One-command setup with ultrawork mode
- Step-by-step Prometheus mode guide
- Troubleshooting prompts
- Context recovery instructions

---

## Research Documentation

Located in `research/` directory:

| File | Content |
|------|---------|
| `CHATGPT_DEEP_RESEARCH.md` | ChatGPT deep research report on mise ecosystem |
| `DEEP_RESEARCH_FINDINGS.md` | YouTube/NotebookLM research findings |
| `GAPS_ANALYSIS.md` | Gap analysis with P1/P2/P3 priorities |
| `AUTOMATION_DOCUMENTATION.md` | Automation patterns and scripts |
| `GEMINI_SPEC_COMPARISON.md` | Gemini vs original spec comparison |
| `MISE_DOCUMENTATION_AUDIT.md` | Mise documentation review |
| `MISE_ECOSYSTEM_RESEARCH.md` | Mise ecosystem tools research |
| `MISE_MCP_SETUP.md` | MCP (Model Context Protocol) setup guide |
| `NOTEBOOKLM_CLI_COMMANDS.md` | CLI commands from NotebookLM |
| `NOTEBOOKLM_DEEP_RESEARCH.md` | NotebookLM research summary |
| `OTHER_TOOLS_AUDIT.md` | Audit of related tools |
| `RESEARCH_TOOLS.md` | Research methodology and tools |

---

## Configuration Files

| File | Purpose |
|------|---------|
| `config/main.pkl` | Pkl configuration → generates mise TOML |
| `config/starship.toml` | Shell prompt configuration |
| `config/chezmoi/dot_zshrc.tmpl` | Zsh configuration template |
| `config/chezmoi/dot_gitconfig.tmpl` | Git configuration template |
| `config/chezmoi/.chezmoi.toml.tmpl` | Chezmoi config template |
| `config/chezmoi/.chezmoiignore` | Chezmoi ignore patterns |
| `config/scripts/validate.sh` | Environment health check |
| `config/scripts/setup-mcp.sh` | MCP setup script |
| `config/scripts/dev-status.1m.sh` | SwiftBar menu status |

---

## Test Files

| File | Coverage |
|------|----------|
| `tests/test_mise.bats` | Mise installation, backends, tasks |
| `tests/test_tools.bats` | CLI tool availability |
| `tests/test_chezmoi.bats` | Dotfile template validation |
| `tests/test_starship.bats` | Prompt configuration |
| `tests/test_integration.bats` | End-to-end project structure |

---

## Key Findings from Research

### Tool Hierarchy (from ChatGPT Deep Research)
```
Mise > Bun > Pixi > Uv
```

### Recommended Stack
- **Mise**: Central orchestrator for all tools
- **Bun**: JavaScript runtime (node backend)
- **Pixi**: Conda-forge packages
- **Uv**: Python package manager (10x faster than pip)
- **Pitchfork**: Development daemon manager

### AI Integration
- MCP (Model Context Protocol) for Claude integration
- oh-my-opencode plugin for OpenCode automation
- Slash commands for ultrawork mode

---

## Session History

### Session 1 (2026-01-26)
- Initial project setup
- Research documentation created
- Git repository initialized

### Session 2 (2026-01-26)
- P1 Sprint completed
- BATS tests created
- Chezmoi templates created
- Starship configuration
- oh-my-opencode documentation

### Session 3 (2026-01-26)
- Enhanced setup.sh
- Fixed mise tool naming (prefix-dev/pixi → pixi)
- Added Quick Start sections
- Created SETUP_ISSUES.md
- Documentation index created

---

## Next Steps

1. Run `./setup.sh` to complete environment setup
2. Verify with `./config/scripts/validate.sh`
3. Run tests with `bats tests/`
4. Apply dotfiles with `chezmoi apply`

---

*Last Updated: 2026-01-26*
