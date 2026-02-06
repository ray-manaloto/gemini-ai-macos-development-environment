#!/bin/bash
# Setup mise MCP for Claude Desktop and Claude Code CLI
# Cross-platform support: macOS, Linux (including DevContainers), and Windows (Git Bash/MSYS/Cygwin)
# This script configures the Model Context Protocol integration

set -e

echo "🔌 Setting up mise MCP integration..."

# Detect platform
OS="$(uname -s)"
echo "  Platform: $OS"

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

# MCP configuration payload (using jq --argjson for safety)
MCP_CONFIG='{"command": "mise", "args": ["mcp"], "env": {"MISE_EXPERIMENTAL": "1"}}'

# Helper function for safe JSON file writing
# Uses atomic write (temp file + move) to prevent corruption
safe_json_write() {
    local target="$1"
    local content="$2"
    local dir
    dir="$(dirname "$target")"
    
    # Ensure directory exists
    mkdir -p "$dir"
    
    # Check if target is a symlink (security concern)
    if [ -L "$target" ]; then
        echo "  ⚠️  Skipping $target (is a symlink)"
        return 1
    fi
    
    # Create temp file in same directory for atomic move
    local tmp
    tmp="$(mktemp "${dir}/.tmp.XXXXXX")"
    
    # Write content to temp file
    echo "$content" > "$tmp"
    
    # Atomic move
    mv -f "$tmp" "$target"
    
    return 0
}

# Helper function to merge MCP config into existing JSON
merge_mcp_config() {
    local target="$1"
    local mcp_config="$2"
    local json_path="$3"  # e.g., ".mcpServers" or ".mcp.servers"
    
    if [ -f "$target" ]; then
        # Validate existing JSON
        if ! jq '.' "$target" > /dev/null 2>&1; then
            echo "  ⚠️  Invalid JSON in $target, backing up and recreating"
            cp "$target" "${target}.backup.$(date +%Y%m%d%H%M%S)"
            return 1  # Signal to create fresh file
        fi
        
        # Check if path exists and merge
        if jq -e "$json_path" "$target" > /dev/null 2>&1; then
            # Path exists, add/update mise entry
            local new_content
            new_content=$(jq --argjson mise "$mcp_config" "${json_path}.mise = \$mise" "$target")
            safe_json_write "$target" "$new_content"
        else
            # Path doesn't exist, add it
            local parent_path="${json_path%.*}"
            local key_name="${json_path##*.}"
            local new_content
            if [ "$parent_path" = "$json_path" ]; then
                # Top-level key (e.g., .mcpServers)
                new_content=$(jq --argjson mise "$mcp_config" ". + {${key_name#.}: {mise: \$mise}}" "$target")
            else
                # Nested key (e.g., .mcp.servers)
                new_content=$(jq --argjson mise "$mcp_config" "${parent_path} + {${key_name}: {mise: \$mise}}" "$target")
            fi
            safe_json_write "$target" "$new_content"
        fi
        return 0
    fi
    return 1  # File doesn't exist
}

# --- Claude Desktop Configuration ---
configure_claude_desktop() {
    echo "📱 Configuring Claude Desktop..."
    
    local config_path
    
    # Platform-specific config paths with XDG support
    case "$OS" in
        Darwin)
            config_path="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
            ;;
        Linux)
            # Use XDG_CONFIG_HOME if set, otherwise default to ~/.config
            # Note: Claude Desktop on Linux uses "Claude" (capital C) directory
            local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
            config_path="${xdg_config}/Claude/claude_desktop_config.json"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            # Windows via Git Bash/MSYS/Cygwin
            if [ -z "$APPDATA" ]; then
                echo "  ⚠️  APPDATA not set, skipping Claude Desktop configuration"
                return 0
            fi
            # Convert Windows path to POSIX path
            if command -v cygpath &> /dev/null; then
                config_path="$(cygpath -u "$APPDATA")/Claude/claude_desktop_config.json"
            else
                echo "  ⚠️  cygpath not available, attempting direct path conversion"
                config_path="${APPDATA//\\//}/Claude/claude_desktop_config.json"
            fi
            ;;
        *)
            echo "  ⚠️  Unknown platform: $OS - skipping Claude Desktop configuration"
            echo "     Supported platforms: Darwin (macOS), Linux, MINGW/MSYS/CYGWIN (Windows)"
            return 0
            ;;
    esac
    
    mkdir -p "$(dirname "$config_path")"

    if ! merge_mcp_config "$config_path" "$MCP_CONFIG" ".mcpServers"; then
        # Create new file
        local content
        content=$(cat << 'EOF'
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
)
        safe_json_write "$config_path" "$content"
    fi
    echo "  ✅ Claude Desktop configured: $config_path"
}

