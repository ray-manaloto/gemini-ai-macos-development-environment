# Team Onboarding Guide

Quick-start guide for teams adopting the God-Tier macOS Development Environment.

## For New Team Members

### 1. Prerequisites

Before starting, ensure you have:

- [ ] macOS 14+ (Sonoma or later)
- [ ] Xcode Command Line Tools: `xcode-select --install`
- [ ] ~10GB free disk space
- [ ] Access to team's 1Password vault (if using shared secrets)

### 2. Installation (5 minutes)

```bash
# Clone the environment repo
git clone https://github.com/ray-manaloto/gemini-ai-macos-development-environment.git ~/dev/github/ray-manaloto/gemini-ai-macos-development-environment

# Run setup
cd ~/dev/github/ray-manaloto/gemini-ai-macos-development-environment
./setup.sh

# Restart terminal
exec $SHELL
```

### 3. Verify Installation

```bash
# Check mise health
mise doctor

# Run validation
mise run validate

# Check tool versions
mise ls --current
```

### 4. Authenticate CLI Tools

```bash
# Check what needs authentication
mise run auth:status

# Authenticate each tool
mise run auth:gh       # GitHub CLI
mise run auth:claude   # Claude Code
mise run auth:aws      # AWS CLI (if using cloud agents)
```

### 5. Apply Team Configuration

If your team has a shared `mise.toml`:

```bash
# Copy team config
cp /path/to/team/mise.toml ~/.config/mise/config.toml

# Trust and install
mise trust
mise install
```

## Shared Configuration Patterns

### Project-Level mise.toml

Create a `mise.toml` in your project root:

```toml
[tools]
node = "20"
python = "3.12"
bun = "latest"

[env]
NODE_ENV = "development"
DATABASE_URL = "postgres://localhost/myapp"

[tasks.dev]
description = "Start development server"
run = "bun run dev"

[tasks.test]
description = "Run tests"
run = "bun test"

[tasks.lint]
description = "Run linter"
run = "bun run lint"
```

### Team Tool Versions

Lock versions for consistency:

```toml
[tools]
node = "20.11.0"      # Specific version
python = "3.12"       # Minor version (auto-updates patch)
bun = "latest"        # Always latest
```

### Environment Variables

```toml
[env]
# Static values
APP_NAME = "my-app"
LOG_LEVEL = "debug"

# Dynamic values with templating
PROJECT_ROOT = "{{config_root}}"
CACHE_DIR = "{{env.HOME}}/.cache/{{env.APP_NAME}}"

# Load from .env file
_.file = ".env"

# Add to PATH
_.path = ["./bin", "./node_modules/.bin"]
```

### Task Definitions

```toml
[tasks.setup]
description = "Initial project setup"
run = """
bun install
cp .env.example .env
mise run db:migrate
"""

[tasks."db:migrate"]
description = "Run database migrations"
run = "bunx prisma migrate dev"

[tasks."db:seed"]
description = "Seed database"
depends = ["db:migrate"]
run = "bunx prisma db seed"
```

## CI/CD Integration

### GitHub Actions

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install mise
        uses: jdx/mise-action@v2
        
      - name: Install dependencies
        run: mise run setup
        
      - name: Run tests
        run: mise run test
```

### GitLab CI

```yaml
stages:
  - test

test:
  image: ubuntu:latest
  before_script:
    - curl https://mise.run | sh
    - eval "$(~/.local/bin/mise activate bash)"
    - mise install
  script:
    - mise run test
```

### Docker / DevContainer

Use the included DevContainer:

```bash
# Start container
mise run devcontainer:up PROVIDER=docker

# Run commands in container
mise run devcontainer:exec 'mise run test'
```

## Troubleshooting FAQ

### "Command not found" after installation

```bash
# Ensure mise is activated
eval "$(mise activate zsh)"

# Reshim
mise reshim

# Verify PATH
echo $PATH | grep -q 'mise/shims' && echo "OK" || echo "Missing shims"
```

### Wrong tool version being used

```bash
# Check which version is active
mise ls

