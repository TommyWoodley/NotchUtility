//
//  StorageManager.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Foundation
import Combine
import AppKit
import CryptoKit

class StorageManager: ObservableObject {
    @Published var storedFiles: [FileItem] = []
    @Published var totalStorageUsed: Int64 = 0
    
    // Static Configuration
    private let storageLimit: Int64 = 100 // 100MB fixed
    private let retentionHours: Int = 24 // 24 hours fixed
    private let tempDirectoryName = "NotchUtilityTemp"
    
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
        // Check if file already exists by computing its hash
        let sourceFileHash = try computeFileHash(at: sourceURL)
        
        if let existingFile = storedFiles.first(where: { $0.contentHash == sourceFileHash }) {
            throw StorageError.duplicateFile(existingFile.name)
        }
        
        // Check storage limit
        let fileSize = try getFileSize(at: sourceURL)
        if totalStorageUsed + fileSize > storageLimit * 1024 * 1024 {
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
            size: fileSize,
            contentHash: sourceFileHash
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
    

    
    // MARK: - Private Methods
    
    private func loadStoredFiles() {
        // For static configuration, we don't persist files between app launches
        // Files are temporary and will be discovered on startup by scanning the temp directory
        storedFiles = []
        
        // Scan temp directory for existing files
        let tempDir = tempDirectory
        guard let contents = try? fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]) else {
            return
        }
        
        for fileURL in contents {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let fileSize = attributes[.size] as? Int64,
               let creationDate = attributes[.creationDate] as? Date {
                
                let fileType = FileType.from(fileExtension: fileURL.pathExtension)
                let contentHash = (try? computeFileHash(at: fileURL)) ?? ""
                
                let fileItem = FileItem(
                    id: UUID(),
                    name: fileURL.lastPathComponent,
                    path: fileURL,
                    type: fileType,
                    size: fileSize,
                    dateAdded: creationDate,
                    contentHash: contentHash
                )
                storedFiles.append(fileItem)
            }
        }
    }
    
    private func saveStoredFiles() {
        // No persistence needed for static configuration
        // Files exist in the filesystem, that's our storage
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
    
    private func computeFileHash(at url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Errors

enum StorageError: LocalizedError {
    case storageLimitExceeded
    case fileNotFound
    case copyFailed
    case duplicateFile(String)
    
    var errorDescription: String? {
        switch self {
        case .storageLimitExceeded:
            return "Storage limit exceeded. Please remove some files."
        case .fileNotFound:
            return "File not found."
        case .copyFailed:
            return "Failed to copy file to storage."
        case .duplicateFile(let fileName):
            return "File '\(fileName)' already exists in storage."
        }
    }
} 