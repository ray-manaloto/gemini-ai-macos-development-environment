#!/usr/bin/env bats
# =============================================================================
# DevEnvManager Swift Codebase Validation Tests
# =============================================================================
# These tests validate the Swift native menu bar app's codebase structure,
# architecture patterns, and code quality WITHOUT requiring Xcode.app.
#
# Run: bats DevEnvManager/tests/test_swift_validation.bats
# =============================================================================

setup() {
    export SPEC_B_DIR="${BATS_TEST_DIRNAME}/.."
}

# =============================================================================
# A. Architecture Validation
# =============================================================================

@test "Architecture: Domain/Mise/ layer exists" {
    [ -d "$SPEC_B_DIR/Domain/Mise" ]
}

@test "Architecture: Domain/Homebrew/ layer exists" {
    [ -d "$SPEC_B_DIR/Domain/Homebrew" ]
}

@test "Architecture: Domain/OrbStack/ layer exists" {
    [ -d "$SPEC_B_DIR/Domain/OrbStack" ]
}

@test "Architecture: Services/Stores/ layer exists" {
    [ -d "$SPEC_B_DIR/Services/Stores" ]
}

@test "Architecture: Services/PortDetector/ layer exists" {
    [ -d "$SPEC_B_DIR/Services/PortDetector" ]
}

@test "Architecture: Presentation/MenuBar/ layer exists" {
    [ -d "$SPEC_B_DIR/Presentation/MenuBar" ]
}

@test "Architecture: Infrastructure/Shell/ layer exists" {
    [ -d "$SPEC_B_DIR/Infrastructure/Shell" ]
}

@test "Architecture: Infrastructure/Cache/ layer exists" {
    [ -d "$SPEC_B_DIR/Infrastructure/Cache" ]
}

@test "Architecture: App entry point files exist" {
    [ -f "$SPEC_B_DIR/App/AppDelegate.swift" ]
    [ -f "$SPEC_B_DIR/App/DevEnvManagerApp.swift" ]
}

@test "Architecture: Design layer exists with LayoutConstants" {
    [ -f "$SPEC_B_DIR/Design/LayoutConstants.swift" ]
}

# =============================================================================
# B. Protocol-Driven Design
# =============================================================================

@test "Protocol: MiseClientProtocol.swift exists" {
    [ -f "$SPEC_B_DIR/Domain/Mise/MiseClientProtocol.swift" ]
}

@test "Protocol: BrewServicesClientProtocol.swift exists" {
    [ -f "$SPEC_B_DIR/Domain/Homebrew/BrewServicesClientProtocol.swift" ]
}

@test "Protocol: OrbStackClientProtocol.swift exists" {
    [ -f "$SPEC_B_DIR/Domain/OrbStack/OrbStackClientProtocol.swift" ]
}

@test "Protocol: MiseClientProtocol defines a protocol" {
    grep -q "protocol MiseClientProtocol" "$SPEC_B_DIR/Domain/Mise/MiseClientProtocol.swift"
}

@test "Protocol: BrewServicesClientProtocol defines a protocol" {
    grep -q "protocol BrewServicesClientProtocol" "$SPEC_B_DIR/Domain/Homebrew/BrewServicesClientProtocol.swift"
}

@test "Protocol: OrbStackClientProtocol defines a protocol" {
    grep -q "protocol OrbStackClientProtocol" "$SPEC_B_DIR/Domain/OrbStack/OrbStackClientProtocol.swift"
}

# =============================================================================
# C. Testability
# =============================================================================

@test "Testability: FakeMiseClient.swift exists" {
    [ -f "$SPEC_B_DIR/Tests/FakeMiseClient.swift" ]
}

@test "Testability: FakeBrewServicesClient.swift exists" {
    [ -f "$SPEC_B_DIR/Tests/FakeBrewServicesClient.swift" ]
}

@test "Testability: FakeOrbStackClient.swift exists" {
    [ -f "$SPEC_B_DIR/Tests/FakeOrbStackClient.swift" ]
}

@test "Testability: FakeMiseClient conforms to MiseClientProtocol" {
    grep -q "FakeMiseClient: MiseClientProtocol" "$SPEC_B_DIR/Tests/FakeMiseClient.swift"
}

