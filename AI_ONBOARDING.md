# AI Agent Onboarding

> One-click context injection for any LLM agent working with this repository.

---

## Universal Prompt (Copy-Paste to Any LLM)

Copy this entire block and paste it at the start of any conversation with an AI agent:

```
I'm working on the God-Tier macOS Development Environment project.

## Quick Context

This is a reproducible macOS development environment using Mise as the central orchestrator:
- **Tool Hierarchy**: Mise > Bun > Pixi > Uv
- **Location**: User-space only (~/.local, ~/.config)
- **System Mods**: Zero sudo, zero Homebrew (except GUI apps)

## Critical Rules

1. NEVER use sudo - Everything is user-space
2. NEVER install globally with npm/pip - Use mise (`mise use -g`)
3. NEVER modify system Python/Node - Mise manages versions
4. ALWAYS use mise tasks - Not raw commands (`mise run validate`)
5. ALWAYS run tests before committing - `bats tests/`

## Key Files

| File | Purpose |
|------|---------|
| config/mise.toml | Tool versions, tasks, settings (SOURCE OF TRUTH) |
| tests/*.bats | 254 BATS tests |
| setup.sh | Bootstrap script |
| AGENTS.md | Full project knowledge base |

## Common Commands

- `mise run validate` - Check environment health
- `mise run tools:status` - Show all tools
- `bats tests/` - Run all tests
- `mise doctor` - Diagnose issues

For full context, read: AGENTS.md
```

---

## Agent-Specific Onboarding

### Claude Code / Claude Desktop

**Method 1: Automatic (via AGENTS.md)**

Claude Code automatically reads `AGENTS.md` when entering this repository. No action needed.

**Method 2: Manual Context Injection**

```
@AGENTS.md @CLAUDE.md

I need help with [your task]. The project follows these rules:
- Mise-first orchestration (Mise > Bun > Pixi > Uv)
- User-space only, no sudo
- Always use mise tasks, not raw commands
```

**OpenSpec Workflow Commands**

| Command | Purpose |
|---------|---------|
| `/opsx:explore` | Think through ideas without implementing |
| `/opsx:new` | Start a new OpenSpec change |
| `/opsx:ff` | Fast-forward to tasks (skip proposal/design) |
| `/opsx:apply` | Apply change to codebase |
| `/opsx:continue` | Continue existing change |
| `/opsx:verify` | Verify change completeness |
| `/opsx:archive` | Archive completed change |

---

### OpenCode / oh-my-opencode

**Automatic Context**

OpenCode reads `AGENTS.md` automatically. For enhanced mode:

```
ultrawork

Read AGENTS.md and understand the mise-first philosophy. I need help with [your task].
```

**OpenSpec Workflow Commands**

| Command | Purpose |
|---------|---------|
| `/opsx-explore` | Think through ideas |
| `/opsx-new` | Start new change |
| `/opsx-ff` | Fast-forward to tasks |
| `/opsx-apply` | Apply change |
| `/opsx-continue` | Continue change |
| `/opsx-verify` | Verify completeness |

**Power Commands**

| Command | Purpose |
|---------|---------|
| `/ulw-loop` | Ultrawork mode until completion |
| `/ralph-loop` | Self-referential development loop |
| `/start-work` | Start from Prometheus plan |
| `/refactor` | LSP + AST-aware refactoring |

---

### Gemini CLI

**Context Injection**

```
@AGENTS.md @CLAUDE.md

Using Gemini CLI with this mise-first project. Key rules:
- Tool hierarchy: Mise > Bun > Pixi > Uv
- No sudo, no global npm/pip
- Use mise tasks for all commands
```

**OpenSpec Workflow Commands**

| Command | Purpose |
|---------|---------|
| `@opsx:explore` | Think through ideas |
| `@opsx:new` | Start new change |
| `@opsx:ff` | Fast-forward to tasks |
| `@opsx:apply` | Apply change |
| `@opsx:continue` | Continue change |
| `@opsx:verify` | Verify completeness |

---

### Cursor

**Setup**

1. Open repository in Cursor
2. Cursor reads `.cursorrules` and `.cursor/` automatically
3. For manual context:

