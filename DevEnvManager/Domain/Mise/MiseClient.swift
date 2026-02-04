import Foundation
import os

/// Actor that executes Mise CLI commands serially.
/// Thread-safe by design - all mise commands run sequentially.
actor MiseClient: MiseClientProtocol {
    private let logger = Logger(subsystem: "dev.devenvmanager", category: "MiseClient")
    private var miseURL: URL?
    
    private let defaultEnvironment: [String: String] = [
        "MISE_YES": "1",
        "MISE_QUIET": "0"
    ]
    
    // MARK: - CLI Location
    
    private func ensureMiseURL() async throws -> URL {
        if let url = miseURL { return url }
        
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            URL(filePath: "\(home)/.local/bin/mise"),
            URL(filePath: "/usr/local/bin/mise"),
            URL(filePath: "/opt/homebrew/bin/mise")
        ]
        
        for candidate in candidates {
            if FileManager.default.isExecutableFile(atPath: candidate.path()) {
                miseURL = candidate
                logger.info("Found mise at \(candidate.path())")
                return candidate
            }
        }
        
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
    
    // MARK: - Protocol Implementation
    
    func isAvailable() async -> Bool {
        do {
            _ = try await ensureMiseURL()
            return true
        } catch {
            return false
        }
    }
    
    func listTools() async throws -> [MiseTool] {
        let miseURL = try await ensureMiseURL()
        let result = try await CommandExecutor.run(
            miseURL,
            arguments: ["ls", "--json"],
            environment: defaultEnvironment,
            timeout: .seconds(30)
        )
        
        guard result.isSuccess else {
            throw MiseError.commandFailed(exitCode: result.exitCode, stderr: result.stderr)
        }
        
        return try decodeToolList(from: result.stdout)
    }
    
    func listTasks() async throws -> [MiseTask] {
        let miseURL = try await ensureMiseURL()
        let result = try await CommandExecutor.run(
            miseURL,
            arguments: ["tasks", "--json"],
            environment: defaultEnvironment,
            timeout: .seconds(30)
        )
        
        guard result.isSuccess else {
            throw MiseError.commandFailed(exitCode: result.exitCode, stderr: result.stderr)
        }
        
        return try decodeTaskList(from: result.stdout)
    }
    
    func installTool(_ name: String, version: String?) async throws {
        let miseURL = try await ensureMiseURL()
        var arguments = ["use", "-g", name]
        if let version { 
            arguments[2] = "\(name)@\(version)" 
        }
        
        let result = try await CommandExecutor.run(
            miseURL,
            arguments: arguments,
            environment: defaultEnvironment,
            timeout: .seconds(600) // Install can be slow
        )
        
        guard result.isSuccess else {
            throw MiseError.installFailed(tool: name, exitCode: result.exitCode, stderr: result.stderr)
        }
        
        logger.info("Installed \(name)\(version.map { "@\($0)" } ?? "")")
    }
    
    func uninstallTool(_ name: String) async throws {
        let miseURL = try await ensureMiseURL()
        let result = try await CommandExecutor.run(
            miseURL,
            arguments: ["uninstall", name],
            environment: defaultEnvironment,
            timeout: .seconds(60)
        )
        
        guard result.isSuccess else {
            throw MiseError.uninstallFailed(tool: name, exitCode: result.exitCode, stderr: result.stderr)
        }
        
        logger.info("Uninstalled \(name)")
    }
    
    func updateTool(_ name: String) async throws {
        let miseURL = try await ensureMiseURL()
        let result = try await CommandExecutor.run(
            miseURL,
            arguments: ["upgrade", name],
            environment: defaultEnvironment,
            timeout: .seconds(600)
        )
        
        guard result.isSuccess else {
            throw MiseError.commandFailed(exitCode: result.exitCode, stderr: result.stderr)
        }
        
        logger.info("Updated \(name)")
    }
    
    func runTask(_ taskName: String) async throws -> String {
        let miseURL = try await ensureMiseURL()
        let result = try await CommandExecutor.run(
            miseURL,
            arguments: ["run", taskName],
            environment: defaultEnvironment,
            timeout: .seconds(600)
        )
        
        guard result.isSuccess else {
            throw MiseError.taskFailed(task: taskName, exitCode: result.exitCode, stderr: result.stderr)
        }
        
        return result.stdout
    }
    
    func doctor() async throws -> MiseDoctorResult {
        let miseURL = try await ensureMiseURL()
        
        let versionResult = try await CommandExecutor.run(
            miseURL,
            arguments: ["--version"],
            environment: defaultEnvironment,
            timeout: .seconds(5)
        )
        
        let doctorResult = try await CommandExecutor.run(
            miseURL,
            arguments: ["doctor"],
            environment: defaultEnvironment,
            timeout: .seconds(30)
        )
        
        return parseDoctorOutput(
            version: versionResult.stdout,
            doctorOutput: doctorResult.stdout
        )
    }
    
    // MARK: - JSON Decoding
    
    private func decodeToolList(from output: String) throws -> [MiseTool] {
        guard let data = output.data(using: .utf8) else {
            throw MiseError.invalidOutput(raw: output)
        }
        
        do {
            let response = try JSONDecoder().decode(MiseToolListResponse.self, from: data)
            return response.toTools()
        } catch {
            throw MiseError.jsonDecodingFailed(raw: output, underlying: error.localizedDescription)
        }
    }
    
    private func decodeTaskList(from output: String) throws -> [MiseTask] {
        guard let data = output.data(using: .utf8) else {
            throw MiseError.invalidOutput(raw: output)
        }
        
        do {
            return try JSONDecoder().decode([MiseTask].self, from: data)
        } catch {
            throw MiseError.jsonDecodingFailed(raw: output, underlying: error.localizedDescription)
        }
    }
    
    private func parseDoctorOutput(version: String, doctorOutput: String) -> MiseDoctorResult {
        var errors: [String] = []
        var warnings: [String] = []
        var configFiles: [String] = []
        var missingTools: [String] = []
        
        for line in doctorOutput.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("ERROR") || trimmed.contains("error") {
                errors.append(String(trimmed))
            } else if trimmed.contains("WARN") || trimmed.contains("warning") {
                warnings.append(String(trimmed))
            } else if trimmed.contains("Config file") || trimmed.hasPrefix("~/.") {
                configFiles.append(String(trimmed))
            } else if trimmed.contains("missing") {
                missingTools.append(String(trimmed))
            }
        }
        
        return MiseDoctorResult(
            version: version.trimmingCharacters(in: .whitespacesAndNewlines),
            activatedVersion: nil,
            configFiles: configFiles.isEmpty ? nil : configFiles,
            missingTools: missingTools.isEmpty ? nil : missingTools,
            errors: errors.isEmpty ? nil : errors,
            warnings: warnings.isEmpty ? nil : warnings
        )
    }
}
