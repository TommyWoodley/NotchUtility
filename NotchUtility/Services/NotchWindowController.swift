//
//  NotchWindowController.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Cocoa
import SwiftUI

/**
 * NOTCH OVERLAY HEIGHT CONFIGURATION
 * This determines how much vertical space our overlay window takes from the top of the screen.
 * 200px is enough to accommodate the expanded notch interface without taking too much screen space.
 */
private let notchHeight: CGFloat = 200

/**
 * NotchWindowController: Manages the lifecycle and positioning of our notch overlay window
 * 
 * This is the "brain" that coordinates between the window, screen detection, and view model.
 * It handles:
 * - Creating and positioning the transparent overlay window
 * - Detecting the physical notch dimensions and position
 * - Setting up the coordinate system for notch interactions
 * - Managing the SwiftUI view hierarchy within the window
 * 
 * Architecture: Window Controller → NotchViewModel → NotchOverlayView → UI Components
 */
class NotchWindowController: NSWindowController {
    // === CORE COMPONENTS ===
    var vm: NotchViewModel?              // State management for notch behavior (open/closed/hover)
    weak var screen: NSScreen?           // Reference to the screen this notch overlay is on
    


    /**
     * Primary initializer: Sets up the notch overlay for a specific screen
     * This method does the critical work of positioning our overlay correctly relative to the physical notch
     */
    init(window: NSWindow, screen: NSScreen) {
        self.screen = screen
        super.init(window: window)

        // === NOTCH DETECTION AND MEASUREMENT ===
        // Get the actual physical notch dimensions from the screen
        var notchSize = screen.notchSize
        
        // === VIEW MODEL SETUP ===
        // Create the state manager with appropriate inset for notch vs non-notch screens
        // Real notches get -4px inset to account for the physical cutout
        // Non-notch screens (older Macs) get 0 inset
        let vm = NotchViewModel(inset: notchSize == .zero ? 0 : -4)
        self.vm = vm
        
        // === SWIFTUI INTEGRATION ===
        // Embed our SwiftUI view hierarchy into the NSWindow using NSHostingController
        contentViewController = NotchViewController(vm)

        // === FALLBACK FOR NON-NOTCH SCREENS ===
        // Older MacBooks without notches get a simulated notch area for consistent experience
        if notchSize == .zero {
            notchSize = .init(width: 150, height: 28)
        }
        
        // === COORDINATE SYSTEM SETUP (CRITICAL) ===
        // Calculate where the notch is positioned in global screen coordinates
        // macOS coordinate system: (0,0) is bottom-left, so we calculate from top
        vm.deviceNotchRect = CGRect(
            x: screen.frame.origin.x + (screen.frame.width - notchSize.width) / 2,  // Horizontally centered
            y: screen.frame.origin.y + screen.frame.height - notchSize.height,       // At the very top of screen
            width: notchSize.width,
            height: notchSize.height
        )
        
        // === WINDOW ACTIVATION ===
        // Make the window visible and active so it can capture events
        window.makeKeyAndOrderFront(nil)

        // === DELAYED INITIALIZATION ===
        // Small delay ensures window is fully set up before we start event handling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak vm] in
            vm?.screenRect = screen.frame           // Set screen bounds for coordinate calculations
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    /**
     * Convenience initializer: Creates both window and controller for a screen
     * This is the main entry point used by AppDelegate to set up notch overlays
     */
    convenience init(screen: NSScreen) {
        // === WINDOW CREATION ===
        // Create a borderless, full-size window that covers the entire screen
        let window = NotchWindow(
            contentRect: screen.frame,                              // Full screen size
            styleMask: [.borderless, .fullSizeContentView],        // No borders, content fills entire window
            backing: .buffered,                                     // Use buffered drawing for performance
            defer: false,                                           // Create window immediately
            screen: screen                                          // Associate with specific screen
        )
        
        // Initialize with the created window
        self.init(window: window, screen: screen)

        // === WINDOW POSITIONING OPTIMIZATION ===
        // Instead of covering the entire screen, we only need the top portion for the notch
        // This improves performance and reduces the area we need to handle events for
        let topRect = CGRect(
            x: screen.frame.origin.x,                              // Start at left edge of screen
            y: screen.frame.origin.y + screen.frame.height - notchHeight,  // Position at top of screen
            width: screen.frame.width,                             // Full width of screen
            height: notchHeight                                     // Only the height we need for notch UI
        )
        window.setFrameOrigin(topRect.origin)
        window.setContentSize(topRect.size)
    }

    deinit {
        destroy()
    }

    /**
     * Clean shutdown: Properly releases all resources and closes the overlay window
     * This prevents memory leaks and ensures clean app termination
     */
    func destroy() {
        vm?.destroy()              // Clean up view model and its event subscriptions
        vm = nil
        window?.close()            // Close the overlay window
        contentViewController = nil // Release the SwiftUI hosting controller
        window = nil
    }
}

/**
 * NotchViewController: Bridges NSWindow and SwiftUI for our notch interface
 * 
 * This is a specialized NSHostingController that embeds our SwiftUI NotchOverlayView
 * into the AppKit window system. It's the glue that allows us to use modern SwiftUI
 * views within the traditional NSWindow/NSViewController architecture needed for
 * precise window positioning and event handling.
 * 
 * Key responsibilities:
 * - Hosts the SwiftUI view hierarchy inside an NSWindow
 * - Passes the NotchViewModel to the SwiftUI components
 * - Handles the bridge between AppKit events and SwiftUI state
 */
class NotchViewController: NSHostingController<NotchOverlayView> {
    /**
     * Initialize with a NotchViewModel that manages the notch state
     * The view model is passed down through the SwiftUI hierarchy to coordinate
     * UI state with the underlying window positioning and event handling
     */
    init(_ vm: NotchViewModel) {
        super.init(rootView: .init(vm: vm))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("NotchViewController cannot be created from storyboards/xibs")
    }
}