# --- Claude Code CLI Configuration ---
configure_claude_code() {
    echo "💻 Configuring Claude Code CLI..."

    # Claude Code uses ~/.claude on all platforms
    local claude_dir="$HOME/.claude"
    mkdir -p "$claude_dir"

    # Create MCP servers configuration
    local mcp_servers_path="$claude_dir/mcp_servers.json"
    local content
    content=$(cat << 'EOF'
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
)
    safe_json_write "$mcp_servers_path" "$content"
    echo "  ✅ Claude Code MCP servers configured: $mcp_servers_path"

    # Create or update settings.json
    local settings_path="$claude_dir/settings.json"
    if ! merge_mcp_config "$settings_path" "$MCP_CONFIG" ".mcp.servers"; then
        content=$(cat << 'EOF'
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
)
        safe_json_write "$settings_path" "$content"
    fi
    echo "  ✅ Claude Code settings configured: $settings_path"
}

# --- OpenCode CLI Configuration ---
configure_opencode() {
    echo "🔧 Configuring OpenCode CLI..."
    
    local opencode_dir="$HOME/.opencode"
    mkdir -p "$opencode_dir"
    
    local mcp_path="$opencode_dir/mcp_servers.json"
    local content
    content=$(cat << 'EOF'
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
)
    safe_json_write "$mcp_path" "$content"
    echo "  ✅ OpenCode MCP configured: $mcp_path"
}

# Detect container environment
is_container() {
    [ -f /.dockerenv ] || \
    [ -f /run/.containerenv ] || \
    [ -n "${REMOTE_CONTAINERS:-}" ] || \
    [ -n "${CODESPACES:-}" ] || \
    [ -n "${DEVCONTAINER:-}" ]
}

# Run all configurations
# In containers, skip Claude Desktop (can't write host GUI config)
if is_container; then
    echo "📦 Container environment detected"
    echo "   Skipping Claude Desktop configuration (container cannot access host GUI)"
    configure_claude_code
    configure_opencode
else
    configure_claude_desktop
    configure_claude_code
    configure_opencode
fi

# --- Verify Installation ---
echo ""
echo "🔍 Verifying mise MCP..."

# Check mise version
MISE_VERSION=$(mise --version 2>/dev/null | head -1 || echo "unknown")
echo "  Mise version: $MISE_VERSION"

# Test MCP command availability
if MISE_EXPERIMENTAL=1 mise mcp --help &> /dev/null; then
    echo "  ✅ mise mcp command available"
else
    echo "  ⚠️  mise mcp command not available"
    echo "     This may require a newer mise version (2024.1+)"
    echo "     Run: mise self-update"
fi

echo ""
echo "✨ Done! MCP integration configured."
echo ""
echo "📋 Configuration locations:"
if ! is_container; then
    case "$OS" in
        Darwin)
            echo "   Claude Desktop: ~/Library/Application Support/Claude/claude_desktop_config.json"
            ;;
        Linux)
            echo "   Claude Desktop: \${XDG_CONFIG_HOME:-~/.config}/Claude/claude_desktop_config.json"
            ;;
    esac
fi
echo "   Claude Code:    ~/.claude/settings.json"
echo "   OpenCode:       ~/.opencode/mcp_servers.json"
echo ""
echo "📋 Next steps:"
if ! is_container; then
    echo "   1. Restart Claude Desktop if running"
fi
echo "   2. Start a new Claude Code CLI session"
echo "   3. Ask: 'What tools are installed via mise?'"
echo ""
echo "📖 Documentation: ~/.config/dev-env/research/MISE_MCP_SETUP.md"
