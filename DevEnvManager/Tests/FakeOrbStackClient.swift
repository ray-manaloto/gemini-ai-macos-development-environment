import Foundation

/// Fake OrbStack client for testing and previews
actor FakeOrbStackClient: OrbStackClientProtocol {
    var machines: [OrbMachine] = []
    var containers: [OrbContainer] = []
    var shouldFail = false
    var operationDelay: Duration = .milliseconds(500)
    
    private var orbAvailable = true
    private var dockerAvailable = true
    private var orbRunning = true
    
    // MARK: - Configuration
    
    func setAvailability(orb: Bool, docker: Bool, running: Bool = true) {
        orbAvailable = orb
        dockerAvailable = docker
        orbRunning = running
    }
    
    // MARK: - OrbStackClientProtocol
    
    func isOrbAvailable() async -> Bool {
        orbAvailable
    }
    
    func isDockerAvailable() async -> Bool {
        dockerAvailable
    }
    
    func isOrbRunning() async -> Bool {
        orbRunning
    }
    
    func listMachines() async throws -> [OrbMachine] {
        if shouldFail {
            throw OrbStackError.operationFailed(operation: "list machines", message: "Fake error")
        }
        try await Task.sleep(for: operationDelay)
        return machines
    }
    
    func startMachine(_ name: String) async throws {
        if shouldFail {
            throw OrbStackError.operationFailed(operation: "start machine", message: "Fake error")
        }
        try await Task.sleep(for: operationDelay)
        
        if let index = machines.firstIndex(where: { $0.name == name }) {
            machines[index] = OrbMachine(
                id: machines[index].id,
                name: machines[index].name,
                distro: machines[index].distro,
                state: .running,
                isDefault: machines[index].isDefault,
                cpuCount: machines[index].cpuCount,
                memoryGB: machines[index].memoryGB,
                diskGB: machines[index].diskGB
            )
        }
    }
    
    func stopMachine(_ name: String) async throws {
        if shouldFail {
            throw OrbStackError.operationFailed(operation: "stop machine", message: "Fake error")
        }
        try await Task.sleep(for: operationDelay)
        
        if let index = machines.firstIndex(where: { $0.name == name }) {
            machines[index] = OrbMachine(
                id: machines[index].id,
                name: machines[index].name,
                distro: machines[index].distro,
                state: .stopped,
                isDefault: machines[index].isDefault,
                cpuCount: machines[index].cpuCount,
                memoryGB: machines[index].memoryGB,
                diskGB: machines[index].diskGB
            )
        }
    }
    
    func restartMachine(_ name: String) async throws {
        try await stopMachine(name)
        try await startMachine(name)
    }
    
    func deleteMachine(_ name: String) async throws {
        if shouldFail {
            throw OrbStackError.operationFailed(operation: "delete machine", message: "Fake error")
        }
        try await Task.sleep(for: operationDelay)
        machines.removeAll { $0.name == name }
    }
    
    func listContainers(all: Bool) async throws -> [OrbContainer] {
        if shouldFail {
            throw OrbStackError.operationFailed(operation: "list containers", message: "Fake error")
        }
        try await Task.sleep(for: operationDelay)
        
        if all {
            return containers
        }
        return containers.filter { $0.state == .running }
    }
    
    func startContainer(_ id: String) async throws {
        if shouldFail {
            throw OrbStackError.operationFailed(operation: "start container", message: "Fake error")
        }
        try await Task.sleep(for: operationDelay)
        
        if let index = containers.firstIndex(where: { $0.id == id }) {
            let c = containers[index]
            containers[index] = OrbContainer(
                id: c.id,
                name: c.name,
                image: c.image,
                state: .running,
                status: "Up Less than a second",
                ports: c.ports,
                composeProject: c.composeProject,
                composeService: c.composeService,
                createdAt: c.createdAt,
                platform: c.platform
            )
        }
    }
    
    func stopContainer(_ id: String) async throws {
        if shouldFail {
            throw OrbStackError.operationFailed(operation: "stop container", message: "Fake error")
        }
        try await Task.sleep(for: operationDelay)
        
        if let index = containers.firstIndex(where: { $0.id == id }) {
            let c = containers[index]
            containers[index] = OrbContainer(
                id: c.id,
                name: c.name,
                image: c.image,
                state: .exited,
                status: "Exited (0) Less than a second ago",
                ports: c.ports,
                composeProject: c.composeProject,
                composeService: c.composeService,
                createdAt: c.createdAt,
                platform: c.platform
            )
        }
    }
    
    func restartContainer(_ id: String) async throws {
        try await stopContainer(id)
        try await startContainer(id)
    }
    
    func removeContainer(_ id: String, force: Bool) async throws {
        if shouldFail {
            throw OrbStackError.operationFailed(operation: "remove container", message: "Fake error")
        }
        try await Task.sleep(for: operationDelay)
        containers.removeAll { $0.id == id }
    }
    
    func pauseContainer(_ id: String) async throws {
        if shouldFail {
            throw OrbStackError.operationFailed(operation: "pause container", message: "Fake error")
        }
        try await Task.sleep(for: operationDelay)
        
        if let index = containers.firstIndex(where: { $0.id == id }) {
            let c = containers[index]
            containers[index] = OrbContainer(
                id: c.id,
                name: c.name,
                image: c.image,
                state: .paused,
                status: "Up 5 minutes (Paused)",
                ports: c.ports,
                composeProject: c.composeProject,
                composeService: c.composeService,
                createdAt: c.createdAt,
                platform: c.platform
            )
        }
    }
    
    func unpauseContainer(_ id: String) async throws {
        try await startContainer(id)
    }
}

