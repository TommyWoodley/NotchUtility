//
//  NotchWindow.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Cocoa

/**
 * NotchWindow: A specialized NSWindow for creating a transparent overlay in the notch area
 * 
 * This is the foundation of our notch integration. It creates a full-screen transparent window
 * that sits above all other windows, allowing us to capture mouse events and display UI
 * specifically in the notch area without interfering with the rest of the desktop.
 * 
 * Key Principles:
 * - Completely transparent background so only our UI shows
 * - High window level to appear above everything else including menu bar
 * - Non-movable to prevent accidental displacement
 * - Configured to work with full-screen apps and multiple spaces
 * - Can receive keyboard focus for interactions
 */
class NotchWindow: NSWindow {
    override init(
        contentRect: NSRect,
        styleMask: NSWindow.StyleMask,
        backing: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: backing,
            defer: flag
        )

        // === TRANSPARENCY CONFIGURATION ===
        // These settings make the window completely transparent except for our content
        isOpaque = false                    // Allows transparency through the window
        alphaValue = 1                      // Keep window fully visible (transparency comes from backgroundColor)
        backgroundColor = NSColor.clear     // Transparent background - crucial for notch overlay effect
        hasShadow = false                   // No shadow to avoid visual artifacts around transparent areas
        
        // === TITLE BAR CONFIGURATION ===
        // Remove all title bar elements since we're overlaying the system UI
        titleVisibility = .hidden           // Hide the window title completely
        titlebarAppearsTransparent = true   // Make title bar area transparent
        
        // === INTERACTION CONFIGURATION ===
        isMovable = false                   // Prevent user from accidentally dragging the window
        // Note: ignoresMouseEvents is NOT set to false because we want to capture clicks/hovers
        
        // === WINDOW BEHAVIOR IN MACOS SYSTEM ===
        // Configure how this window behaves with macOS window management and spaces
        collectionBehavior = [
            .fullScreenAuxiliary,           // Allows window to appear over full-screen applications
            .stationary,                    // Window doesn't move when user switches virtual desktops/spaces
            .canJoinAllSpaces,             // Window appears on all virtual desktops/Mission Control spaces
            .ignoresCycle,                 // Window won't appear when user cycles through windows (Cmd+Tab)
        ]
        
        // === WINDOW LEVEL (CRITICAL FOR NOTCH OVERLAY) ===
        // Set window level higher than status bar to ensure it appears above menu bar and in notch area
        // .statusBar level = 25, so statusBar + 8 = 33, which puts us above menu bar but below dock
        level = .statusBar + 8              // Higher than menu bar (25) but below dock and system alerts
    }

    // === KEYBOARD FOCUS OVERRIDES ===
    // These overrides allow our window to receive keyboard focus and become the active window
    // This is important for text input and keyboard shortcuts within our notch interface
    
    override var canBecomeKey: Bool {
        // Allow this window to receive keyboard focus
        // Required for text input in search fields, clipboard operations, etc.
        true
    }

    override var canBecomeMain: Bool {
        // Allow this window to become the main (active) window
        // This enables menu bar integration and proper event handling
        true
    }
}
