import SwiftUI

// MARK: - Main Section

struct ContainersSection: View {
    @Environment(ContainersStore.self) private var store
    
    var body: some View {
        Section {
            if store.isLoading {
                loadingView
            } else if case .unavailable = store.state {
                unavailableView
            } else if case .error(let message) = store.state {
                errorView(message)
            } else if store.containers.isEmpty && store.machines.isEmpty {
                emptyView
            } else {
                contentView
            }
        } header: {
            sectionHeader
        }
    }
    
    // MARK: - Header
    
    private var sectionHeader: some View {
        HStack {
            Text("OrbStack")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            if store.totalRunning > 0 {
                Text("(\(store.totalRunning) running)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            if store.isRefreshing {
                ProgressView()
                    .controlSize(.mini)
            }
        }
        .padding(.horizontal, LayoutConstants.contentPadding)
        .padding(.vertical, 6)
        .background(.background)
    }
    
    // MARK: - Content States
    
    private var loadingView: some View {
        HStack {
            ProgressView()
                .controlSize(.small)
            Text("Loading containers...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var unavailableView: some View {
        HStack(spacing: 8) {
            Image(systemName: "xmark.circle")
                .foregroundStyle(.secondary)
            Text("OrbStack not installed")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await store.refresh(force: true) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var emptyView: some View {
        Text("No containers or machines")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding()
    }
    
    // MARK: - Content
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // Linux Machines (if any)
            if !store.machines.isEmpty {
                MachinesSubsection(machines: store.machines)
                
                if !store.composeProjects.isEmpty || !store.standaloneContainers.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                }
            }
            
            // Compose Projects
            ForEach(store.composeProjects) { project in
                ComposeProjectRow(project: project)
                
                if project.id != store.composeProjects.last?.id || !store.standaloneContainers.isEmpty {
                    Divider()
                        .padding(.leading, 28)
                }
            }
            
            // Standalone Containers
            ForEach(store.standaloneContainers) { container in
                ContainerRowView(container: container)
                
                if container.id != store.standaloneContainers.last?.id {
                    Divider()
                        .padding(.leading, 28)
                }
            }
        }
    }
}

// MARK: - Machines Subsection

struct MachinesSubsection: View {
    let machines: [OrbMachine]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Linux Machines")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.horizontal, LayoutConstants.contentPadding)
            .padding(.vertical, 4)
            
            ForEach(machines) { machine in
                MachineRowView(machine: machine)
                
                if machine.id != machines.last?.id {
                    Divider()
                        .padding(.leading, 28)
                }
            }
        }
    }
}

// MARK: - Machine Row

struct MachineRowView: View {
    @Environment(ContainersStore.self) private var store
    
    let machine: OrbMachine
    @State private var showingPopover = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: LayoutConstants.statusIndicatorSize, height: LayoutConstants.statusIndicatorSize)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(machine.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if machine.isDefault {
                        Text("default")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 4) {
                    Text(machine.distro)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(machine.state.displayName)
                        .font(.caption)
                        .foregroundStyle(stateTextColor)
                }
            }
            
            Spacer()
            
            if let operation = store.machineOperations[machine.name] {
                operationIndicator(operation)
            }
            
            Button {
                Task {
                    if machine.state == .running {
                        await store.stopMachine(machine.name)
                    } else {
                        await store.startMachine(machine.name)
                    }
                }
            } label: {
                Image(systemName: machine.state == .running ? "stop.circle" : "play.circle")
            }
            .buttonStyle(.borderless)
            .help(machine.state == .running ? "Stop" : "Start")
            
            Button {
                showingPopover.toggle()
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showingPopover) {
                MachineActionsPopover(machine: machine) { action in
                    showingPopover = false
                    handleAction(action)
                }
                .frame(width: 160)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, LayoutConstants.contentPadding)
        .contentShape(Rectangle())
    }
    
    private var statusColor: Color {
        switch machine.state {
        case .running: .green
        case .stopped: .gray
        case .starting, .stopping: .orange
        case .unknown: .red
        }
    }
    
    private var stateTextColor: Color {
        switch machine.state {
        case .running: .green
        case .stopped: .secondary
        case .starting, .stopping: .orange
        case .unknown: .red
        }
    }
    
    @ViewBuilder
    private func operationIndicator(_ operation: OrbOperation) -> some View {
        switch operation.status {
        case .running:
            ProgressView()
                .controlSize(.mini)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .help(operation.error ?? "Failed")
        case .completed:
            EmptyView()
        }
    }
    
    private func handleAction(_ action: MachineAction) {
        Task {
            switch action {
            case .start:
                await store.startMachine(machine.name)
            case .stop:
                await store.stopMachine(machine.name)
            case .restart:
                await store.restartMachine(machine.name)
            case .openTerminal:
                NSWorkspace.shared.open(URL(string: "orb://\(machine.name)")!)
            }
        }
    }
}

enum MachineAction {
    case start, stop, restart, openTerminal
}

