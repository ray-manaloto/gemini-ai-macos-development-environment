# DevContainer Guide

Complete guide for using DevContainers with the God-Tier macOS Development Environment.

---

## Quick Start

### Mise Tasks (Recommended)

```bash
mise run devcontainer:up        # Start DevContainer
mise run devcontainer:ssh       # SSH into container
mise run devcontainer:status    # Check status
mise run devcontainer:down      # Stop container
```

### VS Code / Cursor

```bash
# Open in DevContainer
code .
# Press F1 → "Dev Containers: Reopen in Container"
```

### DevPod

```bash
devpod up .
devpod ssh .
```

### GitHub Codespaces

Click "Code" → "Codespaces" → "Create codespace on main"

---

## Installation Methods

### Method 1: DevContainer Feature (Recommended)

Uses the `devcontainer.json` with mise DevContainer feature:

```bash
# Clone repo
git clone https://github.com/ray-manaloto/gemini-ai-macos-development-environment.git
cd gemini-ai-macos-development-environment

# Open in VS Code and reopen in container
code .
```

### Method 2: Standalone Dockerfile

Build and run the Dockerfile directly:

```bash
# Build
docker build -t god-tier-dev .devcontainer/

# Run interactively
docker run -it --rm \
  -v "$(pwd):/workspaces/project" \
  -w /workspaces/project \
  god-tier-dev

# Run with persistent volumes
docker run -it --rm \
  -v "$(pwd):/workspaces/project" \
  -v god-tier-mise-data:/home/vscode/.local/share/mise \
  -v god-tier-mise-config:/home/vscode/.config/mise \
  -w /workspaces/project \
  god-tier-dev
```

---

## Configuration

### File Structure

```
.devcontainer/
├── devcontainer.json      # Primary config (uses mise feature)
├── Dockerfile             # Standalone Docker build
└── scripts/
    ├── post-create.sh     # Runs after container creation
    └── post-attach.sh     # Runs on each attach
```

### Key Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| Base Image | `mcr.microsoft.com/devcontainers/base:ubuntu-22.04` | Secure, maintained base |
| User | `vscode` (non-root) | Security best practice |
| Shell | `zsh` | Modern shell with plugins |
| Mise Trusted Paths | `/workspaces` | Auto-trust workspace configs |

### Environment Variables

Passed from host to container via `remoteEnv`:

```json
{
  "remoteEnv": {
    "ANTHROPIC_API_KEY": "${localEnv:ANTHROPIC_API_KEY}",
    "OPENAI_API_KEY": "${localEnv:OPENAI_API_KEY}",
    "GITHUB_TOKEN": "${localEnv:GITHUB_TOKEN}"
  }
}
```

Set these in your host shell before launching:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
export GITHUB_TOKEN=ghp_...
```

---

## Lifecycle Scripts

### Execution Order

```
1. initializeCommand     # On host, before container
2. onCreateCommand       # First creation only
3. updateContentCommand  # On content refresh
4. postCreateCommand     # After creation
5. postStartCommand      # Every start
6. postAttachCommand     # Every attach
```

### What Each Script Does

| Script | File | Purpose |
|--------|------|---------|
| `onCreateCommand` | inline | Copy mise.toml, trust configs |
| `postCreateCommand` | `post-create.sh` | Run `mise run setup:container` |
| `postAttachCommand` | `post-attach.sh` | Verify tools, run `mise doctor` |

---

## Start / Stop / Restart

### Mise Tasks (Recommended)

| Command | Description |
|---------|-------------|
| `mise run devcontainer:status` | Show all DevContainers |
| `mise run devcontainer:up` | Start DevContainer |
| `mise run devcontainer:down` | Stop DevContainer |
| `mise run devcontainer:restart` | Restart DevContainer |
| `mise run devcontainer:ssh` | SSH into container |
| `mise run devcontainer:logs` | View container logs |
| `mise run devcontainer:exec -- <cmd>` | Execute command |
| `mise run devcontainer:build` | Build image |
| `mise run devcontainer:rebuild` | Rebuild without cache |
| `mise run devcontainer:delete` | Delete container and volumes |

Provider selection (default: devpod):
```bash
PROVIDER=docker mise run devcontainer:up
PROVIDER=devpod mise run devcontainer:up
```

### VS Code

| Action | Command Palette (F1) |
|--------|---------------------|
| Start | "Dev Containers: Reopen in Container" |
| Stop | "Dev Containers: Close Remote Connection" |
| Restart | "Dev Containers: Rebuild Container" |
| Rebuild (no cache) | "Dev Containers: Rebuild Container Without Cache" |

### DevPod

```bash
# Start
devpod up .

# Stop
devpod stop .

# Restart
devpod stop . && devpod up .

# Delete
devpod delete .
```

### Docker CLI

```bash
# List running containers
docker ps

# Stop container
docker stop <container_id>

