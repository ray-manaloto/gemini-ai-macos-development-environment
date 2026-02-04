import SwiftUI

enum MenuRoute: Equatable {
    case main
    case settings
    case toolDetail(MiseTool)
    
    static func == (lhs: MenuRoute, rhs: MenuRoute) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main), (.settings, .settings):
            return true
        case let (.toolDetail(t1), .toolDetail(t2)):
            return t1.id == t2.id
        default:
            return false
        }
    }
}

struct MenuBarRootView: View {
    @Environment(ToolsStore.self) private var toolsStore
    
    @State private var route: MenuRoute = .main
    @State private var searchText = ""
    
    var body: some View {
        Group {
            switch route {
            case .main:
                MainMenuView(searchText: $searchText, route: $route)
            case .settings:
                SettingsMenuView { route = .main }
            case .toolDetail(let tool):
                ToolDetailView(tool: tool) { route = .main }
            }
        }
        .frame(width: LayoutConstants.menuWidth)
        .animation(.easeInOut(duration: 0.2), value: route)
        .task {
            await toolsStore.restoreFromCache()
            await toolsStore.refresh()
        }
    }
}

struct MainMenuView: View {
    @Environment(ToolsStore.self) private var toolsStore
    @Environment(ServicesStore.self) private var servicesStore
    @Environment(ContainersStore.self) private var containersStore
    
    @Binding var searchText: String
    @Binding var route: MenuRoute
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
            
            if toolsStore.isLoading {
                loadingView
            } else if case .error(let message) = toolsStore.state {
                errorView(message)
            } else {
                toolsListView
            }
            
            Divider()
            
            footerView
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("DevEnv Manager")
                .font(.headline)
            
            Spacer()
            
            if toolsStore.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            }
            
            Button {
                Task { await toolsStore.refresh(force: true) }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh")
            
            Button {
                route = .settings
            } label: {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
            .help("Settings")
        }
        .padding(LayoutConstants.contentPadding)
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading tools...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)
            
            Text("Mise Not Available")
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task { await toolsStore.refresh(force: true) }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var toolsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if !toolsStore.tools.isEmpty {
                    Section {
                        ForEach(filteredTools) { tool in
                            ToolRowView(tool: tool) { action in
                                handleAction(action, for: tool)
                            }
                            
                            if tool.id != filteredTools.last?.id {
                                Divider()
                                    .padding(.leading, 28)
                            }
                        }
                    } header: {
                        sectionHeader("Tools", count: filteredTools.count)
                    }
                }
                
                if !toolsStore.tasks.isEmpty {
                    Section {
                        ForEach(toolsStore.tasks) { task in
                            TaskRowView(task: task) {
                                Task { _ = await toolsStore.runTask(task.name) }
                            }
                        }
                    } header: {
                        sectionHeader("Tasks", count: toolsStore.tasks.count)
                    }
                }
                
                ServicesSection()
                
                ContainersSection()
            }
        }
        .frame(minHeight: 200, maxHeight: 600)
        .task {
            await servicesStore.initialize()
            await containersStore.initialize()
        }
    }
    
    private var filteredTools: [MiseTool] {
        if searchText.isEmpty {
            return toolsStore.tools
        }
        return toolsStore.tools.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Text("(\(count))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            Spacer()
        }
        .padding(.horizontal, LayoutConstants.contentPadding)
        .padding(.vertical, 6)
        .background(.background)
    }
    
    private func handleAction(_ action: ToolAction, for tool: MiseTool) {
        Task {
            switch action {
            case .install:
                await toolsStore.installTool(tool.name)
            case .update:
                await toolsStore.updateTool(tool.name)
            case .uninstall:
                await toolsStore.uninstallTool(tool.name)
            case .info:
                route = .toolDetail(tool)
            }
        }
    }
    
    private var footerView: some View {
        HStack {
            Text("\(toolsStore.tools.count) tools")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(LayoutConstants.contentPadding)
    }
}

struct TaskRowView: View {
    let task: MiseTask
    let onRun: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "play.circle")
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.displayName)
                    .font(.body)
                
                if task.hasDescription {
                    Text(task.description ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button {
                onRun()
            } label: {
                Image(systemName: "play.fill")
            }
            .buttonStyle(.borderless)
            .help("Run task")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, LayoutConstants.contentPadding)
    }
}

struct SettingsMenuView: View {
    let onDismiss: () -> Void
    
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("refreshInterval") private var refreshInterval = 30
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                
                Text("Settings")
                    .font(.headline)
                
                Spacer()
            }
            .padding(LayoutConstants.contentPadding)
            
            Divider()
            
            Form {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Show notifications", isOn: $showNotifications)
                
                Picker("Refresh interval", selection: $refreshInterval) {
                    Text("30 seconds").tag(30)
                    Text("1 minute").tag(60)
                    Text("5 minutes").tag(300)
                    Text("Manual only").tag(0)
                }
            }
            .formStyle(.grouped)
            .padding()
            
            Spacer()
        }
        .frame(width: LayoutConstants.settingsMenuWidth)
    }
}

struct ToolDetailView: View {
    let tool: MiseTool
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                
                Text(tool.displayName)
                    .font(.headline)
                
                Spacer()
                
                StatusBadge(status: tool.status)
            }
            .padding(LayoutConstants.contentPadding)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(label: "Version", value: tool.version)
                
                if let requestedVersion = tool.requestedVersion {
                    DetailRow(label: "Requested", value: requestedVersion)
                }
                
                if let installPath = tool.installPath {
                    DetailRow(label: "Install Path", value: installPath)
                }
                
                if let source = tool.source {
                    DetailRow(label: "Source", value: source.path ?? source.type ?? "Unknown")
                }
            }
            .padding()
            
            Spacer()
        }
        .frame(width: LayoutConstants.detailMenuWidth)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .trailing)
            
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
        }
    }
}