struct MachineActionsPopover: View {
    let machine: OrbMachine
    let onAction: (MachineAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if machine.state == .running {
                Button { onAction(.stop) } label: {
                    Label("Stop", systemImage: "stop.circle")
                }
                .buttonStyle(.borderless)
                
                Button { onAction(.restart) } label: {
                    Label("Restart", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                
                Button { onAction(.openTerminal) } label: {
                    Label("Open Terminal", systemImage: "terminal")
                }
                .buttonStyle(.borderless)
            } else {
                Button { onAction(.start) } label: {
                    Label("Start", systemImage: "play.circle")
                }
                .buttonStyle(.borderless)
            }
            
            Divider()
            
            HStack {
                Text("Distro:")
                    .foregroundStyle(.secondary)
                Text(machine.distro)
                    .fontWeight(.medium)
            }
            .font(.caption)
        }
        .padding(8)
    }
}

// MARK: - Compose Project Row

struct ComposeProjectRow: View {
    @Environment(ContainersStore.self) private var store
    
    let project: ComposeProject
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Project header
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .frame(width: 12)
                
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                
                Text(project.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(project.statusSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, LayoutConstants.contentPadding)
            .contentShape(Rectangle())
            
            // Containers in project
            if isExpanded {
                ForEach(project.containers) { container in
                    ContainerRowView(container: container, indented: true)
                    
                    if container.id != project.containers.last?.id {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
        }
    }
}

// MARK: - Container Row

struct ContainerRowView: View {
    @Environment(ContainersStore.self) private var store
    
    let container: OrbContainer
    var indented: Bool = false
    
    @State private var showingPopover = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: LayoutConstants.statusIndicatorSize, height: LayoutConstants.statusIndicatorSize)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(container.status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    if let port = container.ports.first {
                        Text(":")
                            .foregroundStyle(.tertiary)
                        Text("\(port.hostPort)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            Spacer()
            
            if let operation = store.containerOperations[container.id] {
                operationIndicator(operation)
            }
            
            Button {
                Task {
                    if container.state == .running {
                        await store.stopContainer(container.id, name: container.name)
                    } else {
                        await store.startContainer(container.id, name: container.name)
                    }
                }
            } label: {
                Image(systemName: container.state == .running ? "stop.circle" : "play.circle")
            }
            .buttonStyle(.borderless)
            .help(container.state == .running ? "Stop" : "Start")
            
            Button {
                showingPopover.toggle()
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showingPopover) {
                ContainerActionsPopover(container: container) { action in
                    showingPopover = false
                    handleAction(action)
                }
                .frame(width: 200)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, LayoutConstants.contentPadding)
        .padding(.leading, indented ? 16 : 0)
        .contentShape(Rectangle())
    }
    
    private var displayName: String {
        container.composeService ?? container.name
    }
    
    private var statusColor: Color {
        switch container.state {
        case .running: .green
        case .paused: .yellow
        case .exited, .created: .gray
        case .restarting: .orange
        case .removing, .dead: .red
        case .unknown: .gray
        }
    }
    
    @ViewBuilder
    private func operationIndicator(_ operation: OrbOperation) -> some View {
        switch operation.status {
        case .running:
            ProgressView()
                .controlSize(.mini)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .help(operation.error ?? "Failed")
        case .completed:
            EmptyView()
        }
    }
    
    private func handleAction(_ action: ContainerAction) {
        Task {
            switch action {
            case .start:
                await store.startContainer(container.id, name: container.name)
            case .stop:
                await store.stopContainer(container.id, name: container.name)
            case .restart:
                await store.restartContainer(container.id, name: container.name)
            case .remove:
                await store.removeContainer(container.id, name: container.name, force: false)
            case .forceRemove:
                await store.removeContainer(container.id, name: container.name, force: true)
            case .copyId:
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(container.id, forType: .string)
            case .openPort(let port):
                if let url = URL(string: "http://localhost:\(port)") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

enum ContainerAction {
    case start, stop, restart, remove, forceRemove
    case copyId
    case openPort(Int)
}

struct ContainerActionsPopover: View {
    let container: OrbContainer
    let onAction: (ContainerAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // State-dependent actions
            if container.state == .running {
                Button { onAction(.stop) } label: {
                    Label("Stop", systemImage: "stop.circle")
                }
                .buttonStyle(.borderless)
                
                Button { onAction(.restart) } label: {
                    Label("Restart", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            } else {
                Button { onAction(.start) } label: {
                    Label("Start", systemImage: "play.circle")
                }
                .buttonStyle(.borderless)
                
                Button { onAction(.remove) } label: {
                    Label("Remove", systemImage: "trash")
                }
                .buttonStyle(.borderless)
            }
            
            Divider()
            
            // Info section
            if !container.ports.isEmpty {
                ForEach(container.ports, id: \.hostPort) { port in
                    Button {
                        onAction(.openPort(port.hostPort))
                    } label: {
                        Label("Open ::\(port.hostPort)", systemImage: "globe")
                    }
                    .buttonStyle(.borderless)
                }
                
                Divider()
            }
            
            Button { onAction(.copyId) } label: {
                Label("Copy ID", systemImage: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            
            // Container info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Image:")
                        .foregroundStyle(.secondary)
                    Text(container.image)
                        .lineLimit(1)
                }
                
                HStack {
                    Text("ID:")
                        .foregroundStyle(.secondary)
                    Text(container.shortId)
                        .fontWeight(.medium)
                }
            }
            .font(.caption)
            .padding(.top, 4)
        }
        .padding(8)
    }
}
