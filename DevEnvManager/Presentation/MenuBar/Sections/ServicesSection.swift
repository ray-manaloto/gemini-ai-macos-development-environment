import SwiftUI

struct ServicesSection: View {
    @Environment(ServicesStore.self) private var servicesStore
    
    var body: some View {
        Section {
            if servicesStore.isLoading {
                loadingView
            } else if case .unavailable = servicesStore.state {
                unavailableView
            } else if case .error(let message) = servicesStore.state {
                errorView(message)
            } else if servicesStore.services.isEmpty {
                emptyView
            } else {
                servicesList
            }
        } header: {
            sectionHeader
        }
    }
    
    private var sectionHeader: some View {
        HStack {
            Text("Homebrew Services")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            if !servicesStore.services.isEmpty {
                Text("(\(servicesStore.runningServices.count)/\(servicesStore.services.count))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            if servicesStore.isRefreshing {
                ProgressView()
                    .controlSize(.mini)
            }
        }
        .padding(.horizontal, LayoutConstants.contentPadding)
        .padding(.vertical, 6)
        .background(.background)
    }
    
    private var loadingView: some View {
        HStack {
            ProgressView()
                .controlSize(.small)
            Text("Loading services...")
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
            Text("Homebrew not installed")
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
                Task { await servicesStore.refresh(force: true) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var emptyView: some View {
        Text("No services found")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding()
    }
    
    private var servicesList: some View {
        ForEach(servicesStore.services) { service in
            ServiceRowView(service: service) { action in
                handleAction(action, for: service)
            }
            
            if service.id != servicesStore.services.last?.id {
                Divider()
                    .padding(.leading, 28)
            }
        }
    }
    
    private func handleAction(_ action: ServiceAction, for service: BrewService) {
        Task {
            switch action {
            case .start:
                await servicesStore.startService(service.name)
            case .stop:
                await servicesStore.stopService(service.name)
            case .restart:
                await servicesStore.restartService(service.name)
            case .info:
                break
            }
        }
    }
}

struct ServiceRowView: View {
    @Environment(ServicesStore.self) private var store
    
    let service: BrewService
    let onAction: (ServiceAction) -> Void
    
    @State private var showingPopover = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: LayoutConstants.statusIndicatorSize, height: LayoutConstants.statusIndicatorSize)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(service.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Text(service.status.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let port = service.port {
                        Text(":")
                            .foregroundStyle(.tertiary)
                        Text("\(port)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            Spacer()
            
            if let operation = store.serviceOperations[service.name] {
                operationIndicator(operation)
            }
            
            Button {
                onAction(service.isRunning ? .stop : .start)
            } label: {
                Image(systemName: service.isRunning ? "stop.circle" : "play.circle")
            }
            .buttonStyle(.borderless)
            .help(service.isRunning ? "Stop" : "Start")
            
            Button {
                showingPopover.toggle()
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showingPopover) {
                ServiceActionsPopover(service: service, onAction: { action in
                    showingPopover = false
                    onAction(action)
                })
                .frame(width: 180)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, LayoutConstants.contentPadding)
        .contentShape(Rectangle())
    }
    
    private var statusColor: Color {
        switch service.status {
        case .started: .green
        case .stopped: .gray
        case .error: .red
        case .none, .unknown: .gray
        }
    }
    
    @ViewBuilder
    private func operationIndicator(_ operation: ServiceOperation) -> some View {
        switch operation.status {
        case .running:
            ProgressView()
                .controlSize(.mini)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .help(operation.errorMessage ?? "Failed")
        case .idle:
            EmptyView()
        }
    }
}

struct ServiceActionsPopover: View {
    let service: BrewService
    let onAction: (ServiceAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if service.isRunning {
                Button {
                    onAction(.stop)
                } label: {
                    Label("Stop", systemImage: "stop.circle")
                }
                .buttonStyle(.borderless)
                
                Button {
                    onAction(.restart)
                } label: {
                    Label("Restart", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            } else {
                Button {
                    onAction(.start)
                } label: {
                    Label("Start", systemImage: "play.circle")
                }
                .buttonStyle(.borderless)
            }
            
            Divider()
            
            if let port = service.port {
                HStack {
                    Text("Port:")
                        .foregroundStyle(.secondary)
                    Text("\(port)")
                        .fontWeight(.medium)
                }
                .font(.caption)
            }
            
            if let plistPath = service.plistPath {
                Button {
                    NSWorkspace.shared.selectFile(plistPath, inFileViewerRootedAtPath: "")
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(8)
    }
}
