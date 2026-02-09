# Secrets Management Guide

This guide covers secure secrets management for the God-Tier macOS Development Environment.

---

## Quick Decision Matrix

| Scenario | Recommended Option | Why |
|----------|-------------------|-----|
| Solo developer, simple setup | **Mise Native** | Easy, built-in, no extra tools |
| Team with existing 1Password | **1Password** | Seamless integration, team sharing |
| Enterprise / compliance needs | **Infisical** | Audit logs, rotation, RBAC |
| CI/CD pipelines | **Infisical** or **GitHub Secrets** | Designed for automation |

---

## Option 1: 1Password (Recommended for Teams)

### Prerequisites

```bash
# 1Password CLI is installed via mise
op --version

# Sign in to your 1Password account
op signin
```

### Configuration

Use `op://` URIs in your mise configuration:

```toml
# ~/.config/mise/config.toml or project mise.toml
[env]
ANTHROPIC_API_KEY = "op://Private/Anthropic/credential"
OPENAI_API_KEY = "op://Private/OpenAI/api_key"
AWS_ACCESS_KEY_ID = "op://Private/AWS/access_key_id"
AWS_SECRET_ACCESS_KEY = "op://Private/AWS/secret_access_key"
GITHUB_TOKEN = "op://Private/GitHub/token"
```

### URI Format

```
op://<vault>/<item>/<field>
```

- **vault**: 1Password vault name (e.g., "Private", "Development")
- **item**: Item title in 1Password
- **field**: Field name (e.g., "credential", "password", "api_key")

### Usage

```bash
# Mise automatically resolves op:// URIs when activated
cd my-project
mise trust  # Trust the project's mise config

# Environment variables are now available
echo $ANTHROPIC_API_KEY  # Outputs the actual key
```

### Creating 1Password Items

1. Open 1Password
2. Create new **API Credential** or **Password** item
3. Set the title (e.g., "Anthropic")
4. Add field named "credential" with your API key
5. Save to appropriate vault

### Troubleshooting

```bash
# Check 1Password CLI is authenticated
op whoami

# List available vaults
op vault list

# Get specific item details
op item get "Anthropic" --vault "Private"

# Debug URI resolution
op read "op://Private/Anthropic/credential"
```

---

## Option 2: Infisical (Recommended for Enterprise)

### Prerequisites

```bash
# Infisical CLI is installed via mise
infisical --version

# Login to Infisical
infisical login
```

### Configuration

