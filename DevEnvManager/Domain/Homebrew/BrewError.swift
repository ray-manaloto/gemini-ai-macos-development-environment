import Foundation

enum BrewError: Error, LocalizedError, Equatable, Sendable {
    case notInstalled
    case commandFailed(String)
    case parseError(String)
    case serviceNotFound(String)
    case operationFailed(String)
    case timeout
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .notInstalled:
            "Homebrew is not installed"
        case .commandFailed(let message):
            "Command failed: \(message)"
        case .parseError(let message):
            "Failed to parse output: \(message)"
        case .serviceNotFound(let name):
            "Service not found: \(name)"
        case .operationFailed(let message):
            "Operation failed: \(message)"
        case .timeout:
            "Operation timed out"
        case .cancelled:
            "Operation was cancelled"
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .notInstalled:
            false
        case .timeout, .cancelled:
            true
        default:
            true
        }
    }
}
