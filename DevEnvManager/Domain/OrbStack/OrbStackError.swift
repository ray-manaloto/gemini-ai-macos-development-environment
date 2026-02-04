import Foundation

/// Errors from OrbStack operations
enum OrbStackError: LocalizedError {
    case orbNotFound
    case dockerNotFound
    case orbNotRunning
    case machineNotFound(name: String)
    case containerNotFound(id: String)
    case operationFailed(operation: String, message: String)
    case parseError(message: String)
    case timeout(operation: String)
    case networkError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .orbNotFound:
            return "OrbStack CLI (orb) not found. Please install OrbStack."
        case .dockerNotFound:
            return "Docker CLI not found. Please install OrbStack."
        case .orbNotRunning:
            return "OrbStack is not running. Please start OrbStack."
        case .machineNotFound(let name):
            return "Machine '\(name)' not found."
        case .containerNotFound(let id):
            return "Container '\(id)' not found."
        case .operationFailed(let operation, let message):
            return "\(operation) failed: \(message)"
        case .parseError(let message):
            return "Failed to parse output: \(message)"
        case .timeout(let operation):
            return "\(operation) timed out."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
