import XCTest
import AppKit

final class VisibilityTests: XCTestCase {
    var appDelegate: AppDelegate!
    
    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
    }
    
    override func tearDown() {
        appDelegate = nil
        super.tearDown()
    }
    
    func testInitialActivationPolicyIsAccessory() {
        // When AppDelegate is initialized
        let initialPolicy = NSApp.activationPolicy()
        
        // Then activation policy should be accessory (menu bar only)
        XCTAssertEqual(initialPolicy, .accessory, "Initial activation policy should be .accessory")
    }
    
    func testHandleVisibilityChangeTrueRestoresAccessoryPolicy() {
        // Given the app is in regular mode (Dock visible)
        NSApp.setActivationPolicy(.regular)
        
        // When visibility changes to true (menu bar space available)
        appDelegate.handleVisibilityChange(true)
        
        // Then activation policy should switch back to accessory
        XCTAssertEqual(NSApp.activationPolicy(), .accessory, "Should switch to .accessory when menu bar space is available")
    }
    
    func testHandleVisibilityChangeFalseSwitchesToRegularPolicy() {
        // Given the app is in accessory mode (menu bar only)
        NSApp.setActivationPolicy(.accessory)
        
        // When visibility changes to false (notch overflow detected)
        appDelegate.handleVisibilityChange(false)
        
        // Then activation policy should switch to regular (Dock icon visible)
        XCTAssertEqual(NSApp.activationPolicy(), .regular, "Should switch to .regular when notch overflow is detected")
    }
    
    func testMultipleVisibilityChanges() {
        // Given initial state is accessory
        NSApp.setActivationPolicy(.accessory)
        
        // When visibility changes multiple times
        appDelegate.handleVisibilityChange(false)
        XCTAssertEqual(NSApp.activationPolicy(), .regular)
        
        appDelegate.handleVisibilityChange(true)
        XCTAssertEqual(NSApp.activationPolicy(), .accessory)
        
        appDelegate.handleVisibilityChange(false)
        XCTAssertEqual(NSApp.activationPolicy(), .regular)
        
        // Then each change should be reflected correctly
        appDelegate.handleVisibilityChange(true)
        XCTAssertEqual(NSApp.activationPolicy(), .accessory, "Final state should be .accessory")
    }
}
