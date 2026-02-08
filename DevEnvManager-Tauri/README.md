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
│   │   ├── PortsList.tsx         # Active ports tab
│   │   ├── Toast.tsx             # Individual toast notification
│   │   └── ToastContainer.tsx    # Toast stack container
│   ├── hooks/              # Data fetching hooks
│   │   ├── useQuickActions.ts    # Mise task execution
│   │   ├── usePackageManagers.ts # Package manager status
│   │   ├── useCloudStatus.ts     # SkyPilot/AWS data
│   │   ├── useMiseTools.ts       # Mise tools list
│   │   ├── useBrewServices.ts    # Homebrew services
│   │   ├── useContainers.ts      # OrbStack containers
│   │   ├── usePorts.ts           # Active ports
│   │   └── useProgressOperation.ts  # Tauri event progress
│   ├── contexts/           # React contexts
│   │   └── ToastContext.tsx      # Toast state management
│   ├── lib/tauri.ts        # Tauri invoke wrappers
│   └── styles/             # CSS stylesheets
├── src-tauri/              # Rust backend
│   ├── src/
│   │   ├── lib.rs          # App entry, command registration
│   │   ├── tray.rs         # System tray icon setup
│   │   ├── telemetry.rs    # Telemetry collection
│   │   └── commands/       # Tauri commands
│   │       ├── mise.rs           # Mise operations + progress events
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

## Toast Notifications

All operations show visual feedback via toast notifications:

### Usage
```typescript
import { useToast } from "../contexts/ToastContext";

function MyComponent() {
  const toast = useToast();

  // Simple notifications
  toast.success("Operation completed");
  toast.error("Failed to save", "Network timeout");
  toast.warning("Low disk space");
  toast.info("Opening dashboard...");

  // Progress tracking
  const id = toast.progress("Uploading file", 0);
  toast.updateProgress(id, 50, "Halfway there...");
  toast.removeToast(id);
}
```

### Toast Types
| Type | Color | Auto-dismiss |
|------|-------|--------------|
| Success | Green (#10b981) | 3 seconds |
| Error | Red (#ef4444) | 5 seconds |
| Warning | Amber (#f59e0b) | 4 seconds |
| Info | Blue (#3b82f6) | 3 seconds |
| Progress | Blue | Never (manual) |

### Key Files
| File | Purpose |
|------|---------|
| `src/contexts/ToastContext.tsx` | State management and API |
| `src/components/Toast.tsx` | Individual toast component |
| `src/components/ToastContainer.tsx` | Fixed position container |
| `src/styles/toast.css` | Industrial-brutalist styling |

## Telemetry

All operations emit telemetry events to local storage with optional remote sync.

### Event Emission
```rust
// In Rust commands
use crate::telemetry::telemetry;

telemetry().emit_operation("mise.update_all", "started", None)?;
// ... do work ...
telemetry().emit_operation("mise.update_all", "completed", Some(json!({"tools": 12})))?;
```

### Storage
Events stored in `~/.config/dev-env/telemetry/events.jsonl` as JSON Lines format.

### Key Files
| File | Purpose |
|------|---------|
| `src-tauri/src/telemetry.rs` | Rust telemetry module |
| `config/scripts/telemetry.sh` | Bash helper for scripts |

## Progress Events

Long-running operations emit Tauri events for real-time progress:

### Rust Side
```rust
use tauri::Emitter;

window.emit("operation-progress", json!({
    "operation": "update_all",
    "status": "progress",
    "percent": 50,
    "message": "Updating bun..."
}))?;
```

### React Side
```typescript
import { useProgressOperation } from "../hooks/useProgressOperation";

const progress = useProgressOperation("update_all");
// progress.percent, progress.message, progress.status
```
