import Foundation

/// Protocol for OrbStack operations - supports dependency injection and testing
protocol OrbStackClientProtocol: Sendable {
    // Availability checks
    func isOrbAvailable() async -> Bool
    func isDockerAvailable() async -> Bool
    func isOrbRunning() async -> Bool
    
    // Linux machines
    func listMachines() async throws -> [OrbMachine]
    func startMachine(_ name: String) async throws
    func stopMachine(_ name: String) async throws
    func restartMachine(_ name: String) async throws
    func deleteMachine(_ name: String) async throws
    
    // Docker containers
    func listContainers(all: Bool) async throws -> [OrbContainer]
    func startContainer(_ id: String) async throws
    func stopContainer(_ id: String) async throws
    func restartContainer(_ id: String) async throws
    func removeContainer(_ id: String, force: Bool) async throws
    func pauseContainer(_ id: String) async throws
    func unpauseContainer(_ id: String) async throws
}
