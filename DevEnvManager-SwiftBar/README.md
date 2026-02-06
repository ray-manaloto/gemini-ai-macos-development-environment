# DevEnvManager-SwiftBar

Enhanced SwiftBar plugins for the God-Tier macOS Development Environment. Real-time monitoring of mise tools, Homebrew services, OrbStack containers, and active network ports.

## Features

### 🟢 dev-status.5s.sh (Bash Plugin)
- **5-second refresh interval** for responsive updates
- **🖥️ Local Environment**: Mise status, AI agent readiness, tool installation health
- **🍺 Homebrew Services**: Start/stop/restart services with individual controls
- **📦 OrbStack Containers**: Monitor and manage individual containers
- **🐳 DevContainers**: DevPod workspace management
- **☁️ Cloud Agents**: SkyPilot cluster status and controls
- **🔌 Port Detection**: Real-time listening port monitoring via `lsof`
- **⚙️ Settings**: Quick access to project files and documentation

### 🟢 dev-status-stream.swift (Swift StreamablePlugin)
- **Real-time streaming updates** with 30-second refresh cycle
- **Foundation-based** command execution
- **Mise tools listing** with JSON parsing
- **Homebrew services** status and controls
- **OrbStack containers** with individual management
- **Active ports** display with process information
- **SF Symbols** support for modern icons

## Installation

### Prerequisites
- macOS 12+ (Monterey or later)
- SwiftBar installed: https://github.com/swiftbar/SwiftBar
- Mise, Homebrew, and OrbStack (optional but recommended)

### Quick Install

1. **Copy plugins to SwiftBar directory**:
```bash
# Bash plugin (5-second refresh)
cp DevEnvManager-SwiftBar/dev-status.5s.sh ~/Library/Application\ Support/SwiftBar/Plugins/

# Swift plugin (streaming updates)
cp DevEnvManager-SwiftBar/dev-status-stream.swift ~/Library/Application\ Support/SwiftBar/Plugins/
```

2. **Make executable**:
```bash
chmod +x ~/Library/Application\ Support/SwiftBar/Plugins/dev-status.5s.sh
chmod +x ~/Library/Application\ Support/SwiftBar/Plugins/dev-status-stream.swift
```

3. **Reload SwiftBar**:
   - Click SwiftBar menu bar icon
   - Select "Refresh all plugins"
   - Or restart SwiftBar

### Via Mise Task (Recommended)

If you have mise configured:

```bash
mise run menubar:install
```

This will:
- Copy plugins to the correct SwiftBar directory
- Make them executable
- Reload SwiftBar automatically

## Configuration

### Environment Variables

Both plugins support these overrides:

```bash
# Override project directory
export GODTIER_PROJECT_DIR="/path/to/your/project"

# Override mise command
export MISE_CMD="mise"
```

### Plugin Selection

- **Use `dev-status.5s.sh`** for:
  - Frequent updates (5-second refresh)
  - Lower CPU usage
  - Traditional menu bar plugin behavior

- **Use `dev-status-stream.swift`** for:
  - Real-time streaming updates (30-second cycle)
  - Modern Swift implementation
  - Advanced filtering and formatting

## Features in Detail

### 🍺 Homebrew Services Section

Monitor and control Homebrew services:

```
🍺 Homebrew Services
├── ✅ postgresql (started)
│   ├── ⏹️ Stop postgresql
│   └── 🔄 Restart postgresql
├── ⏹️ redis (stopped)
│   └── ▶️ Start redis
└── ❌ mysql (error)
    └── 🔧 Restart mysql
```

**Actions**:
- Start/stop/restart individual services
- View service status at a glance
- Terminal-free service management

### 📦 OrbStack Containers Section

Monitor individual containers:

```
📦 Containers (OrbStack)
├── ✅ OrbStack: Running
├── 🐳 Running Containers:
│   ├── ✅ web-server
│   │   └── ⏹️ Stop web-server
│   ├── ✅ database
│   │   └── ⏹️ Stop database
│   └── ⏹️ cache
│       └── ▶️ Start cache
```

**Actions**:
- Start/stop individual containers
- View container status
- Quick container lifecycle management

### 🔌 Port Detection Section

Real-time listening port monitoring:

```
🔌 Active Ports
├── ✅ Listening ports:
│   ├── 🔗 node on 127.0.0.1:3000
│   ├── 🔗 python on 127.0.0.1:8000
│   ├── 🔗 postgres on 127.0.0.1:5432
│   └── 🔗 redis on 127.0.0.1:6379
```

**Features**:
- Process name and port number
- Automatic sorting and deduplication
- Graceful handling when `lsof` unavailable

## Testing

### Run All Tests

```bash
# Install BATS if needed
mise use -g npm:bats

# Run enhanced plugin tests
bats DevEnvManager-SwiftBar/tests/test_enhanced_plugin.bats

# Run Swift plugin tests
bats DevEnvManager-SwiftBar/tests/test_swift_plugin.bats

# Run both
bats DevEnvManager-SwiftBar/tests/
```

### Test Coverage

**test_enhanced_plugin.bats** (60+ tests):
- File structure and executability
- SwiftBar metadata validation
- Output format and sections
- Homebrew services functionality
- OrbStack containers functionality
- Port detection functionality
- Action parameters and formatting
- Script quality (no sudo, error handling)
- Environment variable support

**test_swift_plugin.bats** (50+ tests):
- File structure and shebang
- SwiftBar streamable metadata
- Swift language features
- Configuration and constants
- Status functions
- Rendering functions
- Streaming implementation
- Command execution
- Output format
- Error handling
- Swift syntax validation

