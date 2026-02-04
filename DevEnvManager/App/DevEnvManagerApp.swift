import SwiftUI

@main
struct DevEnvManagerApp: App {
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate
    
    @State private var toolsStore = ToolsStore()
    @State private var servicesStore = ServicesStore()
    @State private var containersStore = ContainersStore()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView()
                .environment(toolsStore)
                .environment(servicesStore)
                .environment(containersStore)
        } label: {
            Label("DevEnv Manager", systemImage: menuBarIcon)
                .labelStyle(.iconOnly)
        }
        .menuBarExtraStyle(.window)
        .windowResizability(.contentSize)
        
        Settings {
            AppSettingsView()
                .environment(toolsStore)
                .environment(servicesStore)
                .environment(containersStore)
        }
    }
    
    private var menuBarIcon: String {
        if case .error = toolsStore.state {
            return "exclamationmark.triangle.fill"
        }
        
        if toolsStore.isLoading || servicesStore.isLoading || containersStore.isLoading {
            return "arrow.triangle.2.circlepath"
        }
        
        let hasRunningToolOps = toolsStore.toolOperations.values.contains { $0.status == .running }
        let hasRunningServiceOps = servicesStore.serviceOperations.values.contains { $0.status == .running }
        let hasRunningContainerOps = containersStore.containerOperations.values.contains { $0.status == .running }
        if hasRunningToolOps || hasRunningServiceOps || hasRunningContainerOps {
            return "gearshape.2"
        }
        
        // Show filled icon if any services or containers are running
        let runningServices = servicesStore.runningServices.count
        let runningContainers = containersStore.totalRunning
        if runningServices > 0 || runningContainers > 0 {
            return "terminal.fill"
        }
        
        return "terminal"
    }
}

struct AppSettingsView: View {
    @Environment(ToolsStore.self) private var toolsStore
    @Environment(ServicesStore.self) private var servicesStore
    @Environment(ContainersStore.self) private var containersStore
    
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("refreshInterval") private var refreshInterval = 30
    
    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Show notifications", isOn: $showNotifications)
            }
            
            Section("Refresh") {
                Picker("Auto-refresh interval", selection: $refreshInterval) {
                    Text("30 seconds").tag(30)
                    Text("1 minute").tag(60)
                    Text("5 minutes").tag(300)
                    Text("Manual only").tag(0)
                }
            }
            
            Section("Status") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Mise", value: toolsStore.isMiseAvailable ? "Available" : "Not found")
                LabeledContent("Homebrew", value: servicesStore.isAvailable ? "Available" : "Not found")
                LabeledContent("OrbStack", value: containersStore.isOrbAvailable ? "Available" : "Not found")
                LabeledContent("Running Services", value: "\(servicesStore.runningServices.count)")
                LabeledContent("Running Containers", value: "\(containersStore.runningContainers.count)")
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 400)
    }
}
