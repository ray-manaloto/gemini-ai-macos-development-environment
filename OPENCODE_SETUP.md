# OpenCode Setup Automation

This document provides the exact commands to run OpenCode with oh-my-opencode to complete the God-Tier macOS Development Environment setup.

## Prerequisites

1. **OpenCode installed**: https://opencode.ai
2. **oh-my-opencode plugin installed**:
   ```bash
   bunx oh-my-opencode install
   ```

## Quick Start (One Command)

Open a terminal in the project directory and run:

```bash
cd ~/dev/github/ray-manaloto/gemini-ai-macos-development-environment
opencode
```

Then paste this prompt:

```
ulw complete the God-Tier macOS Development Environment setup

Context:
- Project location: ~/dev/github/ray-manaloto/gemini-ai-macos-development-environment
- Key files: PROJECT_PLAN.md, CLAUDE.md, setup.sh, config/main.pkl
- Principle: Mise-first (Mise > Bun > Pixi > Uv)

Tasks:
1. Run ./setup.sh to bootstrap the environment
2. Verify mise, bun, uv, pixi, starship, chezmoi are installed
3. Generate mise config: pkl eval -f toml config/main.pkl > ~/.config/mise/config.toml
4. Copy starship config: cp config/starship.toml ~/.config/starship.toml
5. Initialize chezmoi with templates from config/chezmoi/
6. Run mise install to install all tools
7. Run ./config/scripts/validate.sh to verify everything works
8. Fix any issues found during validation
9. Run bats tests/ to verify all tests pass

Success criteria:
- mise doctor shows no errors
- ./config/scripts/validate.sh shows all green checks
- bats tests/ shows all tests passing
```

## Alternative: Step-by-Step with Prometheus

For more control, use Prometheus planning mode:

1. **Start OpenCode**:
   ```bash
   cd ~/dev/github/ray-manaloto/gemini-ai-macos-development-environment
   opencode
   ```

2. **Press Tab** to enter Prometheus mode

3. **Describe the task**:
   ```
   Set up the God-Tier macOS Development Environment with all tools configured.

   Requirements:
   - Install mise as the central tool manager
   - Configure bun as node backend, uv as python backend
   - Set up starship prompt with custom config
   - Initialize chezmoi for dotfile management
   - Install all CLI tools (zoxide, fd, ripgrep, bat, eza, fzf)
   - Run validation to ensure everything works
   ```

4. **Review the generated plan** in `.sisyphus/plans/`

5. **Execute**: `/start-work`

## Using /ulw-loop for Continuous Work

If the setup needs multiple iterations:

```
/ulw-loop complete the macOS dev environment setup, fixing any errors until all tests pass

Read PROJECT_PLAN.md and CLAUDE.md first.
Run setup.sh, then validate.sh, then bats tests/.
Keep fixing issues until everything is green.
```

## Troubleshooting Prompts

### If mise fails to install:
```
ulw fix mise installation

Error: [paste error here]
Expected: mise --version returns valid version

Debug and fix the issue.
```

### If validation fails:
```
ulw fix validation failures

./config/scripts/validate.sh shows these errors:
[paste errors here]

Investigate and fix each issue.
```

### If tests fail:
```
ulw fix failing BATS tests

bats tests/ shows:
[paste test output here]

Fix the failing tests or the code they're testing.
```

## Verification Commands

After setup completes, verify manually:

```bash
# Check versions
mise --version
bun --version
uv --version
pixi --version
starship --version
chezmoi --version

# Run health check
./config/scripts/validate.sh

# Run tests
bats tests/

# Check mise doctor
mise doctor
```

## Expected Final State

When complete, you should have:

- ✅ `mise` managing all tool versions
- ✅ `bun` as the node/npm backend
- ✅ `uv` as the python/pip backend
- ✅ `pixi` for conda-forge packages
- ✅ `starship` prompt with custom theme
- ✅ `chezmoi` managing dotfiles
- ✅ CLI tools: zoxide, fd, ripgrep, bat, eza, fzf, jq, yq, delta
- ✅ All BATS tests passing
- ✅ validate.sh showing all green
