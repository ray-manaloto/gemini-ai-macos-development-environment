import Foundation

/// Mise CLI errors with full context for debugging.
enum MiseError: Error, LocalizedError, Equatable, Sendable {
    case notFound
    case commandFailed(exitCode: Int32, stderr: String)
    case jsonDecodingFailed(raw: String, underlying: String)
    case installFailed(tool: String, exitCode: Int32, stderr: String)
    case uninstallFailed(tool: String, exitCode: Int32, stderr: String)
    case taskFailed(task: String, exitCode: Int32, stderr: String)
    case invalidOutput(raw: String)
    case timeout
    case cancelled
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            "Mise is not installed or could not be found."
        case .commandFailed(let exitCode, let stderr):
            "Mise command failed (exit \(exitCode)): \(stderr.prefix(200))"
        case .jsonDecodingFailed(_, let underlying):
            "Failed to parse Mise output: \(underlying)"
        case .installFailed(let tool, let exitCode, let stderr):
            "Failed to install \(tool) (exit \(exitCode)): \(stderr.prefix(200))"
        case .uninstallFailed(let tool, let exitCode, let stderr):
            "Failed to uninstall \(tool) (exit \(exitCode)): \(stderr.prefix(200))"
        case .taskFailed(let task, let exitCode, let stderr):
            "Task '\(task)' failed (exit \(exitCode)): \(stderr.prefix(200))"
        case .invalidOutput:
            "Mise returned invalid output"
        case .timeout:
            "Mise command timed out"
        case .cancelled:
            "Mise command was cancelled"
        case .unknown(let message):
            "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notFound:
            "Install Mise from https://mise.jdx.dev or run: curl https://mise.run | sh"
        case .commandFailed:
            "Check that mise is properly configured and try again."
        case .jsonDecodingFailed:
            "This may be a version compatibility issue. Try updating mise."
        case .installFailed:
            "Check network connection and that the tool name is correct."
        case .uninstallFailed:
            "Check that the tool is installed and try again."
        case .taskFailed:
            "Check the task configuration in mise.toml"
        case .invalidOutput:
            "Try running 'mise doctor' to check for issues."
        case .timeout:
            "Try again or check network connection for slow downloads."
        case .cancelled:
            nil
        case .unknown:
            "Try running 'mise doctor' to diagnose issues."
        }
    }
    
    /// Generate copyable diagnostics for support/debugging.
    var diagnostics: String {
        var lines: [String] = []
        lines.append("Error: \(errorDescription ?? "Unknown")")
        
        if let suggestion = recoverySuggestion {
            lines.append("Suggestion: \(suggestion)")
        }
        
        switch self {
        case .commandFailed(let exitCode, let stderr):
            lines.append("Exit Code: \(exitCode)")
            if !stderr.isEmpty {
                lines.append("Stderr:\n\(stderr)")
            }
        case .installFailed(let tool, let exitCode, let stderr),
             .uninstallFailed(let tool, let exitCode, let stderr):
            lines.append("Tool: \(tool)")
            lines.append("Exit Code: \(exitCode)")
            if !stderr.isEmpty {
                lines.append("Stderr:\n\(stderr)")
            }
        case .taskFailed(let task, let exitCode, let stderr):
            lines.append("Task: \(task)")
            lines.append("Exit Code: \(exitCode)")
            if !stderr.isEmpty {
                lines.append("Stderr:\n\(stderr)")
            }
        case .jsonDecodingFailed(let raw, _):
            lines.append("Raw Output:\n\(raw.prefix(500))")
        case .invalidOutput(let raw):
            lines.append("Raw Output:\n\(raw.prefix(500))")
        default:
            break
        }
        
        return lines.joined(separator: "\n")
    }
}
