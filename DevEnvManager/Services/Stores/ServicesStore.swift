import SwiftUI
import os

enum ServicesState: Equatable {
    case idle
    case loading
    case loaded([BrewService])
    case refreshing([BrewService])
    case unavailable
    case error(String)
}

@MainActor
@Observable
final class ServicesStore {
    var state: ServicesState = .idle
    var nonFatalError: String?
    var serviceOperations: [String: ServiceOperation] = [:]
    
    private var client: BrewServicesClient?
    private let portDetector = PortDetector()
    private let logger = Logger(subsystem: "dev.devenvmanager", category: "ServicesStore")
    
    private var refreshInFlight = false
    private var lastRefresh: Date?
    private let minimumRefreshInterval: TimeInterval = 2.0
    
    var services: [BrewService] {
        switch state {
        case .loaded(let services), .refreshing(let services):
            return services
        default:
            return []
        }
    }
    
    var runningServices: [BrewService] {
        services.filter { $0.isRunning }
    }
    
    var stoppedServices: [BrewService] {
        services.filter { !$0.isRunning }
    }
    
    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }
    
    var isRefreshing: Bool {
        if case .refreshing = state { return true }
        return false
    }
    
    var isAvailable: Bool {
        if case .unavailable = state { return false }
        if case .error = state { return false }
        return true
    }
    
    func initialize() async {
        client = await BrewServicesClient()
        await refresh()
    }
    
    func refresh(force: Bool = false) async {
        guard let client else {
            state = .unavailable
            return
        }
        
        if !force, let lastRefresh,
           Date().timeIntervalSince(lastRefresh) < minimumRefreshInterval {
            return
        }
        
        if refreshInFlight { return }
        refreshInFlight = true
        defer { refreshInFlight = false }
        
        switch state {
        case .loaded(let services):
            state = .refreshing(services)
        case .idle, .error, .unavailable:
            state = .loading
        case .loading, .refreshing:
            break
        }
        
        do {
            var services = try await client.listServices()
            
            services = await enrichWithPorts(services)
            
            state = .loaded(services)
            lastRefresh = Date()
            
        } catch let error as BrewError where error == .notInstalled {
            state = .unavailable
            logger.warning("Homebrew not available")
        } catch {
            if case .refreshing(let oldServices) = state {
                state = .loaded(oldServices)
                nonFatalError = error.localizedDescription
            } else {
                state = .error(error.localizedDescription)
            }
            logger.error("Refresh failed: \(error.localizedDescription)")
        }
    }
    
    private func enrichWithPorts(_ services: [BrewService]) async -> [BrewService] {
        var enriched = services
        let ports = await portDetector.detectListeningPorts()
        
        for (index, service) in enriched.enumerated() {
            if let matchingPort = ports.first(where: { 
                $0.process.lowercased().contains(service.name.lowercased())
            }) {
                enriched[index].port = matchingPort.port
                enriched[index].pid = matchingPort.pid
            }
        }
        
        return enriched
    }
    
    func startService(_ name: String) async {
        guard let client else { return }
        
        serviceOperations[name] = ServiceOperation(
            status: .running,
            action: .start,
            startedAt: Date()
        )
        
        do {
            try await client.startService(name)
            serviceOperations[name] = .idle
            await refresh(force: true)
            
        } catch let error as BrewError {
            serviceOperations[name] = .failed(action: .start, error: error)
            logger.error("Start failed for \(name): \(error.localizedDescription)")
        } catch {
            serviceOperations[name] = ServiceOperation(
                status: .failed,
                action: .start,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    func stopService(_ name: String) async {
        guard let client else { return }
        
        serviceOperations[name] = ServiceOperation(
            status: .running,
            action: .stop,
            startedAt: Date()
        )
        
        do {
            try await client.stopService(name)
            serviceOperations[name] = .idle
            await refresh(force: true)
            
        } catch let error as BrewError {
            serviceOperations[name] = .failed(action: .stop, error: error)
            logger.error("Stop failed for \(name): \(error.localizedDescription)")
        } catch {
            serviceOperations[name] = ServiceOperation(
                status: .failed,
                action: .stop,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    func restartService(_ name: String) async {
        guard let client else { return }
        
        serviceOperations[name] = ServiceOperation(
            status: .running,
            action: .restart,
            startedAt: Date()
        )
        
        do {
            try await client.restartService(name)
            serviceOperations[name] = .idle
            await refresh(force: true)
            
        } catch let error as BrewError {
            serviceOperations[name] = .failed(action: .restart, error: error)
            logger.error("Restart failed for \(name): \(error.localizedDescription)")
        } catch {
            serviceOperations[name] = ServiceOperation(
                status: .failed,
                action: .restart,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    func clearError() {
        nonFatalError = nil
    }
}
