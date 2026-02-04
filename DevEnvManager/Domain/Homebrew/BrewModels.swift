import Foundation

enum BrewServiceStatus: String, Codable, Sendable {
    case started
    case stopped
    case error
    case none
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = BrewServiceStatus(rawValue: rawValue) ?? .unknown
    }
}

struct BrewService: Identifiable, Codable, Equatable, Sendable {
    let name: String
    let status: BrewServiceStatus
    let user: String?
    let file: String?
    let exitCode: Int?
    var port: Int?
    var pid: Int?
    
    var id: String { name }
    
    var isRunning: Bool {
        status == .started
    }
    
    var displayName: String {
        name.replacingOccurrences(of: "homebrew.mxcl.", with: "")
    }
    
    var plistPath: String? {
        file
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case status
        case user
        case file
        case exitCode = "exit_code"
        case port
        case pid
    }
}

struct ServicePort: Equatable, Sendable {
    let port: Int
    let pid: Int
    let process: String
    let address: String
    
    var displayAddress: String {
        if address == "*" || address == "0.0.0.0" {
            return "localhost:\(port)"
        }
        return "\(address):\(port)"
    }
}

enum ServiceAction: Sendable {
    case start
    case stop
    case restart
    case info
}

struct ServiceOperation: Equatable, Sendable {
    var status: OperationStatus
    var action: ServiceAction
    var startedAt: Date?
    var errorMessage: String?
    
    enum OperationStatus: Equatable, Sendable {
        case idle
        case running
        case failed
    }
    
    static let idle = ServiceOperation(status: .idle, action: .info)
    
    static func failed(action: ServiceAction, error: BrewError) -> ServiceOperation {
        ServiceOperation(
            status: .failed,
            action: action,
            errorMessage: error.localizedDescription
        )
    }
}
