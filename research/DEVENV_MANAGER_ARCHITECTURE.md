# DevEnvManager Architecture Guide

> Comprehensive architecture patterns for building a native macOS menu bar app to manage development tools (Mise, OrbStack, DevPod, SkyPilot, Homebrew Services).

**Research Sources:**
- [BrewServicesManager](https://github.com/yimidaw27/BrewServicesManager) - Primary reference implementation
- [Ice](https://github.com/jordanbaird/Ice) - Modern SwiftUI menu bar patterns
- [Stats](https://github.com/exelban/stats) - AppKit-based system monitor
- [Hidden Bar](https://github.com/dwarvesf/hidden) - Simple menu bar manipulation
- [Cork](https://github.com/buresdv/Cork) - Homebrew GUI with streaming
- [ShellOut](https://github.com/JohnSundell/ShellOut) - Shell execution library

---

## Table of Contents

1. [Technology Stack](#1-technology-stack)
2. [Project Structure](#2-project-structure)
3. [Architecture Overview](#3-architecture-overview)
4. [Actor-Based Concurrency](#4-actor-based-concurrency)
5. [State Management](#5-state-management)
6. [Shell Command Execution](#6-shell-command-execution)
7. [Menu Bar Setup](#7-menu-bar-setup)
8. [SwiftUI Patterns](#8-swiftui-patterns)
9. [Error Handling](#9-error-handling)
10. [Caching Strategy](#10-caching-strategy)
11. [Testing Approach](#11-testing-approach)
12. [Security Considerations](#12-security-considerations)
13. [Implementation Roadmap](#13-implementation-roadmap)

---

## 1. Technology Stack

### Recommended Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Language | Swift 6.0+ | Modern concurrency, strict checking |
| UI Framework | SwiftUI | Native macOS, declarative |
| Concurrency | Swift Actors | Thread-safe by design |
| State | @Observable | Modern reactive updates (macOS 14+) |
| Target | macOS 14.0+ (Sonoma) | MenuBarExtra, @Observable support |

### Why Not AppKit?

While Stats uses AppKit, SwiftUI is preferred for DevEnvManager because:
- **MenuBarExtra** provides native menu bar support
- **@Observable** simplifies state management
- **Declarative syntax** is more maintainable
- **BrewServicesManager** proves the pattern works

---

## 2. Project Structure

```
DevEnvManager/
├── App/
│   ├── DevEnvManagerApp.swift      # @main entry point
│   └── AppDelegate.swift           # NSApplicationDelegate bridge
│
├── Domain/                         # Business logic by tool
│   ├── Mise/
│   │   ├── MiseClient.swift        # Actor for mise CLI
│   │   ├── MiseClientProtocol.swift
│   │   ├── MiseModels.swift        # Tool, Version, etc.
│   │   └── MiseError.swift
│   │
│   ├── OrbStack/
│   │   ├── OrbStackClient.swift    # Actor for orb CLI
│   │   ├── OrbStackClientProtocol.swift
│   │   └── OrbStackModels.swift    # Container, VM, etc.
│   │
│   ├── DevPod/
│   │   ├── DevPodClient.swift      # Actor for devpod CLI
│   │   ├── DevPodClientProtocol.swift
│   │   └── DevPodModels.swift      # Workspace, Provider
│   │
│   ├── SkyPilot/
│   │   ├── SkyPilotClient.swift    # Actor for sky CLI
│   │   ├── SkyPilotClientProtocol.swift
│   │   └── SkyPilotModels.swift    # Cluster, Cost
│   │
│   └── Homebrew/
│       ├── BrewServicesClient.swift
│       ├── BrewServicesClientProtocol.swift
│       └── BrewModels.swift        # Service, Status
│
├── Services/                       # Cross-cutting business logic
│   ├── Stores/
│   │   ├── ToolsStore.swift        # Mise state (@Observable)
│   │   ├── ContainersStore.swift   # OrbStack state
│   │   ├── WorkspacesStore.swift   # DevPod state
│   │   ├── ClustersStore.swift     # SkyPilot state
│   │   └── ServicesStore.swift     # Homebrew state
│   │
│   ├── PortDetector.swift          # Actor for lsof port scanning
│   └── AppSettings.swift           # User preferences (@Observable)
│
├── Infrastructure/
│   ├── Shell/
│   │   ├── CommandExecutor.swift   # Process wrapper
│   │   ├── CommandResult.swift
│   │   └── FileHandle+SafeRead.swift
│   │
│   ├── Cache/
│   │   ├── DiskCache.swift         # JSON persistence
│   │   └── CacheModels.swift
│   │
│   └── Privileges/
│       └── PrivilegeEscalator.swift # Sudo via NSAppleScript
│
├── Presentation/
│   ├── MenuBar/
│   │   ├── MenuBarRootView.swift   # Main dropdown
│   │   ├── Sections/
│   │   │   ├── LocalEnvironmentSection.swift
│   │   │   ├── ContainersSection.swift
│   │   │   ├── WorkspacesSection.swift
│   │   │   ├── ClustersSection.swift
│   │   │   └── ServicesSection.swift
│   │   └── Components/
│   │       ├── ToolRowView.swift
│   │       ├── ContainerRowView.swift
│   │       ├── ServiceRowView.swift
│   │       └── ActionPopoverView.swift
│   │
│   ├── Settings/
│   │   └── SettingsView.swift
│   │
│   └── Shared/
│       ├── StatusBadge.swift
│       ├── ProgressOverlay.swift
│       └── ErrorBanner.swift
│
├── Design/
│   ├── LayoutConstants.swift       # Centralized sizing
│   ├── Colors.swift                # Semantic colors
│   └── ViewModifiers.swift         # Reusable modifiers
│
├── Utilities/
│   ├── Logger+Extensions.swift
│   └── URL+Extensions.swift
│
└── Tests/
    ├── Domain/
    │   ├── FakeMiseClient.swift
    │   ├── MiseClientTests.swift
    │   └── ToolsStoreTests.swift
    │
    └── Infrastructure/
        └── CommandExecutorTests.swift
```

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    DevEnvManagerApp (@main)                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    MenuBarExtra                           │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │   │
│  │  │ Local Env   │ │ Containers  │ │  Settings   │        │   │
│  │  │ Section     │ │ Section     │ │  View       │        │   │
│  │  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘        │   │
│  │         └───────────────┴───────────────┘                │   │
│  │                         │                                 │   │
│  │                 @Environment injection                    │   │
│  └─────────────────────────┼────────────────────────────────┘   │
└────────────────────────────┼─────────────────────────────────────┘
                             │
     ┌───────────────────────┼───────────────────────┐
     │                       │                       │
┌────▼─────┐          ┌──────▼──────┐         ┌─────▼─────┐
│ToolsStore│          │ContainersStore│        │AppSettings│
│@Observable│          │@Observable  │         │@Observable│
│@MainActor│          │@MainActor   │         │@MainActor│
└────┬─────┘          └──────┬──────┘         └───────────┘
     │                       │
     │ async/await           │ async/await
     │                       │
┌────▼─────┐          ┌──────▼──────┐
│MiseClient│          │OrbStackClient│
│  actor   │          │   actor     │
└────┬─────┘          └──────┬──────┘
     │                       │
     └───────────┬───────────┘
                 │
         ┌───────▼───────┐
         │CommandExecutor│
         │ (async/await) │
         └───────────────┘
```

### Key Principles

1. **Unidirectional data flow**: Views → Actions → Stores → Clients → CLI
2. **Actor isolation**: Each tool client is an actor (thread-safe)
3. **Protocol abstraction**: Clients implement protocols (testable)
4. **Environment injection**: Stores passed via `.environment()`

---

## 4. Actor-Based Concurrency

### Why Actors?

- **Thread safety**: No data races by design
- **Serial execution**: Commands for each tool run sequentially
- **Isolated state**: CLI paths, caches are safely encapsulated

### Tool Client Actor Template

```swift
/// Actor that executes Mise CLI commands serially.
actor MiseClient: MiseClientProtocol {
    private let logger = Logger(subsystem: "DevEnvManager", category: "MiseClient")
    private var miseURL: URL?
    private let environment: [String: String] = [
        "MISE_YES": "1",  // Auto-confirm prompts
        "HOME": FileManager.default.homeDirectoryForCurrentUser.path,
        "LC_ALL": "en_US.UTF-8"
    ]
    
    // MARK: - Lazy CLI Location
    
    private func ensureMiseURL() async throws -> URL {
        if let url = miseURL { return url }
        
        // Check common locations
        let candidates = [
            URL(filePath: "/usr/local/bin/mise"),
            URL(filePath: "/opt/homebrew/bin/mise"),
            FileManager.default.homeDirectoryForCurrentUser
                .appending(path: ".local/bin/mise")
        ]
        
        for candidate in candidates {
            if FileManager.default.isExecutableFile(atPath: candidate.path()) {
                miseURL = candidate
                logger.info("Found mise at \(candidate.path())")
                return candidate
            }
        }
        
        // Fallback to PATH lookup via /usr/bin/env
        let result = try await CommandExecutor.run(
            path: "/usr/bin/which",
            arguments: ["mise"],
            timeout: .seconds(5)
        )
        
        guard result.isSuccess, !result.stdout.isEmpty else {
            throw MiseError.notFound
        }
        
        let url = URL(filePath: result.stdout.trimmingCharacters(in: .whitespacesAndNewlines))
        miseURL = url
        return url
    }
    
    // MARK: - Commands
    
    func listTools() async throws -> [MiseTool] {
        let miseURL = try await ensureMiseURL()
        let result = try await CommandExecutor.run(
            miseURL,
            arguments: ["ls", "--json"],
            environment: environment,
            timeout: .seconds(30)
        )
        
        guard result.isSuccess else {
            throw MiseError.commandFailed(
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }
        
        return try decodeTools(from: result.stdout)
    }
    
    func installTool(_ name: String, version: String?) async throws {
        let miseURL = try await ensureMiseURL()
        var arguments = ["use", "-g", name]
        if let version { arguments.append("@\(version)") }
        
        let result = try await CommandExecutor.run(
            miseURL,
            arguments: arguments,
            environment: environment,
            timeout: .seconds(300)  // Install can be slow
        )
        
        guard result.isSuccess else {
            throw MiseError.installFailed(
                tool: name,
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }
    }
    
    func runTask(_ taskName: String) async throws -> String {
        let miseURL = try await ensureMiseURL()
        let result = try await CommandExecutor.run(
            miseURL,
            arguments: ["run", taskName],
            environment: environment,
            timeout: .seconds(600)
        )
        
        guard result.isSuccess else {
            throw MiseError.taskFailed(
                task: taskName,
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }
        
        return result.stdout
    }
    
    // MARK: - JSON Decoding
    
    private func decodeTools(from output: String) throws -> [MiseTool] {
        guard let data = output.data(using: .utf8) else {
            throw MiseError.invalidOutput(raw: output)
        }
        
        do {
            return try JSONDecoder().decode([MiseTool].self, from: data)
        } catch {
            throw MiseError.jsonDecodingFailed(
                raw: output,
                underlying: error.localizedDescription
            )
        }
    }
}
```

### Port Detector Actor

```swift
/// Actor for detecting listening ports via lsof.
actor PortDetector {
    private let logger = Logger(subsystem: "DevEnvManager", category: "PortDetector")
    
    func detectPorts(for pid: Int) async throws -> [ServicePort] {
        // Get all PIDs in process tree
        let pids = try await getAllDescendantPIDs(for: pid)
        let pidList = pids.map(String.init).joined(separator: ",")
        
        let result = try await CommandExecutor.run(
            path: "/usr/sbin/lsof",
            arguments: ["-nP", "-iTCP", "-sTCP:LISTEN", "-a", "-p", pidList],
            timeout: .seconds(5)
        )
        
        // Exit code 1 = no ports found (normal)
        if result.exitCode == 1 { return [] }
        
        guard result.isSuccess else {
            throw PortDetectorError.lsofFailed(
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }
        
        return parseLsofOutput(result.stdout)
    }
    
    private func getAllDescendantPIDs(for pid: Int) async throws -> [Int] {
        var allPIDs: Set<Int> = [pid]
        var toCheck: [Int] = [pid]
        
        while !toCheck.isEmpty {
            let currentPID = toCheck.removeFirst()
            let result = try await CommandExecutor.run(
                path: "/usr/bin/pgrep",
                arguments: ["-P", "\(currentPID)"],
                timeout: .seconds(2)
            )
            
            for line in result.stdout.split(separator: "\n") {
                if let childPID = Int(line.trimmingCharacters(in: .whitespaces)),
                   !allPIDs.contains(childPID) {
                    allPIDs.insert(childPID)
                    toCheck.append(childPID)
                }
            }
        }
        
        return Array(allPIDs)
    }
    
    private func parseLsofOutput(_ output: String) -> [ServicePort] {
        // Parse lsof output format:
        // COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        // node    12345 user   23u  IPv4 0x...       TCP *:3000 (LISTEN)
        
        var ports: [ServicePort] = []
        
        for line in output.split(separator: "\n").dropFirst() {
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
            guard components.count >= 9 else { continue }
            
            let name = String(components.last ?? "")
            if let port = extractPort(from: name) {
                ports.append(ServicePort(
                    port: port,
                    protocol: "TCP",
                    address: extractAddress(from: name)
                ))
            }
        }
        
        return ports
    }
    
    private func extractPort(from name: String) -> Int? {
        // Format: *:3000 or 127.0.0.1:3000
        guard let colonIndex = name.lastIndex(of: ":") else { return nil }
        let portString = name[name.index(after: colonIndex)...]
            .replacingOccurrences(of: " (LISTEN)", with: "")
        return Int(portString)
    }
    
    private func extractAddress(from name: String) -> String {
        guard let colonIndex = name.lastIndex(of: ":") else { return "*" }
        return String(name[..<colonIndex])
    }
}
```

---

## 5. State Management

### @Observable Store Pattern

```swift
import SwiftUI
import os

/// Manages Mise tool state with optimistic UI updates.
@MainActor
@Observable
final class ToolsStore {
    // MARK: - Published State
    
    var state: ToolsState = .idle
    var nonFatalError: MiseError?
    var toolOperations: [String: ToolOperation] = [:]
    
    // MARK: - Private State
    
    private let client: MiseClientProtocol
    private let portDetector = PortDetector()
    private let logger = Logger(subsystem: "DevEnvManager", category: "ToolsStore")
    
    private var refreshInFlight = false
    private var pendingRefreshRequest: RefreshRequest?
    private var lastRefresh: Date?
    private let minimumRefreshInterval: TimeInterval = 2.0
    
    // MARK: - Init
    
    init(client: MiseClientProtocol = MiseClient()) {
        self.client = client
    }
    
    // MARK: - Computed Properties
    
    var tools: [MiseTool] {
        switch state {
        case .loaded(let tools), .refreshing(let tools):
            return tools
        default:
            return []
        }
    }
    
    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }
    
    var isRefreshing: Bool {
        if case .refreshing = state { return true }
        return false
    }
    
    // MARK: - Refresh
    
    func refresh(force: Bool = false) async {
        // Throttle rapid refreshes
        if !force, let lastRefresh,
           Date().timeIntervalSince(lastRefresh) < minimumRefreshInterval {
            return
        }
        
        // Queue if refresh already in flight
        if refreshInFlight {
            pendingRefreshRequest = RefreshRequest(force: force)
            return
        }
        
        refreshInFlight = true
        defer { refreshInFlight = false }
        
        // Set appropriate state
        switch state {
        case .loaded(let tools):
            state = .refreshing(tools)  // Keep showing old data
        case .idle, .error:
            state = .loading
        case .loading, .refreshing:
            break
        }
        
        do {
            let tools = try await client.listTools()
            state = .loaded(tools)
            lastRefresh = Date()
            
            // Cache for instant startup
            try? ToolsDiskCache.save(tools: tools, lastRefresh: Date())
            
        } catch {
            if case .refreshing(let oldTools) = state {
                // Keep old data on refresh failure
                state = .loaded(oldTools)
                nonFatalError = error as? MiseError ?? .unknown(error)
            } else {
                state = .error(error as? MiseError ?? .unknown(error))
            }
            logger.error("Refresh failed: \(error.localizedDescription)")
        }
        
        // Process pending request
        if let pending = pendingRefreshRequest {
            pendingRefreshRequest = nil
            await refresh(force: pending.force)
        }
    }
    
    /// Refresh without UI state change (for post-action sync).
    func refreshQuietly() async {
        do {
            let tools = try await client.listTools()
            state = .loaded(tools)
            try? ToolsDiskCache.save(tools: tools, lastRefresh: Date())
        } catch {
            logger.warning("Quiet refresh failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Actions with Optimistic Updates
    
    func installTool(_ name: String, version: String? = nil) async {
        let toolId = "\(name)@\(version ?? "latest")"
        
        // Mark operation in progress
        toolOperations[toolId] = ToolOperation(
            status: .running,
            action: .install,
            startedAt: Date()
        )
        
        do {
            try await client.installTool(name, version: version)
            toolOperations[toolId] = .idle
            
            // Background sync to get actual state
            await refreshQuietly()
            
        } catch {
            toolOperations[toolId] = ToolOperation(
                status: .failed,
                action: .install,
                error: error as? MiseError ?? .unknown(error)
            )
            
            // Force refresh to sync state
            await refresh(force: true)
            
            logger.error("Install failed for \(name): \(error.localizedDescription)")
        }
    }
    
    func runTask(_ taskName: String) async -> String? {
        toolOperations[taskName] = ToolOperation(
            status: .running,
            action: .runTask,
            startedAt: Date()
        )
        
        do {
            let output = try await client.runTask(taskName)
            toolOperations[taskName] = .idle
            return output
            
        } catch {
            toolOperations[taskName] = ToolOperation(
                status: .failed,
                action: .runTask,
                error: error as? MiseError ?? .unknown(error)
            )
            logger.error("Task \(taskName) failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Cache Restoration
    
    func restoreFromCache() {
        Task {
            let cached = await Task.detached(priority: .utility) {
                ToolsDiskCache.load()
            }.value
            
            if let cached {
                state = .loaded(cached.tools)
                lastRefresh = cached.lastRefresh
                logger.info("Restored \(cached.tools.count) tools from cache")
            }
        }
    }
}

// MARK: - Supporting Types

enum ToolsState: Equatable {
    case idle
    case loading
    case loaded([MiseTool])
    case refreshing([MiseTool])
    case error(MiseError)
}

struct ToolOperation: Equatable {
    enum Status: Equatable {
        case idle, running, failed
    }
    
    enum Action: Equatable {
        case install, uninstall, update, runTask
    }
    
    var status: Status = .idle
    var action: Action?
    var error: MiseError?
    var startedAt: Date?
    
    static let idle = ToolOperation()
}

struct RefreshRequest {
    let force: Bool
}
```

### AppSettings Store

```swift
import SwiftUI

@MainActor
@Observable
final class AppSettings {
    // Persisted via @AppStorage
    var autoRefreshInterval: Int = 30
    var showNotifications: Bool = true
    var launchAtLogin: Bool = false
    var selectedSection: MenuSection = .localEnvironment
    
    // Computed
    var autoRefreshEnabled: Bool {
        autoRefreshInterval > 0
    }
}

enum MenuSection: String, CaseIterable, Identifiable {
    case localEnvironment = "Local Environment"
    case containers = "Containers"
    case workspaces = "DevContainers"
    case clusters = "Cloud Agents"
    case services = "Services"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .localEnvironment: "terminal"
        case .containers: "shippingbox"
        case .workspaces: "cube"
        case .clusters: "cloud"
        case .services: "gearshape.2"
        }
    }
}
```

---

## 6. Shell Command Execution

### CommandExecutor (Production-Ready)

```swift
import Foundation
import os

/// Thread-safe command execution with timeout and cancellation support.
enum CommandExecutor {
    private static let logger = Logger(subsystem: "DevEnvManager", category: "CommandExecutor")
    
    /// Execute command with full control over timeout and cancellation.
    static func run(
        _ executableURL: URL,
        arguments: [String],
        environment: [String: String]? = nil,
        workingDirectory: URL? = nil,
        timeout: Duration? = nil
    ) async throws -> CommandResult {
        try await run(
            path: executableURL.path(),
            arguments: arguments,
            environment: environment,
            workingDirectory: workingDirectory,
            timeout: timeout
        )
    }
    
    /// Execute command by path lookup.
    static func run(
        path: String,
        arguments: [String],
        environment: [String: String]? = nil,
        workingDirectory: URL? = nil,
        timeout: Duration? = nil
    ) async throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(filePath: path)
        process.arguments = arguments
        
        if let workingDirectory {
            process.currentDirectoryURL = workingDirectory
        }
        
        // Build environment
        var env = environment ?? [:]
        env["HOME"] = env["HOME"] ?? FileManager.default.homeDirectoryForCurrentUser.path
        env["LC_ALL"] = env["LC_ALL"] ?? "en_US.UTF-8"
        process.environment = env
        
        // Setup pipes
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        // Thread-safe state tracking
        let stateLock = OSAllocatedUnfairLock(initialState: (
            didCancel: false,
            didTimeout: false,
            didResume: false
        ))
        
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                // Completion handler
                let finish: @Sendable (Int32) -> Void = { exitCode in
                    let shouldResume = stateLock.withLock { state -> Bool in
                        guard !state.didResume else { return false }
                        state.didResume = true
                        return true
                    }
                    
                    guard shouldResume else { return }
                    
                    let stdout = stdoutPipe.fileHandleForReading.readToEndSafely()
                    let stderr = stderrPipe.fileHandleForReading.readToEndSafely()
                    
                    let (didTimeout, _) = stateLock.withLock { ($0.didTimeout, $0.didCancel) }
                    
                    if didTimeout {
                        continuation.resume(throwing: CommandExecutorError.timedOut)
                    } else {
                        continuation.resume(returning: CommandResult(
                            stdout: String(data: stdout, encoding: .utf8) ?? "",
                            stderr: String(data: stderr, encoding: .utf8) ?? "",
                            exitCode: exitCode
                        ))
                    }
                }
                
                process.terminationHandler = { process in
                    finish(process.terminationStatus)
                }
                
                // Start process
                do {
                    try process.run()
                    logger.debug("Started: \(path) \(arguments.joined(separator: " "))")
                } catch {
                    continuation.resume(throwing: CommandExecutorError.failedToStart(error))
                    return
                }
                
                // Setup timeout
                if let timeout {
                    Task {
                        try? await Task.sleep(for: timeout)
                        
                        let shouldTimeout = stateLock.withLock { state -> Bool in
                            guard !state.didResume else { return false }
                            state.didTimeout = true
                            return true
                        }
                        
                        if shouldTimeout, process.isRunning {
                            logger.warning("Timeout reached, terminating: \(path)")
                            process.terminate()
                        }
                    }
                }
            }
        } onCancel: {
            let shouldCancel = stateLock.withLock { state -> Bool in
                guard !state.didResume else { return false }
                state.didCancel = true
                return true
            }
            
            if shouldCancel, process.isRunning {
                logger.info("Task cancelled, terminating: \(path)")
                process.terminate()
            }
        }
    }
}

// MARK: - Result Type

struct CommandResult {
    let stdout: String
    let stderr: String
    let exitCode: Int32
    
    var isSuccess: Bool { exitCode == 0 }
    
    var combinedOutput: String {
        [stdout, stderr].filter { !$0.isEmpty }.joined(separator: "\n")
    }
}

// MARK: - Errors

enum CommandExecutorError: Error, LocalizedError {
    case failedToStart(Error)
    case timedOut
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .failedToStart(let error):
            "Failed to start command: \(error.localizedDescription)"
        case .timedOut:
            "Command timed out"
        case .cancelled:
            "Command was cancelled"
        }
    }
}

// MARK: - Safe FileHandle Extension

extension FileHandle {
    /// Safe read that catches ObjC exceptions.
    func readToEndSafely() -> Data {
        do {
            return try self.readToEnd() ?? Data()
        } catch {
            return Data()
        }
    }
}
```

### Streaming Output (AsyncStream)

```swift
import Foundation

/// Stream output for long-running commands (e.g., mise run, docker build).
enum StreamedOutput {
    case stdout(String)
    case stderr(String)
}

extension CommandExecutor {
    /// Execute command with streaming output.
    static func stream(
        _ executableURL: URL,
        arguments: [String],
        environment: [String: String]? = nil
    ) -> AsyncStream<StreamedOutput> {
        AsyncStream { continuation in
            let process = Process()
            process.executableURL = executableURL
            process.arguments = arguments
            
            var env = environment ?? [:]
            env["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
            process.environment = env
            
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            
            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty,
                      let output = String(data: data, encoding: .utf8),
                      !output.isEmpty else {
                    return
                }
                continuation.yield(.stdout(output))
            }
            
            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty,
                      let output = String(data: data, encoding: .utf8),
                      !output.isEmpty else {
                    return
                }
                continuation.yield(.stderr(output))
            }
            
            process.terminationHandler = { _ in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                continuation.finish()
            }
            
            do {
                try process.run()
            } catch {
                continuation.finish()
            }
        }
    }
}

// Usage:
// for await output in CommandExecutor.stream(miseURL, arguments: ["run", "validate"]) {
//     switch output {
//     case .stdout(let line): print("OUT: \(line)")
//     case .stderr(let line): print("ERR: \(line)")
//     }
// }
```

---

## 7. Menu Bar Setup

### App Entry Point

```swift
import SwiftUI

@main
struct DevEnvManagerApp: App {
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate
    
    // Stores owned by App
    @State private var toolsStore = ToolsStore()
    @State private var containersStore = ContainersStore()
    @State private var workspacesStore = WorkspacesStore()
    @State private var clustersStore = ClustersStore()
    @State private var servicesStore = ServicesStore()
    @State private var appSettings = AppSettings()
    
    var body: some Scene {
        // Menu bar dropdown
        MenuBarExtra {
            MenuBarRootView()
                .environment(toolsStore)
                .environment(containersStore)
                .environment(workspacesStore)
                .environment(clustersStore)
                .environment(servicesStore)
                .environment(appSettings)
        } label: {
            Label("DevEnv Manager", systemImage: menuBarIcon)
                .labelStyle(.iconOnly)
        }
        .menuBarExtraStyle(.window)
        .windowResizability(.contentSize)
        
        // Settings window (⌘,)
        Settings {
            SettingsView()
                .environment(appSettings)
        }
    }
    
    // Dynamic icon based on state
    private var menuBarIcon: String {
        // Error state
        if case .error = toolsStore.state { return "exclamationmark.triangle.fill" }
        if case .error = servicesStore.state { return "exclamationmark.triangle.fill" }
        
        // Loading/refreshing
        if toolsStore.isLoading || servicesStore.isLoading { return "arrow.triangle.2.circlepath" }
        if toolsStore.isRefreshing || servicesStore.isRefreshing { return "arrow.triangle.2.circlepath" }
        
        // Has running operations
        let hasRunningOps = !toolsStore.toolOperations.filter { $0.value.status == .running }.isEmpty
        if hasRunningOps { return "gearshape.2" }
        
        // Default healthy state
        return "terminal.fill"
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set as accessory (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
    }
}
```

### Root Menu View

```swift
import SwiftUI

struct MenuBarRootView: View {
    @Environment(ToolsStore.self) private var toolsStore
    @Environment(AppSettings.self) private var settings
    
    @State private var route: MenuRoute = .main
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            // Main content
            MainMenuView(searchText: $searchText, route: $route)
                .opacity(route == .main ? 1 : 0)
            
            // Settings overlay
            if route == .settings {
                SettingsView { route = .main }
                    .transition(.move(edge: .trailing))
            }
            
            // Tool detail overlay
            if case .toolDetail(let tool) = route {
                ToolDetailView(tool: tool) { route = .main }
                    .transition(.move(edge: .trailing))
            }
        }
        .frame(width: LayoutConstants.menuWidth)
        .animation(.easeInOut(duration: 0.2), value: route)
        .task {
            // Initial load from cache, then refresh
            toolsStore.restoreFromCache()
            await toolsStore.refresh()
        }
        .task(id: settings.autoRefreshInterval) {
            // Auto-refresh loop
            guard settings.autoRefreshEnabled else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(settings.autoRefreshInterval))
                await toolsStore.refresh()
            }
        }
    }
}

enum MenuRoute: Equatable {
    case main
    case settings
    case toolDetail(MiseTool)
}
```

---

## 8. SwiftUI Patterns

### Tool Row Component

```swift
import SwiftUI

struct ToolRowView: View {
    @Environment(ToolsStore.self) private var store
    
    let tool: MiseTool
    let onAction: (ToolAction) -> Void
    
    @State private var showingPopover = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            // Tool name and version
            VStack(alignment: .leading, spacing: 2) {
                Text(tool.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(tool.version)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Operation status
            if let operation = store.toolOperations[tool.id] {
                operationIndicator(operation)
            }
            
            // Primary action
            Button {
                onAction(tool.isInstalled ? .update : .install)
            } label: {
                Image(systemName: tool.isInstalled ? "arrow.clockwise" : "arrow.down.circle")
            }
            .buttonStyle(.borderless)
            .help(tool.isInstalled ? "Update" : "Install")
            
            // More options
            Button {
                showingPopover.toggle()
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showingPopover) {
                ToolActionsPopover(tool: tool, onAction: onAction)
                    .frame(width: 200)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
    
    private var statusColor: Color {
        switch tool.status {
        case .installed: .green
        case .outdated: .orange
        case .missing: .red
        case .unknown: .gray
        }
    }
    
    @ViewBuilder
    private func operationIndicator(_ operation: ToolOperation) -> some View {
        switch operation.status {
        case .running:
            ProgressView()
                .controlSize(.mini)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .help(operation.error?.localizedDescription ?? "Failed")
        case .idle:
            EmptyView()
        }
    }
}

enum ToolAction {
    case install
    case update
    case uninstall
    case info
}
```

### Status Badge Component

```swift
import SwiftUI

struct StatusBadge: View {
    let status: ServiceStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor, in: .capsule)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .running: .green.opacity(0.2)
        case .stopped: .secondary.opacity(0.2)
        case .error: .red.opacity(0.2)
        case .starting: .blue.opacity(0.2)
        case .stopping: .orange.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .running: .green
        case .stopped: .secondary
        case .error: .red
        case .starting: .blue
        case .stopping: .orange
        }
    }
}
```

### Layout Constants

```swift
import SwiftUI

enum LayoutConstants {
    // Menu dimensions
    static let menuWidth: CGFloat = 400
    static let detailMenuWidth: CGFloat = 500
    static let settingsMenuWidth: CGFloat = 450
    
    // Spacing
    static let sectionSpacing: CGFloat = 16
    static let itemSpacing: CGFloat = 8
    static let contentPadding: CGFloat = 12
    
    // Components
    static let cornerRadius: CGFloat = 8
    static let iconSize: CGFloat = 16
    static let statusIndicatorSize: CGFloat = 8
    
    // Badge
    static let badgeHorizontalPadding: CGFloat = 8
    static let badgeVerticalPadding: CGFloat = 3
}
```

---

## 9. Error Handling

### Structured Error Types

```swift
import Foundation

/// Mise CLI errors with context.
enum MiseError: Error, LocalizedError, Equatable {
    case notFound
    case commandFailed(exitCode: Int32, stderr: String)
    case jsonDecodingFailed(raw: String, underlying: String)
    case installFailed(tool: String, exitCode: Int32, stderr: String)
    case taskFailed(task: String, exitCode: Int32, stderr: String)
    case invalidOutput(raw: String)
    case timeout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            "Mise is not installed or could not be found."
        case .commandFailed(let exitCode, let stderr):
            "Mise command failed (exit \(exitCode)): \(stderr.prefix(200))"
        case .jsonDecodingFailed(_, let underlying):
            "Failed to parse Mise output: \(underlying)"
        case .installFailed(let tool, let exitCode, let stderr):
            "Failed to install \(tool) (exit \(exitCode)): \(stderr.prefix(200))"
        case .taskFailed(let task, let exitCode, let stderr):
            "Task '\(task)' failed (exit \(exitCode)): \(stderr.prefix(200))"
        case .invalidOutput:
            "Mise returned invalid output"
        case .timeout:
            "Mise command timed out"
        case .unknown(let error):
            "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notFound:
            "Install Mise from https://mise.jdx.dev"
        case .commandFailed, .installFailed:
            "Check that the tool exists and try again."
        case .taskFailed:
            "Check the task configuration in mise.toml"
        case .timeout:
            "Try again or check network connection."
        default:
            nil
        }
    }
    
    // Equatable conformance for unknown case
    static func == (lhs: MiseError, rhs: MiseError) -> Bool {
        switch (lhs, rhs) {
        case (.notFound, .notFound): true
        case (.timeout, .timeout): true
        case let (.commandFailed(e1, s1), .commandFailed(e2, s2)): e1 == e2 && s1 == s2
        case let (.jsonDecodingFailed(r1, u1), .jsonDecodingFailed(r2, u2)): r1 == r2 && u1 == u2
        case let (.installFailed(t1, e1, s1), .installFailed(t2, e2, s2)): t1 == t2 && e1 == e2 && s1 == s2
        case let (.taskFailed(t1, e1, s1), .taskFailed(t2, e2, s2)): t1 == t2 && e1 == e2 && s1 == s2
        case let (.invalidOutput(r1), .invalidOutput(r2)): r1 == r2
        case let (.unknown(e1), .unknown(e2)): e1.localizedDescription == e2.localizedDescription
        default: false
        }
    }
}
```

### Error Banner UI

```swift
import SwiftUI

struct ErrorBanner: View {
    let error: MiseError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.errorDescription ?? "An error occurred")
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let onRetry {
                Button("Retry") { onRetry() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .background(.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
```

---

## 10. Caching Strategy

### Disk Cache for Instant Startup

```swift
import Foundation
import os

/// Persists tool state for instant app startup.
enum ToolsDiskCache {
    private static let logger = Logger(subsystem: "DevEnvManager", category: "ToolsDiskCache")
    
    private static var cacheURL: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return caches.appending(path: "DevEnvManager/tools-cache.json")
    }
    
    struct CachedData: Codable {
        let tools: [MiseTool]
        let lastRefresh: Date
        let version: Int = 1  // Schema version for migrations
    }
    
    static func load() -> CachedData? {
        guard FileManager.default.fileExists(atPath: cacheURL.path()) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: cacheURL)
            let cached = try JSONDecoder().decode(CachedData.self, from: data)
            
            // Cache expiry (24 hours)
            let maxAge: TimeInterval = 24 * 60 * 60
            if Date().timeIntervalSince(cached.lastRefresh) > maxAge {
                logger.info("Cache expired, will refresh")
                return nil
            }
            
            return cached
        } catch {
            logger.warning("Failed to load cache: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func save(tools: [MiseTool], lastRefresh: Date) throws {
        let cached = CachedData(tools: tools, lastRefresh: lastRefresh)
        let data = try JSONEncoder().encode(cached)
        
        // Ensure directory exists
        let directory = cacheURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        // Atomic write
        try data.write(to: cacheURL, options: [.atomic])
        logger.debug("Cached \(tools.count) tools")
    }
    
    static func clear() {
        try? FileManager.default.removeItem(at: cacheURL)
        logger.info("Cache cleared")
    }
}
```

---

## 11. Testing Approach

### Protocol-Based Dependency Injection

```swift
/// Protocol for testable Mise client.
protocol MiseClientProtocol: Actor {
    func listTools() async throws -> [MiseTool]
    func installTool(_ name: String, version: String?) async throws
    func runTask(_ taskName: String) async throws -> String
}
```

### Fake Actor for Testing

```swift
import Foundation

/// Fake client for unit tests.
actor FakeMiseClient: MiseClientProtocol {
    private var tools: [MiseTool]
    private var failures: [String: MiseError] = [:]
    private(set) var performedActions: [(action: String, args: [String])] = []
    
    init(tools: [MiseTool] = []) {
        self.tools = tools
    }
    
    // Test configuration
    func setTools(_ tools: [MiseTool]) {
        self.tools = tools
    }
    
    func setFailure(_ error: MiseError, for operation: String) {
        failures[operation] = error
    }
    
    func clearFailures() {
        failures.removeAll()
    }
    
    // Protocol implementation
    func listTools() async throws -> [MiseTool] {
        performedActions.append(("listTools", []))
        if let error = failures["listTools"] { throw error }
        return tools
    }
    
    func installTool(_ name: String, version: String?) async throws {
        performedActions.append(("installTool", [name, version ?? "latest"]))
        if let error = failures["installTool:\(name)"] { throw error }
        if let error = failures["installTool"] { throw error }
    }
    
    func runTask(_ taskName: String) async throws -> String {
        performedActions.append(("runTask", [taskName]))
        if let error = failures["runTask:\(taskName)"] { throw error }
        if let error = failures["runTask"] { throw error }
        return "Task output"
    }
}
```

### Store Unit Tests

```swift
import Testing
@testable import DevEnvManager

@Suite("ToolsStore Tests")
struct ToolsStoreTests {
    
    @Test func refreshLoadsTools() async {
        let tools = [
            MiseTool(name: "node", version: "20.0.0", status: .installed),
            MiseTool(name: "python", version: "3.12.0", status: .installed)
        ]
        let client = FakeMiseClient(tools: tools)
        let store = await ToolsStore(client: client)
        
        await store.refresh()
        
        #expect(store.tools.count == 2)
        #expect(store.tools.first?.name == "node")
    }
    
    @Test func refreshPreservesDataOnError() async {
        let tools = [MiseTool(name: "node", version: "20.0.0", status: .installed)]
        let client = FakeMiseClient(tools: tools)
        let store = await ToolsStore(client: client)
        
        // Initial load
        await store.refresh()
        #expect(store.tools.count == 1)
        
        // Configure failure
        await client.setFailure(.timeout, for: "listTools")
        
        // Refresh should preserve old data
        await store.refresh()
        
        #expect(store.tools.count == 1)  // Still has old data
        #expect(store.nonFatalError != nil)
    }
    
    @Test func operationTracksProgress() async {
        let client = FakeMiseClient()
        let store = await ToolsStore(client: client)
        
        // Start install (don't await)
        Task {
            await store.installTool("node")
        }
        
        // Give it time to start
        try? await Task.sleep(for: .milliseconds(50))
        
        // Should show running
        #expect(store.toolOperations["node@latest"]?.status == .running)
    }
    
    @Test func failedOperationRecordsError() async {
        let client = FakeMiseClient()
        await client.setFailure(.installFailed(tool: "node", exitCode: 1, stderr: "error"), for: "installTool:node")
        let store = await ToolsStore(client: client)
        
        await store.installTool("node")
        
        #expect(store.toolOperations["node@latest"]?.status == .failed)
        #expect(store.toolOperations["node@latest"]?.error != nil)
    }
}
```

---

## 12. Security Considerations

### Entitlements (DevEnvManager.entitlements)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Allow running unsigned binaries (mise, brew, etc.) -->
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    
    <!-- Disable library validation for external tools -->
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    
    <!-- App sandbox disabled for full CLI access -->
    <!-- If sandboxed, use XPC helper for CLI commands -->
</dict>
</plist>
```

### Path Safety

```swift
extension CommandExecutor {
    /// Validate executable path before running.
    static func validatePath(_ path: String) -> Bool {
        // Must be absolute path
        guard path.hasPrefix("/") else { return false }
        
        // Must exist and be executable
        guard FileManager.default.isExecutableFile(atPath: path) else { return false }
        
        // Disallow suspicious paths
        let suspicious = ["/tmp/", "/var/tmp/", "/dev/"]
        for prefix in suspicious {
            if path.hasPrefix(prefix) { return false }
        }
        
        return true
    }
}
```

### Environment Sanitization

```swift
extension CommandExecutor {
    /// Build safe environment for CLI tools.
    static func safeEnvironment(merging custom: [String: String]? = nil) -> [String: String] {
        var env: [String: String] = [:]
        
        // Essential variables
        env["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
        env["USER"] = NSUserName()
        env["LC_ALL"] = "en_US.UTF-8"
        env["LANG"] = "en_US.UTF-8"
        
        // PATH with safe defaults
        let defaultPath = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        let homeBin = "\(env["HOME"]!)/.local/bin"
        let brewPath = "/opt/homebrew/bin"
        env["PATH"] = "\(homeBin):\(brewPath):\(defaultPath)"
        
        // Merge custom (but don't override security-critical vars)
        if let custom {
            for (key, value) in custom {
                if !["HOME", "USER"].contains(key) {
                    env[key] = value
                }
            }
        }
        
        return env
    }
}
```

---

## 13. Implementation Roadmap

### Sprint 1: Foundation (Week 1-2)

| Task | Priority | Est. |
|------|----------|------|
| Create Xcode project with MenuBarExtra | High | 2h |
| Implement CommandExecutor | High | 4h |
| Create MiseClient actor | High | 4h |
| Create ToolsStore | High | 4h |
| Basic menu bar UI (list tools) | High | 4h |
| Disk caching | Medium | 2h |

**Deliverable:** App shows mise tools in menu bar

### Sprint 2: Local Environment (Week 3-4)

| Task | Priority | Est. |
|------|----------|------|
| Tool row component with actions | High | 4h |
| Install/update operations | High | 4h |
| Mise tasks list and execution | High | 4h |
| Agent readiness check | Medium | 2h |
| Autofix integration | Medium | 2h |
| Error handling and banners | High | 2h |

**Deliverable:** Full Local Environment section working

### Sprint 3: Containers & Services (Week 5-6)

| Task | Priority | Est. |
|------|----------|------|
| OrbStackClient actor | High | 4h |
| ContainersStore | High | 4h |
| BrewServicesClient actor | High | 4h |
| ServicesStore | High | 4h |
| Port detection | Medium | 4h |
| Containers section UI | High | 4h |
| Services section UI | High | 4h |

**Deliverable:** Containers and Services sections working

### Sprint 4: Cloud & Polish (Week 7-8)

| Task | Priority | Est. |
|------|----------|------|
| DevPodClient actor | Medium | 4h |
| WorkspacesStore | Medium | 4h |
| SkyPilotClient actor | Medium | 4h |
| ClustersStore | Medium | 4h |
| Settings panel | High | 4h |
| Keyboard shortcuts | Medium | 2h |
| CLI command copy feature | Medium | 4h |
| Notifications | Low | 2h |

**Deliverable:** Full app feature-complete

### Sprint 5: Testing & Release (Week 9-10)

| Task | Priority | Est. |
|------|----------|------|
| Unit tests for all clients | High | 8h |
| Unit tests for all stores | High | 8h |
| XCUITest for critical flows | Medium | 8h |
| Performance optimization | Medium | 4h |
| App icon and branding | Medium | 2h |
| Notarization and signing | High | 4h |
| Release automation | Medium | 4h |

**Deliverable:** Production-ready 1.0 release

---

## Summary

This architecture guide provides production-ready patterns for DevEnvManager:

| Pattern | Implementation | Reference |
|---------|----------------|-----------|
| **Concurrency** | Swift Actors | BrewServicesManager |
| **State** | @Observable + @MainActor | Ice |
| **Shell** | CommandExecutor with timeout | Cork, ShellOut |
| **Menu Bar** | MenuBarExtra + .window style | BrewServicesManager |
| **Testing** | Protocol injection + Fake actors | BrewServicesManager |
| **Caching** | JSON disk cache | BrewServicesManager |
| **Errors** | Structured enums + LocalizedError | BrewServicesManager |

**Key Files to Create First:**
1. `CommandExecutor.swift` - Foundation for all CLI calls
2. `MiseClient.swift` - Primary tool management
3. `ToolsStore.swift` - State management
4. `DevEnvManagerApp.swift` - App entry point
5. `MenuBarRootView.swift` - Main UI

**Reference Repositories:**
- https://github.com/yimidaw27/BrewServicesManager
- https://github.com/jordanbaird/Ice
- https://github.com/buresdv/Cork