# Start stopped container
docker start <container_id>

# Restart
docker restart <container_id>

# Remove
docker rm -f <container_id>
```

---

## Status & Health

### Check Environment Status

```bash
# Inside container
mise run env:status

# Quick health check
mise doctor

# List installed tools
mise ls --installed
```

### Check Container Status

```bash
# List containers
docker ps -a | grep god-tier

# Container logs
docker logs <container_id>

# Inspect container
docker inspect <container_id>
```

### Verify Tools

```bash
# Run verification script
.devcontainer/scripts/post-attach.sh

# Manual checks
bun --version
node --version
uv --version
pixi --version
```

---

## Logs & Debugging

### View Container Logs

```bash
# Docker logs
docker logs <container_id>
docker logs -f <container_id>  # Follow

# DevPod logs
devpod logs .
```

### DevContainer Extension Logs (VS Code)

1. Press F1 → "Developer: Show Logs"
2. Select "Dev Containers"

### Common Log Locations

| Log | Location |
|-----|----------|
| Mise logs | `~/.local/share/mise/logs/` |
| Shell history | `/commandhistory/.zsh_history` |
| Startup script output | Container stdout |

### Debug Mode

```bash
# Run with verbose mise
MISE_VERBOSE=1 mise install

# Debug shell
bash -x .devcontainer/scripts/post-create.sh
```

---

## Diagnosing Issues

### Problem: Container fails to start

```bash
# Check Docker status
docker info

# Try building manually
docker build -t test .devcontainer/

# Check for build errors
docker build --no-cache -t test .devcontainer/ 2>&1 | tee build.log
```

### Problem: Tools not found

```bash
# Ensure mise is activated
eval "$(mise activate zsh)"

# Reinstall tools
mise install --yes

# Check shims
ls -la ~/.local/share/mise/shims/
```

### Problem: Permission denied

```bash
# Check user
whoami  # Should be: vscode

