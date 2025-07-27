//
//  NotchUtilityUITests.swift
//  NotchUtilityUITests
//
//  Created by thwoodle on 24/07/2025.
//

import XCTest

final class NotchUtilityUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - Test Configuration Helpers
    
    /**
     * Configure the app for UI testing with proper environment variables and arguments
     */
    func configureAppForUITesting(_ app: XCUIApplication) {
        // Set environment variables to ensure UI test detection works
        app.launchEnvironment["UI_TESTING"] = "true"
        app.launchArguments.append("UI_TESTING")
        
    }


    // MARK: - UI Tests
    
    @MainActor
    func testSimpleLaunchAndOpen() throws {
        // UI tests must launch the application that they test.
        // Note: The notch should automatically open during UI tests due to 
        // the isRunningUITests() detection in NotchViewModel
        
        let app = XCUIApplication()
        configureAppForUITesting(app)
        app.launch()
        
        Thread.sleep(forTimeInterval: 1.0)
        
        let notchGroup = app.groups.firstMatch
        XCTAssertTrue(notchGroup.exists, "Notch interface should be visible during UI tests")
        
        // Test basic interactions with the notch interface
        
        let clipboardButton = app.buttons["document.on.clipboard"]
        XCTAssertTrue(clipboardButton.exists, "Clipboard button should exist")
        
        let dropZoneButton = app.buttons["tray.fill"]
        XCTAssertTrue(dropZoneButton.exists, "Drop zone button should exist")
        
        let toolsButton = app.buttons["wrench"]
        XCTAssert(toolsButton.exists, "Tools button should exist")
        
        clipboardButton.click()
        dropZoneButton.click()
        toolsButton.click()
    }
}
