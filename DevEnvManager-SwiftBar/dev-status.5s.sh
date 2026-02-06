#!/bin/bash
# <bitbar.title>God-Tier DevEnv Status (Enhanced)</bitbar.title>
# <bitbar.version>v3.0</bitbar.version>
# <bitbar.author>God-Tier macOS Dev Environment</bitbar.author>
# <bitbar.author.github>ray-manaloto</bitbar.author.github>
# <bitbar.desc>Enhanced multi-environment dev environment manager with Homebrew services, OrbStack containers, and port detection</bitbar.desc>
# <bitbar.dependencies>mise,orbstack,devpod,skypilot,brew,lsof</bitbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>false</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

# ==============================================================================
# Configuration
# ==============================================================================
PROJECT_DIR="${GODTIER_PROJECT_DIR:-$HOME/dev/github/ray-manaloto/gemini-ai-macos-development-environment}"
MISE_CMD="${MISE_CMD:-mise}"

# Colors (SwiftBar format: color=hex or color=name)
COLOR_GREEN="#22c55e"
COLOR_RED="#ef4444"
COLOR_YELLOW="#eab308"
COLOR_BLUE="#3b82f6"
COLOR_GRAY="#6b7280"
COLOR_PURPLE="#a855f7"
COLOR_ORANGE="#f97316"

# ==============================================================================
# Helper Functions
# ==============================================================================

# Check if command exists
cmd_exists() {
    command -v "$1" &>/dev/null
}

# Get mise status (returns: ok, warning, error)
get_mise_status() {
    if ! cmd_exists mise; then
        echo "error"
        return
    fi
    
    # Check if mise doctor has issues
    local doctor_output
    doctor_output=$(mise doctor 2>&1)
    if echo "$doctor_output" | grep -q "problem"; then
        echo "warning"
    else
        echo "ok"
    fi
}

# Get OrbStack status
get_orbstack_status() {
    if ! cmd_exists orb; then
        echo "not_installed"
        return
    fi
    
    local status
    status=$(orb status 2>/dev/null || echo "stopped")
    if [[ "$status" == *"running"* ]]; then
        echo "running"
    else
        echo "stopped"
    fi
}

# Get OrbStack containers
get_orbstack_containers() {
    if ! cmd_exists orb; then
        return
    fi
    
    orb list 2>/dev/null | tail -n +2 | while read -r line; do
        if [[ -n "$line" ]]; then
            echo "$line"
        fi
    done
}

# Get Homebrew services status
get_brew_services() {
    if ! cmd_exists brew; then
        return
    fi
    
    brew services list 2>/dev/null | tail -n +2 | while read -r line; do
        if [[ -n "$line" ]]; then
            echo "$line"
        fi
    done
}

# Get active listening ports
get_active_ports() {
    if ! cmd_exists lsof; then
        return
    fi
    
    lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | tail -n +2 | awk '{print $1, $9}' | sort -u
}

# Get DevPod status (count of running workspaces)
get_devpod_status() {
    if ! cmd_exists devpod; then
        echo "not_installed"
        return
    fi
    
    local count
    count=$(devpod list 2>/dev/null | grep -c "Running" || echo "0")
    echo "$count"
}

# Get SkyPilot status (count of UP clusters)
get_skypilot_status() {
    if ! cmd_exists sky; then
        echo "not_installed"
        return
    fi
    
    local count
    count=$(sky status 2>/dev/null | grep -c "UP" || echo "0")
    echo "$count"
}

# Check agent readiness (returns: ok, warning, error)
get_agent_readiness() {
    local script="$PROJECT_DIR/config/scripts/agent-readiness.sh"
    if [[ ! -f "$script" ]]; then
        echo "not_found"
        return
    fi
    
    local output
    output=$(bash "$script" --json 2>/dev/null)
    local issues
    issues=$(echo "$output" | grep -o '"issues":[0-9]*' | cut -d: -f2)
    
    if [[ "$issues" == "0" ]]; then
        echo "ok"
    elif [[ "$issues" -lt 3 ]]; then
        echo "warning"
    else
        echo "error"
    fi
}

# Check autofix status (returns: ok, warning, error)
get_autofix_status() {
    local script="$PROJECT_DIR/config/scripts/autofix.sh"
    if [[ ! -f "$script" ]]; then
        echo "not_found"
        return
    fi
    
    local output
    output=$(bash "$script" --json 2>/dev/null)
    local issues
    issues=$(echo "$output" | grep -o '"issues":[0-9]*' | cut -d: -f2)
    
    if [[ "$issues" == "0" ]]; then
        echo "ok"
    elif [[ "$issues" -lt 3 ]]; then
        echo "warning"
    else
        echo "error"
    fi
}

