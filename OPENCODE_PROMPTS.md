# OpenCode Prompts for macOS Dev Environment

This file contains pre-built prompts for use with OpenCode and the oh-my-opencode plugin.
Repository: https://github.com/code-yeongyu/oh-my-opencode

---

## Setup Instructions

### 1. Install OpenCode
```bash
# Via mise (already in config)
mise install

# Or manually
npm install -g opencode-ai
```

### 2. Install oh-my-opencode
```bash
# Clone the plugin
git clone https://github.com/code-yeongyu/oh-my-opencode ~/.opencode/plugins/oh-my-opencode

# Or if using mise npm backend (bun)
bun add -g oh-my-opencode
```

### 3. Configure OpenCode
```bash
# Set up OpenCode config
opencode config

# Or set API key directly
export OPENAI_API_KEY="your-key"
# Or for Anthropic
export ANTHROPIC_API_KEY="your-key"
```

---

## Project Context Prompt

Use this prompt at the start of any OpenCode session:

```
You are working on the "God-Tier macOS Development Environment" project.

Key files to understand:
- PROJECT_PLAN.md: Current sprint and backlog
- CLAUDE.md: Development patterns and tool hierarchy
- config/main.pkl: Tool configuration (Pkl → TOML)
- tests/*.bats: BATS test files

Core principles:
1. Mise-first: ALL tools managed through mise
2. Strict hierarchy: Mise > Bun > Pixi > Uv
3. TDD: Write failing tests first, then implement
4. User-space only: No sudo, no system modifications

Current sprint: P1 - Core Completeness
Focus: Chezmoi templates, Starship config, validation tests
```

---

## Feature Implementation Prompts

### Prompt: Implement New Tool
```
Implement [TOOL_NAME] integration for the macOS dev environment.

Context:
- File: config/main.pkl
- Pattern: Add to tools mapping with appropriate backend
- Backends: npm: (bun), uv: (python), cargo: (rust), brew: (gui apps)

Steps:
1. Add tool to config/main.pkl
2. Create test in tests/test_tools.bats
3. Update documentation in CLAUDE.md
4. Run tests: bats tests/test_tools.bats

Example for adding 'delta' (better git diff):
["cargo:delta"] = "latest"
```

### Prompt: Add Chezmoi Template
```
Create a chezmoi template for [DOTFILE_NAME].

Context:
- Directory: config/chezmoi/
- Naming: dot_filename.tmpl (e.g., dot_zshrc.tmpl)
- Template syntax: Go templates with chezmoi data

Requirements:
1. Header comment indicating chezmoi management
2. Support for user-specific data via {{ .variable }}
3. Include .local override file support
4. Add test in tests/test_chezmoi.bats

Example structure:
# Header comment
[content]
# Local overrides
[ -f "$HOME/.filename.local" ] && source "$HOME/.filename.local"
```

### Prompt: Add Mise Task
```
Add a new mise task: [TASK_NAME]

Context:
- File: config/main.pkl
- Section: tasks = new { ... }
- Format: ["task-name"] = new { description = "...", run = "..." }

Requirements:
1. Clear description with emoji prefix
2. Run command should work standalone
3. Update CLAUDE.md with new task
4. Test manually: mise run [task-name]

Example:
["lint"] = new {
  description = "🔍 Run all linters"
  run = "rg --files | xargs shellcheck"
}
```

---

## Bug Fix Prompts

### Prompt: Fix Test Failure
```
Fix failing test in [TEST_FILE].

Context:
- Test file: tests/[TEST_FILE].bats
- Run tests: bats tests/[TEST_FILE].bats
- BATS syntax: @test "description" { commands }

Debug steps:
1. Run single test: bats tests/[TEST_FILE].bats --filter "test name"
2. Add debug output: echo "# debug message" >&3
3. Check exit codes: [ "$status" -eq 0 ]
4. Check output: [[ "$output" =~ "pattern" ]]

Provide:
- Root cause analysis
- Fix implementation
- Verification that test passes
```

### Prompt: Fix Configuration Issue
```
Fix: [CONFIGURATION_ISSUE]

Context:
- Config file: config/main.pkl
- Validation: mise doctor
- Regenerate: pkl eval -f toml config/main.pkl

Common issues:
1. Backend mismatch: Check pip_backend/node_backend settings
2. Tool not found: Verify tool name and backend
3. Task fails: Check run command works standalone

Debug:
1. Run: mise doctor
2. Check: mise ls
3. Verify: mise config
```

---

## Refactoring Prompts

### Prompt: Improve Test Coverage
```
Improve test coverage for [COMPONENT].

Current tests: tests/
Target: [COVERAGE]% line coverage

Steps:
1. Identify untested code paths
2. Write edge case tests
3. Add integration tests
4. Run full suite: bats tests/

Focus areas:
- Error handling paths
- Edge cases (empty input, special characters)
- Integration between components
```

### Prompt: Refactor Script
```
Refactor [SCRIPT_NAME] for better maintainability.

Context:
- File: config/scripts/[SCRIPT_NAME].sh
- Style: Bash strict mode (set -euo pipefail)
- Functions: Prefix with descriptive names

Improvements:
1. Add shellcheck compliance
2. Use functions for repeated logic
3. Add error handling
4. Improve output formatting
5. Add --help option if appropriate
```

---

## Documentation Prompts

### Prompt: Update Documentation
```
Update documentation for [CHANGE_DESCRIPTION].

Files to update:
- README.md: User-facing changes
- CLAUDE.md: AI context and patterns
- PROJECT_PLAN.md: Sprint status, if applicable
- CHANGELOG.md: Version history (if exists)

Format:
- Use tables for tool lists
- Include code examples
- Keep consistent with existing style
```

### Prompt: Add Troubleshooting Entry
```
Add troubleshooting entry for: [ISSUE_DESCRIPTION]

File: CLAUDE.md (Troubleshooting section)

Format:
### "[Error message or symptom]"
```bash
# Solution commands
```
Explanation of why this works.
```

---

## Release Prompts

### Prompt: Prepare Release
```
Prepare release [VERSION].

Checklist:
1. [ ] All tests passing: bats tests/
2. [ ] Documentation updated
3. [ ] CHANGELOG.md updated
4. [ ] PROJECT_PLAN.md status updated
5. [ ] Git status clean
6. [ ] Commit message formatted

Commit format:
feat: [description]
fix: [description]
docs: [description]
refactor: [description]
test: [description]
```

---

## Quick Commands

```bash
# Run all tests
bats tests/

# Run specific test file
bats tests/test_mise.bats

# Validate environment
./config/scripts/validate.sh

# Regenerate mise config
pkl eval -f toml config/main.pkl > ~/.config/mise/config.toml

# Check mise status
mise doctor

# Install all tools
mise install
```

---

## Context Recovery

If OpenCode loses context, paste this:

```
Project: God-Tier macOS Dev Environment
Location: ~/gemini-ai-macos-development-environment
Key files: PROJECT_PLAN.md, CLAUDE.md, config/main.pkl
Test command: bats tests/
Current focus: Check PROJECT_PLAN.md for current sprint
```