1. **Create project** at [app.infisical.com](https://app.infisical.com)
2. **Add secrets** in the Infisical dashboard
3. **Initialize project** locally:

```bash
cd my-project
infisical init
# Select your project and environment
```

### Usage

```bash
# Run command with secrets injected
infisical run -- python train.py

# Run with specific environment
infisical run --env=production -- ./deploy.sh

# Export secrets to shell
eval $(infisical export --format=dotenv)
```

### Integration with Mise

```toml
# mise.toml
[tasks.dev]
run = "infisical run -- python main.py"

[tasks.deploy]
run = "infisical run --env=production -- ./deploy.sh"
```

### Features

- **Audit logs**: Track who accessed what secrets
- **Secret rotation**: Automatic rotation policies
- **RBAC**: Role-based access control
- **Environments**: dev, staging, production separation
- **Secret versioning**: History of all changes

---

## Option 3: Mise Native Secrets

### Setup

```bash
# Set a secret (encrypted, stored in ~/.local/share/mise/secrets)
mise secrets set ANTHROPIC_API_KEY=sk-ant-api03-...

# List secrets
mise secrets ls

# Remove a secret
mise secrets rm ANTHROPIC_API_KEY
```

### Usage

```toml
# mise.toml - reference secrets with mise: prefix
[env]
ANTHROPIC_API_KEY = "mise:ANTHROPIC_API_KEY"
```

### Pros & Cons

**Pros:**
- Built into mise, no extra tools
- Encrypted at rest
- Simple key=value model

**Cons:**
- Not designed for team sharing
- No audit logs
- Manual rotation

---

## Required Secrets by Tool

### AI Assistants

| Secret | Used By | How to Get |
|--------|---------|------------|
| `ANTHROPIC_API_KEY` | Claude Code, Claude API | [console.anthropic.com](https://console.anthropic.com) |
| `OPENAI_API_KEY` | Codex CLI, OpenAI API | [platform.openai.com](https://platform.openai.com) |
| `CONTEXT7_API_KEY` | Context7 MCP | [context7.com/dashboard](https://context7.com/dashboard) |
| `EXA_API_KEY` | Exa MCP (web search) | [dashboard.exa.ai/api-keys](https://dashboard.exa.ai/api-keys) |
| `GITHUB_TOKEN` | GitHub Copilot, gh CLI | [github.com/settings/tokens](https://github.com/settings/tokens) |

### Cloud Providers

| Secret | Used By | How to Get |
|--------|---------|------------|
| `AWS_ACCESS_KEY_ID` | SkyPilot, AWS CLI | IAM Console |
| `AWS_SECRET_ACCESS_KEY` | SkyPilot, AWS CLI | IAM Console |
| `AWS_PROFILE` | AWS credential profiles | ~/.aws/credentials |

### Other Services

| Secret | Used By | How to Get |
|--------|---------|------------|
| `HF_TOKEN` | Hugging Face models | [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) |
| `WANDB_API_KEY` | Weights & Biases | [wandb.ai/authorize](https://wandb.ai/authorize) |

---

## CLI Tool Authentication Setup

### GitHub CLI (gh)

```bash
# Interactive login (recommended)
gh auth login

# Or use environment variable
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx

# Or use 1Password
# In mise.toml:
# [env]
# GITHUB_TOKEN = "op://Private/GitHub/token"

# Verify authentication
gh auth status
```

**Required scopes:** `repo`, `read:org`, `workflow` (for Actions)

### Claude Code CLI

```bash
# Option 1: Interactive setup (requires Claude subscription)
claude setup-token

# Option 2: Environment variable (API key users)
export ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxx

# Option 3: Mise secrets
mise secrets set ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxx

# Option 4: 1Password
# In mise.toml:
# [env]
# ANTHROPIC_API_KEY = "op://Private/Anthropic/credential"

# Verify
claude --version
```

### Codex CLI (OpenAI)

```bash
# Option 1: Interactive login
codex login

# Option 2: Environment variable
export OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxx

# Option 3: Mise secrets
mise secrets set OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxx

# Option 4: 1Password
# In mise.toml:
# [env]
# OPENAI_API_KEY = "op://Private/OpenAI/api_key"

# Verify
codex --version

# Logout (remove stored credentials)
codex logout
```

### OpenCode CLI

```bash
# Option 1: Interactive auth setup
opencode auth

# Option 2: Environment variables (supports multiple providers)
export ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxx  # For Claude models
export OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxx       # For OpenAI models

# Option 3: Mise secrets
mise secrets set ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxx

# Option 4: 1Password (multiple keys)
# In mise.toml:
# [env]
# ANTHROPIC_API_KEY = "op://Private/Anthropic/credential"
# OPENAI_API_KEY = "op://Private/OpenAI/api_key"

# List available models
opencode models

# Use specific provider
opencode -m anthropic/claude-sonnet-4-20250514
```

---

## Quick Setup with Mise Secrets

For solo developers, mise native secrets is the simplest approach:

```bash
# Set all secrets at once
mise secrets set GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
mise secrets set ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxx
mise secrets set OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxx
mise secrets set CONTEXT7_API_KEY=ctx7sk-xxxxxxxxxxxxxxxxxxxx
mise secrets set EXA_API_KEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Verify secrets are stored
mise secrets ls

# Reference in mise.toml
# [env]
# GITHUB_TOKEN = "mise:GITHUB_TOKEN"
# ANTHROPIC_API_KEY = "mise:ANTHROPIC_API_KEY"
# OPENAI_API_KEY = "mise:OPENAI_API_KEY"
# CONTEXT7_API_KEY = "mise:CONTEXT7_API_KEY"
# EXA_API_KEY = "mise:EXA_API_KEY"
```

### Secrets Registry & Validation (Mise-only)

The canonical list of required secrets lives in `config/secrets.toml` under `[secrets]`.
Validation is enforced by `config/scripts/secrets-status.sh` and surfaced in `mise run validate`.

**Rule:** Secrets must come from Mise (global config), not shell exports.

```bash
# Validate sources (no values printed)
bash config/scripts/secrets-status.sh
```

---

## Quick Setup with 1Password

For team environments with 1Password:

```bash
# 1. Sign in to 1Password CLI
op signin

# 2. Create items in 1Password for each service
# 3. Add to mise.toml:
```

### Scripted 1Password Bootstrap (Recommended)

Use the bootstrap script to create the required items interactively:

```bash
eval "$(op signin)"
VAULT=Private bash config/scripts/1password-bootstrap.sh

# Optional: overwrite existing items
VAULT=Private bash config/scripts/1password-bootstrap.sh --force
```

Then apply them to Mise:

```bash
bash config/scripts/secrets-1password-setup.sh
bash config/scripts/secrets-status.sh
```

```toml
# mise.toml or ~/.config/mise/config.toml
[env]
GITHUB_TOKEN = "op://Private/GitHub/token"
ANTHROPIC_API_KEY = "op://Private/Anthropic/credential"
OPENAI_API_KEY = "op://Private/OpenAI/api_key"
CONTEXT7_API_KEY = "op://Private/Context7/api_key"
EXA_API_KEY = "op://Private/Exa/api_key"
```

```bash
# 4. Verify secrets resolve
mise trust
mise env | grep -E "GITHUB|ANTHROPIC|OPENAI|CONTEXT7|EXA"
```

### One-time Automation (Preferred)

Use the provided template and script to apply all 1Password secrets to Mise globally:

```bash
# 1) Edit template (set correct op:// paths)
$EDITOR config/secrets.1password.toml

# 2) Apply to Mise global config
bash config/scripts/secrets-1password-setup.sh

# 3) Verify
bash config/scripts/secrets-status.sh
```

---

## Encrypted Secrets File (SOPS + age)

If you want a single encrypted file as the source of truth, mise supports **SOPS‑encrypted** files referenced from `env._.file` (jdx/mise docs).

**Workflow (recommended):**

```bash
# 1) Create an age key (one-time)
age-keygen -o ~/.config/mise/age.txt

# 2) Copy the example file and fill values
cp config/secrets.env.json.example .env.json
$EDITOR .env.json

# 3) Encrypt with sops (age)
sops encrypt -i --age "$(age-keygen -y ~/.config/mise/age.txt)" .env.json

# 4) Reference it in global mise config
# ~/.config/mise/config.toml
[env]
_.file = { path = "~/.config/dev-env/.env.json", redact = true }

# 5) Verify
mise env --redacted | grep -E "GITHUB|ANTHROPIC|OPENAI|CONTEXT7|EXA"
```

**Notes**:
- Encrypted `.env.json` can be safely stored in the repo.
- Mise automatically decrypts if the age key exists.

---

## .env.example Template

Create this file in your project root as a reference:

```bash
# .env.example - Copy to .env and fill in values
# DO NOT COMMIT .env TO GIT

# AI Services
ANTHROPIC_API_KEY=sk-ant-api03-...
OPENAI_API_KEY=sk-...

# GitHub
GITHUB_TOKEN=ghp_...

# AWS (for SkyPilot)
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_PROFILE=default

# Optional
HF_TOKEN=hf_...
WANDB_API_KEY=...
```

**Important:** Add `.env` to your `.gitignore`:

```gitignore
# .gitignore
.env
.env.local
.env.*.local
```

---

## Security Best Practices

### DO

- Use `op://` URIs for team environments
- Rotate secrets regularly (every 90 days)
- Use least-privilege access (minimal scopes)
- Store secrets in dedicated vaults/projects
- Use environment-specific secrets (dev vs prod)

### DON'T

- Commit secrets to git (check with `git secrets`)
- Share secrets via Slack/email
- Use the same secret across environments
- Store secrets in plain text files
- Hardcode secrets in scripts

### Secret Scanning

```bash
# Install git-secrets (via mise)
mise use -g "ubi:awslabs/git-secrets"

# Initialize in repo
git secrets --install
git secrets --register-aws

# Scan for secrets
git secrets --scan
```

---

## Troubleshooting

### "Secret not found" errors

```bash
# 1Password: Check authentication
op whoami
op signin

# Infisical: Check project initialization
infisical export --format=dotenv

# Mise: List available secrets
mise secrets ls
```

### "Permission denied" errors

```bash
# 1Password: Check vault access
op vault list

# Infisical: Check role permissions
infisical user get
```

### Secrets not loading in mise

```bash
# Trust the config file
mise trust

# Check config is valid
mise config

# Verify env vars
mise env
```

---

## Related Documentation

- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
- [Infisical Documentation](https://infisical.com/docs)
- [Mise Secrets Documentation](https://mise.jdx.dev/configuration.html#secrets)
- [AWS Credentials Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