# ==============================================================================
# Status Collection (parallel for faster refresh)
# ==============================================================================

_tmpdir=$(mktemp -d)
trap 'rm -rf "$_tmpdir"' EXIT

get_mise_status     > "$_tmpdir/mise"     &
get_orbstack_status > "$_tmpdir/orb"      &
get_devpod_status   > "$_tmpdir/devpod"   &
get_skypilot_status > "$_tmpdir/sky"      &
get_agent_readiness > "$_tmpdir/agent"    &
get_autofix_status  > "$_tmpdir/autofix"  &
wait

MISE_STATUS=$(cat "$_tmpdir/mise")
ORB_STATUS=$(cat "$_tmpdir/orb")
DEVPOD_COUNT=$(cat "$_tmpdir/devpod")
SKY_COUNT=$(cat "$_tmpdir/sky")
AGENT_READY=$(cat "$_tmpdir/agent")
AUTOFIX_STATUS=$(cat "$_tmpdir/autofix")

# ==============================================================================
# Menu Bar Icon (Traffic Light System)
# ==============================================================================

# Determine overall status
overall_status="ok"
status_parts=()

# Check local environment
if [[ "$MISE_STATUS" == "error" ]]; then
    overall_status="error"
    status_parts+=("mise")
elif [[ "$MISE_STATUS" == "warning" ]]; then
    [[ "$overall_status" != "error" ]] && overall_status="warning"
fi

# Check containers
if [[ "$ORB_STATUS" == "running" ]]; then
    status_parts+=("orb")
fi

# Check DevPod
if [[ "$DEVPOD_COUNT" != "not_installed" && "$DEVPOD_COUNT" != "0" ]]; then
    status_parts+=("dev:$DEVPOD_COUNT")
fi

# Check cloud
if [[ "$SKY_COUNT" != "not_installed" && "$SKY_COUNT" != "0" ]]; then
    status_parts+=("sky:$SKY_COUNT")
fi

# Build status string
if [[ ${#status_parts[@]} -eq 0 ]]; then
    status_text="idle"
else
    status_text=$(IFS=','; echo "${status_parts[*]}")
fi

# Menu bar display
case "$overall_status" in
    ok)
        if [[ "$status_text" == "idle" ]]; then
            echo "⚪ | color=$COLOR_GRAY"
        else
            echo "🟢 $status_text | color=$COLOR_GREEN"
        fi
        ;;
    warning)
        echo "🟡 $status_text | color=$COLOR_YELLOW"
        ;;
    error)
        echo "🔴 $status_text | color=$COLOR_RED"
        ;;
esac

echo "---"

# ==============================================================================
# 🖥️ LOCAL ENVIRONMENT
# ==============================================================================

echo "🖥️ Local Environment | color=$COLOR_BLUE size=14"
echo "---"

# Mise Status
case "$MISE_STATUS" in
    ok)
        echo "✅ Mise: Healthy"
        ;;
    warning)
        echo "⚠️ Mise: Has warnings | color=$COLOR_YELLOW"
        ;;
    error)
        echo "❌ Mise: Not installed | color=$COLOR_RED"
        ;;
esac

# Mise actions
echo "--📋 Run mise doctor | bash=$MISE_CMD param1=doctor terminal=true"
echo "--🔄 Update all tools | bash=$MISE_CMD param1=run param2=tools:update terminal=true refresh=true"
echo "--📊 Show tools status | bash=$MISE_CMD param1=run param2=tools:status terminal=true"
echo "--🔧 Reinstall tools | bash=$MISE_CMD param1=run param2=tools:install terminal=true refresh=true"

echo "---"

# Agent Readiness
case "$AGENT_READY" in
    ok)
        echo "✅ AI Agent Setup: Ready"
        ;;
    warning)
        echo "⚠️ AI Agent Setup: Has issues | color=$COLOR_YELLOW"
        ;;
    error)
        echo "❌ AI Agent Setup: Needs attention | color=$COLOR_RED"
        ;;
    not_found)
        echo "⚪ AI Agent Setup: Script not found | color=$COLOR_GRAY"
        ;;
esac

echo "--📋 Check agent readiness | bash=bash param1=$PROJECT_DIR/config/scripts/agent-readiness.sh param2=status terminal=true"
echo "--🔧 Fix agent issues | bash=bash param1=$PROJECT_DIR/config/scripts/agent-readiness.sh param2=fix terminal=true refresh=true"

echo "---"

