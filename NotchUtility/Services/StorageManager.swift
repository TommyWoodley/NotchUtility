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
    @Published var convertingFiles: Set<UUID> = []
    
    // Static Configuration
    private let storageLimit: Int64 = 100 // 100MB fixed
    private let retentionHours: Int = 24 // 24 hours fixed
    private let tempDirectoryName = "NotchUtilityTemp"
    
    private let fileManager = FileManager.default
    private var cleanupTimer: Timer?
    
    // Storage directory
    private lazy var tempDirectory: URL = {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
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
        // Skip hidden files (files starting with a dot)
        let fileName = sourceURL.lastPathComponent
        if fileName.hasPrefix(".") {
            throw StorageError.hiddenFileNotSupported
        }
        
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
        
        // Remove from converting files
        convertingFiles.remove(fileItem.id)
        
        saveStoredFiles()
    }

    func removeAllFiles() throws {
        for file in storedFiles where fileManager.fileExists(atPath: file.path.path) {
            try fileManager.removeItem(at: file.path)
        }
        
        storedFiles.removeAll()
        totalStorageUsed = 0
        convertingFiles.removeAll()
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
    
    func validateAndCleanupFiles() {
        let invalidFiles = storedFiles.filter { !fileManager.fileExists(atPath: $0.path.path) }
        
        for invalidFile in invalidFiles {
            storedFiles.removeAll { $0.id == invalidFile.id }
            totalStorageUsed -= invalidFile.size
            convertingFiles.remove(invalidFile.id)
        }
        
        if !invalidFiles.isEmpty {
            saveStoredFiles()
        }
    }
    
    func fileExists(_ fileItem: FileItem) -> Bool {
        fileManager.fileExists(atPath: fileItem.path.path)
    }
    
    // MARK: - Document Conversion
    
    func convertFile(_ fileItem: FileItem, to format: ConversionFormat) async throws {
        guard fileItem.canBeConverted(to: format) else {
            throw ConversionError.unsupportedConversion
        }
        
        guard format.targetExtension != fileItem.fileExtension else {
            throw ConversionError.sameFormat
        }
        
        // Mark as converting
        _ = await MainActor.run {
            convertingFiles.insert(fileItem.id)
        }
        
        do {
            // Perform the conversion
            let convertedURL = try await performConversion(fileItem: fileItem, to: format)
            
            // Replace the original file
            try await replaceFile(fileItem, with: convertedURL, newFormat: format)
            
            // Mark as done
            _ = await MainActor.run {
                convertingFiles.remove(fileItem.id)
            }
            
        } catch {
            _ = await MainActor.run {
                convertingFiles.remove(fileItem.id)
            }
            throw error
        }
    }
    
    private func performConversion(fileItem: FileItem, to format: ConversionFormat) async throws -> URL {
        try convertImageFile(fileItem: fileItem, to: format)
    }
    
    private func convertImageFile(fileItem: FileItem, to format: ConversionFormat) throws -> URL {
        guard let image = NSImage(contentsOf: fileItem.path) else {
            throw ConversionError.invalidSourceFile
        }
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            throw ConversionError.conversionFailed
        }
        
        let fileType: NSBitmapImageRep.FileType
        let properties: [NSBitmapImageRep.PropertyKey: Any]
        
        switch format.targetExtension.lowercased() {
        case "jpg", "jpeg":
            fileType = .jpeg
            properties = [NSBitmapImageRep.PropertyKey.compressionFactor: 0.9]
        case "png":
            fileType = .png
            properties = [:]
        default:
            throw ConversionError.unsupportedFormat
        }
        
        guard let convertedData = bitmapRep.representation(using: fileType, properties: properties) else {
            throw ConversionError.conversionFailed
        }
        
        // Create output filename
        let nameWithoutExtension = (fileItem.name as NSString).deletingPathExtension
        let convertedFileName = "\(nameWithoutExtension).\(format.targetExtension)"
        let convertedURL = tempDirectory.appendingPathComponent(convertedFileName)
        
        // Write converted file
        try convertedData.write(to: convertedURL)
        
        return convertedURL
    }
    
    private func replaceFile(_ originalItem: FileItem, with convertedURL: URL, newFormat: ConversionFormat) async throws {
        _ = await MainActor.run {
            // Remove original file from storage
            if fileManager.fileExists(atPath: originalItem.path.path) {
                try? fileManager.removeItem(at: originalItem.path)
            }
            
            // Update the file item with new information
            if let index = storedFiles.firstIndex(where: { $0.id == originalItem.id }) {
                let newSize = (try? getFileSize(at: convertedURL)) ?? 0
                let newHash = (try? computeFileHash(at: convertedURL)) ?? ""
                let newType = FileType.from(fileExtension: newFormat.targetExtension)
                let nameWithoutExtension = (originalItem.name as NSString).deletingPathExtension
                let newName = "\(nameWithoutExtension).\(newFormat.targetExtension)"
                
                let updatedItem = FileItem(
                    id: originalItem.id, // Keep the same ID
                    name: newName,
                    path: convertedURL,
                    type: newType,
                    size: newSize,
                    dateAdded: originalItem.dateAdded,
                    contentHash: newHash
                )
                
                // Update storage tracking
                totalStorageUsed = totalStorageUsed - originalItem.size + newSize
                
                // Replace in array
                storedFiles[index] = updatedItem
                
                saveStoredFiles()
            }
        }
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
            // Skip hidden files (files starting with a dot)
            let fileName = fileURL.lastPathComponent
            if fileName.hasPrefix(".") {
                continue
            }
            
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
            Task { @MainActor in
                self.performCleanup()
            }
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
