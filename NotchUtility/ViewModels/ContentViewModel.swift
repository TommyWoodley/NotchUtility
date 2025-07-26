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
    @Published var clipboardService = ClipboardService()
    @Published var isDropTargetActive = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var showingSettings = false
    @Published var showingConversionMenu: UUID? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private var validationTimer: Timer?
    
    init() {
        setupBindings()
        setupFileValidation()
    }
    
    deinit {
        validationTimer?.invalidate()
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
    
    func validateFiles() {
        storageManager.validateAndCleanupFiles()
    }
    
    // MARK: - Document Conversion
    
    func convertFile(_ fileItem: FileItem, to format: ConversionFormat) {
        Task.fire {
            try await self.storageManager.convertFile(fileItem, to: format)
        } catch: { error in
            self.showError(error.localizedDescription)
        }
    }
    
    func isConverting(_ fileItem: FileItem) -> Bool {
        storageManager.convertingFiles.contains(fileItem.id)
    }
    
    func showConversionMenu(for fileItem: FileItem) {
        if fileItem.canBeConverted {
            showingConversionMenu = fileItem.id
        }
    }
    
    func hideConversionMenu() {
        showingConversionMenu = nil
    }
    
    // MARK: - Clipboard Operations
    
    func copyClipboardItem(_ item: ClipboardItem) {
        clipboardService.copyToClipboard(item)
    }
    
    func removeClipboardItem(_ item: ClipboardItem) {
        clipboardService.removeItem(item)
    }
    
    func clearClipboardHistory() {
        clipboardService.clearHistory()
    }
    
    // MARK: - UI State Management
    
    func setDropTargetActive(_ active: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isDropTargetActive = active
        }
    }
    
    func showSettings() {
        showingSettings = true
    }
    
    func hideSettings() {
        showingSettings = false
    }

    
    // MARK: - Computed Properties
    
    var hasFiles: Bool {
        !storageManager.storedFiles.isEmpty
    }
    
    var storagePercentage: Double {
        let limitBytes: Int64 = 100 * 1024 * 1024 // 100MB in bytes
        return Double(storageManager.totalStorageUsed) / Double(limitBytes)
    }
    
    var formattedStorageUsage: String {
        let usedMB = Double(storageManager.totalStorageUsed) / (1024 * 1024)
        return String(format: "%.1f MB / 100 MB", usedMB)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor storage manager for changes
        storageManager.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Monitor clipboard service for changes
        clipboardService.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func setupFileValidation() {
        // Validate files every 5 seconds to clean up any that were dragged out
        validationTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.validateFiles()
            }
        }
        
        // Also validate files when the app becomes active
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.validateFiles()
                }
            }
            .store(in: &cancellables)
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
} 