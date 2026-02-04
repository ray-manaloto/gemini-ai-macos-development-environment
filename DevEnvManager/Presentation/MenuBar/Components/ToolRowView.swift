import SwiftUI

struct ToolRowView: View {
    @Environment(ToolsStore.self) private var store
    
    let tool: MiseTool
    let onAction: (ToolAction) -> Void
    
    @State private var showingPopover = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: LayoutConstants.statusIndicatorSize, height: LayoutConstants.statusIndicatorSize)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tool.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(tool.displayVersion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let operation = store.toolOperations[tool.name] {
                operationIndicator(operation)
            }
            
            Button {
                onAction(tool.isInstalled ? .update : .install)
            } label: {
                Image(systemName: tool.isInstalled ? "arrow.clockwise" : "arrow.down.circle")
            }
            .buttonStyle(.borderless)
            .help(tool.isInstalled ? "Update" : "Install")
            
            Button {
                showingPopover.toggle()
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showingPopover) {
                ToolActionsPopover(tool: tool, onAction: { action in
                    showingPopover = false
                    onAction(action)
                })
                .frame(width: 200)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, LayoutConstants.contentPadding)
        .contentShape(Rectangle())
    }
    
    private var statusColor: Color {
        switch tool.status {
        case .installed: .green
        case .outdated: .orange
        case .missing: .red
        case .unknown: .gray
        }
    }
    
    @ViewBuilder
    private func operationIndicator(_ operation: ToolOperation) -> some View {
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

struct ToolActionsPopover: View {
    let tool: MiseTool
    let onAction: (ToolAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                onAction(.info)
            } label: {
                Label("Show Info", systemImage: "info.circle")
            }
            .buttonStyle(.borderless)
            
            Divider()
            
            if tool.isInstalled {
                Button {
                    onAction(.update)
                } label: {
                    Label("Update", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                
                Button(role: .destructive) {
                    onAction(.uninstall)
                } label: {
                    Label("Uninstall", systemImage: "trash")
                }
                .buttonStyle(.borderless)
            } else {
                Button {
                    onAction(.install)
                } label: {
                    Label("Install", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(8)
    }
}
