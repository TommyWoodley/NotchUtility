//
//  StorageManager.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Foundation
import Combine
import AppKit

class StorageManager: ObservableObject {
    @Published var storedFiles: [FileItem] = []
    @Published var totalStorageUsed: Int64 = 0
    
    // Configuration
    private let maxStorageSizeMB: Int64 = 100 // 100MB default
    private let defaultRetentionHours: Int = 24 // 24 hours default
    private let tempDirectoryName = "NotchUtilityTemp"
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private var cleanupTimer: Timer?
    
    // Storage directory
    private lazy var tempDirectory: URL = {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let tempDir = documentsDirectory.appendingPathComponent(tempDirectoryName)
        
        if !fileManager.fileExists(atPath: tempDir.path) {
            try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        }
        
        return tempDir
    }()
    
    init() {
        loadStoredFiles()
        setupCleanupTimer()
        calculateStorageUsed()
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func addFile(from sourceURL: URL) throws -> FileItem {
        // Check storage limit
        let fileSize = try getFileSize(at: sourceURL)
        if totalStorageUsed + fileSize > maxStorageSizeMB * 1024 * 1024 {
            throw StorageError.storageLimitExceeded
        }
        
        // Create unique filename
        let fileName = sourceURL.lastPathComponent
        let uniqueFileName = generateUniqueFileName(fileName)
        let destinationURL = tempDirectory.appendingPathComponent(uniqueFileName)
        
        // Copy file to temp directory
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        
        // Create FileItem
        let fileType = FileType.from(fileExtension: sourceURL.pathExtension)
        let fileItem = FileItem(
            name: fileName,
            path: destinationURL,
            type: fileType,
            size: fileSize
        )
        
        // Add to storage
        storedFiles.append(fileItem)
        totalStorageUsed += fileSize
        saveStoredFiles()
        
        return fileItem
    }
    
    func removeFile(_ fileItem: FileItem) throws {
        // Remove physical file
        if fileManager.fileExists(atPath: fileItem.path.path) {
            try fileManager.removeItem(at: fileItem.path)
        }
        
        // Remove from array
        storedFiles.removeAll { $0.id == fileItem.id }
        totalStorageUsed -= fileItem.size
        saveStoredFiles()
    }
    
    func removeAllFiles() throws {
        for file in storedFiles {
            if fileManager.fileExists(atPath: file.path.path) {
                try fileManager.removeItem(at: file.path)
            }
        }
        
        storedFiles.removeAll()
        totalStorageUsed = 0
        saveStoredFiles()
    }
    
    func openFile(_ fileItem: FileItem) {
        NSWorkspace.shared.open(fileItem.path)
    }
    
    func revealInFinder(_ fileItem: FileItem) {
        NSWorkspace.shared.selectFile(fileItem.path.path, inFileViewerRootedAtPath: "")
    }
    
    func copyPathToClipboard(_ fileItem: FileItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fileItem.path.path, forType: NSPasteboard.PasteboardType.string)
    }
    
    // MARK: - Configuration
    
    var storageLimit: Int64 {
        get { userDefaults.object(forKey: "storageLimit") as? Int64 ?? maxStorageSizeMB }
        set { userDefaults.set(newValue, forKey: "storageLimit") }
    }
    
    var retentionHours: Int {
        get { userDefaults.object(forKey: "retentionHours") as? Int ?? defaultRetentionHours }
        set { userDefaults.set(newValue, forKey: "retentionHours") }
    }
    
    // MARK: - Private Methods
    
    private func loadStoredFiles() {
        guard let data = userDefaults.data(forKey: "storedFiles"),
              let files = try? JSONDecoder().decode([FileItem].self, from: data) else {
            return
        }
        
        // Filter out files that no longer exist
        storedFiles = files.filter { fileManager.fileExists(atPath: $0.path.path) }
        
        // Save filtered list
        if storedFiles.count != files.count {
            saveStoredFiles()
        }
    }
    
    private func saveStoredFiles() {
        guard let data = try? JSONEncoder().encode(storedFiles) else { return }
        userDefaults.set(data, forKey: "storedFiles")
    }
    
    private func calculateStorageUsed() {
        totalStorageUsed = storedFiles.reduce(0) { $0 + $1.size }
    }
    
    private func getFileSize(at url: URL) throws -> Int64 {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
    
    private func generateUniqueFileName(_ originalName: String) -> String {
        let nameWithoutExtension = (originalName as NSString).deletingPathExtension
        let pathExtension = (originalName as NSString).pathExtension
        
        var counter = 1
        var uniqueName = originalName
        
        while fileManager.fileExists(atPath: tempDirectory.appendingPathComponent(uniqueName).path) {
            if pathExtension.isEmpty {
                uniqueName = "\(nameWithoutExtension)_\(counter)"
            } else {
                uniqueName = "\(nameWithoutExtension)_\(counter).\(pathExtension)"
            }
            counter += 1
        }
        
        return uniqueName
    }
    
    private func setupCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.performCleanup()
        }
    }
    
    private func performCleanup() {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(retentionHours * 3600))
        let filesToRemove = storedFiles.filter { $0.dateAdded < cutoffDate }
        
        for file in filesToRemove {
            try? removeFile(file)
        }
    }
}

// MARK: - Errors

enum StorageError: LocalizedError {
    case storageLimitExceeded
    case fileNotFound
    case copyFailed
    
    var errorDescription: String? {
        switch self {
        case .storageLimitExceeded:
            return "Storage limit exceeded. Please remove some files."
        case .fileNotFound:
            return "File not found."
        case .copyFailed:
            return "Failed to copy file to storage."
        }
    }
} 