# Autofix Status
case "$AUTOFIX_STATUS" in
    ok)
        echo "✅ Tool Installation: Clean"
        ;;
    warning)
        echo "⚠️ Tool Installation: Has shadows | color=$COLOR_YELLOW"
        ;;
    error)
        echo "❌ Tool Installation: Needs fixing | color=$COLOR_RED"
        ;;
    not_found)
        echo "⚪ Autofix: Script not found | color=$COLOR_GRAY"
        ;;
esac

echo "--📋 Check for issues | bash=bash param1=$PROJECT_DIR/config/scripts/autofix.sh param2=status terminal=true"
echo "--🔧 Auto-fix issues | bash=bash param1=$PROJECT_DIR/config/scripts/autofix.sh param2=fix terminal=true refresh=true"

echo "---"

# Quick Actions - Local
echo "🚀 Quick Actions"
echo "--📊 Launch Dashboard | bash=$MISE_CMD param1=run param2=dashboard terminal=true"
echo "--✅ Validate Environment | bash=$MISE_CMD param1=run param2=validate terminal=true"
echo "--📖 Show Manual | bash=$MISE_CMD param1=run param2=help terminal=true"

# ==============================================================================
# 🍺 HOMEBREW SERVICES
# ==============================================================================

echo "---"
echo "🍺 Homebrew Services | color=$COLOR_ORANGE size=14"
echo "---"

if ! cmd_exists brew; then
    echo "⚪ Homebrew: Not installed | color=$COLOR_GRAY"
    echo "--📥 Install Homebrew | href=https://brew.sh/"
else
    brew_services=$(get_brew_services)
    
    if [[ -z "$brew_services" ]]; then
        echo "⏹️ No services configured"
    else
        echo "$brew_services" | while read -r service_line; do
            if [[ -n "$service_line" ]]; then
                # Parse: service_name started/stopped/error
                service_name=$(echo "$service_line" | awk '{print $1}')
                service_status=$(echo "$service_line" | awk '{print $2}')
                
                case "$service_status" in
                    started)
                        echo "✅ $service_name | color=$COLOR_GREEN"
                        echo "--⏹️ Stop $service_name | bash=brew param1=services param2=stop param3=$service_name terminal=false refresh=true"
                        echo "--🔄 Restart $service_name | bash=brew param1=services param2=restart param3=$service_name terminal=false refresh=true"
                        ;;
                    stopped)
                        echo "⏹️ $service_name"
                        echo "--▶️ Start $service_name | bash=brew param1=services param2=start param3=$service_name terminal=false refresh=true"
                        ;;
                    error)
                        echo "❌ $service_name | color=$COLOR_RED"
                        echo "--🔧 Restart $service_name | bash=brew param1=services param2=restart param3=$service_name terminal=false refresh=true"
                        ;;
                esac
            fi
        done
    fi
fi

# ==============================================================================
# 📦 CONTAINERS (OrbStack)
# ==============================================================================

echo "---"
echo "📦 Containers (OrbStack) | color=$COLOR_BLUE size=14"
echo "---"

case "$ORB_STATUS" in
    running)
        echo "✅ OrbStack: Running | color=$COLOR_GREEN"
        echo "--⏹️ Stop OrbStack | bash=orb param1=stop terminal=false refresh=true"
        echo "--🔄 Restart OrbStack | bash=orb param1=restart terminal=false refresh=true"
        
        # Show individual containers
        containers=$(get_orbstack_containers)
        if [[ -n "$containers" ]]; then
            echo "---"
            echo "🐳 Running Containers:"
            echo "$containers" | while read -r container_line; do
                if [[ -n "$container_line" ]]; then
                    container_name=$(echo "$container_line" | awk '{print $1}')
                    container_status=$(echo "$container_line" | awk '{print $NF}')
                    
                    if [[ "$container_status" == "running" ]]; then
                        echo "--✅ $container_name | color=$COLOR_GREEN"
                        echo "---⏹️ Stop $container_name | bash=orb param1=stop param2=$container_name terminal=false refresh=true"
                    else
                        echo "--⏹️ $container_name"
                        echo "---▶️ Start $container_name | bash=orb param1=start param2=$container_name terminal=false refresh=true"
                    fi
                fi
            done
        fi
        ;;
    stopped)
        echo "⏹️ OrbStack: Stopped"
        echo "--▶️ Start OrbStack | bash=orb param1=start terminal=false refresh=true"
        ;;
    not_installed)
        echo "⚪ OrbStack: Not installed | color=$COLOR_GRAY"
        echo "--📥 Install OrbStack | href=https://orbstack.dev/"
        ;;
esac

# ==============================================================================
# 🐳 DEVCONTAINERS
# ==============================================================================

echo "---"
echo "🐳 DevContainers | color=$COLOR_BLUE size=14"
echo "---"

