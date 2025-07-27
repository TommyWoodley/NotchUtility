//
//  FileConversionServiceTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 27/07/2025.
//

import Testing
import Foundation
import AppKit
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
        
        // Create a test image
        let image = createTestImage()
        
        // Save to file based on extension
        if let tiffData = image.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData) {
            
            let fileType: NSBitmapImageRep.FileType
            let properties: [NSBitmapImageRep.PropertyKey: Any]
            
            switch `extension`.lowercased() {
            case "jpg", "jpeg":
                fileType = .jpeg
                properties = [.compressionFactor: 0.9]
            case "png":
                fileType = .png
                properties = [:]
            default:
                throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unsupported format"])
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
    
    // MARK: - Success Tests
    
    @Test("Convert JPEG to PNG successfully")
    func testConvertJPEGToPNG() async throws {
        let testName = "test_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "jpg")
        let format = ConversionFormat.png
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName == "\(testName).png")
        #expect(!result.data.isEmpty)
        
        // Verify the converted data is valid PNG
        guard let convertedImage = NSImage(data: result.data) else {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Converted data is not a valid image"])
        }
        #expect(convertedImage.isValid)
        
        // Clean up
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Convert PNG to JPEG successfully")
    func testConvertPNGToJPEG() async throws {
        let testName = "test_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "png")
        let format = ConversionFormat.jpeg
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName == "\(testName).jpg")
        #expect(!result.data.isEmpty)
        
        // Verify the converted data is valid JPEG
        guard let convertedImage = NSImage(data: result.data) else {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Converted data is not a valid image"])
        }
        #expect(convertedImage.isValid)
        
        // Clean up
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Convert file with complex name")
    func testConvertFileWithComplexName() async throws {
        let testName = "my-test_file (1)_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "jpg")
        let format = ConversionFormat.png
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.newFileName == "\(testName).png")
        #expect(result.format == format)
        
        // Clean up
        try? FileManager.default.removeItem(at: fileItem.path)
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
            try await service.convertFile(fileItem, to: .png)
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    @Test("Throw sameFormat when converting to same format")
    func testSameFormatError() async throws {
        let fileItem = try createTestFileItem(name: "test_\(UUID().uuidString)", extension: "png")
        
        await #expect(throws: ConversionError.unsupportedConversion) {
            try await service.convertFile(fileItem, to: .png)
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Throw sameFormat when converting JPEG to JPEG")
    func testSameFormatErrorJPEG() async throws {
        let fileItem = try createTestFileItem(name: "test_\(UUID().uuidString)", extension: "jpeg")
        
        await #expect(throws: ConversionError.unsupportedConversion) {
            try await service.convertFile(fileItem, to: .jpeg)
        }
        
        // Clean up
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
        
        // Clean up
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - Edge Cases
    
    @Test("Handle case insensitive extensions")
    func testCaseInsensitiveExtensions() async throws {
        let testName = "test_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "JPG")
        let format = ConversionFormat.png
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName == "\(testName).png")
        
        // Clean up
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Handle files with no extension in name")
    func testFileWithNoExtensionInName() async throws {
        let testName = "testfile_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "png")
        let format = ConversionFormat.jpeg
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.newFileName == "\(testName).jpg")
        
        // Clean up
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Handle files with multiple dots in name")
    func testFileWithMultipleDots() async throws {
        let testName = "my.test.file_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "jpg")
        let format = ConversionFormat.png
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.newFileName == "\(testName).png")
        
        // Clean up
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
        
        // Clean up
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
        
        // Clean up
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
