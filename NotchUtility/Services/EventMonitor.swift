//
//  EventMonitor.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Cocoa

/**
 * EventMonitor: A wrapper for NSEvent global monitoring
 * 
 * This class simplifies the process of monitoring global system events (mouse, keyboard)
 * that occur anywhere on the screen, even outside our application. This is essential
 * for the notch interface because we need to detect:
 * 
 * - Mouse movements over the notch area (which is technically outside our app)
 * - Clicks anywhere on screen to close the interface
 * - Keyboard shortcuts for global functionality
 * 
 * The class manages the lifecycle of NSEvent monitors and provides a clean interface
 * for starting/stopping event monitoring.
 */
class EventMonitor {
    // === MONITOR STORAGE ===
    private var monitor: Any?                                 // Holds the NSEvent monitor reference
    private let mask: NSEvent.EventTypeMask                   // Which types of events to monitor
    private let handler: (NSEvent?) -> Void                   // Callback function for when events occur

    /**
     * Initialize an event monitor for specific event types
     * 
     * @param mask: Bitmask of event types to monitor (e.g., .mouseMoved, .leftMouseDown)
     * @param handler: Closure called when matching events occur anywhere on screen
     */
    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }

    deinit {
        // === CLEANUP ===
        // Ensure we stop monitoring when this object is deallocated
        // This prevents memory leaks and removes our event handler from the system
        stop()
    }

    /**
     * Start monitoring global events
     * 
     * This registers our handler with the system to receive events of the specified types
     * that occur anywhere on screen, regardless of which app is active.
     * 
     * IMPORTANT: This requires accessibility permissions on macOS to monitor events
     * outside our own application.
     */
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }

    /**
     * Stop monitoring global events
     * 
     * This unregisters our handler from the system and cleans up resources.
     * Should be called when we no longer need to monitor events or when shutting down.
     */
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)   // Remove the global monitor
            self.monitor = nil               // Clear our reference
        }
    }
} 
