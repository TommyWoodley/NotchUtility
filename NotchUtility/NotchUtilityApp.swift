//
//  NotchUtilityApp.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI

@main
struct NotchUtilityApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        
        Settings {
            AppSettingsView()
        }
    }
}

struct AppSettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            StorageSettingsView()
                .tabItem {
                    Label("Storage", systemImage: "externaldrive")
                }
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    
    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Show in menu bar", isOn: $showInMenuBar)
            }
            
            Section("Interface") {
                // Future UI customization options
                Text("Interface customization options coming soon...")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .navigationTitle("General")
    }
}

struct StorageSettingsView: View {
    @AppStorage("defaultStorageLimit") private var storageLimit: Int = 100
    @AppStorage("defaultRetentionHours") private var retentionHours: Int = 24
    @AppStorage("autoCleanupEnabled") private var autoCleanupEnabled = true
    
    var body: some View {
        Form {
            Section("Storage Limits") {
                HStack {
                    Text("Default storage limit (MB)")
                    Spacer()
                    TextField("MB", value: $storageLimit, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
                HStack {
                    Text("Default retention period (hours)")
                    Spacer()
                    TextField("Hours", value: $retentionHours, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
                Toggle("Enable automatic cleanup", isOn: $autoCleanupEnabled)
            }
            
            Section("File Types") {
                // Future file type filtering options
                Text("File type filtering options coming soon...")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .navigationTitle("Storage")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 8) {
                Text("NotchUtility")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0 (Phase 1)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Transform your MacBook's notch into a productive workspace")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Link("GitHub Repository", destination: URL(string: "https://github.com/user/NotchUtility")!)
                    .buttonStyle(.link)
                
                Text("Built with SwiftUI and ❤️")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("About")
    }
}
