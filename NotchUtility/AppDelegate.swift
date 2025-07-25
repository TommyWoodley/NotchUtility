//
//  AppDelegate.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import AppKit
import Cocoa

/**
 * AppDelegate: Application lifecycle manager and notch system coordinator
 * 
 * This is the entry point and coordinator for the entire notch overlay system.
 * It manages:
 * - App initialization as an accessory (background) app
 * - Creating and managing the transparent overlay windows
 * - Responding to display configuration changes
 * - Coordinating between multiple screens
 * - Ensuring the overlay stays active and responsive
 * 
 * Key Architecture:
 * - Accessory app: No dock icon, runs in background
 * - Screen-aware: Automatically adapts to display changes
 * - Self-healing: Periodically ensures overlay windows stay active
 * - Multi-screen: Handles multiple displays appropriately
 */
class AppDelegate: NSObject, NSApplicationDelegate {
    // === STATE TRACKING ===
    var mainWindowController: NotchWindowController?    // The primary notch overlay controller
    var timer: Timer?                                   // Periodic maintenance timer

    /**
     * Application launch: Set up the entire notch overlay system
     * This is called once when the app starts and initializes all core systems
     */
    func applicationDidFinishLaunching(_: Notification) {
        // === DISPLAY CHANGE MONITORING ===
        // Listen for screen configuration changes (resolution, arrangement, connection/disconnection)
        // When displays change, we need to rebuild our overlay windows to match the new configuration
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(rebuildApplicationWindows),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        // === ACCESSORY APP CONFIGURATION ===
        // Convert to accessory app mode: no dock icon, no menu bar presence
        // This allows us to run in the background without cluttering the user's dock
        NSApp.setActivationPolicy(.accessory)

        // === GLOBAL EVENT SYSTEM INITIALIZATION ===
        // Initialize the global event monitoring system (singleton pattern)
        // This starts monitoring mouse position, clicks, and keyboard events system-wide
        _ = EventMonitors.shared
        
        // === MAINTENANCE TIMER SETUP ===
        // Set up periodic checks to ensure our overlay windows stay active and responsive
        // macOS can sometimes deactivate windows, so we periodically re-assert visibility
        let timer = Timer.scheduledTimer(
            withTimeInterval: 5,          // Check every 5 seconds
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.makeKeyAndVisibleIfNeeded()
            }
        }
        self.timer = timer

        // === INITIAL WINDOW CREATION ===
        // Create the first notch overlay window for the current screen configuration
        rebuildApplicationWindows()
    }

    /**
     * Clean shutdown: Properly cleanup all resources when app terminates
     * This prevents memory leaks and ensures clean exit
     */
    func applicationWillTerminate(_: Notification) {
        timer?.invalidate()               // Stop periodic maintenance timer
        mainWindowController?.destroy()   // Cleanup overlay window and event subscriptions
    }

    /**
     * Smart screen selection: Choose the best screen for notch overlay
     * 
     * Priority order:
     * 1. Built-in display with actual notch (MacBook Pro 2021+)
     * 2. Main display (fallback for older MacBooks or external setups)
     * 
     * This ensures we show the interface where it makes the most sense
     */
    func findScreenFitsOurNeeds() -> NSScreen? {
        // First preference: Built-in laptop display with actual physical notch
        if let screen = NSScreen.buildin, screen.notchSize != .zero { 
            return screen 
        }
        // Fallback: Main display (works on older MacBooks without notches)
        return .main
    }

    /**
     * Rebuild overlay windows: Recreate the notch interface for current screen setup
     * 
     * This is called:
     * - On app launch
     * - When display configuration changes (resolution, arrangement, new displays)
     * - When recovering from system sleep/wake
     * 
     * The method ensures we always have the correct overlay window for the current setup
     */
    @objc 
    func rebuildApplicationWindows() {
        // === CLEANUP EXISTING OVERLAY ===
        // Destroy any existing overlay window and free its resources
        if let mainWindowController {
            mainWindowController.destroy()
        }
        mainWindowController = nil
        
        // === CREATE NEW OVERLAY ===
        // Build new overlay window for the current optimal screen
        guard let mainScreen = findScreenFitsOurNeeds() else { return }
        mainWindowController = .init(screen: mainScreen)
    }

    /**
     * Maintenance function: Ensure overlay window stays active when interface is open
     * 
     * macOS can sometimes deactivate windows or change window ordering.
     * This function periodically checks if our overlay should be key and visible,
     * and re-asserts it if needed. Called every 5 seconds by maintenance timer.
     */
    @MainActor 
    func makeKeyAndVisibleIfNeeded() {
        guard let controller = mainWindowController,
              let window = controller.window,
              let vm = controller.vm,
              vm.status == .opened        // Only make key when interface is actually open
        else { return }
        window.makeKeyAndOrderFront(nil)  // Bring window to front and make it active
    }

    /**
     * Handle app reactivation: Respond to dock icon clicks or app reopening
     * 
     * Since we're an accessory app (no dock icon), this mainly handles:
     * - Spotlight launching
     * - AppleScript/automation opening
     * - System attempts to reopen the app
     * 
     * Response: Open the notch interface to show the user the app is active
     */
    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        guard let controller = mainWindowController,
              let vm = controller.vm
        else { return true }
        Task { @MainActor in
            vm.notchOpen(.click)  // Open with click behavior (stays open)
        }
        return true
    }
} 
