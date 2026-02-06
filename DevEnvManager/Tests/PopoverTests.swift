import XCTest
import AppKit

final class PopoverTests: XCTestCase {
    var appDelegate: AppDelegate!
    
    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
    }
    
    override func tearDown() {
        appDelegate = nil
        super.tearDown()
    }
    
    func testPopoverIsCreatedWithCorrectContentSize() {
        // Given AppDelegate is initialized
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        
        // When we access the popover
        guard let popover = appDelegate.popover else {
            XCTFail("Popover should be created")
            return
        }
        
        // Then popover should have correct content size
        let expectedSize = NSSize(width: 400, height: 500)
        XCTAssertEqual(popover.contentSize, expectedSize, "Popover content size should be 400x500")
    }
    
    func testPopoverBehaviorIsTransient() {
        // Given AppDelegate is initialized
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        
        // When we access the popover
        guard let popover = appDelegate.popover else {
            XCTFail("Popover should be created")
            return
        }
        
        // Then popover behavior should be transient (click-outside-to-dismiss)
        XCTAssertEqual(popover.behavior, .transient, "Popover behavior should be .transient")
    }
    
    func testPopoverContentViewControllerIsHostingController() {
        // Given AppDelegate is initialized
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        
        // When we access the popover
        guard let popover = appDelegate.popover else {
            XCTFail("Popover should be created")
            return
        }
        
        // Then content view controller should be NSHostingController
        XCTAssertTrue(popover.contentViewController is NSHostingController<AnyView>, "Content view controller should be NSHostingController")
    }
    
    func testTogglePopoverShowsWhenHidden() {
        // Given AppDelegate is initialized with a status item
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        
        guard let popover = appDelegate.popover else {
            XCTFail("Popover should be created")
            return
        }
        
        // When popover is hidden and we toggle it
        XCTAssertFalse(popover.isShown, "Popover should initially be hidden")
        appDelegate.togglePopover()
        
        // Then popover should be shown
        XCTAssertTrue(popover.isShown, "Popover should be shown after toggle")
    }
    
    func testTogglePopoverHidesWhenShown() {
        // Given AppDelegate is initialized with a status item
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        
        guard let popover = appDelegate.popover else {
            XCTFail("Popover should be created")
            return
        }
        
        // When popover is shown
        appDelegate.togglePopover()
        XCTAssertTrue(popover.isShown, "Popover should be shown")
        
        // And we toggle it again
        appDelegate.togglePopover()
        
        // Then popover should be hidden
        XCTAssertFalse(popover.isShown, "Popover should be hidden after second toggle")
    }
    
    func testStatusItemButtonActionIsSet() {
        // Given AppDelegate is initialized
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        
        // When we access the status item
        guard let statusItem = appDelegate.statusItem,
              let button = statusItem.button else {
            XCTFail("Status item and button should be created")
            return
        }
        
        // Then button action should be togglePopover
        XCTAssertEqual(button.action, #selector(AppDelegate.togglePopover), "Button action should be togglePopover")
        XCTAssertEqual(button.target as? AppDelegate, appDelegate, "Button target should be AppDelegate")
    }
}