// MARK: - Sample Data

extension FakeOrbStackClient {
    static func withSampleData() async -> FakeOrbStackClient {
        let client = FakeOrbStackClient()
        
        client.machines = [
            OrbMachine(
                id: "ubuntu",
                name: "ubuntu",
                distro: "ubuntu",
                state: .running,
                isDefault: true,
                cpuCount: 4,
                memoryGB: 8.0,
                diskGB: 64.0
            ),
            OrbMachine(
                id: "fedora",
                name: "fedora",
                distro: "fedora",
                state: .stopped,
                isDefault: false,
                cpuCount: 2,
                memoryGB: 4.0,
                diskGB: 32.0
            )
        ]
        
        client.containers = [
            OrbContainer(
                id: "abc123def456",
                name: "myapp_backend",
                image: "python:3.12-slim",
                state: .running,
                status: "Up 5 minutes (healthy)",
                ports: [
                    OrbContainer.PortMapping(hostPort: 8000, containerPort: 8000, hostIP: "0.0.0.0", proto: "tcp")
                ],
                composeProject: "myapp",
                composeService: "backend",
                createdAt: Date().addingTimeInterval(-300),
                platform: OrbContainer.Platform(os: "linux", architecture: "arm64")
            ),
            OrbContainer(
                id: "def456ghi789",
                name: "myapp_db",
                image: "postgres:16-alpine",
                state: .running,
                status: "Up 5 minutes (healthy)",
                ports: [
                    OrbContainer.PortMapping(hostPort: 5432, containerPort: 5432, hostIP: "0.0.0.0", proto: "tcp")
                ],
                composeProject: "myapp",
                composeService: "db",
                createdAt: Date().addingTimeInterval(-300),
                platform: OrbContainer.Platform(os: "linux", architecture: "arm64")
            ),
            OrbContainer(
                id: "ghi789jkl012",
                name: "myapp_redis",
                image: "redis:7-alpine",
                state: .running,
                status: "Up 5 minutes",
                ports: [
                    OrbContainer.PortMapping(hostPort: 6379, containerPort: 6379, hostIP: "0.0.0.0", proto: "tcp")
                ],
                composeProject: "myapp",
                composeService: "redis",
                createdAt: Date().addingTimeInterval(-300),
                platform: OrbContainer.Platform(os: "linux", architecture: "arm64")
            ),
            OrbContainer(
                id: "standalone123",
                name: "nginx-test",
                image: "nginx:alpine",
                state: .exited,
                status: "Exited (0) 2 hours ago",
                ports: [],
                composeProject: nil,
                composeService: nil,
                createdAt: Date().addingTimeInterval(-7200),
                platform: OrbContainer.Platform(os: "linux", architecture: "arm64")
            )
        ]
        
        return client
    }
}