if [[ "$DEVPOD_COUNT" == "not_installed" ]]; then
    echo "⚪ DevPod: Not installed | color=$COLOR_GRAY"
    echo "--📥 Install via mise | bash=$MISE_CMD param1=use param2=-g param3=aqua:loft-sh/devpod terminal=true refresh=true"
else
    if [[ "$DEVPOD_COUNT" == "0" ]]; then
        echo "⏹️ DevPod: No workspaces running"
    else
        echo "✅ DevPod: $DEVPOD_COUNT workspace(s) running | color=$COLOR_GREEN"
    fi
    
    echo "--📋 List workspaces | bash=devpod param1=list terminal=true"
    echo "--▶️ Start workspace | bash=$MISE_CMD param1=run param2=devcontainer:up terminal=true refresh=true"
    echo "--⏹️ Stop workspace | bash=$MISE_CMD param1=run param2=devcontainer:down terminal=true refresh=true"
    echo "--🔗 SSH to workspace | bash=$MISE_CMD param1=run param2=devcontainer:ssh terminal=true"
    echo "--🗑️ Delete workspace | bash=$MISE_CMD param1=run param2=devcontainer:delete terminal=true refresh=true"
fi

# ==============================================================================
# ☁️ CLOUD AGENTS (SkyPilot)
# ==============================================================================

echo "---"
echo "☁️ Cloud Agents (SkyPilot) | color=$COLOR_BLUE size=14"
echo "---"

if [[ "$SKY_COUNT" == "not_installed" ]]; then
    echo "⚪ SkyPilot: Not installed | color=$COLOR_GRAY"
    echo "--📥 Install SkyPilot | bash=$MISE_CMD param1=use param2=-g param3=pipx:skypilot terminal=true refresh=true"
else
    if [[ "$SKY_COUNT" == "0" ]]; then
        echo "⏹️ SkyPilot: No agents running"
    else
        echo "✅ SkyPilot: $SKY_COUNT agent(s) UP | color=$COLOR_GREEN"
        echo "--🔴 STOP ALL AGENTS | bash=sky param1=down param2=--all param3=-y terminal=true refresh=true color=$COLOR_RED"
    fi
    
    echo "--📋 Show status | bash=$MISE_CMD param1=run param2=agent:status terminal=true"
    echo "--▶️ Launch agent | bash=$MISE_CMD param1=run param2=agent:up terminal=true refresh=true"
    echo "--⏹️ Stop agent | bash=$MISE_CMD param1=run param2=agent:down terminal=true refresh=true"
    echo "--🔗 SSH to agent | bash=$MISE_CMD param1=run param2=agent:ssh terminal=true"
    echo "--📜 View logs | bash=$MISE_CMD param1=run param2=agent:logs terminal=true"
    echo "--🔑 Check AWS credentials | bash=$MISE_CMD param1=run param2=agent:check terminal=true"
fi

# ==============================================================================
# 🔌 PORT DETECTION
# ==============================================================================

echo "---"
echo "🔌 Active Ports | color=$COLOR_PURPLE size=14"
echo "---"

if ! cmd_exists lsof; then
    echo "⚪ lsof: Not available | color=$COLOR_GRAY"
else
    active_ports=$(get_active_ports)
    
    if [[ -z "$active_ports" ]]; then
        echo "⏹️ No listening ports detected"
    else
        echo "✅ Listening ports:"
        echo "$active_ports" | while read -r port_line; do
            if [[ -n "$port_line" ]]; then
                process=$(echo "$port_line" | awk '{print $1}')
                port=$(echo "$port_line" | awk '{print $2}')
                echo "--🔗 $process on $port"
            fi
        done
    fi
fi

# ==============================================================================
# ⚙️ SETTINGS & HELP
# ==============================================================================

echo "---"
echo "⚙️ Settings"
echo "--📂 Open project folder | bash=open param1=$PROJECT_DIR terminal=false"
echo "--📝 Edit mise.toml | bash=open param1=$PROJECT_DIR/config/mise.toml terminal=false"
echo "--🔄 Refresh this menu | refresh=true"
echo "---"
echo "📚 Documentation"
echo "--📖 AGENTS.md | bash=open param1=$PROJECT_DIR/AGENTS.md terminal=false"
echo "--📖 CLAUDE.md | bash=open param1=$PROJECT_DIR/CLAUDE.md terminal=false"
echo "--📖 README.md | bash=open param1=$PROJECT_DIR/README.md terminal=false"
echo "---"
echo "🌐 External Links"
echo "--📚 Mise Docs | href=https://mise.jdx.dev/"
echo "--📚 SwiftBar Docs | href=https://github.com/swiftbar/SwiftBar"
echo "--📚 SkyPilot Docs | href=https://skypilot.readthedocs.io/"
