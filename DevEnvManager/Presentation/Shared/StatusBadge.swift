import SwiftUI

struct StatusBadge: View {
    let status: MiseToolStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, LayoutConstants.badgeHorizontalPadding)
            .padding(.vertical, LayoutConstants.badgeVerticalPadding)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor, in: .capsule)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .installed: .green.opacity(0.2)
        case .outdated: .orange.opacity(0.2)
        case .missing: .red.opacity(0.2)
        case .unknown: .secondary.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .installed: .green
        case .outdated: .orange
        case .missing: .red
        case .unknown: .secondary
        }
    }
}
