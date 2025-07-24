//
//  NotchUtilityApp.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI

@main
struct NotchUtilityApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We need to keep a Scene for app lifecycle, but it won't show
        // The actual UI is managed by the AppDelegate through NotchWindowController
        Settings {
            EmptyView()
        }
    }
}