## Troubleshooting

### Plugin Not Appearing in Menu Bar

1. **Check SwiftBar is running**:
   ```bash
   pgrep -l SwiftBar
   ```

2. **Verify plugin location**:
   ```bash
   ls -la ~/Library/Application\ Support/SwiftBar/Plugins/dev-status*
   ```

3. **Check permissions**:
   ```bash
   chmod +x ~/Library/Application\ Support/SwiftBar/Plugins/dev-status.5s.sh
   chmod +x ~/Library/Application\ Support/SwiftBar/Plugins/dev-status-stream.swift
   ```

4. **Reload SwiftBar**:
   - Click menu bar icon → "Refresh all plugins"
   - Or restart SwiftBar

### Plugin Shows Error

1. **Check dependencies**:
   ```bash
   # Bash plugin needs
   command -v mise
   command -v brew
   command -v orb
   command -v lsof
   
   # Swift plugin needs
   which swift
   ```

2. **Test plugin directly**:
   ```bash
   # Bash plugin
   bash ~/Library/Application\ Support/SwiftBar/Plugins/dev-status.5s.sh
   
   # Swift plugin
   swift ~/Library/Application\ Support/SwiftBar/Plugins/dev-status-stream.swift
   ```

3. **Check logs**:
   ```bash
   # SwiftBar logs
   log stream --predicate 'process == "SwiftBar"' --level debug
   ```

### Homebrew Services Not Showing

1. **Verify Homebrew is installed**:
   ```bash
   which brew
   ```

2. **Check services are configured**:
   ```bash
   brew services list
   ```

3. **Verify plugin can access brew**:
   ```bash
   bash -c 'command -v brew && brew services list'
   ```

### Port Detection Not Working

1. **Verify lsof is available**:
   ```bash
   which lsof
   ```

2. **Test lsof directly**:
   ```bash
   lsof -iTCP -sTCP:LISTEN -P -n
   ```

3. **Check permissions**:
   ```bash
   # lsof may need elevated privileges
   sudo lsof -iTCP -sTCP:LISTEN -P -n
   ```

## Architecture

### Bash Plugin (dev-status.5s.sh)

```
Configuration
    ↓
Helper Functions (cmd_exists, get_*_status)
    ↓
Status Collection (parallel execution)
    ↓
Menu Bar Icon (traffic light system)
    ↓
Section Rendering (Local, Homebrew, OrbStack, Ports, etc.)
    ↓
SwiftBar Output
```

**Refresh**: 5 seconds (filename: `.5s.sh`)

### Swift Plugin (dev-status-stream.swift)

```
Configuration
    ↓
Helper Functions (shell, commandExists, get_*_status)
    ↓
Rendering Functions (renderMenuBar, renderServices, etc.)
    ↓
refreshMenu() - Initial render
    ↓
Streaming Loop (30-second cycle)
    ├── sleep(30)
    ├── refreshMenu()
    └── print("~~~")
```

**Refresh**: 30 seconds (streaming)

## Performance

### Bash Plugin
- **Startup**: ~500ms (depends on command availability)
- **Refresh**: 5 seconds
- **CPU**: Minimal (shell commands only)
- **Memory**: ~2-5MB

### Swift Plugin
- **Startup**: ~1-2s (Swift compilation)
- **Refresh**: 30 seconds (streaming)
- **CPU**: Low (Foundation-based)
- **Memory**: ~10-20MB

## Customization

### Adding New Sections

**Bash Plugin**:
```bash
# Add new helper function
get_custom_status() {
    # Your logic here
    echo "status"
}

# Add section rendering
echo "---"
echo "🎯 Custom Section | color=$COLOR_BLUE size=14"
echo "---"
# Your output here
```

**Swift Plugin**:
```swift
// Add new function
func renderCustomSection() -> String {
    var output = "---\n"
    output += "🎯 Custom Section | color=\(COLOR_BLUE) size=14\n"
    output += "---\n"
    // Your output here
    return output
}

// Call in refreshMenu()
func refreshMenu() {
    print(renderMenuBar())
    print(renderCustomSection())
    // ... other sections
}
```

### Changing Colors

Edit color constants at the top of either plugin:

```bash
# Bash
COLOR_CUSTOM="#your-hex-color"

# Swift
let COLOR_CUSTOM = "#your-hex-color"
```

Available colors:
- `#22c55e` - Green
- `#ef4444` - Red
- `#eab308` - Yellow
- `#3b82f6` - Blue
- `#6b7280` - Gray
- `#a855f7` - Purple
- `#f97316` - Orange

## Contributing

To improve these plugins:

1. **Test changes**:
   ```bash
   bats DevEnvManager-SwiftBar/tests/
   ```

2. **Verify output**:
   ```bash
   bash DevEnvManager-SwiftBar/dev-status.5s.sh
   swift DevEnvManager-SwiftBar/dev-status-stream.swift
   ```

3. **Check for regressions**:
   - All tests should pass
   - No new warnings or errors
   - Output format unchanged

## Related Documentation

- [AGENTS.md](../AGENTS.md) - Project knowledge base
- [CLAUDE.md](../CLAUDE.md) - AI assistant context
- [SwiftBar Docs](https://github.com/swiftbar/SwiftBar) - Plugin development
- [Mise Docs](https://mise.jdx.dev/) - Tool management

## License

Part of the God-Tier macOS Development Environment. See main project LICENSE.

---

**Last Updated**: February 2026
**Version**: 3.0 (Bash), 1.0 (Swift)
