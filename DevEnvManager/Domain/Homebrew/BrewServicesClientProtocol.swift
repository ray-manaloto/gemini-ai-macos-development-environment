import Foundation

protocol BrewServicesClientProtocol: Sendable {
    func listServices() async throws -> [BrewService]
    func startService(_ name: String) async throws
    func stopService(_ name: String) async throws
    func restartService(_ name: String) async throws
    func getServiceInfo(_ name: String) async throws -> BrewService?
}
