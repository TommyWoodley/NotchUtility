//
//  NotchViewModel.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Cocoa
import Combine
import Foundation
import SwiftUI

/**
 * NotchViewModel: The brain of the notch interface - manages all state and behavior
 * 
 * This is the central state management system that coordinates between:
 * - Global event monitoring (mouse position, clicks, drags)
 * - UI state (closed/opened/popping)
 * - Animation and visual feedback
 * - File management integration
 * 
 * The view model uses Combine to reactively update the UI based on user interactions
 * and system events. It translates low-level mouse coordinates into high-level
 * interface states (hover, click, drag).
 * 
 * Key Architecture Principles:
 * - @MainActor ensures all UI updates happen on main thread
 * - ObservableObject for SwiftUI integration
 * - Published properties for reactive UI updates
 * - Combine subscriptions for event handling
 */
@MainActor
class NotchViewModel: NSObject, ObservableObject {
    // === COMBINE SUBSCRIPTIONS ===
    var cancellables: Set<AnyCancellable> = []    // Stores all event subscriptions for cleanup
    
    // === GEOMETRY CONFIGURATION ===
    let inset: CGFloat                            // Pixel adjustment for notch positioning (-4 for real notches)
    
    // === CONTENT INTEGRATION ===
    // Bridge to the existing file management system
    @Published var contentViewModel = ContentViewModel()

    /**
     * Initialize the notch view model with positioning configuration
     * @param inset: Pixel adjustment for notch positioning (negative values move inward)
     */
    init(inset: CGFloat = -4) {
        self.inset = inset
        super.init()
        setupCancellables()    // Set up event monitoring subscriptions
    }

    deinit {
        // === CLEANUP ===
        // Ensure proper cleanup when view model is deallocated
        Task { @MainActor in
            destroy()
        }
    }

    // === ANIMATION CONFIGURATION ===
    /// Smooth spring animation for notch open/close transitions
    /// Tuned for natural feel that matches macOS system animations
    let animation: Animation = .interactiveSpring(
        duration: 0.5,          // Half second duration
        extraBounce: 0.25,      // Subtle bounce for organic feel  
        blendDuration: 0.125    // Smooth blending between animation states
    )
    
    // === INTERFACE DIMENSIONS ===
    /// Size of the expanded notch interface (width x height in pixels)
    let notchOpenedSize: CGSize = .init(width: 600, height: 170)
    
    /// Range in pixels for drag detection around notch area
    let dropDetectorRange: CGFloat = 32

    /**
     * Interface States: Represents the current state of the notch interface
     */
    enum Status: String, Codable, Hashable, Equatable {
        case closed    // Notch is hidden/minimal - normal desktop state
        case opened    // Notch is fully expanded showing interface
        case popping   // Notch is in preview/hover state (not used in current implementation)
    }

    /**
     * Open Reasons: Tracks why the interface was opened (for different behaviors)
     */
    enum OpenReason: String, Codable, Hashable, Equatable {
        case click     // User clicked on notch (interface stays open until clicked again)
        case hover     // User hovered over notch (interface closes when mouse leaves)
        case drag      // User dragged files over notch (interface closes after drop)
        case boot      // Interface opened automatically on app launch
        case unknown   // Default/unspecified reason
    }

    // === COMPUTED GEOMETRY ===
    // These computed properties calculate interface positioning based on screen dimensions
    
    /**
     * Calculate the screen rectangle for the fully expanded notch interface
     * This centers the expanded interface horizontally and positions it at the top of screen
     */
    var notchOpenedRect: CGRect {
        .init(
            x: screenRect.origin.x + (screenRect.width - notchOpenedSize.width) / 2,    // Horizontally centered
            y: screenRect.origin.y + screenRect.height - notchOpenedSize.height,        // At top of screen
            width: notchOpenedSize.width,
            height: notchOpenedSize.height
        )
    }

    /**
     * Calculate the screen rectangle for the headline/title area of expanded interface
     * This is the area that connects the physical notch to the expanded interface
     */
    var headlineOpenedRect: CGRect {
        .init(
            x: screenRect.origin.x + (screenRect.width - notchOpenedSize.width) / 2,    // Same horizontal centering
            y: screenRect.origin.y + screenRect.height - deviceNotchRect.height,        // Height of physical notch
            width: notchOpenedSize.width,
            height: deviceNotchRect.height
        )
    }

    // === PUBLISHED STATE PROPERTIES ===
    // These properties automatically trigger UI updates when changed
    
    /// Current interface state - the primary state that drives all UI behavior
    @Published private(set) var status: Status = .closed
    
    /// Why the interface was opened - determines closing behavior (hover vs click)
    @Published var openReason: OpenReason = .unknown

    /// Visual styling properties for consistent interface appearance
    @Published var spacing: CGFloat = 16         // Spacing between UI elements
    @Published var cornerRadius: CGFloat = 16    // Rounded corner radius for interface
    
    /// Geometry properties set by NotchWindowController during initialization
    @Published var deviceNotchRect: CGRect = .zero    // Physical notch dimensions and position
    @Published var screenRect: CGRect = .zero         // Full screen dimensions
    
    /// User interaction state
    @Published var optionKeyPressed: Bool = false     // Whether Option key is held down
    @Published var notchVisible: Bool = true          // Whether notch interface should be visible

    /// Haptic feedback system for user interaction confirmation
    let hapticSender = PassthroughSubject<Void, Never>()

    // === STATE MANAGEMENT METHODS ===
    
    /**
     * Open the notch interface with specified reason
     * Different reasons result in different closing behaviors:
     * - hover: closes when mouse leaves area
     * - click: stays open until clicked again
     * - drag: closes after file drop completes
     */
    func notchOpen(_ reason: OpenReason) {
        openReason = reason
        status = .opened
        // Bring our app to front so notch interface receives events properly
        NSApp.activate(ignoringOtherApps: true)
    }

    /**
     * Close the notch interface and reset to default state
     * Clears the open reason to prevent unintended behavior
     */
    func notchClose() {
        openReason = .unknown
        status = .closed
    }

    /**
     * Show preview/hover state (currently unused but available for future features)
     * Could be used for subtle preview when hovering without full expansion
     */
    func notchPop() {
        openReason = .unknown
        status = .popping
    }
    
    /**
     * Clean shutdown - cancel all event subscriptions and free resources
     * Critical for preventing memory leaks and cleaning up global event monitors
     */
    func destroy() {
        cancellables.forEach { $0.cancel() }   // Cancel all Combine subscriptions
        cancellables.removeAll()               // Clear the storage array
    }
} 
