import Foundation

/// Protocol for testable Mise client.
protocol MiseClientProtocol: Actor {
    func listTools() async throws -> [MiseTool]
    func listTasks() async throws -> [MiseTask]
    func installTool(_ name: String, version: String?) async throws
    func uninstallTool(_ name: String) async throws
    func updateTool(_ name: String) async throws
    func runTask(_ taskName: String) async throws -> String
    func doctor() async throws -> MiseDoctorResult
    func isAvailable() async -> Bool
}