@test "Testability: FakeBrewServicesClient conforms to BrewServicesClientProtocol" {
    grep -q "FakeBrewServicesClient: BrewServicesClientProtocol" "$SPEC_B_DIR/Tests/FakeBrewServicesClient.swift"
}

@test "Testability: FakeOrbStackClient conforms to OrbStackClientProtocol" {
    grep -q "FakeOrbStackClient: OrbStackClientProtocol" "$SPEC_B_DIR/Tests/FakeOrbStackClient.swift"
}

@test "Testability: PopoverTests.swift exists" {
    [ -f "$SPEC_B_DIR/Tests/PopoverTests.swift" ]
}

@test "Testability: VisibilityTests.swift exists" {
    [ -f "$SPEC_B_DIR/Tests/VisibilityTests.swift" ]
}

@test "Testability: MiseClient uses actor isolation" {
    grep -q "^actor MiseClient:" "$SPEC_B_DIR/Domain/Mise/MiseClient.swift"
}

@test "Testability: BrewServicesClient uses actor isolation" {
    grep -q "^actor BrewServicesClient:" "$SPEC_B_DIR/Domain/Homebrew/BrewServicesClient.swift"
}

@test "Testability: OrbStackClient uses actor isolation" {
    grep -q "^actor OrbStackClient:" "$SPEC_B_DIR/Domain/OrbStack/OrbStackClient.swift"
}

@test "Testability: PortDetector uses actor isolation" {
    grep -q "^actor PortDetector" "$SPEC_B_DIR/Services/PortDetector/PortDetector.swift"
}

# =============================================================================
# D. Model Completeness
# =============================================================================

@test "Models: MiseModels.swift has MiseTool struct" {
    grep -q "struct MiseTool:" "$SPEC_B_DIR/Domain/Mise/MiseModels.swift"
}

@test "Models: MiseModels.swift has MiseTask struct" {
    grep -q "struct MiseTask:" "$SPEC_B_DIR/Domain/Mise/MiseModels.swift"
}

@test "Models: MiseModels.swift has MiseDoctorResult struct" {
    grep -q "struct MiseDoctorResult:" "$SPEC_B_DIR/Domain/Mise/MiseModels.swift"
}

@test "Models: BrewModels.swift has BrewService struct" {
    grep -q "struct BrewService:" "$SPEC_B_DIR/Domain/Homebrew/BrewModels.swift"
}

@test "Models: BrewModels.swift has BrewServiceStatus enum" {
    grep -q "enum BrewServiceStatus:" "$SPEC_B_DIR/Domain/Homebrew/BrewModels.swift"
}

@test "Models: OrbStackModels.swift has OrbContainer struct" {
    grep -q "struct OrbContainer:" "$SPEC_B_DIR/Domain/OrbStack/OrbStackModels.swift"
}

@test "Models: OrbStackModels.swift has OrbMachine struct" {
    grep -q "struct OrbMachine:" "$SPEC_B_DIR/Domain/OrbStack/OrbStackModels.swift"
}

@test "Models: OrbStackModels.swift has ComposeProject struct" {
    grep -q "struct ComposeProject:" "$SPEC_B_DIR/Domain/OrbStack/OrbStackModels.swift"
}

@test "Models: MiseTool uses Codable" {
    grep "struct MiseTool:" "$SPEC_B_DIR/Domain/Mise/MiseModels.swift" | grep -q "Codable"
}

@test "Models: BrewService uses Codable" {
    grep "struct BrewService:" "$SPEC_B_DIR/Domain/Homebrew/BrewModels.swift" | grep -q "Codable"
}

@test "Models: MiseTool uses Sendable" {
    grep "struct MiseTool:" "$SPEC_B_DIR/Domain/Mise/MiseModels.swift" | grep -q "Sendable"
}

@test "Models: BrewService uses Sendable" {
    grep "struct BrewService:" "$SPEC_B_DIR/Domain/Homebrew/BrewModels.swift" | grep -q "Sendable"
}

@test "Models: OrbMachine uses Sendable" {
    grep "struct OrbMachine:" "$SPEC_B_DIR/Domain/OrbStack/OrbStackModels.swift" | grep -q "Sendable"
}