# Check for .tool-versions or mise.toml in parent directories
mise config

# Trust the config
mise trust

# Force reinstall
mise install --force
```

### Tool not installing

```bash
# Run doctor
mise doctor

# Check for specific tool
mise install node@20 --verbose

# Clear cache and retry
rm -rf ~/.local/share/mise/cache
mise install
```

### Environment variables not loading

```bash
# Check mise.toml [env] section
cat mise.toml | grep -A10 '\[env\]'

# Verify mise is activated
mise env

# Check for _.file loading
ls -la .env
```

### Proxy issues in corporate network

```bash
# Check proxy status
mise run proxy:status

# Configure proxy
mise run proxy:setup

# Test connectivity
mise run proxy:test
```

## Best Practices

### 1. Version Pinning Strategy

| Environment | Strategy | Example |
|-------------|----------|---------|
| Development | Minor version | `node = "20"` |
| CI/CD | Exact version | `node = "20.11.0"` |
| Production | Exact version | `node = "20.11.0"` |

### 2. Secrets Management

**DO:**
- Use 1Password references: `op://Vault/Item/field`
- Use mise secrets: `mise secrets set KEY=value`
- Keep `.env` in `.gitignore`

**DON'T:**
- Commit API keys to Git
- Share secrets via Slack/email
- Hardcode credentials in scripts

### 3. Task Naming Conventions

```toml
[tasks.dev]           # Start development
[tasks.test]          # Run tests
[tasks.lint]          # Run linter
[tasks.build]         # Build for production
[tasks.deploy]        # Deploy to environment
[tasks."db:migrate"]  # Database migrations
[tasks."db:seed"]     # Database seeding
[tasks."docker:up"]   # Start Docker services
```

### 4. Documentation

Every project should have:

- `README.md` - Project overview and quick start
- `mise.toml` - Tool versions and tasks
- `.env.example` - Environment variable template
- `CONTRIBUTING.md` - Development workflow

## Team Standards

### Required Tools (All Projects)

```toml
[tools]
bun = "latest"
node = "20"
```

### Recommended Tools

```toml
[tools]
shellcheck = "latest"   # Shell script linting
hadolint = "latest"     # Dockerfile linting
"pipx:pre-commit" = "latest"  # Git hooks
```

### Code Quality Tasks

Every project should define:

```toml
[tasks.lint]
description = "Run all linters"
run = "bun run lint && shellcheck **/*.sh"

[tasks.format]
description = "Format code"
run = "bun run format"

[tasks.typecheck]
description = "Type checking"
run = "bun run typecheck"
```

## Getting Help

### Resources

| Resource | URL |
|----------|-----|
| Mise Documentation | https://mise.jdx.dev/ |
| Project AGENTS.md | [AGENTS.md](AGENTS.md) |
| Secrets Guide | [SECRETS.md](SECRETS.md) |
| Proxy Guide | [PROXY.md](PROXY.md) |

### Commands

```bash
# Show system manual
mise run help

# Run health check
mise run validate

# Show all available tasks
mise tasks

# Get mise diagnostics
mise doctor
```

### Escalation

1. Check FAQ above
2. Run `mise doctor` and share output
3. Check [mise GitHub issues](https://github.com/jdx/mise/issues)
4. Ask in team chat with error output

## Checklist for Team Leads

### Setting Up a New Project

- [ ] Create `mise.toml` with required tools
- [ ] Add project-specific tasks
- [ ] Create `.env.example` template
- [ ] Add mise to CI/CD pipeline
- [ ] Document project-specific setup in README

### Onboarding New Members

- [ ] Share this guide
- [ ] Provide access to 1Password vault
- [ ] Add to GitHub team/org
- [ ] Schedule pair programming session
- [ ] Review first PR together

### Maintaining Standards

- [ ] Review `mise.toml` changes in PRs
- [ ] Update tool versions quarterly
- [ ] Run security audits on dependencies
- [ ] Keep documentation current
