//
//  EventMonitors.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Cocoa
import Combine

/**
 * EventMonitors: Central coordinator for all global system event monitoring
 * 
 * This is the "nervous system" of our notch interface. It monitors global system events
 * and publishes them through Combine publishers for reactive UI updates.
 * 
 * Key responsibilities:
 * - Track mouse position globally (for hover detection over notch)
 * - Detect clicks anywhere on screen (for closing interface)
 * - Monitor file dragging (for auto-opening drop zone)
 * - Watch modifier keys (for advanced features)
 * 
 * The class uses a singleton pattern because we need exactly one global event monitoring
 * system that all components can subscribe to.
 */
class EventMonitors {
    // === SINGLETON INSTANCE ===
    static let shared = EventMonitors()

    // === EVENT MONITOR INSTANCES ===
    // Each monitor handles a specific type of global event
    private var mouseMoveEvent: EventMonitor!           // Tracks mouse cursor position
    private var mouseDownEvent: EventMonitor!           // Detects clicks anywhere on screen
    private var mouseDraggingFileEvent: EventMonitor!   // Detects file drag operations
    private var optionKeyPressEvent: EventMonitor!      // Monitors Option key for modifier actions

    // === COMBINE PUBLISHERS ===
    // These publishers emit events that UI components can subscribe to for reactive updates
    
    /// Continuously updated mouse position in global screen coordinates
    let mouseLocation: CurrentValueSubject<NSPoint, Never> = .init(.zero)
    
    /// Emits when user clicks anywhere on screen (used for closing interface)
    let mouseDown: PassthroughSubject<Void, Never> = .init()
    
    /// Emits when user is dragging files (used for auto-opening drop zone)
    let mouseDraggingFile: PassthroughSubject<Void, Never> = .init()
    
    /// Current state of Option key (for advanced UI modes)
    let optionKeyPress: CurrentValueSubject<Bool, Never> = .init(false)

    /**
     * Private initializer sets up all global event monitoring
     * This runs once when the singleton is first accessed
     */
    private init() {
        // === MOUSE MOVEMENT MONITORING ===
        // Critical for notch hover detection - we need to know mouse position at all times
        mouseMoveEvent = EventMonitor(mask: .mouseMoved) { [weak self] _ in
            guard let self else { return }
            // Get current mouse position in global coordinates (screen space)
            let mouseLocation = NSEvent.mouseLocation
            // Publish the new location for UI components to react to
            self.mouseLocation.send(mouseLocation)
        }
        mouseMoveEvent.start()

        // === MOUSE CLICK MONITORING ===
        // Used to detect clicks outside the notch interface to close it
        mouseDownEvent = EventMonitor(mask: .leftMouseDown) { [weak self] _ in
            guard let self else { return }
            // Signal that a click occurred somewhere on screen
            mouseDown.send()
        }
        mouseDownEvent.start()

        // === FILE DRAG MONITORING ===
        // Detects when user is dragging files, which should auto-open our drop zone
        mouseDraggingFileEvent = EventMonitor(mask: .leftMouseDragged) { [weak self] _ in
            guard let self else { return }
            // Note: This detects general dragging - file detection happens at drop time
            mouseDraggingFile.send()
        }
        mouseDraggingFileEvent.start()

        // === MODIFIER KEY MONITORING ===
        // Monitor Option key for advanced features (e.g., showing hidden info, alternate actions)
        optionKeyPressEvent = EventMonitor(mask: .flagsChanged) { [weak self] event in
            guard let self else { return }
            // Check if Option key is currently pressed
            if event?.modifierFlags.contains(.option) == true {
                optionKeyPress.send(true)   // Option key pressed
            } else {
                optionKeyPress.send(false)  // Option key released
            }
        }
        optionKeyPressEvent.start()
    }
} 