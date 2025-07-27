//
//  DropUtility.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Foundation
import AppKit

struct DropUtility {
    static func extractURLs(from providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
        let group = DispatchGroup()
        var urls: [URL] = []
        
        for provider in providers where provider.canLoadObject(ofClass: URL.self) {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                defer { group.leave() }
                
                if let url = url, url.isFileURL {
                    urls.append(url)
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(urls)
        }
    }
    
    // MARK: - Drag Out Support
    
    /**
     * Creates an NSItemProvider for dragging a file out of the interface
     * This allows files to be dragged from the notch to Finder, Desktop, or other apps
     */
    static func createDragProvider(for fileItem: FileItem, onCompletion: @escaping () -> Void = {}) -> NSItemProvider {
        let provider = NSItemProvider()
        
        // Register the file URL for dragging with the original filename
        provider.registerFileRepresentation(
            forTypeIdentifier: "public.file-url",
            fileOptions: .openInPlace,
            visibility: .all
        ) { completion in
            // Create a temporary file with the original name for dragging
            let tempDragURL = createTempFileForDrag(fileItem: fileItem)
            completion(tempDragURL, true, nil)
            
            // Call the completion callback after a short delay to allow the drag to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onCompletion()
            }
            
            return nil
        }
        
        // Also register as a generic file for broader compatibility
        provider.registerDataRepresentation(
            forTypeIdentifier: "public.data",
            visibility: .all
        ) { completion in
            do {
                let data = try Data(contentsOf: fileItem.path)
                completion(data, nil)
            } catch {
                completion(nil, error)
            }
            return nil
        }
        
        provider.suggestedName = fileItem.name
        
        return provider
    }
    
    /**
     * Creates a temporary file with the original filename for drag operations
     * This ensures the dragged file has the correct name when dropped
     */
    private static func createTempFileForDrag(fileItem: FileItem) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let dragTempDir = tempDir.appendingPathComponent("NotchUtilityDrag")
        
        // Create drag temp directory if it doesn't exist
        try? FileManager.default.createDirectory(at: dragTempDir, withIntermediateDirectories: true)
        
        // Create temp file with original name
        let tempFileURL = dragTempDir.appendingPathComponent(fileItem.name)
        
        // Remove existing temp file if it exists
        try? FileManager.default.removeItem(at: tempFileURL)
        
        // Create hard link or copy the file with original name
        do {
            try FileManager.default.linkItem(at: fileItem.path, to: tempFileURL)
        } catch {
            // If linking fails, copy the file
            try? FileManager.default.copyItem(at: fileItem.path, to: tempFileURL)
        }
        
        return tempFileURL
    }
    
    /**
     * Creates multiple NSItemProviders for dragging multiple files
     */
    static func createDragProviders(for fileItems: [FileItem]) -> [NSItemProvider] {
        fileItems.map { createDragProvider(for: $0) }
    }
    
    /**
     * Cleans up old temporary drag files to prevent accumulation
     * Should be called periodically to maintain system cleanliness
     */
    static func cleanupTempDragFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        let dragTempDir = tempDir.appendingPathComponent("NotchUtilityDrag")
        
        guard FileManager.default.fileExists(atPath: dragTempDir.path) else { return }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: dragTempDir, includingPropertiesForKeys: [.creationDateKey])
            let cutoffDate = Date().addingTimeInterval(-3600) // Remove files older than 1 hour
            
            for fileURL in contents {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   creationDate < cutoffDate {
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
            
            // Remove the directory if it's empty
            let remainingContents = try? FileManager.default.contentsOfDirectory(at: dragTempDir, includingPropertiesForKeys: nil)
            if remainingContents?.isEmpty == true {
                try? FileManager.default.removeItem(at: dragTempDir)
            }
        } catch {
            // Silent failure for cleanup operations
        }
    }
} 
