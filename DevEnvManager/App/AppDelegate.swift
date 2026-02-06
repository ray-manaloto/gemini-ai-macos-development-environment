import AppKit
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    
    // Stores created here and passed to views via environment
    var toolsStore = ToolsStore()
    var servicesStore = ServicesStore()
    var containersStore = ContainersStore()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let statusItem = statusItem else { return }
        
        // Set initial icon
        updateStatusIcon()
        
        // Create popover
        popover = NSPopover()
        popover?.behavior = .transient
        popover?.contentSize = NSSize(width: 400, height: 500)
        
        // Create hosting controller with all stores in environment
        let rootView = MenuBarRootView()
            .environment(toolsStore)
            .environment(servicesStore)
            .environment(containersStore)
        
        let hostingController = NSHostingController(rootView: rootView)
        popover?.contentViewController = hostingController
        
        // Set button action
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self
        
        // Monitor isVisible changes via KVO
        statusItem.publisher(for: \.isVisible)
            .sink { [weak self] isVisible in
                self?.handleVisibilityChange(isVisible)
            }
            .store(in: &cancellables)
        
        // Initialize stores
        Task {
            await servicesStore.initialize()
            await containersStore.initialize()
            await toolsStore.restoreFromCache()
            await toolsStore.refresh()
        }
        
        // Subscribe to store changes to update icon
        subscribeToStoreChanges()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    // MARK: - Status Icon Management
    
    private func updateStatusIcon() {
        let iconName = computeIconName()
        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "DevEnv Manager") {
            statusItem?.button?.image = image
        }
    }
    
    private func computeIconName() -> String {
        // Error state takes priority
        if case .error = toolsStore.state {
            return "exclamationmark.triangle.fill"
        }
        
        // Loading state
        if toolsStore.isLoading || servicesStore.isLoading || containersStore.isLoading {
            return "arrow.triangle.2.circlepath"
        }
        
        // Running operations
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
    
    private func subscribeToStoreChanges() {
        observeStoreChanges()
    }
    
    private func observeStoreChanges() {
        withObservationTracking {
            _ = toolsStore.state
            _ = toolsStore.isLoading
            _ = toolsStore.toolOperations
            _ = servicesStore.isLoading
            _ = servicesStore.runningServices
            _ = servicesStore.serviceOperations
            _ = containersStore.isLoading
            _ = containersStore.totalRunning
            _ = containersStore.containerOperations
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.updateStatusIcon()
                self?.observeStoreChanges()
            }
        }
    }
    
    // MARK: - Popover Management
    
    @objc func togglePopover() {
        guard let statusItem = statusItem,
              let button = statusItem.button,
              let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    // MARK: - Visibility Handling
    
    func handleVisibilityChange(_ isVisible: Bool) {
        if isVisible {
            // Menu bar space available, use accessory mode
            NSApp.setActivationPolicy(.accessory)
        } else {
            // Notch overflow detected, switch to regular mode for Dock icon
            NSApp.setActivationPolicy(.regular)
        }
    }
}
