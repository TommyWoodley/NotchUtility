//
//  NotchDetectorTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 24/07/2025.
//

import Testing
import Foundation
import AppKit
@testable import NotchUtility

@MainActor
struct NotchDetectorTests {
    
    @Test("NotchDetector initialization")
    func testNotchDetectorInitialization() async throws {
        let detector = NotchDetector()
        
        #expect(detector.notchDimensions != nil)
        #expect(detector.optimalPosition != nil)
        #expect(detector.hasNotch == (detector.notchDimensions != .none))
    }
    
    @Test("NotchDimensions enum properties")
    func testNotchDimensionsProperties() async throws {
        // Test none case
        let none = NotchDimensions.none
        #expect(none.width == 0)
        #expect(none.height == 0)
        #expect(none.displayName == "No Notch")
        
        // Test MacBook Pro 14-inch
        let macBook14 = NotchDimensions.macBook14Inch
        #expect(macBook14.width == 200)
        #expect(macBook14.height == 32)
        #expect(macBook14.displayName == "14-inch MacBook Pro")
        
        // Test MacBook Pro 16-inch
        let macBook16 = NotchDimensions.macBook16Inch
        #expect(macBook16.width == 200)
        #expect(macBook16.height == 32)
        #expect(macBook16.displayName == "16-inch MacBook Pro")
        
        // Test MacBook Air 13-inch
        let macBookAir13 = NotchDimensions.macBookAir13Inch
        #expect(macBookAir13.width == 180)
        #expect(macBookAir13.height == 25)
        #expect(macBookAir13.displayName == "13-inch MacBook Air")
        
        // Test MacBook Air 15-inch
        let macBookAir15 = NotchDimensions.macBookAir15Inch
        #expect(macBookAir15.width == 190)
        #expect(macBookAir15.height == 25)
        #expect(macBookAir15.displayName == "15-inch MacBook Air")
    }
    
    @Test("Window frame calculation")
    func testWindowFrameCalculation() async throws {
        let detector = NotchDetector()
        let windowSize = CGSize(width: 320, height: 200)
        
        let frame = detector.getWindowFrame(for: windowSize)
        
        #expect(frame.size.width == windowSize.width)
        #expect(frame.size.height == windowSize.height)
        #expect(frame.origin.x >= 0)
        #expect(frame.origin.y >= 0)
    }
    
    @Test("Notch detection method")
    func testNotchDetectionMethod() async throws {
        let detector = NotchDetector()
        
        // Test detection
        detector.detectNotchAndCalculatePosition()
        
        // Should have valid state after detection
        #expect(detector.notchDimensions != nil)
        #expect(detector.optimalPosition.x != 0 || detector.optimalPosition.y != 0)
    }
}

@MainActor
struct WindowManagerTests {
    
    @Test("WindowManager initialization")
    func testWindowManagerInitialization() async throws {
        let windowManager = WindowManager()
        
        #expect(!windowManager.isNotchMode)
        #expect(windowManager.currentWindowLevel == .normal)
    }
    
    @Test("Window level management")
    func testWindowLevelManagement() async throws {
        let windowManager = WindowManager()
        
        // Test setting different window levels
        windowManager.setWindowLevel(.floating)
        #expect(windowManager.currentWindowLevel == .floating)
        
        windowManager.setWindowLevel(.normal)
        #expect(windowManager.currentWindowLevel == .normal)
    }
    
    @Test("Notch mode toggle")
    func testNotchModeToggle() async throws {
        let windowManager = WindowManager()
        
        let initialMode = windowManager.isNotchMode
        windowManager.toggleNotchMode()
        
        #expect(windowManager.isNotchMode != initialMode)
        
        // Toggle back
        windowManager.toggleNotchMode()
        #expect(windowManager.isNotchMode == initialMode)
    }
    
    @Test("WindowConfiguration constants")
    func testWindowConfigurationConstants() async throws {
        let notchConfig = WindowConfiguration.notchMode
        #expect(notchConfig.isFloating)
        #expect(notchConfig.allowsInteraction)
        #expect(notchConfig.staysOnTop)
        #expect(!notchConfig.hasBackground)
        
        let normalConfig = WindowConfiguration.normalMode
        #expect(!normalConfig.isFloating)
        #expect(normalConfig.allowsInteraction)
        #expect(!normalConfig.staysOnTop)
        #expect(normalConfig.hasBackground)
    }
}

struct NotchIntegrationTests {
    
    @Test("NotchDimensions equality")
    func testNotchDimensionsEquality() async throws {
        #expect(NotchDimensions.none == NotchDimensions.none)
        #expect(NotchDimensions.macBook14Inch == NotchDimensions.macBook14Inch)
        #expect(NotchDimensions.none != NotchDimensions.macBook14Inch)
    }
    
    @Test("Window level extensions")
    func testWindowLevelExtensions() async throws {
        let notchLevel = NSWindow.Level.notchLevel
        let alwaysOnTop = NSWindow.Level.alwaysOnTop
        
        #expect(notchLevel.rawValue > NSWindow.Level.normal.rawValue)
        #expect(alwaysOnTop.rawValue > notchLevel.rawValue)
    }
    
    @Test("Multiple display scenario simulation")
    func testMultipleDisplayScenario() async throws {
        let detector = NotchDetector()
        
        // Simulate screen change
        detector.detectNotchAndCalculatePosition()
        let initialPosition = detector.optimalPosition
        
        // Trigger another detection (simulating screen change)
        detector.detectNotchAndCalculatePosition()
        let newPosition = detector.optimalPosition
        
        // Position should be recalculated (may be same if no actual screen change)
        #expect(newPosition.x != CGFloat.infinity)
        #expect(newPosition.y != CGFloat.infinity)
    }
} 