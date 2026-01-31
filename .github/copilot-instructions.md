# GitHub Copilot Instructions

## Entry Points
- [AGENTS.md](../AGENTS.md) - AI instructions (start here)
- [llms.txt](../llms.txt) - Documentation index
- [CLAUDE.md](../CLAUDE.md) - AI assistant context

## Project Type
macOS Development Environment. Mise-first orchestration.

## Tool Hierarchy
| Level | Tool | Purpose |
|-------|------|---------|
| 1 | Mise | Global orchestrator, manages ALL tools |
| 2 | Bun | JavaScript/TypeScript (replaces Node/npm) |
| 3 | Pixi | Binary packages (conda-forge) |
| 4 | Uv | Python packages (10x faster than pip) |

## Critical Rules
1. **NEVER use sudo** - Everything is user-space
2. **NEVER install globally with npm/pip** - Use mise (`mise use -g`)
3. **NEVER modify system Python/Node** - Mise manages versions
4. **NEVER commit secrets** - Use op://, infisical, or mise secrets
5. **ALWAYS use mise tasks** - Not raw commands
6. **ALWAYS run tests before committing** - `bats tests/`

## Common Commands
```bash
mise run validate           # Check environment health
mise run tools:status       # Show all tools and settings
mise run tools:update       # Update all tools to latest
bats tests/                 # Run all 254 tests
mise doctor                 # Diagnose issues
```

## Tool Installation Pattern
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

## Do Not
- Use sudo for any installation
- Install packages globally (npm -g, pip install)
- Modify system Python/Node
- Commit .env files or API keys
- Suppress TypeScript errors with `as any` or `@ts-ignore`
- Skip tests before committing

## Key Files
| File | Purpose |
|------|---------|
| config/mise.toml | Tool versions, tasks, settings (SOURCE OF TRUTH) |
| tests/*.bats | 254 BATS tests |
| setup.sh | Bootstrap script |
| AGENTS.md | Full project knowledge base |
