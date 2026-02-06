import Foundation

// MARK: - Linux Machine Models

/// A Linux machine (VM) managed by OrbStack
struct OrbMachine: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let distro: String
    let state: MachineState
    let isDefault: Bool
    let cpuCount: Int?
    let memoryGB: Double?
    let diskGB: Double?
    
    enum MachineState: String, Sendable, CaseIterable {
        case running
        case stopped
        case starting
        case stopping
        case unknown
        
        var displayName: String {
            switch self {
            case .running: return "Running"
            case .stopped: return "Stopped"
            case .starting: return "Starting"
            case .stopping: return "Stopping"
            case .unknown: return "Unknown"
            }
        }
        
        var icon: String {
            switch self {
            case .running: return "play.circle.fill"
            case .stopped: return "stop.circle.fill"
            case .starting: return "arrow.clockwise.circle"
            case .stopping: return "arrow.clockwise.circle"
            case .unknown: return "questionmark.circle"
            }
        }
        
        var color: String {
            switch self {
            case .running: return "green"
            case .stopped: return "gray"
            case .starting, .stopping: return "orange"
            case .unknown: return "red"
            }
        }
    }
}

// MARK: - Docker Container Models

/// A Docker container running on OrbStack
struct OrbContainer: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let image: String
    let state: ContainerState
    let status: String
    let ports: [PortMapping]
    let composeProject: String?
    let composeService: String?
    let createdAt: Date?
    let platform: Platform?
    
    enum ContainerState: String, Sendable, CaseIterable {
        case running
        case paused
        case exited
        case created
        case restarting
        case removing
        case dead
        case unknown
        
        var displayName: String {
            switch self {
            case .running: return "Running"
            case .paused: return "Paused"
            case .exited: return "Exited"
            case .created: return "Created"
            case .restarting: return "Restarting"
            case .removing: return "Removing"
            case .dead: return "Dead"
            case .unknown: return "Unknown"
            }
        }
        
        var icon: String {
            switch self {
            case .running: return "play.circle.fill"
            case .paused: return "pause.circle.fill"
            case .exited: return "stop.circle.fill"
            case .created: return "plus.circle"
            case .restarting: return "arrow.clockwise.circle"
            case .removing: return "trash.circle"
            case .dead: return "xmark.circle.fill"
            case .unknown: return "questionmark.circle"
            }
        }
        
        var color: String {
            switch self {
            case .running: return "green"
            case .paused: return "yellow"
            case .exited, .created: return "gray"
            case .restarting: return "orange"
            case .removing, .dead: return "red"
            case .unknown: return "gray"
            }
        }
    }
    
    struct PortMapping: Hashable, Sendable {
        let hostPort: Int
        let containerPort: Int
        let hostIP: String?
        let proto: String  // tcp, udp
        
        var displayString: String {
            let host = hostIP ?? "0.0.0.0"
            return "\(host):\(hostPort) -> \(containerPort)/\(proto)"
        }
    }
    
    struct Platform: Hashable, Sendable {
        let os: String
        let architecture: String
    }
    
    /// Whether this container is part of a Docker Compose project
    var isComposeContainer: Bool {
        composeProject != nil
    }
    
    /// Short container ID (first 12 chars)
    var shortId: String {
        String(id.prefix(12))
    }
}

// MARK: - Compose Project Grouping

/// A Docker Compose project with its containers
struct ComposeProject: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let workingDir: String?
    let configFile: String?
    var containers: [OrbContainer]
    
    var runningCount: Int {
        containers.filter { $0.state == .running }.count
    }
    
    var totalCount: Int {
        containers.count
    }
    
    var statusSummary: String {
        "\(runningCount)/\(totalCount) running"
    }
}

// MARK: - Operation Models

/// Operation being performed on a machine or container
struct OrbOperation: Identifiable, Sendable {
    let id: UUID
    let targetId: String
    let targetName: String
    let kind: Kind
    let status: Status
    let startedAt: Date
    let error: String?
    
    enum Kind: String, Sendable {
        // Machine operations
        case startMachine = "start_machine"
        case stopMachine = "stop_machine"
        case restartMachine = "restart_machine"
        case deleteMachine = "delete_machine"
        
        // Container operations
        case startContainer = "start_container"
        case stopContainer = "stop_container"
        case restartContainer = "restart_container"
        case removeContainer = "remove_container"
        case pauseContainer = "pause_container"
        case unpauseContainer = "unpause_container"
        
        var displayName: String {
            switch self {
            case .startMachine: return "Starting"
            case .stopMachine: return "Stopping"
            case .restartMachine: return "Restarting"
            case .deleteMachine: return "Deleting"
            case .startContainer: return "Starting"
            case .stopContainer: return "Stopping"
            case .restartContainer: return "Restarting"
            case .removeContainer: return "Removing"
            case .pauseContainer: return "Pausing"
            case .unpauseContainer: return "Unpausing"
            }
        }
    }
    
