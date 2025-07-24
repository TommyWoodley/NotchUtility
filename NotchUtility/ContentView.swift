//
//  ContentView.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with storage info
                headerView
                
                Divider()
                
                // Main content area
                mainContentView
            }
            .navigationTitle("NotchUtility")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if viewModel.hasFiles {
                        Button(action: viewModel.removeAllFiles) {
                            Image(systemName: "trash")
                        }
                        .help("Clear All Files")
                    }
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }

    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Storage Usage")
                    .font(.headline)
                
                Text(viewModel.formattedStorageUsage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Storage usage bar
            ProgressView(value: viewModel.storagePercentage)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 100)
        }
        .padding()
    }
    
    private var mainContentView: some View {
        Group {
            if viewModel.hasFiles {
                fileListView
            } else {
                emptyStateView
            }
        }
    }
    
    private var fileListView: some View {
        FileGridView(files: viewModel.storageManager.storedFiles) { action, file in
            switch action {
            case .open:
                viewModel.openFile(file)
            case .revealInFinder:
                viewModel.revealInFinder(file)
            case .copyPath:
                viewModel.copyPathToClipboard(file)
            case .remove:
                viewModel.removeFile(file)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            DropZoneView(
                isActive: viewModel.isDropTargetActive,
                onFilesDropped: viewModel.handleFilesDrop,
                onDropStateChanged: viewModel.setDropTargetActive
            )
            .frame(maxWidth: 400, maxHeight: 200)
            
            VStack(spacing: 8) {
                Text("Welcome to NotchUtility")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Your temporary file storage solution")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("Drag and drop files above to get started")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}



#Preview {
    ContentView()
}
