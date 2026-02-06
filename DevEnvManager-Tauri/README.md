# DevEnvManager-Tauri

macOS menu bar app for managing development environment tools. Built with Tauri 2 + React.

## For AI Agents

### Quick Facts
- **Type**: Menu bar app (system tray)
- **Stack**: Tauri 2 (Rust backend) + React (TypeScript frontend)
- **Purpose**: Unified control for Mise tools, services, containers, cloud agents

### Key Commands
```bash
# Development
cd DevEnvManager-Tauri && bun tauri dev

# Build
cd DevEnvManager-Tauri && bun tauri build

# Output location
DevEnvManager-Tauri/src-tauri/target/release/bundle/macos/DevEnvManager.app
```

### Architecture
```
DevEnvManager-Tauri/
├── src/                    # React frontend
│   ├── components/         # UI components
│   │   ├── MenuBarPopup.tsx      # Main popup container
│   │   ├── StatusHeader.tsx      # Environment health overview
│   │   ├── QuickActionsBar.tsx   # Mise task buttons
│   │   ├── PackageManagersStatus.tsx  # Mise/Bun/Uv/Pixi cards
│   │   ├── CloudStatus.tsx       # SkyPilot/AWS status
│   │   ├── CloudTab.tsx          # Cloud clusters detail
│   │   ├── ToolsList.tsx         # Mise tools tab
│   │   ├── ServicesList.tsx      # Homebrew services tab
│   │   ├── ContainersList.tsx    # OrbStack containers tab
│   │   └── PortsList.tsx         # Active ports tab
│   ├── hooks/              # Data fetching hooks
│   │   ├── useQuickActions.ts    # Mise task execution
│   │   ├── usePackageManagers.ts # Package manager status
│   │   ├── useCloudStatus.ts     # SkyPilot/AWS data
│   │   ├── useMiseTools.ts       # Mise tools list
│   │   ├── useBrewServices.ts    # Homebrew services
│   │   ├── useContainers.ts      # OrbStack containers
│   │   └── usePorts.ts           # Active ports
│   ├── lib/tauri.ts        # Tauri invoke wrappers
│   └── styles/             # CSS stylesheets
├── src-tauri/              # Rust backend
│   ├── src/
│   │   ├── lib.rs          # App entry, command registration
│   │   ├── tray.rs         # System tray icon setup
│   │   └── commands/       # Tauri commands
│   │       ├── mise.rs           # Mise operations
│   │       ├── homebrew.rs       # Brew services
│   │       ├── orbstack.rs       # Container management
│   │       ├── ports.rs          # Port detection
│   │       ├── package_managers.rs  # Pkg mgr status
│   │       └── cloud.rs          # SkyPilot/AWS
│   └── Cargo.toml          # Rust dependencies
└── package.json            # Bun/npm config
```

## Features

### Quick Actions Bar
Global mise tasks accessible with one click:
| Button | Command | Description |
|--------|---------|-------------|
| Validate | `mise run validate` | Environment health check |
| Doctor | `mise run tools:doctor` | Tool diagnostics |
| Update All | `mise run tools:update` | Update all tools |
| Dashboard | `mise run dashboard` | Open TUI manager |

### Status Header
- Overall environment health indicator (green/amber/red)
- Real-time counts: tools, services, containers, clusters

### Package Managers (2x2 Grid)
| Manager | Actions |
|---------|---------|
| Mise | Status, Doctor, Update |
| Bun | Status, Update |
| Uv | Status, Update |
| Pixi | Status, Update |

### Cloud Status
| Provider | Actions |
|----------|---------|
| SkyPilot | Status, Launch, Stop, SSH, Logs |
| AWS | Status, Configure |

### Tabs

#### Tools Tab
- List all mise-managed tools
- Actions: Install, Update

#### Services Tab (Homebrew)
- List brew services
- Actions: Start, Stop, Restart

#### Containers Tab (OrbStack)
- List OrbStack containers
- Actions: Start, Stop, Restart, Shell, Logs

#### Ports Tab
- List listening TCP ports
- Actions: Kill process

#### Cloud Tab
- Detailed SkyPilot cluster list
- Actions per cluster: SSH, Logs, Stop

## Rust Commands Reference

### Mise Tasks
```rust
run_mise_validate()      // mise run validate
run_mise_doctor()        // mise run tools:doctor
run_mise_update_all()    // mise run tools:update
run_mise_dashboard()     // mise run dashboard
```

### Package Managers
```rust
get_package_managers_status()  // Get versions and health
update_package_manager(name)   // Update via mise
```

### Tools
```rust
list_mise_tools()        // List all tools
install_tool(name)       // Install tool
update_tool(name)        // Update tool
mise_doctor()            // Run diagnostics
```

### Services
```rust
list_brew_services()     // List services
start_service(name)      // Start service
stop_service(name)       // Stop service
restart_service(name)    // Restart service
```

### Containers
```rust
list_containers()        // List OrbStack containers
start_container(name)    // Start container
stop_container(name)     // Stop container
restart_container(name)  // Restart container
shell_container(name)    // Open shell
logs_container(name)     // Get logs
```

### Ports
```rust
list_active_ports()      // List listening ports
kill_port(pid)           // Kill process by PID
```

### Cloud
```rust
get_skypilot_status()    // SkyPilot cluster info
get_aws_status()         // AWS credentials status
launch_skypilot_agent()  // Launch agent
stop_skypilot_agents()   // Stop all agents
list_skypilot_clusters() // List clusters
stop_skypilot_cluster(name)  // Stop specific cluster
ssh_skypilot_cluster(name)   // SSH to cluster
get_skypilot_logs(name)      // Get cluster logs
```

## Requirements

- macOS 14+ (Sonoma)
- Rust toolchain (for building)
- Bun (for frontend)

## Development

```bash
# Install dependencies
bun install

# Development mode (hot reload)
bun tauri dev

# Production build
bun tauri build
```

## UI Design

Industrial-brutalist aesthetic:
- Monospace typography (SF Mono)
- High-contrast colors
- Sharp geometric shapes
- Animated scan-line effects
- Staggered slide-in animations
