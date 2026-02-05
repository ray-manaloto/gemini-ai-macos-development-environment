#!/usr/bin/swift
// <swiftbar.type>streamable</swiftbar.type>
// <bitbar.title>God-Tier DevEnv Status (Streaming)</bitbar.title>
// <bitbar.version>v1.0</bitbar.version>
// <bitbar.author>God-Tier macOS Dev Environment</bitbar.author>
// <bitbar.author.github>ray-manaloto</bitbar.author.github>
// <bitbar.desc>Real-time streaming status updates for mise tools, Homebrew services, and OrbStack containers</bitbar.desc>
// <bitbar.dependencies>mise,brew,orb</bitbar.dependencies>
// <swiftbar.hideAbout>true</swiftbar.hideAbout>
// <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
// <swiftbar.hideLastUpdated>false</swiftbar.hideLastUpdated>

import Foundation

// ==============================================================================
// Configuration
// ==============================================================================

let PROJECT_DIR = ProcessInfo.processInfo.environment["GODTIER_PROJECT_DIR"] ?? 
    "\(NSHomeDirectory())/dev/github/ray-manaloto/gemini-ai-macos-development-environment"
let MISE_CMD = ProcessInfo.processInfo.environment["MISE_CMD"] ?? "mise"

// Colors (SwiftBar format)
let COLOR_GREEN = "#22c55e"
let COLOR_RED = "#ef4444"
let COLOR_YELLOW = "#eab308"
let COLOR_BLUE = "#3b82f6"
let COLOR_GRAY = "#6b7280"
let COLOR_PURPLE = "#a855f7"
let COLOR_ORANGE = "#f97316"

// ==============================================================================
// Helper Functions
// ==============================================================================

func shell(_ command: String) -> String {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", command]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = Pipe()
    
    do {
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    } catch {
        return ""
    }
    
    return ""
}

func commandExists(_ command: String) -> Bool {
    let result = shell("command -v \(command)")
    return !result.isEmpty
}

func getMiseStatus() -> String {
    guard commandExists("mise") else { return "error" }
    
    let output = shell("mise doctor 2>&1")
    if output.contains("problem") {
        return "warning"
    }
    return "ok"
}

func getOrbStackStatus() -> String {
    guard commandExists("orb") else { return "not_installed" }
    
    let status = shell("orb status 2>/dev/null || echo 'stopped'")
    return status.contains("running") ? "running" : "stopped"
}

func getOrbStackContainers() -> [String] {
    guard commandExists("orb") else { return [] }
    
    let output = shell("orb list 2>/dev/null | tail -n +2")
    return output.split(separator: "\n").map { String($0) }
}

func getBrewServices() -> [String] {
    guard commandExists("brew") else { return [] }
    
    let output = shell("brew services list 2>/dev/null | tail -n +2")
    return output.split(separator: "\n").map { String($0) }
}

func getActivePorts() -> [String] {
    guard commandExists("lsof") else { return [] }
    
    let output = shell("lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | tail -n +2 | awk '{print $1, $9}' | sort -u")
    return output.split(separator: "\n").map { String($0) }
}

func getMiseTools() -> [String] {
    guard commandExists("mise") else { return [] }
    
    let output = shell("mise ls 2>/dev/null | head -20")
    return output.split(separator: "\n").map { String($0) }
}

func getDevPodStatus() -> String {
    guard commandExists("devpod") else { return "not_installed" }
    
    let count = shell("devpod list 2>/dev/null | grep -c 'Running' || echo '0'")
    return count
}

func getSkyPilotStatus() -> String {
    guard commandExists("sky") else { return "not_installed" }
    
    let count = shell("sky status 2>/dev/null | grep -c 'UP' || echo '0'")
    return count
}

// ==============================================================================
// Menu Rendering
// ==============================================================================

