import Foundation
import os

// MARK: - Command Result

/// Result of a shell command execution.
struct CommandResult: Sendable {
    let stdout: String
    let stderr: String
    let exitCode: Int32
    
    var isSuccess: Bool { exitCode == 0 }
    
    var combinedOutput: String {
        [stdout, stderr].filter { !$0.isEmpty }.joined(separator: "\n")
    }
}

// MARK: - Command Executor Errors

enum CommandExecutorError: Error, LocalizedError, Sendable {
    case failedToStart(String)
    case timedOut
    case cancelled
    case invalidExecutable(String)
    
    var errorDescription: String? {
        switch self {
        case .failedToStart(let message):
            "Failed to start command: \(message)"
        case .timedOut:
            "Command timed out"
        case .cancelled:
            "Command was cancelled"
        case .invalidExecutable(let path):
            "Invalid executable: \(path)"
        }
    }
}

// MARK: - Command Executor

/// Thread-safe command execution with timeout and cancellation support.
/// Uses modern Swift concurrency patterns from BrewServicesManager.
enum CommandExecutor {
    private static let logger = Logger(subsystem: "dev.devenvmanager", category: "CommandExecutor")
    
    // MARK: - Public API
    
    /// Execute command at URL with full control over timeout and cancellation.
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
    
    /// Execute command by path with full control over timeout and cancellation.
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
        
        // Build safe environment
        process.environment = safeEnvironment(merging: environment)
        
        // Setup pipes for output capture
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        // Thread-safe state tracking using OSAllocatedUnfairLock
        let stateLock = OSAllocatedUnfairLock(initialState: (
            didCancel: false,
            didTimeout: false,
            didResume: false,
            timeoutTask: nil as Task<Void, Never>?
        ))
        
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                // Completion handler - called when process terminates
                let finish: @Sendable (Int32) -> Void = { exitCode in
                    let (shouldResume, taskToCancel) = stateLock.withLock { state -> (Bool, Task<Void, Never>?) in
                        guard !state.didResume else { return (false, nil) }
                        state.didResume = true
                        let task = state.timeoutTask
                        state.timeoutTask = nil
                        return (true, task)
                    }
                    
                    guard shouldResume else { return }
                    
                    taskToCancel?.cancel()
                    
                    // Read output data safely
                    let stdout = stdoutPipe.fileHandleForReading.readToEndSafely()
                    let stderr = stderrPipe.fileHandleForReading.readToEndSafely()
                    
                    let (didTimeout, didCancel) = stateLock.withLock { ($0.didTimeout, $0.didCancel) }
                    
                    if didTimeout {
                        continuation.resume(throwing: CommandExecutorError.timedOut)
                    } else if didCancel {
                        continuation.resume(throwing: CommandExecutorError.cancelled)
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
                    continuation.resume(throwing: CommandExecutorError.failedToStart(error.localizedDescription))
                    return
                }
                
                // Setup timeout task if specified
                if let timeout {
                    let task = Task {
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
                    stateLock.withLock { $0.timeoutTask = task }
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
    
    // MARK: - Environment Helpers
    
    /// Build safe environment for CLI tools.
    static func safeEnvironment(merging custom: [String: String]? = nil) -> [String: String] {
        var env: [String: String] = [:]
        
        // Essential variables
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        env["HOME"] = home
        env["USER"] = NSUserName()
        env["LC_ALL"] = "en_US.UTF-8"
        env["LANG"] = "en_US.UTF-8"
        
        let systemPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let defaultPath = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        let homeBin = "\(home)/.local/bin"
        let miseShims = "\(home)/.local/share/mise/shims"
        let brewPath = "/opt/homebrew/bin"
        let basePath = systemPath.isEmpty ? defaultPath : systemPath
        env["PATH"] = "\(miseShims):\(homeBin):\(brewPath):\(basePath)"
        
        // Mise-specific
        env["MISE_YES"] = "1"  // Auto-confirm prompts
        
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

// MARK: - Streaming Support

/// Output types for streaming commands.
enum StreamedOutput: Sendable {
    case stdout(String)
    case stderr(String)
}

extension CommandExecutor {
    /// Execute command with streaming output for long-running operations.
    static func stream(
        _ executableURL: URL,
        arguments: [String],
        environment: [String: String]? = nil,
        workingDirectory: URL? = nil
    ) -> AsyncStream<StreamedOutput> {
        AsyncStream { continuation in
            let process = Process()
            process.executableURL = executableURL
            process.arguments = arguments
            process.environment = safeEnvironment(merging: environment)
            
            if let workingDirectory {
                process.currentDirectoryURL = workingDirectory
            }
            
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            
            stdoutPipe.fileHandleForReading.readabilityHandler = { @Sendable handle in
                let data = handle.availableData
                guard !data.isEmpty,
                      let output = String(data: data, encoding: .utf8),
                      !output.isEmpty else {
                    return
                }
                continuation.yield(.stdout(output))
            }
            
            stderrPipe.fileHandleForReading.readabilityHandler = { @Sendable handle in
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

// MARK: - FileHandle Safe Read Extension

extension FileHandle {
    /// Safe read that catches ObjC exceptions which would crash the app.
    /// CRITICAL: Never use readDataToEndOfFile() or availableData without try-catch.
    func readToEndSafely() -> Data {
        do {
            return try self.readToEnd() ?? Data()
        } catch {
            return Data()
        }
    }
    
    /// Safe read up to count bytes.
    func readSafely(upToCount count: Int) -> Data {
        do {
            return try self.read(upToCount: count) ?? Data()
        } catch {
            return Data()
        }
    }
}
