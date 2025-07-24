//
//  NSScreen+NotchDetection.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Cocoa

/**
 * NSScreen Extension: Advanced notch detection for MacBook Pro models
 * 
 * This extension provides precise methods for detecting and measuring the physical notch
 * on newer MacBook Pro models. It uses Apple's safe area APIs to determine the exact
 * dimensions and position of the notch cutout in the display.
 * 
 * The math here is critical for proper positioning of our overlay interface.
 */
extension NSScreen {
    /**
     * Calculate the precise size of the notch cutout
     * 
     * How it works:
     * 1. Check if screen has any top safe area inset (indicates notch presence)
     * 2. Use auxiliary areas to calculate usable space on left and right of notch
     * 3. Subtract those areas from total width to get notch width
     * 
     * Returns: CGSize with exact notch dimensions, or .zero for non-notch screens
     */
    var notchSize: CGSize {
        // === NOTCH PRESENCE CHECK ===
        // If safeAreaInsets.top is 0, there's no notch on this screen
        guard safeAreaInsets.top > 0 else { return .zero }
        
        // === NOTCH HEIGHT CALCULATION ===
        // The top safe area inset equals the notch height
        let notchHeight = safeAreaInsets.top
        
        // === SCREEN WIDTH MEASUREMENT ===
        let fullWidth = frame.width
        
        // === AUXILIARY AREA CALCULATION ===
        // These areas represent the usable space on either side of the notch
        // where the menu bar and system UI elements can be placed
        let leftPadding = auxiliaryTopLeftArea?.width ?? 0      // Menu bar area width
        let rightPadding = auxiliaryTopRightArea?.width ?? 0    // Control center/wifi icons area width
        
        // === VALIDATION ===
        // Both areas should exist on notched MacBooks - if not, something's wrong
        guard leftPadding > 0, rightPadding > 0 else { return .zero }
        
        // === NOTCH WIDTH CALCULATION ===
        // The notch width is the screen width minus the usable areas on both sides
        // Example: 3024px total - 300px left - 300px right = 2424px notch width
        let notchWidth = fullWidth - leftPadding - rightPadding
        
        return CGSize(width: notchWidth, height: notchHeight)
    }

    /**
     * Determine if this is the built-in laptop display (vs external monitor)
     * 
     * This is important because:
     * - Only built-in displays have notches (for now)
     * - We want to position our overlay only on the main laptop screen
     * - External monitors should not show notch interface
     * 
     * Returns: true if this is the laptop's built-in display, false for external monitors
     */
    var isBuildinDisplay: Bool {
        // === SCREEN ID EXTRACTION ===
        // Get the Core Graphics display ID for this screen from device description
        let screenNumberKey = NSDeviceDescriptionKey(rawValue: "NSScreenNumber")
        guard let id = deviceDescription[screenNumberKey],
              let rid = (id as? NSNumber)?.uint32Value,    // Convert to display ID
              CGDisplayIsBuiltin(rid) == 1                 // Check if built-in (returns 1 for built-in, 0 for external)
        else { return false }
        return true
    }

    /**
     * Convenience method to find the built-in laptop display
     * 
     * This is the primary screen we want to show our notch interface on.
     * On multi-monitor setups, this ensures we only show the overlay on the laptop screen.
     * 
     * Returns: The built-in NSScreen if found, nil if no built-in display detected
     */
    static var buildin: NSScreen? {
        screens.first { $0.isBuildinDisplay }
    }
}
