//
//  AppDelegate.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import AppKit
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var isFirstOpen = true
    var mainWindowController: NotchWindowController?
    var timer: Timer?

    func applicationDidFinishLaunching(_: Notification) {
        // Set up display change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(rebuildApplicationWindows),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        // Convert to accessory app (no dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Initialize event monitors
        _ = EventMonitors.shared
        
        // Setup periodic checks
        let timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.makeKeyAndVisibleIfNeeded()
            }
        }
        self.timer = timer

        // Build the initial notch window
        rebuildApplicationWindows()
    }

    func applicationWillTerminate(_: Notification) {
        // Cleanup when app terminates
        timer?.invalidate()
        mainWindowController?.destroy()
    }

    func findScreenFitsOurNeeds() -> NSScreen? {
        // Prefer built-in display with notch, fallback to main screen
        if let screen = NSScreen.buildin, screen.notchSize != .zero { 
            return screen 
        }
        return .main
    }

    @objc func rebuildApplicationWindows() {
        defer { isFirstOpen = false }
        
        // Clean up existing window
        if let mainWindowController {
            mainWindowController.destroy()
        }
        mainWindowController = nil
        
        // Create new window for current screen configuration
        guard let mainScreen = findScreenFitsOurNeeds() else { return }
        mainWindowController = .init(screen: mainScreen)
        
        // Open on first launch
        if isFirstOpen {
            mainWindowController?.openAfterCreate = true
        }
    }

    @MainActor func makeKeyAndVisibleIfNeeded() {
        guard let controller = mainWindowController,
              let window = controller.window,
              let vm = controller.vm,
              vm.status == .opened
        else { return }
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        // Handle dock icon click or app reopen
        guard let controller = mainWindowController,
              let vm = controller.vm
        else { return true }
        Task { @MainActor in
            vm.notchOpen(.click)
        }
        return true
    }
} 