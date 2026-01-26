# OpenCode + oh-my-opencode Guide

This file contains setup instructions, commands, and prompts for using OpenCode with the oh-my-opencode plugin on this macOS development environment project.

Repository: https://github.com/code-yeongyu/oh-my-opencode

---

## Quick Start (TL;DR)

**Lazy mode:** Just include `ultrawork` (or `ulw`) in your prompt. The agent handles everything.

```
ulw implement the validation tests for this project
```

**Precise mode:** Press **Tab** to enter Prometheus (Planner) mode, then run `/start-work`.

---

## Installation

### 1. Verify OpenCode is Installed

```bash
if command -v opencode &> /dev/null; then
    echo "OpenCode $(opencode --version) is installed"
else
    echo "Install OpenCode first: https://opencode.ai/docs"
fi
```

### 2. Install oh-my-opencode Plugin

```bash
# Interactive installer (recommended)
bunx oh-my-opencode install

# Or with explicit options (non-interactive)
bunx oh-my-opencode install --no-tui \
    --claude=max20 \
    --openai=yes \
    --gemini=yes \
    --copilot=no
```

**Provider flags:**
- `--claude=<yes|no|max20>` - Claude Pro/Max subscription
- `--openai=<yes|no>` - OpenAI/ChatGPT Plus
- `--gemini=<yes|no>` - Google Gemini
- `--copilot=<yes|no>` - GitHub Copilot (fallback)
- `--opencode-zen=<yes|no>` - OpenCode Zen
- `--zai-coding-plan=<yes|no>` - Z.ai Coding Plan

### 3. Authenticate Providers

```bash
opencode auth login
# Select provider and complete OAuth flow
```

### 4. Verify Setup

```bash
opencode --version        # Should be 1.0.150+
cat ~/.config/opencode/opencode.json  # Should contain "oh-my-opencode"
```

---

## Slash Commands

