//
//  NotchUtilityUITests.swift
//  NotchUtilityUITests
//
//  Created by thwoodle on 24/07/2025.
//

import XCTest

final class FeatureTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - UI Tests
    
    @MainActor
    func testDevToolsBase64() throws {
        // UI tests must launch the application that they test.
        // Note: The notch should automatically open during UI tests due to 
        // the isRunningUITests() detection in NotchViewModel
        
        let app = XCUIApplication()
        UITestHelper.configureAppForUITesting(app)
        app.launch()
        
        Thread.sleep(forTimeInterval: 1.0)
        
        UITestHelper.clickButton(app, name: "wrench")
        UITestHelper.clickButton(app, name: "Base64, Encode & Decode")
        UITestHelper.clickButton(app, name: "Close")
        
    }
}
