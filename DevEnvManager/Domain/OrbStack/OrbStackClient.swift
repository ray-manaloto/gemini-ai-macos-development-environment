import Foundation
import os

/// Actor for thread-safe OrbStack and Docker CLI operations
actor OrbStackClient: OrbStackClientProtocol {
    private let logger = Logger(subsystem: "dev.devenvmanager", category: "OrbStackClient")
    private let orbPath: String
    private let dockerPath: String
    private let timeout: Duration = .seconds(30)
    
    init() async {
        self.orbPath = await Self.findOrbPath()
        self.dockerPath = await Self.findDockerPath()
    }
    
    // MARK: - Path Discovery
    
    private static func findOrbPath() async -> String {
        let possiblePaths = [
            "/opt/homebrew/bin/orb",
            "/usr/local/bin/orb",
            "/Applications/OrbStack.app/Contents/MacOS/xbin/orb"
        ]
        
        for path in possiblePaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        return "/opt/homebrew/bin/orb"
    }
    
    private static func findDockerPath() async -> String {
        let possiblePaths = [
            "/opt/homebrew/bin/docker",
            "/usr/local/bin/docker",
            "/Applications/OrbStack.app/Contents/MacOS/xbin/docker"
        ]
        
        for path in possiblePaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        return "/opt/homebrew/bin/docker"
    }
    
    // MARK: - Availability Checks
    
    func isOrbAvailable() async -> Bool {
        FileManager.default.isExecutableFile(atPath: orbPath)
    }
    
    func isDockerAvailable() async -> Bool {
        FileManager.default.isExecutableFile(atPath: dockerPath)
    }
    
    func isOrbRunning() async -> Bool {
        do {
            let result = try await CommandExecutor.run(
                path: orbPath,
                arguments: ["status"],
                timeout: .seconds(5)
            )
            return result.isSuccess && result.stdout.lowercased().contains("running")
        } catch {
            return false
        }
    }
    
    // MARK: - Linux Machines
    
    func listMachines() async throws -> [OrbMachine] {
        guard await isOrbAvailable() else {
            throw OrbStackError.orbNotFound
        }
        
        let result = try await CommandExecutor.run(
            path: orbPath,
            arguments: ["list", "--format", "json"],
            timeout: timeout
        )
        
        guard result.isSuccess else {
            // Empty list is valid
            if result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "[]" {
                return []
            }
            throw OrbStackError.operationFailed(operation: "list machines", message: result.stderr)
        }
        
        guard let data = result.stdout.data(using: .utf8) else {
            throw OrbStackError.parseError(message: "Invalid UTF-8 output")
        }
        
        // Handle empty JSON array
        let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "[]" || trimmed.isEmpty {
            return []
        }
        
        do {
            let machines = try JSONDecoder().decode([OrbMachineJSON].self, from: data)
            logger.debug("Loaded \(machines.count) machines")
            return machines.map { $0.toOrbMachine() }
        } catch {
            // orb list might return non-JSON for empty list
            logger.warning("Failed to parse machine list: \(error)")
            return []
        }
    }
    
    func startMachine(_ name: String) async throws {
        logger.info("Starting machine: \(name)")
        
        let result = try await CommandExecutor.run(
            path: orbPath,
            arguments: ["start", name],
            timeout: .seconds(60)
        )
        
        guard result.isSuccess else {
            throw OrbStackError.operationFailed(operation: "start machine", message: result.stderr)
        }
        
        logger.info("Started machine: \(name)")
    }
    
    func stopMachine(_ name: String) async throws {
        logger.info("Stopping machine: \(name)")
        
        let result = try await CommandExecutor.run(
            path: orbPath,
            arguments: ["stop", name],
            timeout: .seconds(30)
        )
        
        guard result.isSuccess else {
            throw OrbStackError.operationFailed(operation: "stop machine", message: result.stderr)
        }
        
        logger.info("Stopped machine: \(name)")
    }
    
    func restartMachine(_ name: String) async throws {
        logger.info("Restarting machine: \(name)")
        
        let result = try await CommandExecutor.run(
            path: orbPath,
            arguments: ["restart", name],
            timeout: .seconds(90)
        )
        
        guard result.isSuccess else {
            throw OrbStackError.operationFailed(operation: "restart machine", message: result.stderr)
        }
        
        logger.info("Restarted machine: \(name)")
    }
    
    func deleteMachine(_ name: String) async throws {
        logger.info("Deleting machine: \(name)")
        
        let result = try await CommandExecutor.run(
            path: orbPath,
            arguments: ["delete", "-f", name],
            timeout: .seconds(30)
        )
        
        guard result.isSuccess else {
            throw OrbStackError.operationFailed(operation: "delete machine", message: result.stderr)
        }
        
        logger.info("Deleted machine: \(name)")
    }
    
    // MARK: - Docker Containers
    
    func listContainers(all: Bool = true) async throws -> [OrbContainer] {
        guard await isDockerAvailable() else {
            throw OrbStackError.dockerNotFound
        }
        
        var arguments = ["ps", "--format", "json"]
        if all {
            arguments.insert("-a", at: 1)
        }
        
        let result = try await CommandExecutor.run(
            path: dockerPath,
            arguments: arguments,
            timeout: timeout
        )
        
        guard result.isSuccess else {
            throw OrbStackError.operationFailed(operation: "list containers", message: result.stderr)
        }
        
        // Docker outputs one JSON object per line (not a JSON array)
        let lines = result.stdout.split(separator: "\n")
        var containers: [OrbContainer] = []
        
        for line in lines {
            guard let data = String(line).data(using: .utf8) else { continue }
            do {
                let containerJSON = try JSONDecoder().decode(DockerContainerJSON.self, from: data)
                containers.append(containerJSON.toOrbContainer())
            } catch {
                logger.warning("Failed to parse container: \(error)")
            }
        }
        
        logger.debug("Loaded \(containers.count) containers")
        return containers
    }
    
    func startContainer(_ id: String) async throws {
        logger.info("Starting container: \(id)")
        
        let result = try await CommandExecutor.run(
            path: dockerPath,
            arguments: ["start", id],
            timeout: .seconds(30)
        )
        
        guard result.isSuccess else {
            throw OrbStackError.operationFailed(operation: "start container", message: result.stderr)
        }
        
        logger.info("Started container: \(id)")
    }
    
    func stopContainer(_ id: String) async throws {
        logger.info("Stopping container: \(id)")
        
        let result = try await CommandExecutor.run(
            path: dockerPath,
            arguments: ["stop", id],
            timeout: .seconds(30)
        )
        
        guard result.isSuccess else {
            throw OrbStackError.operationFailed(operation: "stop container", message: result.stderr)
        }
        
        logger.info("Stopped container: \(id)")
    }
    
    func restartContainer(_ id: String) async throws {
        logger.info("Restarting container: \(id)")
        
        let result = try await CommandExecutor.run(
            path: dockerPath,
            arguments: ["restart", id],
            timeout: .seconds(60)
        )
        
        guard result.isSuccess else {
            throw OrbStackError.operationFailed(operation: "restart container", message: result.stderr)
        }
        
        logger.info("Restarted container: \(id)")
    }
    
    func removeContainer(_ id: String, force: Bool = false) async throws {
        logger.info("Removing container: \(id) (force: \(force))")
        
        var arguments = ["rm", id]
        if force {
            arguments.insert("-f", at: 1)
        }
        
        let result = try await CommandExecutor.run(
            path: dockerPath,
            arguments: arguments,
            timeout: .seconds(30)
        )
        
        guard result.isSuccess else {
            throw OrbStackError.operationFailed(operation: "remove container", message: result.stderr)
        }
        
        logger.info("Removed container: \(id)")
    }
    
    func pauseContainer(_ id: String) async throws {
        logger.info("Pausing container: \(id)")
        
        let result = try await CommandExecutor.run(
            path: dockerPath,
            arguments: ["pause", id],
            timeout: .seconds(10)
        )
        
        guard result.isSuccess else {
            throw OrbStackError.operationFailed(operation: "pause container", message: result.stderr)
        }
        
        logger.info("Paused container: \(id)")
    }
    
    func unpauseContainer(_ id: String) async throws {
        logger.info("Unpausing container: \(id)")
        
        let result = try await CommandExecutor.run(
            path: dockerPath,
            arguments: ["unpause", id],
            timeout: .seconds(10)
        )
        
        guard result.isSuccess else {
            throw OrbStackError.operationFailed(operation: "unpause container", message: result.stderr)
        }
        
        logger.info("Unpaused container: \(id)")
    }
}