func renderMenuBar() -> String {
    let miseStatus = getMiseStatus()
    let orbStatus = getOrbStackStatus()
    let devpodCount = getDevPodStatus()
    let skyCount = getSkyPilotStatus()
    
    var statusParts: [String] = []
    var overallStatus = "ok"
    
    if miseStatus == "error" {
        overallStatus = "error"
        statusParts.append("mise")
    } else if miseStatus == "warning" {
        overallStatus = "warning"
    }
    
    if orbStatus == "running" {
        statusParts.append("orb")
    }
    
    if devpodCount != "not_installed" && devpodCount != "0" {
        statusParts.append("dev:\(devpodCount)")
    }
    
    if skyCount != "not_installed" && skyCount != "0" {
        statusParts.append("sky:\(skyCount)")
    }
    
    let statusText = statusParts.isEmpty ? "idle" : statusParts.joined(separator: ",")
    
    switch overallStatus {
    case "ok":
        if statusText == "idle" {
            return "⚪ | color=\(COLOR_GRAY)"
        } else {
            return "🟢 \(statusText) | color=\(COLOR_GREEN)"
        }
    case "warning":
        return "🟡 \(statusText) | color=\(COLOR_YELLOW)"
    case "error":
        return "🔴 \(statusText) | color=\(COLOR_RED)"
    default:
        return "⚪ | color=\(COLOR_GRAY)"
    }
}

func renderLocalEnvironment() -> String {
    let miseStatus = getMiseStatus()
    var output = "---\n"
    output += "🖥️ Local Environment | color=\(COLOR_BLUE) size=14\n"
    output += "---\n"
    
    switch miseStatus {
    case "ok":
        output += "✅ Mise: Healthy\n"
    case "warning":
        output += "⚠️ Mise: Has warnings | color=\(COLOR_YELLOW)\n"
    case "error":
        output += "❌ Mise: Not installed | color=\(COLOR_RED)\n"
    default:
        output += "⚪ Mise: Unknown | color=\(COLOR_GRAY)\n"
    }
    
    output += "--📋 Run mise doctor | bash=\(MISE_CMD) param1=doctor terminal=true\n"
    output += "--🔄 Update all tools | bash=\(MISE_CMD) param1=run param2=tools:update terminal=true refresh=true\n"
    output += "--📊 Show tools status | bash=\(MISE_CMD) param1=run param2=tools:status terminal=true\n"
    
    return output
}

func renderMiseTools() -> String {
    let tools = getMiseTools()
    guard !tools.isEmpty else { return "" }
    
    var output = "---\n"
    output += "🛠️ Mise Tools | color=\(COLOR_BLUE) size=14\n"
    output += "---\n"
    
    for tool in tools.prefix(10) {
        output += "--\(tool)\n"
    }
    
    if tools.count > 10 {
        output += "--... and \(tools.count - 10) more\n"
    }
    
    return output
}

func renderBrewServices() -> String {
    let services = getBrewServices()
    guard !services.isEmpty else {
        return "---\n🍺 Homebrew Services | color=\(COLOR_ORANGE) size=14\n---\n⏹️ No services configured\n"
    }
    
    var output = "---\n"
    output += "🍺 Homebrew Services | color=\(COLOR_ORANGE) size=14\n"
    output += "---\n"
    
    for service in services {
        let parts = service.split(separator: " ", maxSplits: 2)
        guard parts.count >= 2 else { continue }
        
        let serviceName = String(parts[0])
        let serviceStatus = String(parts[1])
        
        switch serviceStatus {
        case "started":
            output += "✅ \(serviceName) | color=\(COLOR_GREEN)\n"
            output += "--⏹️ Stop \(serviceName) | bash=brew param1=services param2=stop param3=\(serviceName) terminal=false refresh=true\n"
        case "stopped":
            output += "⏹️ \(serviceName)\n"
            output += "--▶️ Start \(serviceName) | bash=brew param1=services param2=start param3=\(serviceName) terminal=false refresh=true\n"
        case "error":
            output += "❌ \(serviceName) | color=\(COLOR_RED)\n"
            output += "--🔧 Restart \(serviceName) | bash=brew param1=services param2=restart param3=\(serviceName) terminal=false refresh=true\n"
        default:
            output += "⚪ \(serviceName) | color=\(COLOR_GRAY)\n"
        }
    }
    
    return output
}

