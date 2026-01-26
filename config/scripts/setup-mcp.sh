#!/bin/bash
# Setup mise MCP for Claude Desktop and Claude Code CLI
# This script configures the Model Context Protocol integration

set -e

echo "🔌 Setting up mise MCP integration..."

# Check if mise is installed
if ! command -v mise &> /dev/null; then
    echo "❌ Error: mise is not installed. Please run setup.sh first."
    exit 1
fi

# Check if jq is installed (needed for JSON manipulation)
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq not found, installing via mise..."
    mise use -g jq
fi

# --- Claude Desktop Configuration ---
echo "📱 Configuring Claude Desktop..."

CLAUDE_DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
mkdir -p "$(dirname "$CLAUDE_DESKTOP_CONFIG")"

MCP_CONFIG='{"command": "mise", "args": ["mcp"], "env": {"MISE_EXPERIMENTAL": "1"}}'

if [ -f "$CLAUDE_DESKTOP_CONFIG" ]; then
    # File exists, merge configuration
    if jq -e '.mcpServers' "$CLAUDE_DESKTOP_CONFIG" > /dev/null 2>&1; then
        # mcpServers exists, add/update mise entry
        jq --argjson mise "$MCP_CONFIG" '.mcpServers.mise = $mise' \
            "$CLAUDE_DESKTOP_CONFIG" > "$CLAUDE_DESKTOP_CONFIG.tmp" && \
            mv "$CLAUDE_DESKTOP_CONFIG.tmp" "$CLAUDE_DESKTOP_CONFIG"
    else
        # mcpServers doesn't exist, add it
        jq --argjson mise "$MCP_CONFIG" '. + {mcpServers: {mise: $mise}}' \
            "$CLAUDE_DESKTOP_CONFIG" > "$CLAUDE_DESKTOP_CONFIG.tmp" && \
            mv "$CLAUDE_DESKTOP_CONFIG.tmp" "$CLAUDE_DESKTOP_CONFIG"
    fi
else
    # Create new file
    cat > "$CLAUDE_DESKTOP_CONFIG" << EOF
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
echo "  ✅ Claude Desktop configured: $CLAUDE_DESKTOP_CONFIG"

# --- Claude Code CLI Configuration ---
echo "💻 Configuring Claude Code CLI..."

CLAUDE_CODE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_CODE_DIR"

# Create MCP servers configuration
CLAUDE_CODE_MCP="$CLAUDE_CODE_DIR/mcp_servers.json"
cat > "$CLAUDE_CODE_MCP" << EOF
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
echo "  ✅ Claude Code MCP servers configured: $CLAUDE_CODE_MCP"

# Create or update settings.json
CLAUDE_CODE_SETTINGS="$CLAUDE_CODE_DIR/settings.json"
if [ -f "$CLAUDE_CODE_SETTINGS" ]; then
    # Merge with existing settings
    if jq -e '.mcp' "$CLAUDE_CODE_SETTINGS" > /dev/null 2>&1; then
        jq --argjson mise "$MCP_CONFIG" '.mcp.servers.mise = $mise' \
            "$CLAUDE_CODE_SETTINGS" > "$CLAUDE_CODE_SETTINGS.tmp" && \
            mv "$CLAUDE_CODE_SETTINGS.tmp" "$CLAUDE_CODE_SETTINGS"
    else
        jq --argjson mise "$MCP_CONFIG" '. + {mcp: {servers: {mise: $mise}}}' \
            "$CLAUDE_CODE_SETTINGS" > "$CLAUDE_CODE_SETTINGS.tmp" && \
            mv "$CLAUDE_CODE_SETTINGS.tmp" "$CLAUDE_CODE_SETTINGS"
    fi
else
    cat > "$CLAUDE_CODE_SETTINGS" << EOF
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
echo "  ✅ Claude Code settings configured: $CLAUDE_CODE_SETTINGS"

# --- Verify Installation ---
echo ""
echo "🔍 Verifying mise MCP..."
if MISE_EXPERIMENTAL=1 mise mcp --help &> /dev/null; then
    echo "  ✅ mise mcp command available"
else
    echo "  ⚠️  mise mcp command not available (may need newer mise version)"
fi

echo ""
echo "✨ Done! MCP integration configured."
echo ""
echo "📋 Next steps:"
echo "  1. Restart Claude Desktop if running"
echo "  2. Start a new Claude Code CLI session"
echo "  3. Ask: 'What tools are installed via mise?'"
echo ""
echo "📖 Documentation: ~/.config/dev-env/research/MISE_MCP_SETUP.md"