# Check permissions
ls -la ~/.local/
ls -la ~/.config/mise/
```

### Problem: Config not trusted

```bash
# Trust configs manually
mise trust ~/.config/mise/config.toml
mise trust /workspaces/*/.mise.toml
```

### Problem: GitHub rate limits (during build)

```bash
# Use authenticated Docker build
docker build \
  --build-arg GITHUB_TOKEN=$GITHUB_TOKEN \
  -t god-tier-dev .devcontainer/
```

---

## AI/LLM Agent Integration

### Context Files

The container includes AI-friendly context files:

| File | Purpose |
|------|---------|
| `AGENTS.md` | Project knowledge base for AI agents |
| `CLAUDE.md` | Claude-specific context and patterns |
| `llms.txt` | LLM-readable documentation index |
| `.claude/` | Claude Code commands and skills |
| `.cursor/` | Cursor IDE configuration |

### API Keys

Pass API keys via host environment:

```bash
# On host, add to ~/.zshrc or ~/.bashrc
export ANTHROPIC_API_KEY=sk-ant-...
export OPENAI_API_KEY=sk-...
```

These are automatically available in the container.

### MCP (Model Context Protocol)

The container is MCP-ready:

```bash
# Setup MCP
mise run setup-mcp

# Verify
cat ~/.config/claude/mcp_config.json
```

---

## Port Forwarding

### Default Ports

| Port | Service | Auto-Forward |
|------|---------|--------------|
| 3000 | React/Next.js | notify |
| 5000 | Flask | notify |
| 8000 | Django/FastAPI | notify |
| 8080 | General HTTP | silent |
| 8888 | Jupyter | notify |

### Add Custom Ports

In `devcontainer.json`:

```json
{
  "forwardPorts": [3000, 5000, 8000, 8080, 8888, 9000],
  "portsAttributes": {
    "9000": { "label": "Custom", "onAutoForward": "notify" }
  }
}
```

---

## Volumes & Persistence

### Persistent Volumes

```json
{
  "mounts": [
    "source=${localWorkspaceFolderBasename}-mise-data,target=/home/vscode/.local/share/mise,type=volume",
    "source=${localWorkspaceFolderBasename}-mise-config,target=/home/vscode/.config/mise,type=volume",
    "source=${localWorkspaceFolderBasename}-shell-history,target=/commandhistory,type=volume"
  ]
}
```

### Manage Volumes

```bash
# List volumes
docker volume ls | grep mise

# Remove volumes (reset)
docker volume rm $(docker volume ls -q | grep mise)

# Inspect volume
docker volume inspect <volume_name>
```

---

## Customization

### Add VS Code Extensions

Edit `.devcontainer/devcontainer.json`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "existing.extension",
        "your.new-extension"
      ]
    }
  }
}
```

### Add System Packages

Edit `.devcontainer/Dockerfile`:

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    your-package \
    && rm -rf /var/lib/apt/lists/*
```

### Add Mise Tools

Edit `config/mise.toml`:

```toml
[tools]
"your-tool" = "latest"
```

---

## Best Practices Applied

### Security
- Non-root user (`vscode`)
- Read-only SSH key mounts
- Secrets via environment variables only
- Minimal base image

### Performance
- Named volumes for `mise` data (10x faster than bind mounts)
- Layer caching in Dockerfile
- Parallel lifecycle commands where possible

### AI/LLM Integration
- Context files included (AGENTS.md, CLAUDE.md)
- API key passthrough via `remoteEnv`
- MCP-ready configuration
- Shell history persistence for agent context

---

## Troubleshooting Checklist

- [ ] Docker Desktop running?
- [ ] Sufficient disk space? (`docker system df`)
- [ ] Network connectivity? (`curl -I https://github.com`)
- [ ] Host environment variables set?
- [ ] Correct user? (`whoami` → `vscode`)
- [ ] Mise trusted? (`mise trust`)
- [ ] Shims in PATH? (`echo $PATH | grep mise`)

---

## AI Agent Sandboxing

For enhanced security when running AI coding agents, this project supports two sandboxing approaches.

### Option 1: Docker Sandboxes (Built-in)

Docker Desktop 4.40+ includes native AI sandbox support with microVM isolation.

```bash
# Launch Claude Code in sandbox (macOS/Windows)
docker sandbox run claude ~/dev/github/ray-manaloto/gemini-ai-macos-development-environment

# With network restrictions
docker sandbox run --net-deny-all --net-allow github.com,api.anthropic.com claude .
```

**Features:**
- MicroVM isolation (not just containers)
- Network allow/deny lists
- Docker-in-Docker isolated from host
- Automatic environment detection

**Limitations:**
- Requires Docker Desktop 4.40+
- macOS/Windows only (Linux uses containers)
- Environment variables require sandbox restart

### Option 2: Leash (Policy-Based Governance)

[Leash](https://github.com/strongdm/leash) provides policy-based AI agent governance using Cedar policies.

#### Installation

```bash
# Install via mise (recommended)
mise use -g "npm:@strongdm/leash"

# Verify
leash --version
```

#### Quick Start

```bash
# Launch Claude Code with Control UI
leash --open claude

# Control UI available at http://localhost:18080
```

#### Configuration

1. Copy the template to your config directory:

```bash
cp .devcontainer/leash-config.toml ~/.config/leash/config.toml
```

2. Edit with your project path and preferences

3. Copy Cedar policies:

```bash
mkdir -p ~/.config/leash/policies
cp .devcontainer/sandbox-policies/*.cedar ~/.config/leash/policies/
```

#### Operation Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| **Record** | All operations allowed, events logged | Learning agent behavior |
| **Shadow** | Policies evaluated, not enforced | Testing policies safely |
| **Enforce** | Policies enforced, violations blocked | Production governance |

Start in Record mode, review in Control UI, then progress to Enforce.

#### Cedar Policies

Three policy templates are included in `.devcontainer/sandbox-policies/`:

| Policy | Description |
|--------|-------------|
| `default.cedar` | Balanced security for development |
| `permissive.cedar` | Trusted environments, convenience prioritized |
| `restrictive.cedar` | Untrusted code review, minimal permissions |

Example policy rules:

```cedar
// Allow workspace file access
permit (principal, action == Action::"FileOpenReadWrite", resource)
when { resource in [ Dir::"/workspace/" ] };

// Block sensitive files
forbid (principal, action == Action::"read", resource)
when { resource.path.contains("/.ssh/") };

// Allow specific network hosts
permit (principal, action == Action::"NetworkConnect", resource)
when { resource.host in [ "api.anthropic.com", "github.com" ] };
```

#### MCP Governance

Leash can govern MCP (Model Context Protocol) tool calls:

```cedar
// Block dangerous MCP tools
forbid (principal, action == Action::"McpCall", resource == MCP::Tool::"execute-shell")
when { resource in [ MCP::Server::"*" ] };
```

### Comparison

| Feature | Docker Sandbox | Leash |
|---------|---------------|-------|
| Isolation | MicroVM | Container + eBPF |
| Policy Language | CLI flags | Cedar (expressive) |
| Network Control | Allow/deny lists | Hostname policies |
| Secret Injection | Environment vars | Proxy injection |
| MCP Governance | No | Yes |
| Telemetry | Minimal | Configurable |
| Control UI | No | Yes (localhost:18080) |

### Recommendation

- **Quick isolation**: Use Docker Sandboxes
- **Fine-grained control**: Use Leash with Cedar policies
- **MCP governance**: Leash required

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [AGENTS.md](AGENTS.md) | Project knowledge base |
| [CLAUDE.md](CLAUDE.md) | AI assistant context |
| [SECRETS.md](SECRETS.md) | Secrets management |
| [SKYPILOT.md](SKYPILOT.md) | Cloud agent setup |
