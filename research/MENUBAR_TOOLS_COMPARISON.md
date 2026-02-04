# Menu Bar Tools Comparison for macOS Development

> Research conducted: February 2026
> Purpose: Evaluate SwiftBar vs xbar, catalog plugins, identify service manager patterns

## Executive Summary

This document compares macOS menu bar plugin systems and catalogs relevant plugins for development environment management. The goal is to identify patterns similar to [BrewServicesManager](https://github.com/validatedev/BrewServicesManager) for our mise-based dev environment.

**Key Finding**: No general-purpose "mise service manager" exists. We have an opportunity to either:
1. Enhance our existing SwiftBar plugin (`dev-status.1m.sh`) with service controls
2. Build a native Swift app following BrewServicesManager's architecture

---

## 1. SwiftBar vs xbar Comparison

| Aspect | SwiftBar | xbar |
|--------|----------|------|
| **Last Release** | Feb 2025 (v2.0.1) | Oct 2021 (v2.1.7-beta) |
| **GitHub Stars** | 3,707 | 17,999 |
| **Language** | Native Swift | Go + Wails |
| **Development** | **Active** | Stalled (4+ years) |
| **Plugin Compat** | 100% BitBar/xbar | 100% BitBar |
| **Unique Features** | Streamable, Shortcuts, SF Symbols, WebViews | Variables UI, Keyboard shortcuts |
| **Homebrew** | `brew install swiftbar` | Manual download only |
| **macOS Updates** | Ongoing fixes | No Sequoia+ support |

### Verdict: SwiftBar

SwiftBar is the clear winner for active development. The 4-year gap in xbar development makes it unsuitable for production environments that need macOS compatibility updates.

### SwiftBar Unique Capabilities
- **Streamable Plugins** - Long-running processes with real-time updates
- **macOS Shortcuts Integration** - Native automation workflows
- **Ephemeral Plugins** - Temporary menu items via URL scheme
- **SF Symbols** - Native macOS iconography
- **Cron Scheduling** - Advanced refresh patterns
- **WebView Support** - Embed web content in dropdowns

---

## 2. Plugin Ecosystems

### 2.1 Official Repositories

| Repository | Stars | Plugins | Focus |
|------------|-------|---------|-------|
| [matryer/xbar-plugins](https://github.com/matryer/xbar-plugins) | 2,561 | 400+ | General (20+ categories) |
| [swiftbar/swiftbar-plugins](https://github.com/swiftbar/swiftbar-plugins) | 3 | ~10 | SwiftBar-specific |
| [donutheist/SwiftBar-plugins](https://github.com/donutheist/SwiftBar-plugins) | 3 | ~15 | System monitoring |

### 2.2 Development-Related Plugins (xbar-plugins)

#### Homebrew Services
| Plugin | Features |
|--------|----------|
| [brew-services.10m.rb](https://github.com/matryer/xbar-plugins/blob/main/Dev/Homebrew/brew-services.10m.rb) | Start/stop/restart, grouping, hide services |

#### Container Management
| Plugin | Features |
|--------|----------|
| [bitbarDockerContainers.1m.py](https://github.com/matryer/xbar-plugins/blob/main/Tools/bitbarDockerContainers.1m.py) | Docker container start/stop, bulk actions |
| [colima-status.2s.sh](https://github.com/matryer/xbar-plugins/blob/main/Dev/colima-status.2s.sh) | Colima VM start/stop, progress indicators |
| [podman.5s.sh](https://github.com/matryer/xbar-plugins/blob/main/Dev/podman.5s.sh) | Podman machine management |

#### Database Services
| Plugin | Features |
|--------|----------|
| [postgresql-status.1m.sh](https://github.com/matryer/xbar-plugins/blob/main/System/postgresql-status.1m.sh) | pg_ctl control, live stats |
| [redis-memcached.10s.sh](https://github.com/matryer/xbar-plugins/blob/main/System/redis-memcached.10s.sh) | Dual service management, flush |

#### System Services
| Plugin | Features |
|--------|----------|
| [launch-agents.10s.sh](https://github.com/matryer/xbar-plugins/blob/main/System/launch-agents.10s.sh) | LaunchAgents/Daemons load/unload/reload |
| [process-monitoring.1s.sh](https://github.com/matryer/xbar-plugins/blob/main/Dev/process-monitoring.1s.sh) | CPU/memory for specific process |

#### Mise Tools
| Plugin | Features |
|--------|----------|
| [mise-updates.1h.rb](https://github.com/matryer/xbar-plugins/blob/main/Dev/Mise/mise-updates.1h.rb) | Outdated tools, upgrade individual/all |

#### CI/CD Monitoring
| Plugin | Features |
|--------|----------|
| [circleci-check.5m.py](https://github.com/matryer/xbar-plugins/blob/main/Dev/circleci-check.5m.py) | CircleCI build status |
| [drone-status.1m.sh](https://github.com/matryer/xbar-plugins/blob/main/Dev/drone-status.1m.sh) | Drone CI monitoring |

---

## 3. Native macOS Service Manager Apps

### 3.1 Comparison Table

| App | Stars | Focus | Tech | Menu Bar | Open Source |
|-----|-------|-------|------|----------|-------------|
| [BrewServicesManager](https://github.com/validatedev/BrewServicesManager) | 141 | Homebrew services | Swift/SwiftUI | Yes | MIT |
| [Cork](https://github.com/buresdv/Cork) | 4,075 | Homebrew GUI | SwiftUI | Yes | Yes |
| [PHP Monitor](https://github.com/nicoverbruggen/phpmon) | 3,205 | PHP/Valet | Swift | Yes | MIT |
| [Pearcleaner](https://github.com/alienator88/Pearcleaner) | 11,091 | App cleaner + daemons | Swift | Yes | Fair-code |
| [Postgres.app](https://github.com/PostgresApp/PostgresApp) | 7,685 | PostgreSQL | Native | Yes | PostgreSQL |
| [DBngin](https://dbngin.com) | 1,203 | Multi-database | Native | Yes | Proprietary |
| [OrbStack](https://orbstack.dev) | N/A | Docker/Linux VMs | Swift | Yes | Proprietary |

### 3.2 BrewServicesManager Architecture (Reference)

**Key Features:**
- Native Swift 6.2+ / SwiftUI
- Menu bar-only app (no dock icon)
- Real-time service status
- Start/stop/restart services
- Port detection (using `lsof`)
- Service links (custom URLs)
- System domain support (sudo)
- Launch at login
- Auto-refresh

**Architecture Patterns:**
```swift
// Actor-based concurrency for thread safety
actor BrewServicesClient: BrewServicesClientProtocol
actor PortDetector

// Observable state management
@MainActor
@Observable
final class ServicesStore {
    var state: ServicesState = .idle
    var serviceOperations: [String: ServiceOperation] = [:]
}
```

**Port Detection:**
- Recursive child process discovery via `pgrep -P`
- Uses `lsof -nP -iTCP -sTCP:LISTEN`
- Handles complex services with worker processes

---

## 4. Gap Analysis

### What Exists
| Capability | Plugin/App |
|------------|------------|
| Homebrew services | brew-services.10m.rb, BrewServicesManager, Cork |
| Docker containers | bitbarDockerContainers.1m.py, OrbStack |
| Colima/Podman | colima-status.2s.sh, podman.5s.sh |
| PostgreSQL | postgresql-status.1m.sh, Postgres.app, DBngin |
| Redis/Memcached | redis-memcached.10s.sh |
| LaunchAgents | launch-agents.10s.sh, Pearcleaner |
| Mise tool updates | mise-updates.1h.rb |
| CI/CD monitoring | circleci, drone, travis plugins |

### What's Missing
| Gap | Description |
|-----|-------------|
| **Mise service manager** | No start/stop/restart for mise-managed services |
| **Pitchfork integration** | No menu bar control for Pitchfork daemons |
| **Multi-environment dashboard** | No unified view of local + containers + cloud |
| **SkyPilot controls** | No menu bar launch/terminate for cloud agents |
| **DevPod workspace manager** | Limited DevPod integration |

### Our Current Plugin vs BrewServicesManager

| Feature | Our `dev-status.1m.sh` | BrewServicesManager |
|---------|------------------------|---------------------|
| Status display | Yes | Yes |
| Service start/stop | Via mise tasks (terminal) | Native controls |
| Port detection | No | Yes (automatic) |
| Service links | No | Yes (custom URLs) |
| Multi-environment | Yes (Local, Containers, Cloud) | No (Homebrew only) |
| Native app | No (SwiftBar plugin) | Yes (Swift/SwiftUI) |

---

## 5. Recommendations

### Option A: Enhance SwiftBar Plugin (Quick)
Extend `dev-status.1m.sh` to add:
- Direct service controls (not just links to terminal)
- Port detection section
- Service health indicators
- Quick action buttons (start all, stop all)

**Pros:** Fast to implement, leverages existing infrastructure
**Cons:** Limited by SwiftBar capabilities, not as polished

### Option B: Build Native Swift App (Long-term)
Create "MiseServicesManager" following BrewServicesManager patterns:
- Native SwiftUI menu bar app
- Unified view of mise, containers, cloud agents
- Port detection and service links
- Launch at login, auto-refresh

**Pros:** Professional UX, full control, contribution to ecosystem
**Cons:** Significant development effort

### Option C: Hybrid Approach
1. Continue using SwiftBar for status display
2. Add BrewServicesManager for Homebrew services
3. Add Cork for Homebrew package management
4. Use OrbStack for containers

**Pros:** Uses best-in-class existing tools
**Cons:** Multiple apps, no unified experience

---

## 6. Plugin Pattern Reference

### Status Detection
```bash
# Process-based
pgrep service-name

# Port-based
lsof -nP -iTCP -sTCP:LISTEN | grep service

# CLI-based
brew services list --json
mise doctor --json
```

### Action Execution (SwiftBar/xbar)
```bash
echo "Start Service | bash=/usr/local/bin/mise param1=run param2=service:start terminal=false refresh=true"
```

### Visual Indicators
```bash
# Traffic light system
echo "🟢 Running | color=#22c55e"
echo "🔴 Stopped | color=#ef4444"
echo "🟡 Warning | color=#eab308"
echo "⚪ Unknown | color=#6b7280"
```

---

## 7. Resources

### Repositories
- [SwiftBar](https://github.com/swiftbar/SwiftBar) - Native Swift menu bar framework
- [xbar-plugins](https://github.com/matryer/xbar-plugins) - 400+ community plugins
- [BrewServicesManager](https://github.com/validatedev/BrewServicesManager) - Reference architecture
- [Cork](https://github.com/buresdv/Cork) - Modern Homebrew GUI

### Documentation
- [SwiftBar Plugin API](https://github.com/swiftbar/SwiftBar#plugin-api)
- [BitBar Plugin Format](https://github.com/matryer/xbar-plugins/blob/main/CONTRIBUTING.md)

---

## Conclusion

**SwiftBar was the right choice** for our project. It provides active development, native macOS integration, and 100% plugin compatibility with the mature xbar ecosystem.

**Our SwiftBar plugin fills a genuine gap** - no existing mise-focused menu bar tool provides multi-environment status (Local + Containers + DevContainers + Cloud).

**Future consideration:** If we need more sophisticated service management (port detection, service links, native controls), BrewServicesManager's architecture provides an excellent reference for building a dedicated native app.