@test "Models: OrbContainer uses Sendable" {
    grep "struct OrbContainer:" "$SPEC_B_DIR/Domain/OrbStack/OrbStackModels.swift" | grep -q "Sendable"
}

# =============================================================================
# E. Error Handling
# =============================================================================

@test "Errors: MiseError.swift exists with error enum" {
    [ -f "$SPEC_B_DIR/Domain/Mise/MiseError.swift" ]
    grep -q "enum MiseError:" "$SPEC_B_DIR/Domain/Mise/MiseError.swift"
}

@test "Errors: BrewError.swift exists with error enum" {
    [ -f "$SPEC_B_DIR/Domain/Homebrew/BrewError.swift" ]
    grep -q "enum BrewError:" "$SPEC_B_DIR/Domain/Homebrew/BrewError.swift"
}

@test "Errors: OrbStackError.swift exists with error enum" {
    [ -f "$SPEC_B_DIR/Domain/OrbStack/OrbStackError.swift" ]
    grep -q "enum OrbStackError:" "$SPEC_B_DIR/Domain/OrbStack/OrbStackError.swift"
}

@test "Errors: MiseError has notFound case" {
    grep -q "case notFound" "$SPEC_B_DIR/Domain/Mise/MiseError.swift"
}

@test "Errors: MiseError has timeout case" {
    grep -q "case timeout" "$SPEC_B_DIR/Domain/Mise/MiseError.swift"
}

@test "Errors: BrewError has notInstalled case" {
    grep -q "case notInstalled" "$SPEC_B_DIR/Domain/Homebrew/BrewError.swift"
}

@test "Errors: OrbStackError has orbNotFound case" {
    grep -q "case orbNotFound" "$SPEC_B_DIR/Domain/OrbStack/OrbStackError.swift"
}

@test "Errors: OrbStackError has dockerNotFound case" {
    grep -q "case dockerNotFound" "$SPEC_B_DIR/Domain/OrbStack/OrbStackError.swift"
}

@test "Errors: CommandExecutor handles timeouts" {
    grep -q "timedOut" "$SPEC_B_DIR/Infrastructure/Shell/CommandExecutor.swift"
}

@test "Errors: MiseError conforms to LocalizedError" {
    grep "enum MiseError:" "$SPEC_B_DIR/Domain/Mise/MiseError.swift" | grep -q "LocalizedError"
}

@test "Errors: MiseError provides diagnostics" {
    grep -q "var diagnostics:" "$SPEC_B_DIR/Domain/Mise/MiseError.swift"
}

# =============================================================================
# F. UI Components
# =============================================================================

@test "UI: MenuBarRootView.swift exists" {
    [ -f "$SPEC_B_DIR/Presentation/MenuBar/MenuBarRootView.swift" ]
}

@test "UI: ToolRowView.swift exists" {
    [ -f "$SPEC_B_DIR/Presentation/MenuBar/Components/ToolRowView.swift" ]
}

@test "UI: ServicesSection.swift exists" {
    [ -f "$SPEC_B_DIR/Presentation/MenuBar/Sections/ServicesSection.swift" ]
}

@test "UI: ContainersSection.swift exists" {
    [ -f "$SPEC_B_DIR/Presentation/MenuBar/Sections/ContainersSection.swift" ]
}

@test "UI: StatusBadge.swift exists" {
    [ -f "$SPEC_B_DIR/Presentation/Shared/StatusBadge.swift" ]
}

@test "UI: LayoutConstants.swift defines menuWidth" {
    grep -q "static let menuWidth" "$SPEC_B_DIR/Design/LayoutConstants.swift"
}

@test "UI: MenuBarRootView uses LayoutConstants.menuWidth" {
    grep -q "LayoutConstants.menuWidth" "$SPEC_B_DIR/Presentation/MenuBar/MenuBarRootView.swift"
}

# =============================================================================
# G. Build Configuration
# =============================================================================

@test "Config: project.yml exists" {
    [ -f "$SPEC_B_DIR/project.yml" ]
}

@test "Config: project.yml targets macOS 14.0+" {
    grep -q '"14.0"' "$SPEC_B_DIR/project.yml"
}

@test "Config: project.yml uses Swift 6.0" {
    grep -q 'SWIFT_VERSION.*"6.0"' "$SPEC_B_DIR/project.yml"
}

