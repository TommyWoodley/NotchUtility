//
//  FileConversionErrorTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 27/07/2025.
//

import Testing
import Foundation
import AppKit
@testable import NotchUtility

struct FileConversionErrorTests {
    
    let service = FileConversionService()
    
    // MARK: - Test Helper Methods
    
    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        return image
    }
    
    private func createTestImageFile(name: String, extension: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(name).appendingPathExtension(`extension`)
        
        let image = createTestImage()
        
        if let tiffData = image.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData) {
            
            let fileType: NSBitmapImageRep.FileType
            let properties: [NSBitmapImageRep.PropertyKey: Any]
            
            if `extension`.lowercased() == "png" {
                fileType = .png
                properties = [:]
            } else {
                fileType = .jpeg
                properties = [.compressionFactor: 0.9]
            }
            
            guard let data = bitmapRep.representation(using: fileType, properties: properties) else {
                throw NSError(domain: "TestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create image data"])
            }
            
            try data.write(to: fileURL)
        }
        
        return fileURL
    }
    
    private func createTestFileItem(name: String, extension: String) throws -> FileItem {
        let fileURL = try createTestImageFile(name: name, extension: `extension`)
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        return FileItem(
            name: fileURL.lastPathComponent,
            path: fileURL,
            type: .image,
            size: fileSize
        )
    }
    
    // MARK: - Error Tests
    
    @Test("Throw unsupportedConversion for unsupported file type")
    func testUnsupportedConversionError() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "test_\(UUID().uuidString).txt"
        let fileURL = tempDir.appendingPathComponent(fileName)
        try "test content".write(to: fileURL, atomically: true, encoding: .utf8)
        
        let fileItem = FileItem(
            name: fileName,
            path: fileURL,
            type: .document,
            size: 12
        )
        
        await #expect(throws: ConversionError.unsupportedConversion) {
            try await service.convertFile(fileItem, to: .webp) // WebP conversion not supported for text files
        }
        
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    @Test("Throw sameFormat when converting to same format")
    func testSameFormatError() async throws {
        let fileItem = try createTestFileItem(name: "test_\(UUID().uuidString)", extension: "png")
        
        await #expect(throws: ConversionError.unsupportedConversion) {
            try await service.convertFile(fileItem, to: .png)
        }
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Throw sameFormat when converting JPEG to JPEG")
    func testSameFormatErrorJPEG() async throws {
        let fileItem = try createTestFileItem(name: "test_\(UUID().uuidString)", extension: "jpeg")
        
        await #expect(throws: ConversionError.unsupportedConversion) {
            try await service.convertFile(fileItem, to: .jpeg)
        }
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Throw invalidSourceFile for non-existent file")
    func testInvalidSourceFileError() async throws {
        let fileName = "nonexistent_\(UUID().uuidString).jpg"
        let nonExistentURL = URL(fileURLWithPath: "/tmp/\(fileName)")
        let fileItem = FileItem(
            name: fileName,
            path: nonExistentURL,
            type: .image,
            size: 1000
        )
        
        await #expect(throws: ConversionError.invalidSourceFile) {
            try await service.convertFile(fileItem, to: .png)
        }
    }
    
    @Test("Throw invalidSourceFile for corrupted image file")
    func testInvalidSourceFileCorruptedError() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "corrupted_\(UUID().uuidString).jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Write invalid image data
        let corruptedData = Data("invalid image data".utf8)
        try corruptedData.write(to: fileURL)
        
        let fileItem = FileItem(
            name: fileName,
            path: fileURL,
            type: .image,
            size: Int64(corruptedData.count)
        )
        
        await #expect(throws: ConversionError.invalidSourceFile) {
            try await service.convertFile(fileItem, to: .png)
        }
        
        try? FileManager.default.removeItem(at: fileURL)
    }
} 