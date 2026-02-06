import SwiftUI
import os

enum ToolsState: Equatable {
    case idle
    case loading
    case loaded([MiseTool])
    case refreshing([MiseTool])
    case error(String)
}

@MainActor
@Observable
final class ToolsStore {
    var state: ToolsState = .idle
    var tasks: [MiseTask] = []
    var nonFatalError: String?
    var toolOperations: [String: ToolOperation] = [:]
    
    private let client: any MiseClientProtocol
    private let logger = Logger(subsystem: "dev.devenvmanager", category: "ToolsStore")
    
    private var refreshInFlight = false
    private var pendingRefreshRequest: RefreshRequest?
    private var lastRefresh: Date?
    private let minimumRefreshInterval: TimeInterval = 2.0
    
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
    
    var isMiseAvailable: Bool {
        if case .error = state { return false }
        return true
    }
    
    init(client: any MiseClientProtocol = MiseClient()) {
        self.client = client
    }
    
    func refresh(force: Bool = false) async {
        if !force, let lastRefresh,
           Date().timeIntervalSince(lastRefresh) < minimumRefreshInterval {
            return
        }
        
        if refreshInFlight {
            pendingRefreshRequest = RefreshRequest(force: force)
            return
        }
        
        refreshInFlight = true
        defer { refreshInFlight = false }
        
        switch state {
        case .loaded(let tools):
            state = .refreshing(tools)
        case .idle, .error:
            state = .loading
        case .loading, .refreshing:
            break
        }
        
        do {
            let tools = try await client.listTools()
            let tasks = try? await client.listTasks()
            
            state = .loaded(tools)
            self.tasks = tasks ?? []
            lastRefresh = Date()
            
            do {
                try await ToolsDiskCache.save(tools: tools, tasks: tasks)
            } catch {
                logger.warning("Failed to save cache: \(error.localizedDescription)")
            }
            
        } catch {
            if case .refreshing(let oldTools) = state {
                state = .loaded(oldTools)
                nonFatalError = error.localizedDescription
            } else {
                state = .error(error.localizedDescription)
            }
            logger.error("Refresh failed: \(error.localizedDescription)")
        }
        
        if let pending = pendingRefreshRequest {
            pendingRefreshRequest = nil
            await refresh(force: pending.force)
        }
    }
    
    func refreshQuietly() async {
        do {
            let tools = try await client.listTools()
            let tasks = try? await client.listTasks()
            state = .loaded(tools)
            self.tasks = tasks ?? self.tasks
            
            do {
                try await ToolsDiskCache.save(tools: tools, tasks: tasks ?? self.tasks)
            } catch {
                logger.warning("Failed to save cache: \(error.localizedDescription)")
            }
        } catch {
            logger.warning("Quiet refresh failed: \(error.localizedDescription)")
        }
    }
    
    func installTool(_ name: String, version: String? = nil) async {
        toolOperations[name] = ToolOperation(
            status: .running,
            action: .install,
            startedAt: Date()
        )
        
        do {
            try await client.installTool(name, version: version)
            toolOperations[name] = .idle
            await refreshQuietly()
            
        } catch let error as MiseError {
            toolOperations[name] = .failed(action: .install, error: error)
            await refresh(force: true)
            logger.error("Install failed for \(name): \(error.localizedDescription)")
        } catch {
            toolOperations[name] = ToolOperation(
                status: .failed,
                action: .install,
                errorMessage: error.localizedDescription
            )
            await refresh(force: true)
        }
    }
    
    func uninstallTool(_ name: String) async {
        toolOperations[name] = ToolOperation(
            status: .running,
            action: .uninstall,
            startedAt: Date()
        )
        
        do {
            try await client.uninstallTool(name)
            toolOperations[name] = .idle
            await refreshQuietly()
            
        } catch let error as MiseError {
            toolOperations[name] = .failed(action: .uninstall, error: error)
            await refresh(force: true)
        } catch {
            toolOperations[name] = ToolOperation(
                status: .failed,
                action: .uninstall,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    func updateTool(_ name: String) async {
        toolOperations[name] = ToolOperation(
            status: .running,
            action: .update,
            startedAt: Date()
        )
        
        do {
            try await client.updateTool(name)
            toolOperations[name] = .idle
            await refreshQuietly()
            
        } catch let error as MiseError {
            toolOperations[name] = .failed(action: .update, error: error)
            await refresh(force: true)
        } catch {
            toolOperations[name] = ToolOperation(
                status: .failed,
                action: .update,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    func runTask(_ taskName: String) async -> String? {
        toolOperations[taskName] = ToolOperation(
            status: .running,
            action: .info,
            startedAt: Date()
        )
        
        do {
            let output = try await client.runTask(taskName)
            toolOperations[taskName] = .idle
            return output
            
        } catch {
            toolOperations[taskName] = ToolOperation(
                status: .failed,
                action: .info,
                errorMessage: error.localizedDescription
            )
            logger.error("Task \(taskName) failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func restoreFromCache() async {
        let cached = await Task.detached(priority: .utility) {
            ToolsDiskCache.load()
        }.value
        
        if let cached {
            state = .loaded(cached.tools)
            tasks = cached.tasks ?? []
            lastRefresh = cached.lastRefresh
            logger.info("Restored \(cached.tools.count) tools from cache")
        }
    }
    
    func clearError() {
        nonFatalError = nil
    }
}

struct RefreshRequest {
    let force: Bool
}