```
@AGENTS.md

Working on the God-Tier macOS Dev Environment. This uses:
- Mise as central orchestrator
- Bun for JS (not npm)
- Uv for Python (not pip)
- No sudo, user-space only
```

**OpenSpec Workflow Commands**

Use the same commands as Claude Code with `/opsx:` prefix.

---

### ChatGPT / GPT-4

**Context Injection**

ChatGPT doesn't have file access. Paste this expanded context:

```
# Project: God-Tier macOS Development Environment

## What It Is
A reproducible macOS development environment using Mise as the central orchestrator.

## Tool Hierarchy (STRICT)
Mise > Bun > Pixi > Uv

| Level | Tool | Purpose |
|-------|------|---------|
| 1 | Mise | Global orchestrator, manages ALL tools |
| 2 | Bun | JavaScript/TypeScript (replaces Node/npm) |
| 3 | Pixi | Binary packages (conda-forge) |
| 4 | Uv | Python packages (10x faster than pip) |

## Critical Rules
1. NEVER use sudo - User-space only
2. NEVER `npm install -g` - Use `mise use -g "npm:<pkg>"`
3. NEVER `pip install` - Use `mise use -g "pipx:<pkg>"`
4. ALWAYS use mise tasks - `mise run <task>`
5. ALWAYS test before commit - `bats tests/`

## Key Commands
- `mise run validate` - Health check
- `mise run tools:status` - Show tools
- `mise run tools:update` - Update all
- `mise doctor` - Diagnostics
- `bats tests/` - Run 402 tests

## Project Structure
- config/mise.toml - Tool config (SOURCE OF TRUTH)
- config/scripts/ - Task scripts
- tests/*.bats - BATS test suite
- setup.sh - Bootstrap script

## When Installing Tools
```bash
# Correct
mise use -g <tool>
mise use -g "npm:<package>"
mise use -g "pipx:<package>"

# WRONG (never do this)
npm install -g <package>
pip install <package>
brew install <cli-tool>
```

Now help me with [your task].
```

---

## Context Recovery Prompts

Use these when an agent loses context mid-conversation:

### Quick Recovery

```
Context reset. Project: God-Tier macOS Dev Environment.
Rules: Mise-first, no sudo, no global npm/pip, use mise tasks.
Continue with: [describe current task]
```

### Full Recovery

```
I'm working on the God-Tier macOS Development Environment.

Previous work: [describe what was done]
Current state: [describe current issue/status]
Next step: [what you need help with]

Key context:
- Tool hierarchy: Mise > Bun > Pixi > Uv
- Config at: config/mise.toml
- Tests with: bats tests/
- Validate with: mise run validate

Please continue from here.
```

---

## Fetching Fresh Context

For agents with web access, fetch the latest context:

```
Fetch and read: https://raw.githubusercontent.com/ray-manaloto/gemini-ai-macos-development-environment/main/AGENTS.md

This is the project knowledge base. Use it to understand:
- Project structure and navigation
- Tool hierarchy and rules
- Available mise tasks
- Testing and validation
```

---

## Verification Prompt

After onboarding, verify the agent understands:

```
Quick check - you should know:
1. What is the tool hierarchy?
2. Why can't we use `npm install -g`?
3. How do we run tests?
4. What is the source of truth for tool config?

Answer briefly, then help me with [task].
```

**Expected answers:**
1. Mise > Bun > Pixi > Uv
2. Use mise instead (`mise use -g "npm:<pkg>"`)
3. `bats tests/`
4. `config/mise.toml`

---

## Raw URLs for Programmatic Access

| Resource | URL |
|----------|-----|
| AGENTS.md | `https://raw.githubusercontent.com/ray-manaloto/gemini-ai-macos-development-environment/main/AGENTS.md` |
| CLAUDE.md | `https://raw.githubusercontent.com/ray-manaloto/gemini-ai-macos-development-environment/main/CLAUDE.md` |
| llms.txt | `https://raw.githubusercontent.com/ray-manaloto/gemini-ai-macos-development-environment/main/llms.txt` |
| mise.toml | `https://raw.githubusercontent.com/ray-manaloto/gemini-ai-macos-development-environment/main/config/mise.toml` |

---

*Last Updated: 2026-01-26*