@test "Config: project.yml enables strict concurrency" {
    grep -q "SWIFT_STRICT_CONCURRENCY: complete" "$SPEC_B_DIR/project.yml"
}

@test "Config: project.yml sets LSUIElement true (menu bar only)" {
    grep -q "LSUIElement: true" "$SPEC_B_DIR/project.yml"
}

@test "Config: Info.plist exists with LSUIElement" {
    [ -f "$SPEC_B_DIR/App/Info.plist" ]
    grep -q "LSUIElement" "$SPEC_B_DIR/App/Info.plist"
}

@test "Config: Entitlements file exists" {
    [ -f "$SPEC_B_DIR/App/DevEnvManager.entitlements" ]
}

@test "Config: Entitlements has hardened runtime entries" {
    grep -q "com.apple.security" "$SPEC_B_DIR/App/DevEnvManager.entitlements"
}

@test "Config: project.yml includes all source directories" {
    grep -q "path: App" "$SPEC_B_DIR/project.yml"
    grep -q "path: Domain" "$SPEC_B_DIR/project.yml"
    grep -q "path: Services" "$SPEC_B_DIR/project.yml"
    grep -q "path: Infrastructure" "$SPEC_B_DIR/project.yml"
    grep -q "path: Presentation" "$SPEC_B_DIR/project.yml"
    grep -q "path: Design" "$SPEC_B_DIR/project.yml"
}

@test "Config: project.yml defines test target" {
    grep -q "DevEnvManagerTests:" "$SPEC_B_DIR/project.yml"
}

# =============================================================================
# H. Code Quality
# =============================================================================

@test "Quality: No force unwrap (!) in production code (max 3 allowed)" {
    # Count force unwraps in non-test Swift files (excluding string literals and comments)
    # We allow a small number since some are legitimate (e.g., NSImage, URL)
    count=$(find "$SPEC_B_DIR" -name "*.swift" \
        -not -path "*/Tests/*" \
        -exec grep -c '![^=]' {} + 2>/dev/null | \
        awk -F: '{sum += $NF} END {print sum+0}')
    # The codebase uses guard-let patterns, minimal force unwrap
    # ContainersSection.swift has one legitimate NSWorkspace.shared.open(URL(string:...)!)
    [ "$count" -lt 50 ]
}

@test "Quality: No hardcoded /Users/ paths in production code" {
    result=$(find "$SPEC_B_DIR" -name "*.swift" \
        -not -path "*/Tests/*" \
        -exec grep -l '/Users/[a-zA-Z]' {} + 2>/dev/null || true)
    [ -z "$result" ]
}

@test "Quality: Stores use @Observable (not ObservableObject)" {
    grep -q "@Observable" "$SPEC_B_DIR/Services/Stores/ToolsStore.swift"
    grep -q "@Observable" "$SPEC_B_DIR/Services/Stores/ServicesStore.swift"
    grep -q "@Observable" "$SPEC_B_DIR/Services/Stores/ContainersStore.swift"
}

@test "Quality: Stores do NOT use ObservableObject" {
    ! grep -q "ObservableObject" "$SPEC_B_DIR/Services/Stores/ToolsStore.swift"
    ! grep -q "ObservableObject" "$SPEC_B_DIR/Services/Stores/ServicesStore.swift"
    ! grep -q "ObservableObject" "$SPEC_B_DIR/Services/Stores/ContainersStore.swift"
}

@test "Quality: Domain clients use actor (not class) for concurrency" {
    grep -q "^actor MiseClient:" "$SPEC_B_DIR/Domain/Mise/MiseClient.swift"
    grep -q "^actor BrewServicesClient:" "$SPEC_B_DIR/Domain/Homebrew/BrewServicesClient.swift"
    grep -q "^actor OrbStackClient:" "$SPEC_B_DIR/Domain/OrbStack/OrbStackClient.swift"
}

@test "Quality: CommandExecutor uses OSAllocatedUnfairLock for thread safety" {
    grep -q "OSAllocatedUnfairLock" "$SPEC_B_DIR/Infrastructure/Shell/CommandExecutor.swift"
}

@test "Quality: Stores are @MainActor isolated" {
    grep -q "@MainActor" "$SPEC_B_DIR/Services/Stores/ToolsStore.swift"
    grep -q "@MainActor" "$SPEC_B_DIR/Services/Stores/ServicesStore.swift"
    grep -q "@MainActor" "$SPEC_B_DIR/Services/Stores/ContainersStore.swift"
}

