import Foundation

actor FakeBrewServicesClient: BrewServicesClientProtocol {
    var services: [BrewService] = []
    var shouldFail: Bool = false
    var delay: Duration = .zero
    
    private(set) var startCalls: [String] = []
    private(set) var stopCalls: [String] = []
    private(set) var restartCalls: [String] = []
    
    func configure(services: [BrewService], shouldFail: Bool = false, delay: Duration = .zero) {
        self.services = services
        self.shouldFail = shouldFail
        self.delay = delay
    }
    
    func listServices() async throws -> [BrewService] {
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        
        if shouldFail {
            throw BrewError.commandFailed("Simulated failure")
        }
        
        return services
    }
    
    func startService(_ name: String) async throws {
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        
        if shouldFail {
            throw BrewError.operationFailed("Failed to start \(name)")
        }
        
        startCalls.append(name)
        
        if let index = services.firstIndex(where: { $0.name == name }) {
            services[index] = BrewService(
                name: services[index].name,
                status: .started,
                user: services[index].user,
                file: services[index].file,
                exitCode: 0,
                port: services[index].port,
                pid: Int.random(in: 1000...9999)
            )
        }
    }
    
    func stopService(_ name: String) async throws {
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        
        if shouldFail {
            throw BrewError.operationFailed("Failed to stop \(name)")
        }
        
        stopCalls.append(name)
        
        if let index = services.firstIndex(where: { $0.name == name }) {
            services[index] = BrewService(
                name: services[index].name,
                status: .stopped,
                user: services[index].user,
                file: services[index].file,
                exitCode: nil,
                port: nil,
                pid: nil
            )
        }
    }
    
    func restartService(_ name: String) async throws {
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        
        if shouldFail {
            throw BrewError.operationFailed("Failed to restart \(name)")
        }
        
        restartCalls.append(name)
    }
    
    func getServiceInfo(_ name: String) async throws -> BrewService? {
        return services.first { $0.name == name }
    }
    
    func reset() {
        services = []
        shouldFail = false
        delay = .zero
        startCalls = []
        stopCalls = []
        restartCalls = []
    }
}
