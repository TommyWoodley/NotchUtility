//
//  UITestHelper.swift
//  NotchUtilityUITests
//
//  Created by thwoodle on 28/07/2025.
//

import Foundation
import XCTest

final class UITestHelper {
    
    // MARK: - Test Configuration Helpers
    
    /**
     * Configure the app for UI testing with proper environment variables and arguments
     */
    static func configureAppForUITesting(_ app: XCUIApplication) {
        // Set environment variables to ensure UI test detection works
        app.launchEnvironment["UI_TESTING"] = "true"
        app.launchArguments.append("UI_TESTING")
        
    }
    
    static func clickButton(_ app: XCUIApplication, name: String) {
        let toolsButton = app.buttons[name]
        
        if !toolsButton.exists {
            // Collect debug information about available buttons
            let availableButtons = app.buttons.allElementsBoundByIndex.compactMap { button in
                var buttonInfo: [String] = []
                
                if !button.identifier.isEmpty {
                    buttonInfo.append("id: '\(button.identifier)'")
                }
                if !button.label.isEmpty {
                    buttonInfo.append("label: '\(button.label)'")
                }
                if !button.title.isEmpty {
                    buttonInfo.append("title: '\(button.title)'")
                }
                
                return buttonInfo.isEmpty ? nil : "[\(buttonInfo.joined(separator: ", "))]"
            }
            
            let debugInfo = availableButtons.isEmpty 
                ? "No buttons found" 
                : availableButtons.joined(separator: ", ")
            
            XCTFail("\(name) button should exist. Available buttons: \(debugInfo)")
        }
        
        toolsButton.click()
        
        Thread.sleep(forTimeInterval: 0.1)
    }
}