func renderOrbStackContainers() -> String {
    let orbStatus = getOrbStackStatus()
    var output = "---\n"
    output += "📦 Containers (OrbStack) | color=\(COLOR_BLUE) size=14\n"
    output += "---\n"
    
    switch orbStatus {
    case "running":
        output += "✅ OrbStack: Running | color=\(COLOR_GREEN)\n"
        output += "--⏹️ Stop OrbStack | bash=orb param1=stop terminal=false refresh=true\n"
        
        let containers = getOrbStackContainers()
        if !containers.isEmpty {
            output += "---\n"
            output += "🐳 Running Containers:\n"
            for container in containers {
                let parts = container.split(separator: " ")
                guard !parts.isEmpty else { continue }
                let containerName = String(parts[0])
                output += "--🐳 \(containerName)\n"
            }
        }
        
    case "stopped":
        output += "⏹️ OrbStack: Stopped\n"
        output += "--▶️ Start OrbStack | bash=orb param1=start terminal=false refresh=true\n"
        
    case "not_installed":
        output += "⚪ OrbStack: Not installed | color=\(COLOR_GRAY)\n"
        output += "--📥 Install OrbStack | href=https://orbstack.dev/\n"
        
    default:
        output += "⚪ OrbStack: Unknown | color=\(COLOR_GRAY)\n"
    }
    
    return output
}

func renderActivePorts() -> String {
    let ports = getActivePorts()
    guard !ports.isEmpty else {
        return "---\n🔌 Active Ports | color=\(COLOR_PURPLE) size=14\n---\n⏹️ No listening ports detected\n"
    }
    
    var output = "---\n"
    output += "🔌 Active Ports | color=\(COLOR_PURPLE) size=14\n"
    output += "---\n"
    output += "✅ Listening ports:\n"
    
    for port in ports.prefix(15) {
        output += "--🔗 \(port)\n"
    }
    
    if ports.count > 15 {
        output += "--... and \(ports.count - 15) more\n"
    }
    
    return output
}

func renderSettings() -> String {
    var output = "---\n"
    output += "⚙️ Settings\n"
    output += "--📂 Open project folder | bash=open param1=\(PROJECT_DIR) terminal=false\n"
    output += "--📝 Edit mise.toml | bash=open param1=\(PROJECT_DIR)/config/mise.toml terminal=false\n"
    output += "--🔄 Refresh this menu | refresh=true\n"
    output += "---\n"
    output += "📚 Documentation\n"
    output += "--📖 AGENTS.md | bash=open param1=\(PROJECT_DIR)/AGENTS.md terminal=false\n"
    output += "--📖 README.md | bash=open param1=\(PROJECT_DIR)/README.md terminal=false\n"
    output += "---\n"
    output += "🌐 External Links\n"
    output += "--📚 Mise Docs | href=https://mise.jdx.dev/\n"
    output += "--📚 SwiftBar Docs | href=https://github.com/swiftbar/SwiftBar\n"
    
    return output
}

// ==============================================================================
// Main Streaming Loop
// ==============================================================================

func refreshMenu() {
    print(renderMenuBar())
    print(renderLocalEnvironment())
    print(renderMiseTools())
    print(renderBrewServices())
    print(renderOrbStackContainers())
    print(renderActivePorts())
    print(renderSettings())
}

// Initial render
refreshMenu()

// Streaming separator
print("~~~")

// Periodic updates every 30 seconds
while true {
    sleep(30)
    refreshMenu()
    print("~~~")
}