| Command | Description |
|---------|-------------|
| `/ulw-loop` | **Ultrawork loop** - runs continuously at max intensity until completion |
| `/ralph-loop` | **Self-referential loop** - continues until task is done (named after Anthropic's plugin) |
| `/start-work` | **Execute Prometheus plan** - starts work from a generated plan |
| `/init-deep` | **Generate AGENTS.md** - creates hierarchical context files throughout project |
| `/refactor` | **LSP + AST refactoring** - intelligent rename/restructure with TDD verification |
| `/cancel-ralph` | **Cancel active loop** - stops ralph-loop or ulw-loop |

### Usage Examples

```bash
# Start ultrawork loop for a task
/ulw-loop "Implement all validation tests for the mise configuration"

# Start planning mode (precise work)
# Press Tab to enter Prometheus mode, describe task, then:
/start-work

# Generate hierarchical AGENTS.md files
/init-deep --create-new --max-depth=3

# Intelligent refactoring
/refactor validate.sh --scope=file --strategy=safe
```

---

## Magic Keywords

Include these in prompts to activate special modes:

| Keyword | Effect |
|---------|--------|
| `ultrawork` or `ulw` | **Maximum intensity** - parallel agents, aggressive exploration |
| `search` or `find` | **Parallel exploration** - multiple search agents |
| `analyze` or `investigate` | **Deep analysis** - thorough code examination |
| `think deeply` or `ultrathink` | **Extended thinking** - 32k token thinking budget |

**Example:**
```
ulw add comprehensive BATS tests for all chezmoi templates
```

---

## Agents

oh-my-opencode provides 10 specialized agents:

### Core Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| **Sisyphus** | `anthropic/claude-opus-4-5` | Default orchestrator with todo-driven workflow |
| **Oracle** | `openai/gpt-5.2` | Architecture decisions, code review (read-only) |
| **Librarian** | `opencode/big-pickle` | Multi-repo analysis, documentation lookup |
| **Explore** | `opencode/gpt-5-nano` | Fast codebase exploration, contextual grep |
| **Multimodal-Looker** | `google/gemini-3-flash` | Visual content (PDFs, images, diagrams) |

### Planning Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| **Prometheus** | `anthropic/claude-opus-4-5` | Strategic planner with interview mode |
| **Metis** | `anthropic/claude-sonnet-4-5` | Pre-planning analysis, ambiguity detection |
| **Momus** | `anthropic/claude-sonnet-4-5` | Plan validation and review |

### Invoking Agents Explicitly

```
Ask @oracle to review this architecture decision
Ask @librarian how similar projects implement this pattern
Ask @explore for all files related to mise configuration
```

---

## Skills (Specialized Workflows)

| Skill | Trigger | Description |
|-------|---------|-------------|
| **playwright** | Browser tasks | Browser automation via Playwright MCP |
| **frontend-ui-ux** | UI/UX tasks | Designer-turned-developer persona |
| **git-master** | commit, rebase | Atomic commits, history search |

### Usage

```
/playwright Navigate to localhost:3000 and take a screenshot
/git-master commit these changes with atomic commits
```

---

## Two Workflows

### 1. Ultrawork Mode (Quick Work)

```
ulw implement authentication for this Next.js app
```

The agent automatically:
1. Explores codebase for existing patterns
2. Researches best practices
3. Implements following conventions
4. Verifies with tests/diagnostics
5. Keeps working until complete

### 2. Prometheus Mode (Precise Work)

1. Press **Tab** to enter Prometheus mode
2. Describe what you want
3. Prometheus interviews you, generates a plan
4. Run `/start-work` to execute

**When to use Prometheus:**
- Multi-day projects
- Critical production changes
- Complex refactoring
- When you need a documented decision trail

---

## Project-Specific Prompts

### Context Initialization

Use this at the start of any OpenCode session for this project:

```
You are working on the "God-Tier macOS Development Environment" project.

Key files:
- PROJECT_PLAN.md: Current sprint and backlog
- CLAUDE.md: Development patterns and tool hierarchy
- config/main.pkl: Tool configuration (Pkl -> TOML)
- tests/*.bats: BATS test files

Core principles:
1. Mise-first: ALL tools managed through mise
2. Strict hierarchy: Mise > Bun > Pixi > Uv
3. TDD: Write failing tests first, then implement
4. User-space only: No sudo, no system modifications
```

### Feature Implementation

```
ulw implement [FEATURE_NAME]

Context:
- Config file: config/main.pkl
- Test pattern: tests/test_[feature].bats
- Tool backends: npm: (bun), uv: (python), cargo: (rust)

Requirements:
1. Add to config/main.pkl with appropriate backend
2. Create BATS test in tests/
3. Update CLAUDE.md documentation
4. Verify: bats tests/
```

### Bug Fix

```
ulw fix [BUG_DESCRIPTION]

Debug steps:
1. Run failing test: bats tests/[file].bats --filter "test name"
2. Analyze root cause
3. Implement fix
4. Verify all tests pass: bats tests/
```

### Refactoring

```
/refactor [TARGET] --scope=module --strategy=safe

Requirements:
1. Maintain existing behavior
2. Update all tests
3. Run full test suite before and after
4. Use LSP for renames
```

---

## Hooks (Lifecycle Automation)

oh-my-opencode includes 25+ built-in hooks:

### Key Hooks

| Hook | Event | Description |
|------|-------|-------------|
| **keyword-detector** | UserPromptSubmit | Detects `ultrawork`, `search`, etc. |
| **directory-agents-injector** | PostToolUse | Auto-injects AGENTS.md files |
| **comment-checker** | PostToolUse | Reminds to reduce excessive comments |
| **ralph-loop** | Stop | Manages loop continuation |
| **session-recovery** | Stop | Recovers from session errors |

---

## Built-in MCPs (Model Context Protocol)

| MCP | Purpose |
|-----|---------|
| **websearch** | Real-time web search (Exa AI) |
| **context7** | Official library documentation lookup |
| **grep_app** | Ultra-fast code search across public GitHub |

---

## Context Recovery

If OpenCode loses context mid-session:

```
Project: God-Tier macOS Dev Environment
Location: ~/gemini-ai-macos-development-environment
Key files: PROJECT_PLAN.md, CLAUDE.md, config/main.pkl
Test command: bats tests/
Current sprint: Check PROJECT_PLAN.md

Resume with: /start-work or ulw continue previous task
```

---

## Configuration

Config location: `~/.config/opencode/oh-my-opencode.json`

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",
  "agents": {
    "atlas": { "model": "anthropic/claude-sonnet-4-5", "variant": "max" },
    "explore": { "model": "opencode/gpt-5-nano" }
  },
  "experimental": {
    "aggressive_truncation": true
  }
}
```

### Disable Features

```json
{
  "disabled_hooks": ["comment-checker", "auto-update-checker"],
  "disabled_skills": ["playwright"]
}
```

---

## Quick Reference

```bash
# Run tests
bats tests/

# Validate environment
./config/scripts/validate.sh

# Regenerate mise config
pkl eval -f toml config/main.pkl > ~/.config/mise/config.toml

# Check mise status
mise doctor

# Start OpenCode with oh-my-opencode
opencode

# Quick ultrawork task
# (inside opencode)
ulw run all tests and fix any failures
```

---

## Philosophy (Ultrawork Manifesto)

> "Human intervention during agentic work is fundamentally a wrong signal."

**Core principles:**
1. **Human intervention = failure signal** - The agent should complete work autonomously
2. **Indistinguishable code** - Output should match senior engineer quality
3. **Minimize cognitive load** - You provide intent, agent handles execution
4. **Predictable, continuous, delegatable** - Like a compiler: plan in, code out

---

## Further Reading

- [oh-my-opencode Features](https://github.com/code-yeongyu/oh-my-opencode/blob/master/docs/features.md)
- [Ultrawork Manifesto](https://github.com/code-yeongyu/oh-my-opencode/blob/master/docs/ultrawork-manifesto.md)
- [Configuration Guide](https://github.com/code-yeongyu/oh-my-opencode/blob/master/docs/configurations.md)
- [Orchestration System](https://github.com/code-yeongyu/oh-my-opencode/blob/master/docs/guide/understanding-orchestration-system.md)
