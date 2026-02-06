import SwiftUI

@main
struct DevEnvManagerApp: App {
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate
    
    var body: some Scene {
        Settings {
            AppSettingsView()
                .environment(appDelegate.toolsStore)
                .environment(appDelegate.servicesStore)
                .environment(appDelegate.containersStore)
        }
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
