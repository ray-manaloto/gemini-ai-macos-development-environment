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
| `OPENAI_API_KEY` | OpenAI API | [platform.openai.com](https://platform.openai.com) |
| `GOOGLE_API_KEY` | Gemini CLI | [ai.google.dev](https://ai.google.dev) |
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

## .env.example Template

Create this file in your project root as a reference:

```bash
# .env.example - Copy to .env and fill in values
# DO NOT COMMIT .env TO GIT

# AI Services
ANTHROPIC_API_KEY=sk-ant-api03-...
OPENAI_API_KEY=sk-...
GOOGLE_API_KEY=...

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
