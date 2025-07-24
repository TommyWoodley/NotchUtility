//
//  NotchDetector.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import AppKit
import SwiftUI

class NotchDetector: ObservableObject {
    @Published var hasNotch: Bool = false
    @Published var notchDimensions: NotchDimensions = .none
    @Published var optimalPosition: CGPoint = .zero
    @Published var currentScreen: NSScreen?
    
    private var screenChangeObserver: Any?
    
    init() {
        detectNotchAndCalculatePosition()
        setupScreenChangeObserver()
    }
    
    deinit {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public Methods
    
    func detectNotchAndCalculatePosition() {
        guard let mainScreen = NSScreen.main else { return }
        
        currentScreen = mainScreen
        notchDimensions = detectNotchDimensions(for: mainScreen)
        hasNotch = notchDimensions != .none
        optimalPosition = calculateOptimalPosition(for: mainScreen)
    }
    
    func getWindowFrame(for windowSize: CGSize) -> CGRect {
        guard let screen = currentScreen else {
            return CGRect(origin: optimalPosition, size: windowSize)
        }
        
        let screenFrame = screen.frame
        let centerX = screenFrame.midX - (windowSize.width / 2)
        
        // Position just below the notch or at the top if no notch
        let yPosition = hasNotch ? 
            screenFrame.maxY - notchDimensions.height - windowSize.height - 8 :
            screenFrame.maxY - windowSize.height - 8
        
        return CGRect(
            x: centerX,
            y: yPosition,
            width: windowSize.width,
            height: windowSize.height
        )
    }
    
    // MARK: - Private Methods
    
    private func detectNotchDimensions(for screen: NSScreen) -> NotchDimensions {
        let screenSize = screen.frame.size
        let safeAreaInsets = screen.notchSafeAreaInsets
        
        // Check if there's a top safe area inset (indicating a notch)
        if safeAreaInsets.top > 0 {
            // Determine MacBook model based on screen dimensions
            if screenSize.width >= 3456 && screenSize.height >= 2234 {
                // 16-inch MacBook Pro (M1/M2/M3)
                return .macBook16Inch
            } else if screenSize.width >= 3024 && screenSize.height >= 1964 {
                // 14-inch MacBook Pro (M1/M2/M3)
                return .macBook14Inch
            } else if screenSize.width >= 2560 && screenSize.height >= 1664 {
                // 13-inch MacBook Air (M2/M3)
                return .macBookAir13Inch
            } else if screenSize.width >= 2880 && screenSize.height >= 1800 {
                // 15-inch MacBook Air (M2/M3)
                return .macBookAir15Inch
            }
        }
        
        return .none
    }
    
    private func calculateOptimalPosition(for screen: NSScreen) -> CGPoint {
        let screenFrame = screen.frame
        let centerX = screenFrame.midX
        
        if hasNotch {
            // Position just below the notch
            let yPosition = screenFrame.maxY - notchDimensions.height - 50
            return CGPoint(x: centerX, y: yPosition)
        } else {
            // Position at the top center for non-notch Macs
            let yPosition = screenFrame.maxY - 50
            return CGPoint(x: centerX, y: yPosition)
        }
    }
    
    private func setupScreenChangeObserver() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.detectNotchAndCalculatePosition()
        }
    }
}

// MARK: - NotchDimensions

enum NotchDimensions {
    case none
    case macBook14Inch
    case macBook16Inch
    case macBookAir13Inch
    case macBookAir15Inch
    
    var width: CGFloat {
        switch self {
        case .none: return 0
        case .macBook14Inch, .macBook16Inch: return 200
        case .macBookAir13Inch: return 180
        case .macBookAir15Inch: return 190
        }
    }
    
    var height: CGFloat {
        switch self {
        case .none: return 0
        case .macBook14Inch, .macBook16Inch: return 32
        case .macBookAir13Inch, .macBookAir15Inch: return 25
        }
    }
    
    var displayName: String {
        switch self {
        case .none: return "No Notch"
        case .macBook14Inch: return "14-inch MacBook Pro"
        case .macBook16Inch: return "16-inch MacBook Pro"
        case .macBookAir13Inch: return "13-inch MacBook Air"
        case .macBookAir15Inch: return "15-inch MacBook Air"
        }
    }
}

// MARK: - NSScreen Extension

extension NSScreen {
    var notchSafeAreaInsets: NSEdgeInsets {
        // Get the safe area insets from the screen
        // This is available on macOS 12.0+ for notched displays
        if #available(macOS 12.0, *) {
            return self.safeAreaInsets
        } else {
            return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
} 