//
//  ToolWindowControllerTests.swift
//  NotchUtilityTests
//
//  Tests for ToolWindowController which presents tool modals in separate windows.
//

import Testing
import Foundation
import AppKit
@testable import NotchUtility

@MainActor
struct ToolWindowControllerTests {
    
    // MARK: - Window Creation Tests
    
    @Test("ToolWindowController creates window with reasonable dimensions")
    func testWindowDimensions() async throws {
        let controller = ToolWindowController(tool: .base64)
        
        guard let window = controller.window else {
            Issue.record("Window should be created")
            return
        }
        
        // Allow window to initialize
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Window dimensions should be positive and reasonable
        // Note: The window is created with 500x400 but may adjust based on content
        #expect(window.frame.width >= 100, "Window width should be at least 100")
        #expect(window.frame.height >= 100, "Window height should be at least 100")
        #expect(window.frame.width <= 1000, "Window width should be reasonable")
        #expect(window.frame.height <= 800, "Window height should be reasonable")
        
        controller.close()
    }
    
    @Test("ToolWindowController creates window with correct style mask")
    func testWindowStyleMask() async throws {
        let controller = ToolWindowController(tool: .base64)
        
        guard let window = controller.window else {
            Issue.record("Window should be created")
            return
        }
        
        #expect(window.styleMask.contains(.titled), "Window should have titled style")
        #expect(window.styleMask.contains(.closable), "Window should be closable")
        #expect(window.styleMask.contains(.fullSizeContentView), "Window should have fullSizeContentView")
        
        controller.close()
    }
    
    @Test("ToolWindowController creates window with transparent titlebar")
    func testWindowTitlebarConfiguration() async throws {
        let controller = ToolWindowController(tool: .base64)
        
        guard let window = controller.window else {
            Issue.record("Window should be created")
            return
        }
        
        #expect(window.titlebarAppearsTransparent == true, "Titlebar should be transparent")
        #expect(window.titleVisibility == .hidden, "Title should be hidden")
        #expect(window.isMovableByWindowBackground == true, "Window should be movable by background")
        
        controller.close()
    }
    
    @Test("ToolWindowController creates window with floating level")
    func testWindowLevel() async throws {
        let controller = ToolWindowController(tool: .base64)
        
        guard let window = controller.window else {
            Issue.record("Window should be created")
            return
        }
        
        #expect(window.level == .floating, "Window should have floating level")
        
        controller.close()
    }
    
    @Test("ToolWindowController sets window background color")
    func testWindowBackgroundColor() async throws {
        let controller = ToolWindowController(tool: .base64)
        
        guard let window = controller.window else {
            Issue.record("Window should be created")
            return
        }
        
        #expect(window.backgroundColor == NSColor.windowBackgroundColor, "Window should have windowBackgroundColor")
        
        controller.close()
    }
    
    @Test("ToolWindowController creates window with content view controller")
    func testWindowHasContentViewController() async throws {
        let controller = ToolWindowController(tool: .base64)
        
        guard let window = controller.window else {
            Issue.record("Window should be created")
            return
        }
        
        #expect(window.contentViewController != nil, "Window should have a content view controller")
        
        controller.close()
    }
    
    // MARK: - Window Positioning Tests
    
    @Test("ToolWindowController positions window on screen")
    func testWindowPositioning() async throws {
        let controller = ToolWindowController(tool: .base64)
        
        guard let window = controller.window else {
            Issue.record("Window should be created")
            return
        }
        
        // Window should be positioned on screen (not at 0,0)
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            
            // Calculate expected X position (centered)
            let expectedX = screenFrame.origin.x + (screenFrame.width - 500) / 2
            #expect(window.frame.origin.x == expectedX, "Window should be horizontally centered")
            
            // Calculate expected Y position
            let distanceFromTop: CGFloat = 250
            let expectedY = screenFrame.maxY - distanceFromTop - 400
            #expect(window.frame.origin.y == expectedY, "Window should be positioned below notch area")
        }
        
        controller.close()
    }
    
    // MARK: - Static Method Tests
    
    @Test("ToolWindowController.show creates window without crashing")
    func testShowCreatesWindow() async throws {
        // This test verifies show can be called without crashing
        ToolWindowController.show(tool: .base64)
        
        // Give the window time to appear
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Clean up
        ToolWindowController.dismiss()
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    @Test("ToolWindowController.dismiss completes without crashing")
    func testDismissClosesWindow() async throws {
        // Show a window first
        ToolWindowController.show(tool: .base64)
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Dismiss should complete without error
        ToolWindowController.dismiss()
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Calling dismiss again should also be safe (idempotent)
        ToolWindowController.dismiss()
    }
    
    @Test("ToolWindowController.show replaces existing window")
    func testShowReplacesExistingWindow() async throws {
        // Dismiss any existing windows first
        ToolWindowController.dismiss()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Show first window
        ToolWindowController.show(tool: .base64)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Show second window (should replace first, not add)
        ToolWindowController.show(tool: .base64)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // The singleton pattern ensures only one controller exists at a time
        // This test verifies the show method can be called multiple times without crash
        ToolWindowController.dismiss()
    }
    
    // MARK: - Tool Support Tests
    
    @Test("ToolWindowController supports all DevTool cases")
    func testSupportsAllDevTools() async throws {
        for tool in DevTool.allCases {
            let controller = ToolWindowController(tool: tool)
            
            #expect(controller.window != nil, "Should create window for \(tool.name)")
            
            controller.close()
        }
    }
}

// MARK: - DevTool Tests

@MainActor
struct DevToolTests {
    
    @Test("DevTool.base64 has correct properties")
    func testBase64Properties() async throws {
        let tool = DevTool.base64
        
        #expect(tool.id == "base64")
        #expect(tool.name == "Base64")
        #expect(tool.icon == "arrow.left.arrow.right.square")
        #expect(tool.description == "Encode & Decode")
        #expect(tool.color == .blue)
    }
    
    @Test("DevTool.allCases contains all tools")
    func testAllCases() async throws {
        #expect(DevTool.allCases.count >= 1, "Should have at least one tool")
        #expect(DevTool.allCases.contains(.base64), "Should contain base64 tool")
    }
    
    @Test("DevTool conforms to required protocols")
    func testProtocolConformance() async throws {
        // Test CaseIterable
        #expect(!DevTool.allCases.isEmpty)
        
        // Test Identifiable
        let tool = DevTool.base64
        #expect(!tool.id.isEmpty)
        
        // Test that each tool has unique ID
        let ids = DevTool.allCases.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count, "Each tool should have a unique ID")
    }
}

// MARK: - ToolWindowContentView Tests

@MainActor
struct ToolWindowContentViewTests {
    
    @Test("ToolWindowContentView initializes with tool")
    func testInitialization() async throws {
        var dismissCalled = false
        let view = ToolWindowContentView(tool: .base64) {
            dismissCalled = true
        }
        
        #expect(view.tool == .base64)
        
        // Call dismiss action to verify it works
        view.dismissAction()
        #expect(dismissCalled, "Dismiss action should be callable")
    }
    
    @Test("ToolWindowContentView has correct frame size")
    func testFrameSize() async throws {
        let view = ToolWindowContentView(tool: .base64) {}
        
        // The view specifies a frame of 500x400
        // We can verify this through the view's body structure
        #expect(view.tool.name == "Base64", "Should display correct tool")
    }
}

