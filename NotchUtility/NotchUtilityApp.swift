//
//  NotchUtilityApp.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI

@main
struct NotchUtilityApp: App {
    @StateObject private var windowManager = WindowManager()
    
    var body: some Scene {
        WindowGroup {
            NotchAppView()
                .environmentObject(windowManager)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
    }
}

struct NotchAppView: View {
    @EnvironmentObject var windowManager: WindowManager
    @State private var windowConfigured = false
    
    var body: some View {
        NotchView()
            .background(WindowConfiguratorView())
            .onAppear {
                if !windowConfigured {
                    configureWindow()
                    windowConfigured = true
                }
            }
    }
    
    private func configureWindow() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                windowManager.configureForNotchMode(window)
            }
        }
    }
}



struct WindowConfiguratorView: NSViewRepresentable {
    @EnvironmentObject var windowManager: WindowManager
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        DispatchQueue.main.async {
            if let window = view.window {
                windowManager.configureForNotchMode(window)
                
                // Setup display change notifications
                NotificationCenter.default.addObserver(
                    forName: NSApplication.didChangeScreenParametersNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    windowManager.handleDisplayChange()
                }
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // No updates needed
    }
}