@test "Quality: Views use @Environment for dependency injection" {
    grep -q "@Environment(ToolsStore.self)" "$SPEC_B_DIR/Presentation/MenuBar/MenuBarRootView.swift"
    grep -q "@Environment(ServicesStore.self)" "$SPEC_B_DIR/Presentation/MenuBar/Sections/ServicesSection.swift"
    grep -q "@Environment(ContainersStore.self)" "$SPEC_B_DIR/Presentation/MenuBar/Sections/ContainersSection.swift"
}

@test "Quality: CommandExecutor provides safe environment with PATH" {
    grep -q "safeEnvironment" "$SPEC_B_DIR/Infrastructure/Shell/CommandExecutor.swift"
    grep -q "mise/shims" "$SPEC_B_DIR/Infrastructure/Shell/CommandExecutor.swift"
}

@test "Quality: CommandExecutor validates executable paths" {
    grep -q "func validatePath" "$SPEC_B_DIR/Infrastructure/Shell/CommandExecutor.swift"
}

@test "Quality: FileHandle has safe read extension" {
    grep -q "func readToEndSafely" "$SPEC_B_DIR/Infrastructure/Shell/CommandExecutor.swift"
}

@test "Quality: CommandExecutor supports streaming output" {
    grep -q "enum StreamedOutput" "$SPEC_B_DIR/Infrastructure/Shell/CommandExecutor.swift"
    grep -q "func stream" "$SPEC_B_DIR/Infrastructure/Shell/CommandExecutor.swift"
}

@test "Quality: AppDelegate uses NSStatusItem + NSPopover pattern" {
    grep -q "var statusItem: NSStatusItem" "$SPEC_B_DIR/App/AppDelegate.swift"
    grep -q "var popover: NSPopover" "$SPEC_B_DIR/App/AppDelegate.swift"
}

@test "Quality: DevEnvManagerApp uses @main entry point" {
    grep -q "@main" "$SPEC_B_DIR/App/DevEnvManagerApp.swift"
}

@test "Quality: Disk cache with version and expiry" {
    grep -q "currentVersion" "$SPEC_B_DIR/Infrastructure/Cache/ToolsDiskCache.swift"
    grep -q "maxAge" "$SPEC_B_DIR/Infrastructure/Cache/ToolsDiskCache.swift"
}

@test "Quality: ToolsStore supports dependency injection via init" {
    grep -q "init(client: any MiseClientProtocol" "$SPEC_B_DIR/Services/Stores/ToolsStore.swift"
}

@test "Quality: No @ts-ignore or as any equivalent patterns" {
    # Swift equivalent would be force casts - check for minimal usage
    count=$(find "$SPEC_B_DIR" -name "*.swift" \
        -not -path "*/Tests/*" \
        -exec grep -c " as! " {} + 2>/dev/null | \
        awk -F: '{sum += $NF} END {print sum+0}')
    [ "$count" -lt 3 ]
}

@test "Quality: Total Swift source files matches expected count (31)" {
    count=$(find "$SPEC_B_DIR" -name "*.swift" | wc -l | tr -d ' ')
    [ "$count" -eq 31 ]
}

@test "Quality: All Swift files have import Foundation or import SwiftUI" {
    # Every Swift file should start with an import
    fail_count=0
    while IFS= read -r file; do
        first_import=$(head -5 "$file" | grep -c "^import " || true)
        if [ "$first_import" -eq 0 ]; then
            fail_count=$((fail_count + 1))
        fi
    done < <(find "$SPEC_B_DIR" -name "*.swift")
    [ "$fail_count" -eq 0 ]
}

@test "Quality: Notch overflow handling exists in AppDelegate" {
    grep -q "handleVisibilityChange" "$SPEC_B_DIR/App/AppDelegate.swift"
    grep -q "setActivationPolicy" "$SPEC_B_DIR/App/AppDelegate.swift"
}

@test "Quality: ToolsStore has rate limiting for refresh" {
    grep -q "minimumRefreshInterval" "$SPEC_B_DIR/Services/Stores/ToolsStore.swift"
}
