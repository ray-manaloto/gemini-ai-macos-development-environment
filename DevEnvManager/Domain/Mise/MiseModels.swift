import Foundation

// MARK: - Tool Models

/// Represents a tool managed by Mise.
struct MiseTool: Identifiable, Codable, Equatable, Sendable {
    let name: String
    let version: String
    let requestedVersion: String?
    let installPath: String?
    let source: MiseToolSource?
    let installed: Bool
    
    var id: String { "\(name)@\(version)" }
    
    var displayName: String {
        name.capitalized
    }
    
    var displayVersion: String {
        if version == "system" {
            return "system"
        }
        return version
    }
    
    var status: MiseToolStatus {
        if !installed {
            return .missing
        }
        // TODO: Check if outdated by comparing with latest
        return .installed
    }
    
    var isInstalled: Bool { installed }
}

/// Source of a tool configuration.
struct MiseToolSource: Codable, Equatable, Sendable {
    let type: String?
    let path: String?
}

/// Tool installation status.
enum MiseToolStatus: String, Codable, Sendable {
    case installed
    case outdated
    case missing
    case unknown
    
    var displayName: String {
        switch self {
        case .installed: "Installed"
        case .outdated: "Update Available"
        case .missing: "Not Installed"
        case .unknown: "Unknown"
        }
    }
}

// MARK: - Task Models

/// Represents a mise task.
struct MiseTask: Identifiable, Codable, Equatable, Sendable {
    let name: String
    let description: String?
    let source: String?
    let aliases: [String]?
    let depends: [String]?
    
    var id: String { name }
    
    var displayName: String {
        name.replacingOccurrences(of: ":", with: " > ")
    }
    
    var hasDescription: Bool {
        !(description?.isEmpty ?? true)
    }
}

// MARK: - Doctor Models

/// Result of mise doctor command.
struct MiseDoctorResult: Codable, Equatable, Sendable {
    let version: String?
    let activatedVersion: String?
    let configFiles: [String]?
    let missingTools: [String]?
    let errors: [String]?
    let warnings: [String]?
    
    var isHealthy: Bool {
        (errors ?? []).isEmpty
    }
    
    var hasWarnings: Bool {
        !(warnings ?? []).isEmpty
    }
}

// MARK: - Settings Models

/// Mise settings from `mise settings`.
struct MiseSettings: Codable, Equatable, Sendable {
    let experimental: Bool?
    let legacyVersionFile: Bool?
    let notFoundAutoInstall: Bool?
    let pythonUvVenvAuto: Bool?
    
    enum CodingKeys: String, CodingKey {
        case experimental
        case legacyVersionFile = "legacy_version_file"
        case notFoundAutoInstall = "not_found_auto_install"
        case pythonUvVenvAuto = "python_uv_venv_auto"
    }
}

// MARK: - JSON Decoding Helpers

/// Wrapper for mise ls --json output which is a dictionary keyed by tool name.
struct MiseToolListResponse: Codable {
    let tools: [String: [MiseToolEntry]]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        tools = try container.decode([String: [MiseToolEntry]].self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(tools)
    }
    
    /// Convert to flat array of MiseTool.
    func toTools() -> [MiseTool] {
        var result: [MiseTool] = []
        for (name, entries) in tools.sorted(by: { $0.key < $1.key }) {
            for entry in entries {
                result.append(MiseTool(
                    name: name,
                    version: entry.version,
                    requestedVersion: entry.requestedVersion,
                    installPath: entry.installPath,
                    source: entry.source.map { MiseToolSource(type: $0.type, path: $0.path) },
                    installed: entry.installed
                ))
            }
        }
        return result
    }
}

/// Individual tool entry from mise ls --json.
struct MiseToolEntry: Codable {
    let version: String
    let requestedVersion: String?
    let installPath: String?
    let source: MiseToolSourceEntry?
    let installed: Bool
    
    enum CodingKeys: String, CodingKey {
        case version
        case requestedVersion = "requested_version"
        case installPath = "install_path"
        case source
        case installed
    }
}

struct MiseToolSourceEntry: Codable {
    let type: String?
    let path: String?
}

// MARK: - Operation Types

/// Actions that can be performed on a tool.
enum ToolAction: String, Sendable {
    case install
    case update
    case uninstall
    case info
}

/// Operation state for tracking in-progress actions.
struct ToolOperation: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case idle
        case running
        case failed
    }
    
    var status: Status = .idle
    var action: ToolAction?
    var errorMessage: String?
    var errorDiagnostics: String?
    var startedAt: Date?
    
    static let idle = ToolOperation()
    
    init(
        status: Status = .idle,
        action: ToolAction? = nil,
        errorMessage: String? = nil,
        errorDiagnostics: String? = nil,
        startedAt: Date? = nil
    ) {
        self.status = status
        self.action = action
        self.errorMessage = errorMessage
        self.errorDiagnostics = errorDiagnostics
        self.startedAt = startedAt
    }
    
    /// Create a failed operation from a MiseError.
    static func failed(action: ToolAction, error: MiseError) -> ToolOperation {
        ToolOperation(
            status: .failed,
            action: action,
            errorMessage: error.errorDescription,
            errorDiagnostics: error.diagnostics,
            startedAt: nil
        )
    }
}
