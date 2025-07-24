//
//  ContentViewModel.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    @Published var storageManager = StorageManager()
    @Published var isDropTargetActive = false
    @Published var showingError = false
    @Published var errorMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    // MARK: - File Operations
    
    func handleFilesDrop(_ urls: [URL]) {
        for url in urls {
            do {
                _ = try storageManager.addFile(from: url)
            } catch {
                showError(error.localizedDescription)
            }
        }
    }
    
    func removeFile(_ fileItem: FileItem) {
        do {
            try storageManager.removeFile(fileItem)
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    func removeAllFiles() {
        do {
            try storageManager.removeAllFiles()
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    func openFile(_ fileItem: FileItem) {
        storageManager.openFile(fileItem)
    }
    
    func revealInFinder(_ fileItem: FileItem) {
        storageManager.revealInFinder(fileItem)
    }
    
    func copyPathToClipboard(_ fileItem: FileItem) {
        storageManager.copyPathToClipboard(fileItem)
    }
    
    // MARK: - UI State Management
    
    func setDropTargetActive(_ active: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isDropTargetActive = active
        }
    }
    

    
    // MARK: - Computed Properties
    
    var hasFiles: Bool {
        !storageManager.storedFiles.isEmpty
    }
    
    var storagePercentage: Double {
        let limitBytes = storageManager.storageLimit * 1024 * 1024
        return Double(storageManager.totalStorageUsed) / Double(limitBytes)
    }
    
    var formattedStorageUsage: String {
        let usedMB = Double(storageManager.totalStorageUsed) / (1024 * 1024)
        let limitMB = storageManager.storageLimit
        return String(format: "%.1f MB / %lld MB", usedMB, limitMB)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor storage manager for changes
        storageManager.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
} 