# Mise MCP (Model Context Protocol) Setup Guide

This document explains how to configure mise MCP integration for AI assistants.

---

## What is MCP?

The Model Context Protocol (MCP) is a standard protocol that enables AI assistants to interact with development tools and access project context. Mise provides an MCP server that allows AI assistants to query information about your development environment.

When you run `mise mcp`, it starts a server that AI assistants can connect to and query information about your mise-managed development environment. The server communicates over stdin/stdout using JSON-RPC protocol.

> ⚠️ **WARNING**: The MCP feature is experimental and requires enabling experimental features with `MISE_EXPERIMENTAL=1`.

---

## Available Resources

The MCP server exposes the following read-only resources:

| Resource | Description |
|----------|-------------|
| `mise://tools` | Lists all tools managed by mise (names, versions, status, source) |
| `mise://tasks` | Shows available mise tasks (names, descriptions, dependencies, commands) |
| `mise://env` | Displays environment variables defined in mise configuration |
| `mise://config` | Provides mise configuration info (active files, project root, settings) |

---

## Available Tools (Future)

These tools are planned for future implementation:

- `install_tool` - Install a specific tool version
- `run_task` - Execute a mise task

---

## Installation for Claude Desktop

### Configuration File Location

- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **Linux**: `~/.config/claude/claude_desktop_config.json`

### Configuration

Add this to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "mise": {
      "command": "mise",
      "args": ["mcp"],
      "env": {
        "MISE_EXPERIMENTAL": "1"
      }
    }
  }
}
```

After adding this configuration and restarting Claude Desktop, the assistant will be able to:
- Query your installed tools and versions
- List available tasks in your project
- Access environment variables from your mise configuration
- View your mise configuration structure

---

## Installation for Claude Code CLI

### Configuration File Location

Claude Code CLI uses configurations at:
- **User level**: `~/.claude/` or `~/.config/claude/`
- **Project level**: `.claude/` in project root

### Configuration for Claude Code

For Claude Code CLI, create/edit `~/.claude/mcp_servers.json`:

```json
{
  "mcpServers": {
    "mise": {
      "command": "mise",
      "args": ["mcp"],
      "env": {
        "MISE_EXPERIMENTAL": "1"
      }
    }
  }
}
```

Alternatively, you can configure it in `~/.claude/settings.json`:

```json
{
  "mcp": {
    "servers": {
      "mise": {
        "command": "mise",
        "args": ["mcp"],
        "env": {
          "MISE_EXPERIMENTAL": "1"
        }
      }
    }
  }
}
```

---

## Manual Testing

You can test the MCP server manually:

```bash
# Enable experimental features
export MISE_EXPERIMENTAL=1

# Start the MCP server (it will wait for JSON-RPC input on stdin)
mise mcp
```

---

## Example Queries

When integrated with an AI assistant, you can ask questions like:

- "What version of Node.js is this project using?"
- "List all the tasks available in this project"
- "What environment variables are set by mise?"
- "Show me the mise configuration for this project"

The AI assistant will query the MCP server to provide accurate, up-to-date information about your development environment.

---

## Technical Details

- **Implementation**: `src/cli/mcp.rs` in mise repository
- **Protocol**: JSON-RPC 2.0 over stdio
- **Library**: Uses `rmcp` crate (ServerHandler trait)
- **Compatibility**: Any AI assistant that supports MCP

---

## Prerequisites

1. **Mise installed**: Ensure mise is installed and in your PATH
2. **Experimental features**: Must set `MISE_EXPERIMENTAL=1`
3. **Valid mise config**: Should have a `mise.toml` or `.mise.toml` in your project

---

## Automation Script

Add this to your `setup.sh` to automatically configure mise MCP:

```bash
#!/bin/bash

# Configure mise MCP for Claude Desktop (macOS)
CLAUDE_DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
mkdir -p "$(dirname "$CLAUDE_DESKTOP_CONFIG")"

# Create or update Claude Desktop config
if [ -f "$CLAUDE_DESKTOP_CONFIG" ]; then
    # Merge with existing config using jq
    jq '.mcpServers.mise = {"command": "mise", "args": ["mcp"], "env": {"MISE_EXPERIMENTAL": "1"}}' \
        "$CLAUDE_DESKTOP_CONFIG" > "$CLAUDE_DESKTOP_CONFIG.tmp" && \
        mv "$CLAUDE_DESKTOP_CONFIG.tmp" "$CLAUDE_DESKTOP_CONFIG"
else
    cat > "$CLAUDE_DESKTOP_CONFIG" << 'EOF'
{
  "mcpServers": {
    "mise": {
      "command": "mise",
      "args": ["mcp"],
      "env": {
        "MISE_EXPERIMENTAL": "1"
      }
    }
  }
}
EOF
fi

# Configure mise MCP for Claude Code CLI
CLAUDE_CODE_CONFIG="$HOME/.claude/settings.json"
mkdir -p "$(dirname "$CLAUDE_CODE_CONFIG")"

if [ -f "$CLAUDE_CODE_CONFIG" ]; then
    jq '.mcp.servers.mise = {"command": "mise", "args": ["mcp"], "env": {"MISE_EXPERIMENTAL": "1"}}' \
        "$CLAUDE_CODE_CONFIG" > "$CLAUDE_CODE_CONFIG.tmp" && \
        mv "$CLAUDE_CODE_CONFIG.tmp" "$CLAUDE_CODE_CONFIG"
else
    cat > "$CLAUDE_CODE_CONFIG" << 'EOF'
{
  "mcp": {
    "servers": {
      "mise": {
        "command": "mise",
        "args": ["mcp"],
        "env": {
          "MISE_EXPERIMENTAL": "1"
        }
      }
    }
  }
}
EOF
fi

echo "✅ Mise MCP configured for Claude Desktop and Claude Code CLI"
```

---

## Related Links

- [Mise MCP Documentation](https://mise.jdx.dev/mcp.html)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Claude Desktop MCP Setup](https://docs.anthropic.com/en/docs/claude-desktop/mcp)

---

*Generated: January 2026*