    enum Status: Sendable {
        case running
        case completed
        case failed
    }
    
    init(
        id: UUID = UUID(),
        targetId: String,
        targetName: String,
        kind: Kind,
        status: Status = .running,
        startedAt: Date = Date(),
        error: String? = nil
    ) {
        self.id = id
        self.targetId = targetId
        self.targetName = targetName
        self.kind = kind
        self.status = status
        self.startedAt = startedAt
        self.error = error
    }
}

// MARK: - JSON Parsing (docker ps --format json)

struct DockerContainerJSON: Decodable {
    let ID: String
    let Names: String
    let Image: String
    let State: String
    let Status: String
    let Ports: String
    let Labels: String
    let CreatedAt: String?
    let Command: String?
    let Platform: PlatformJSON?
    
    struct PlatformJSON: Decodable {
        let os: String
        let architecture: String
    }
    
    func toOrbContainer() -> OrbContainer {
        // Parse compose labels
        let labelDict = parseLabels(Labels)
        let composeProject = labelDict["com.docker.compose.project"]
        let composeService = labelDict["com.docker.compose.service"]
        
        // Parse ports: "0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp"
        let portMappings = parsePorts(Ports)
        
        // Parse state
        let state: OrbContainer.ContainerState
        switch State.lowercased() {
        case "running": state = .running
        case "paused": state = .paused
        case "exited": state = .exited
        case "created": state = .created
        case "restarting": state = .restarting
        case "removing": state = .removing
        case "dead": state = .dead
        default: state = .unknown
        }
        
        // Parse created date
        let createdDate: Date?
        if let createdStr = CreatedAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z zzz"
            createdDate = formatter.date(from: createdStr)
        } else {
            createdDate = nil
        }
        
        let platform: OrbContainer.Platform?
        if let p = Platform {
            platform = OrbContainer.Platform(os: p.os, architecture: p.architecture)
        } else {
            platform = nil
        }
        
        return OrbContainer(
            id: ID,
            name: Names,
            image: Image,
            state: state,
            status: Status,
            ports: portMappings,
            composeProject: composeProject,
            composeService: composeService,
            createdAt: createdDate,
            platform: platform
        )
    }
    
    private func parseLabels(_ labels: String) -> [String: String] {
        var result: [String: String] = [:]
        let pairs = labels.split(separator: ",")
        for pair in pairs {
            let kv = pair.split(separator: "=", maxSplits: 1)
            if kv.count == 2 {
                result[String(kv[0])] = String(kv[1])
            }
        }
        return result
    }
    
    private func parsePorts(_ ports: String) -> [OrbContainer.PortMapping] {
        guard !ports.isEmpty else { return [] }
        
        var result: [OrbContainer.PortMapping] = []
        // Example: "0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp"
        let portEntries = ports.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        for entry in portEntries {
            // Skip IPv6 entries for now
            if entry.hasPrefix("[::]:") { continue }
            
            // Parse "0.0.0.0:8000->8000/tcp" or "8000/tcp"
            if let arrowIndex = entry.firstIndex(of: "-") {
                // Has mapping: "0.0.0.0:8000->8000/tcp"
                let hostPart = String(entry[..<arrowIndex])
                let containerPart = String(entry[entry.index(arrowIndex, offsetBy: 2)...])
                
                // Parse host: "0.0.0.0:8000"
                let hostComponents = hostPart.split(separator: ":")
                let hostIP = hostComponents.count > 1 ? String(hostComponents[0]) : nil
                let hostPort = Int(hostComponents.last ?? "") ?? 0
                
                // Parse container: "8000/tcp"
                let containerComponents = containerPart.split(separator: "/")
                let containerPort = Int(containerComponents.first ?? "") ?? 0
                let proto = String(containerComponents.last ?? "tcp")
                
                if hostPort > 0 && containerPort > 0 {
                    result.append(OrbContainer.PortMapping(
                        hostPort: hostPort,
                        containerPort: containerPort,
                        hostIP: hostIP,
                        proto: proto
                    ))
                }
            }
        }
        
        return result
    }
}

// MARK: - JSON Parsing (orb list --format json)

struct OrbMachineJSON: Decodable {
    let name: String
    let distro: String?
    let state: String?
    let default_machine: Bool?
    let cpu_count: Int?
    let memory_gb: Double?
    let disk_gb: Double?
    
    func toOrbMachine() -> OrbMachine {
        let machineState: OrbMachine.MachineState
        switch (state ?? "").lowercased() {
        case "running": machineState = .running
        case "stopped": machineState = .stopped
        case "starting": machineState = .starting
        case "stopping": machineState = .stopping
        default: machineState = .unknown
        }
        
        return OrbMachine(
            id: name,
            name: name,
            distro: distro ?? "unknown",
            state: machineState,
            isDefault: default_machine ?? false,
            cpuCount: cpu_count,
            memoryGB: memory_gb,
            diskGB: disk_gb
        )
    }
}
