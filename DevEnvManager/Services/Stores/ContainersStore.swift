import SwiftUI
import os

// MARK: - State

enum ContainersState: Equatable {
    case idle
    case loading
    case loaded(machines: [OrbMachine], containers: [OrbContainer], projects: [ComposeProject])
    case refreshing(machines: [OrbMachine], containers: [OrbContainer], projects: [ComposeProject])
    case unavailable
    case error(String)
}

// MARK: - Store

@MainActor
@Observable
final class ContainersStore {
    var state: ContainersState = .idle
    var nonFatalError: String?
    var containerOperations: [String: OrbOperation] = [:]
    var machineOperations: [String: OrbOperation] = [:]
    
    private var client: OrbStackClient?
    private let logger = Logger(subsystem: "dev.devenvmanager", category: "ContainersStore")
    
    private var refreshInFlight = false
    private var lastRefresh: Date?
    private let minimumRefreshInterval: TimeInterval = 2.0
    
    // MARK: - Computed Properties
    
    var machines: [OrbMachine] {
        switch state {
        case .loaded(let machines, _, _), .refreshing(let machines, _, _):
            return machines
        default:
            return []
        }
    }
    
    var containers: [OrbContainer] {
        switch state {
        case .loaded(_, let containers, _), .refreshing(_, let containers, _):
            return containers
        default:
            return []
        }
    }
    
    var composeProjects: [ComposeProject] {
        switch state {
        case .loaded(_, _, let projects), .refreshing(_, _, let projects):
            return projects
        default:
            return []
        }
    }
    
    var runningMachines: [OrbMachine] {
        machines.filter { $0.state == .running }
    }
    
    var runningContainers: [OrbContainer] {
        containers.filter { $0.state == .running }
    }
    
