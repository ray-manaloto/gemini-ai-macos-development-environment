import Foundation

actor FakeMiseClient: MiseClientProtocol {
    private var tools: [MiseTool]
    private var tasks: [MiseTask]
    private var failures: [String: MiseError] = [:]
    private(set) var performedActions: [(action: String, args: [String])] = []
    
    init(tools: [MiseTool] = [], tasks: [MiseTask] = []) {
        self.tools = tools
        self.tasks = tasks
    }
    
    func setTools(_ tools: [MiseTool]) {
        self.tools = tools
    }
    
    func setTasks(_ tasks: [MiseTask]) {
        self.tasks = tasks
    }
    
    func setFailure(_ error: MiseError, for operation: String) {
        failures[operation] = error
    }
    
    func clearFailures() {
        failures.removeAll()
    }
    
    func isAvailable() async -> Bool {
        return true
    }
    
    func listTools() async throws -> [MiseTool] {
        performedActions.append(("listTools", []))
        if let error = failures["listTools"] { throw error }
        return tools
    }
    
    func listTasks() async throws -> [MiseTask] {
        performedActions.append(("listTasks", []))
        if let error = failures["listTasks"] { throw error }
        return tasks
    }
    
    func installTool(_ name: String, version: String?) async throws {
        performedActions.append(("installTool", [name, version ?? "latest"]))
        if let error = failures["installTool:\(name)"] { throw error }
        if let error = failures["installTool"] { throw error }
    }
    
    func uninstallTool(_ name: String) async throws {
        performedActions.append(("uninstallTool", [name]))
        if let error = failures["uninstallTool:\(name)"] { throw error }
        if let error = failures["uninstallTool"] { throw error }
    }
    
    func updateTool(_ name: String) async throws {
        performedActions.append(("updateTool", [name]))
        if let error = failures["updateTool:\(name)"] { throw error }
        if let error = failures["updateTool"] { throw error }
    }
    
    func runTask(_ taskName: String) async throws -> String {
        performedActions.append(("runTask", [taskName]))
        if let error = failures["runTask:\(taskName)"] { throw error }
        if let error = failures["runTask"] { throw error }
        return "Task output for \(taskName)"
    }
    
    func doctor() async throws -> MiseDoctorResult {
        performedActions.append(("doctor", []))
        if let error = failures["doctor"] { throw error }
        return MiseDoctorResult(
            version: "2024.1.0",
            activatedVersion: "2024.1.0",
            configFiles: ["~/.config/mise/config.toml"],
            missingTools: nil,
            errors: nil,
            warnings: nil
        )
    }
}
