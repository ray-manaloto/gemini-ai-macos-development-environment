import Foundation
import os

actor BrewServicesClient: BrewServicesClientProtocol {
    private let logger = Logger(subsystem: "dev.devenvmanager", category: "BrewServicesClient")
    private let brewPath: String
    private let timeout: Duration = .seconds(30)
    
    init() async {
        self.brewPath = await Self.findBrewPath()
    }
    
    private static func findBrewPath() async -> String {
        let possiblePaths = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew",
            "/home/linuxbrew/.linuxbrew/bin/brew"
        ]
        
        for path in possiblePaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        return "/opt/homebrew/bin/brew"
    }
    
    func listServices() async throws -> [BrewService] {
        guard FileManager.default.isExecutableFile(atPath: brewPath) else {
            throw BrewError.notInstalled
        }
        
        let result = try await CommandExecutor.run(
            path: brewPath,
            arguments: ["services", "list", "--json"],
            timeout: timeout
        )
        
        guard result.isSuccess else {
            throw BrewError.commandFailed(result.stderr)
        }
        
        guard let data = result.stdout.data(using: .utf8) else {
            throw BrewError.parseError("Invalid UTF-8 output")
        }
        
        do {
            let services = try JSONDecoder().decode([BrewService].self, from: data)
            logger.debug("Loaded \(services.count) services")
            return services
        } catch {
            throw BrewError.parseError(error.localizedDescription)
        }
    }
    
    func startService(_ name: String) async throws {
        logger.info("Starting service: \(name)")
        
        let result = try await CommandExecutor.run(
            path: brewPath,
            arguments: ["services", "start", name],
            timeout: timeout
        )
        
        guard result.isSuccess else {
            throw BrewError.operationFailed(result.stderr.isEmpty ? result.stdout : result.stderr)
        }
        
        logger.info("Started service: \(name)")
    }
    
    func stopService(_ name: String) async throws {
        logger.info("Stopping service: \(name)")
        
        let result = try await CommandExecutor.run(
            path: brewPath,
            arguments: ["services", "stop", name],
            timeout: timeout
        )
        
        guard result.isSuccess else {
            throw BrewError.operationFailed(result.stderr.isEmpty ? result.stdout : result.stderr)
        }
        
        logger.info("Stopped service: \(name)")
    }
    
    func restartService(_ name: String) async throws {
        logger.info("Restarting service: \(name)")
        
        let result = try await CommandExecutor.run(
            path: brewPath,
            arguments: ["services", "restart", name],
            timeout: timeout
        )
        
        guard result.isSuccess else {
            throw BrewError.operationFailed(result.stderr.isEmpty ? result.stdout : result.stderr)
        }
        
        logger.info("Restarted service: \(name)")
    }
    
    func getServiceInfo(_ name: String) async throws -> BrewService? {
        let services = try await listServices()
        return services.first { $0.name == name }
    }
    
    var isAvailable: Bool {
        get async {
            FileManager.default.isExecutableFile(atPath: brewPath)
        }
    }
}
