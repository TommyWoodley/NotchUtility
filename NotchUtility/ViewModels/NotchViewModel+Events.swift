//
//  NotchViewModel+Events.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Cocoa
import Combine
import Foundation
import SwiftUI

/**
 * NotchViewModel Event Handling Extension
 * 
 * This extension contains the sophisticated event handling logic that makes the notch interface
 * feel natural and responsive. It translates raw global events (mouse position, clicks) into
 * intelligent interface behavior.
 * 
 * Key Behaviors Implemented:
 * 1. HOVER TO OPEN: Mouse over notch → interface expands
 * 2. HOVER TO CLOSE: Mouse leaves notch area → interface closes (if opened by hover)
 * 3. CLICK TO PIN: Click notch → interface stays open until clicked again
 * 4. CLICK OUTSIDE TO CLOSE: Click elsewhere → closes pinned interface
 * 5. HAPTIC FEEDBACK: Subtle vibration on interface state changes
 * 
 * The logic handles complex scenarios like:
 * - Distinguishing between hover-opened and click-opened states
 * - Preventing accidental triggers when mouse rapidly passes over notch
 * - Managing expanded interface area hover detection
 * - Providing appropriate feedback for user actions
 */
extension NotchViewModel {
    /**
     * Set up all event handling subscriptions
     * This is called once during initialization and creates reactive subscriptions
     * to global system events that control the notch interface behavior
     */
    func setupCancellables() {
        let events = EventMonitors.shared
        // === MOUSE CLICK HANDLING ===
        // This subscription handles all click behavior for opening/closing the interface
        events.mouseDown
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let mouseLocation: NSPoint = NSEvent.mouseLocation
                switch status {
                case .opened:
                    // === INTERFACE IS CURRENTLY OPEN ===
                    
                    // Click inside the notch area → always closes (toggle behavior)
                    if deviceNotchRect.insetBy(dx: inset, dy: inset).contains(mouseLocation) {
                        notchClose()
                    }
                    // Click outside interface → only close if it was click-opened (not hover-opened)
                    // This preserves hover behavior where only mouse leaving closes the interface
                    else if !notchOpenedRect.contains(mouseLocation) && openReason == .click {
                        notchClose()
                    }
                    
                case .closed, .popping:
                    // === INTERFACE IS CURRENTLY CLOSED ===
                    
                    // Click inside notch area → open and "pin" it (stays open until clicked again)
                    if deviceNotchRect.insetBy(dx: inset, dy: inset).contains(mouseLocation) {
                        notchOpen(.click)
                    }
                }
            }
            .store(in: &cancellables)

        // === OPTION KEY MONITORING ===
        // Track Option key state for advanced features (like showing detailed file info)
        events.optionKeyPress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] input in
                guard let self else { return }
                optionKeyPressed = input
            }
            .store(in: &cancellables)

        // === MOUSE HOVER HANDLING ===
        // This is the core of the hover-to-open/close behavior
        events.mouseLocation
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main) // Prevent accidental triggers from rapid mouse movement
            .sink { [weak self] mouseLocation in
                guard let self else { return }
                let mouseLocation: NSPoint = NSEvent.mouseLocation
                
                // === AREA DETECTION ===
                // Check if mouse is over the notch area or expanded interface area
                let overNotchArea = deviceNotchRect.insetBy(dx: inset, dy: inset).contains(mouseLocation)
                let overExpandedArea = notchOpenedRect.contains(mouseLocation)
                
                // === HOVER TO OPEN ===
                // Mouse enters notch area while interface is closed → open with hover behavior
                if status == .closed, overNotchArea { 
                    notchOpen(.hover)
                }
                
                // === HOVER TO CLOSE ===
                // Mouse leaves both notch and expanded areas → close if opened by hover
                // This creates intuitive behavior where hover-opened interfaces close when you move away,
                // but click-opened interfaces stay open (they require another click to close)
                if [.opened, .popping].contains(status), !overNotchArea && !overExpandedArea {
                    if openReason == .hover {
                        notchClose()
                    }
                }
            }
            .store(in: &cancellables)

        // === INTERFACE VISIBILITY MANAGEMENT ===
        // Show the interface immediately when it becomes active (opened or popping)
        $status
            .filter { $0 != .closed }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                withAnimation { self?.notchVisible = true }
            }
            .store(in: &cancellables)

        // === HAPTIC FEEDBACK TRIGGERING ===
        // Provide tactile feedback when interface opens (but not during mouse drag operations)
        $status
            .filter { $0 == .opened }
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] _ in
                // Only provide haptic feedback if user isn't dragging (no mouse buttons pressed)
                guard NSEvent.pressedMouseButtons == 0 else { return }
                self?.hapticSender.send()
            }
            .store(in: &cancellables)

        // === HAPTIC FEEDBACK EXECUTION ===
        // Actually perform the haptic feedback when requested
        hapticSender
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] _ in
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .levelChange,          // Subtle "level change" haptic (like adjusting volume)
                    performanceTime: .now  // Execute immediately
                )
            }
            .store(in: &cancellables)

        // === INTERFACE HIDING WITH DELAY ===
        // Hide the interface after a delay when it closes (allows for smooth exit animations)
        $status
            .debounce(for: 0.5, scheduler: DispatchQueue.global())  // Wait 0.5s to ensure interface is truly closed
            .filter { $0 == .closed }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                withAnimation {
                    self?.notchVisible = false  // Animate the interface out of view
                }
            }
            .store(in: &cancellables)
    }
} 