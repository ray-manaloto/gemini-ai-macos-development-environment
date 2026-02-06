# DevEnvManager

Native macOS menu bar app for managing development tools (Mise, OrbStack, DevPod, SkyPilot, Homebrew Services).

## Quick Install (Recommended)

Install the prebuilt app using mise:

```bash
mise run devenv-app:install
```

This downloads the latest release from GitHub and installs it to `~/Applications/`.

### Other Commands

| Command | Description |
|---------|-------------|
| `mise run devenv-app:status` | Check installation and running status |
| `mise run devenv-app:open` | Open the app |
| `mise run devenv-app:quit` | Quit the app |
| `mise run devenv-app:restart` | Restart the app |
| `mise run devenv-app:uninstall` | Remove app, preferences, and cache |
| `mise run devenv-app:logs` | View system logs |

## Requirements

- macOS 14.0+ (Sonoma)
- Universal Binary (Apple Silicon + Intel)

---

## Building from Source (Contributors)

> **Note**: Building from source requires the full Xcode.app (~12GB). Most users should use `mise run devenv-app:install` instead.

### Build Requirements

- **Xcode 15.0+** (Full App Required) - Command Line Tools alone are NOT sufficient
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

> **Important**: SwiftUI's `MenuBarExtra` requires the full Xcode.app to build properly. Building with `swiftc` or Xcode Command Line Tools will compile but the menu bar icon won't appear.

### Build Steps

#### 1. Install Xcode

Download and install [Xcode from the Mac App Store](https://apps.apple.com/us/app/xcode/id497799835) (~12GB).

After installation, select Xcode as the active developer directory:
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

#### 2. Build with Mise

```bash
mise run devenv-app:build
```

This installs XcodeGen (if needed), generates the Xcode project, builds, and installs the app.

#### 3. Or Build Manually

```bash
# Install XcodeGen
mise use -g "ubi:yonaskolb/XcodeGen"
# or: brew install xcodegen

# Generate and build
cd DevEnvManager
xcodegen generate
xcodebuild -scheme DevEnvManager -configuration Release build

# Install
cp -R build/Release/DevEnvManager.app ~/Applications/
open ~/Applications/DevEnvManager.app
```

The app will appear in your menu bar.

## Verification (Without Full Xcode)

You can verify the code compiles correctly without Xcode using type-checking:
```bash
swiftc -typecheck -sdk $(xcrun --show-sdk-path) -target arm64-apple-macosx14.0 \
  $(find . -name "*.swift" -not -path "./Tests/*" | tr '\n' ' ')
```
This validates syntax and types but won't produce a runnable app.

## Project Structure

```
DevEnvManager/
├── App/                    # App entry point, delegate
├── Domain/                 # Business logic by tool
│   ├── Mise/              # Mise CLI integration
│   ├── Homebrew/          # Brew services integration
│   └── OrbStack/          # Containers (future)
├── Services/              # Cross-cutting business logic
│   ├── Stores/            # @Observable state stores
│   └── PortDetector/      # lsof-based port detection
├── Infrastructure/        # External dependencies
│   ├── Shell/             # Command execution
│   └── Cache/             # Disk persistence
├── Presentation/          # UI layer
│   ├── MenuBar/           # Main dropdown views
│   │   ├── Components/    # Row views
│   │   └── Sections/      # Services, Tools sections
│   └── Shared/            # Reusable components
├── Design/                # Layout constants, tokens
├── Utilities/             # Extensions, helpers
└── Tests/                 # Unit tests, fake clients
```

## Architecture

The app follows a **domain-driven architecture** inspired by [BrewServicesManager](https://github.com/yimidaw27/BrewServicesManager):

- **Actors** for thread-safe CLI execution (MiseClient, PortDetector)
- **@Observable** stores for reactive state management
- **Protocol abstraction** for testability
- **MenuBarExtra** for SwiftUI menu bar integration

See `research/DEVENV_MANAGER_ARCHITECTURE.md` for full details.

## Key Features

- [x] Mise tool listing with status indicators
- [x] Tool install/update/uninstall operations
- [x] Mise task execution
- [x] Disk caching for instant startup
- [x] Settings panel with @AppStorage persistence
- [x] Homebrew services (Sprint 2)
- [x] Port detection via lsof (Sprint 2)
- [x] OrbStack Linux machines (Sprint 3)
- [x] Docker containers via OrbStack (Sprint 3)
- [x] Docker Compose project grouping (Sprint 3)
- [ ] DevPod workspaces (Sprint 4)
- [ ] SkyPilot clusters (Sprint 4)
- [ ] CLI command copy (Sprint 4)

## Development

### Running Tests

```bash
# Using xcodebuild
xcodebuild test -scheme DevEnvManager -destination 'platform=macOS'

# Or in Xcode: Cmd+U
```

### Adding a New Tool Domain

1. Create actor client in `Domain/<Tool>/<Tool>Client.swift`
2. Create protocol in `Domain/<Tool>/<Tool>ClientProtocol.swift`
3. Create models in `Domain/<Tool>/<Tool>Models.swift`
4. Create store in `Services/Stores/<Tool>Store.swift`
5. Add UI section in `Presentation/MenuBar/Sections/`
6. Wire up in `DevEnvManagerApp.swift`

## License

MIT
