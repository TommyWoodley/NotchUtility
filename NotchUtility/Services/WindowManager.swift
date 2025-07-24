//
//  WindowManager.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import AppKit
import SwiftUI
import Combine

class WindowManager: ObservableObject {
    @Published var currentWindowLevel: NSWindow.Level = .floating
    @Published var alwaysOnTop: Bool = true
    
    private let notchDetector = NotchDetector()
    private weak var mainWindow: NSWindow?
    private var windowLevelObserver: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    deinit {
        windowLevelObserver?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func configureForNotchMode(_ window: NSWindow) {
        mainWindow = window
        
        // Remove all window chrome for clean floating appearance
        window.styleMask = [.borderless, .fullSizeContentView]
        
        // Make window fully transparent and floating
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.hasShadow = false  // Remove system shadow since NotchView has its own
        window.level = alwaysOnTop ? .floating : .normal
        currentWindowLevel = window.level
        
        // Configure for floating behavior - disable global window dragging
        window.isMovableByWindowBackground = false
        window.canHide = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Set initial position
        let windowSize = CGSize(width: 320, height: 200) // Default notch window size
        let newFrame = notchDetector.getWindowFrame(for: windowSize)
        window.setFrame(newFrame, display: true)
        
        // Setup window level observer
        observeWindowLevel(window)
    }
    
    func setAlwaysOnTop(_ stayOnTop: Bool) {
        alwaysOnTop = stayOnTop
        guard let window = mainWindow else { return }
        
        window.level = stayOnTop ? .floating : .normal
        currentWindowLevel = window.level
    }
    
    func updateWindowPosition() {
        guard let window = mainWindow else { return }
        
        // Update notch detection
        notchDetector.detectNotchAndCalculatePosition()
        
        // Calculate new frame
        let windowSize = window.frame.size
        let newFrame = notchDetector.getWindowFrame(for: windowSize)
        
        // Animate to new position
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        }
    }
    
    func setWindowLevel(_ level: NSWindow.Level) {
        currentWindowLevel = level
        mainWindow?.level = level
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Observe notch detector changes
        notchDetector.objectWillChange
            .sink { [weak self] in
                DispatchQueue.main.async {
                    self?.updateWindowPosition()
                }
            }
            .store(in: &cancellables)
    }
    

    
    private func observeWindowLevel(_ window: NSWindow) {
        windowLevelObserver = window.observe(\.level, options: [.new]) { [weak self] _, change in
            if let newLevel = change.newValue {
                self?.currentWindowLevel = newLevel
            }
        }
    }
    
    // MARK: - Multiple Display Support
    
    func handleDisplayChange() {
        // Delay to allow system to settle after display change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateWindowPosition()
        }
    }
    
    func moveToDisplay(_ screen: NSScreen) {
        guard let window = mainWindow else { return }
        
        // Update notch detector for new screen
        notchDetector.detectNotchAndCalculatePosition()
        
        // Calculate frame for new screen
        let windowSize = window.frame.size
        let newFrame = notchDetector.getWindowFrame(for: windowSize)
        
        // Move window to new display
        window.setFrame(newFrame, display: true)
    }
}

// MARK: - Window Level Extensions

extension NSWindow.Level {
    static let notchLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
    static let alwaysOnTop = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
}

// MARK: - WindowManager Configuration

struct WindowConfiguration {
    let isFloating: Bool
    let allowsInteraction: Bool
    let staysOnTop: Bool
    let hasBackground: Bool
    
    static let notchMode = WindowConfiguration(
        isFloating: true,
        allowsInteraction: true,
        staysOnTop: true,
        hasBackground: false
    )
    
    static let normalMode = WindowConfiguration(
        isFloating: false,
        allowsInteraction: true,
        staysOnTop: false,
        hasBackground: true
    )
} 