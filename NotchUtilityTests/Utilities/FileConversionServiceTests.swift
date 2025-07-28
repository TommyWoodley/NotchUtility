//
//  FileConversionServiceTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 27/07/2025.
//

import Testing
import Foundation
import AppKit
import PDFKit
@testable import NotchUtility

struct FileConversionServiceTests {
    
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
    
    // MARK: - Legacy Tests (Basic Functionality)
    
    @Test("Convert file with complex name")
    func testConvertFileWithComplexName() async throws {
        let testName = "my-test_file (1)_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "jpg")
        let format = ConversionFormat.png
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.newFileName == "\(testName).png")
        #expect(result.format == format)
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Handle files with no extension in name")
    func testFileWithNoExtensionInName() async throws {
        let testName = "testfile_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "png")
        let format = ConversionFormat.jpeg
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.newFileName == "\(testName).jpg")
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Handle files with multiple dots in name")
    func testFileWithMultipleDots() async throws {
        let testName = "my.test.file_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "jpg")
        let format = ConversionFormat.png
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.newFileName == "\(testName).png")
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    

    
    // MARK: - ConversionResult Tests
    
    @Test("ConversionResult contains correct data")
    func testConversionResultData() async throws {
        let fileItem = try createTestFileItem(name: "test_\(UUID().uuidString)", extension: "jpg")
        let format = ConversionFormat.png
        
        let result = try await service.convertFile(fileItem, to: format)
        
        // Verify all fields are correctly populated
        #expect(result.format == format)
        #expect(result.newFileName.hasSuffix(".png"))
        #expect(!result.data.isEmpty)
        
        // Verify the data is a valid image
        let image = NSImage(data: result.data)
        #expect(image != nil)
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    // MARK: - Performance Tests
    
    @Test("Conversion performance within reasonable time")
    func testConversionPerformance() async throws {
        let fileItem = try createTestFileItem(name: "performance_test_\(UUID().uuidString)", extension: "jpg")
        let format = ConversionFormat.png
        
        let startTime = Date()
        let result = try await service.convertFile(fileItem, to: format)
        let endTime = Date()
        
        let conversionTime = endTime.timeIntervalSince(startTime)
        
        // Conversion should complete within 5 seconds for a small test image
        #expect(conversionTime < 5.0)
        #expect(!result.data.isEmpty)
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    // MARK: - Integration Tests
    
    @Test("Full conversion workflow integration")
    func testFullConversionWorkflow() async throws {
        // Test the complete workflow from file creation to conversion
        let testName = "workflow_test_\(UUID().uuidString)"
        let originalFileItem = try createTestFileItem(name: testName, extension: "jpg")
        
        // Convert to PNG
        let pngResult = try await service.convertFile(originalFileItem, to: .png)
        
        // Verify PNG conversion
        #expect(pngResult.format == .png)
        #expect(pngResult.newFileName == "\(testName).png")
        
        // Create a new FileItem from the converted data for reverse conversion
        let pngFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(pngResult.newFileName)
        try pngResult.data.write(to: pngFileURL)
        
        let pngFileItem = FileItem(
            name: pngResult.newFileName,
            path: pngFileURL,
            type: .image,
            size: Int64(pngResult.data.count)
        )
        
        // Convert back to JPEG
        let jpegResult = try await service.convertFile(pngFileItem, to: .jpeg)
        
        // Verify JPEG conversion
        #expect(jpegResult.format == .jpeg)
        #expect(jpegResult.newFileName == "\(testName).jpg")
        
        // Clean up
        try? FileManager.default.removeItem(at: originalFileItem.path)
        try? FileManager.default.removeItem(at: pngFileURL)
    }
} 