    var standaloneContainers: [OrbContainer] {
        containers.filter { !$0.isComposeContainer }
    }
    
    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }
    
    var isRefreshing: Bool {
        if case .refreshing = state { return true }
        return false
    }
    
    var isOrbAvailable: Bool {
        if case .unavailable = state { return false }
        if case .error = state { return false }
        return true
    }
    
    var totalRunning: Int {
        runningMachines.count + runningContainers.count
    }
    
    // MARK: - Lifecycle
    
    func initialize() async {
        client = await OrbStackClient()
        await refresh()
    }
    
    func refresh(force: Bool = false) async {
        guard let client else {
            state = .unavailable
            return
        }
        
        // Rate limiting
        if !force, let lastRefresh,
           Date().timeIntervalSince(lastRefresh) < minimumRefreshInterval {
            return
        }
        
        if refreshInFlight { return }
        refreshInFlight = true
        defer { refreshInFlight = false }
        
        // Transition state
        switch state {
        case .loaded(let machines, let containers, let projects):
            state = .refreshing(machines: machines, containers: containers, projects: projects)
        case .idle, .error, .unavailable:
            state = .loading
        case .loading, .refreshing:
            break
        }
        
        do {
            // Check OrbStack availability
            let orbAvailable = await client.isOrbAvailable()
            let dockerAvailable = await client.isDockerAvailable()
            
            if !orbAvailable && !dockerAvailable {
                state = .unavailable
                logger.warning("OrbStack/Docker not available")
                return
            }
            
            // Fetch data in parallel
            async let machinesTask = orbAvailable ? client.listMachines() : []
            async let containersTask = dockerAvailable ? client.listContainers(all: true) : []
            
            let (machines, containers) = try await (machinesTask, containersTask)
            
            // Group containers by compose project
            let projects = groupByComposeProject(containers)
            
            state = .loaded(machines: machines, containers: containers, projects: projects)
            lastRefresh = Date()
            logger.debug("Loaded \(machines.count) machines, \(containers.count) containers, \(projects.count) projects")
            
        } catch let error as OrbStackError {
            handleError(error)
        } catch {
            if case .refreshing(let oldMachines, let oldContainers, let oldProjects) = state {
                state = .loaded(machines: oldMachines, containers: oldContainers, projects: oldProjects)
                nonFatalError = error.localizedDescription
            } else {
                state = .error(error.localizedDescription)
            }
            logger.error("Refresh failed: \(error.localizedDescription)")
        }
    }
    
    private func groupByComposeProject(_ containers: [OrbContainer]) -> [ComposeProject] {
        var projectMap: [String: ComposeProject] = [:]
        
        for container in containers where container.isComposeContainer {
            guard let projectName = container.composeProject else { continue }
            
            if var project = projectMap[projectName] {
                project.containers.append(container)
                projectMap[projectName] = project
            } else {
                projectMap[projectName] = ComposeProject(
                    id: projectName,
                    name: projectName,
                    workingDir: nil,
                    configFile: nil,
                    containers: [container]
                )
            }
        }
        
        return Array(projectMap.values).sorted { $0.name < $1.name }
    }
    
    private func handleError(_ error: OrbStackError) {
        switch error {
        case .orbNotFound, .dockerNotFound:
            state = .unavailable
        default:
            if case .refreshing(let oldMachines, let oldContainers, let oldProjects) = state {
                state = .loaded(machines: oldMachines, containers: oldContainers, projects: oldProjects)
                nonFatalError = error.localizedDescription
            } else {
                state = .error(error.localizedDescription)
            }
        }
        logger.error("OrbStack error: \(error.localizedDescription)")
    }
    
    // MARK: - Machine Operations
    
    func startMachine(_ name: String) async {
        guard let client else { return }
        
        machineOperations[name] = OrbOperation(
            targetId: name,
            targetName: name,
            kind: .startMachine
        )
        
        do {
            try await client.startMachine(name)
            machineOperations.removeValue(forKey: name)
            await refresh(force: true)
        } catch {
            machineOperations[name] = OrbOperation(
                targetId: name,
                targetName: name,
                kind: .startMachine,
                status: .failed,
                error: error.localizedDescription
            )
            logger.error("Start machine failed for \(name): \(error.localizedDescription)")
        }
    }
    
    func stopMachine(_ name: String) async {
        guard let client else { return }
        
        machineOperations[name] = OrbOperation(
            targetId: name,
            targetName: name,
            kind: .stopMachine
        )
        
        do {
            try await client.stopMachine(name)
            machineOperations.removeValue(forKey: name)
            await refresh(force: true)
        } catch {
            machineOperations[name] = OrbOperation(
                targetId: name,
                targetName: name,
                kind: .stopMachine,
                status: .failed,
                error: error.localizedDescription
            )
            logger.error("Stop machine failed for \(name): \(error.localizedDescription)")
        }
    }
    
    func restartMachine(_ name: String) async {
        guard let client else { return }
        
        machineOperations[name] = OrbOperation(
            targetId: name,
            targetName: name,
            kind: .restartMachine
        )
        
        do {
            try await client.restartMachine(name)
            machineOperations.removeValue(forKey: name)
            await refresh(force: true)
        } catch {
            machineOperations[name] = OrbOperation(
                targetId: name,
                targetName: name,
                kind: .restartMachine,
                status: .failed,
                error: error.localizedDescription
            )
            logger.error("Restart machine failed for \(name): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Container Operations
    
    func startContainer(_ id: String, name: String) async {
        guard let client else { return }
        
        containerOperations[id] = OrbOperation(
            targetId: id,
            targetName: name,
            kind: .startContainer
        )
        
        do {
            try await client.startContainer(id)
            containerOperations.removeValue(forKey: id)
            await refresh(force: true)
        } catch {
            containerOperations[id] = OrbOperation(
                targetId: id,
                targetName: name,
                kind: .startContainer,
                status: .failed,
                error: error.localizedDescription
            )
            logger.error("Start container failed for \(name): \(error.localizedDescription)")
        }
    }
    
    func stopContainer(_ id: String, name: String) async {
        guard let client else { return }
        
        containerOperations[id] = OrbOperation(
            targetId: id,
            targetName: name,
            kind: .stopContainer
        )
        
        do {
            try await client.stopContainer(id)
            containerOperations.removeValue(forKey: id)
            await refresh(force: true)
        } catch {
            containerOperations[id] = OrbOperation(
                targetId: id,
                targetName: name,
                kind: .stopContainer,
                status: .failed,
                error: error.localizedDescription
            )
            logger.error("Stop container failed for \(name): \(error.localizedDescription)")
        }
    }
    
    func restartContainer(_ id: String, name: String) async {
        guard let client else { return }
        
        containerOperations[id] = OrbOperation(
            targetId: id,
            targetName: name,
            kind: .restartContainer
        )
        
        do {
            try await client.restartContainer(id)
            containerOperations.removeValue(forKey: id)
            await refresh(force: true)
        } catch {
            containerOperations[id] = OrbOperation(
                targetId: id,
                targetName: name,
                kind: .restartContainer,
                status: .failed,
                error: error.localizedDescription
            )
            logger.error("Restart container failed for \(name): \(error.localizedDescription)")
        }
    }
    
    func removeContainer(_ id: String, name: String, force: Bool = false) async {
        guard let client else { return }
        
        containerOperations[id] = OrbOperation(
            targetId: id,
            targetName: name,
            kind: .removeContainer
        )
        
        do {
            try await client.removeContainer(id, force: force)
            containerOperations.removeValue(forKey: id)
            await refresh(force: true)
        } catch {
            containerOperations[id] = OrbOperation(
                targetId: id,
                targetName: name,
                kind: .removeContainer,
                status: .failed,
                error: error.localizedDescription
            )
            logger.error("Remove container failed for \(name): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Utilities
    
    func clearError() {
        nonFatalError = nil
    }
    
    func clearOperation(forContainer id: String) {
        containerOperations.removeValue(forKey: id)
    }
    
    func clearOperation(forMachine name: String) {
        machineOperations.removeValue(forKey: name)
    }
}
