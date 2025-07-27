//
//  FileConversionImageTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 27/07/2025.
//

import Testing
import Foundation
import AppKit
@testable import NotchUtility

struct FileConversionImageTests {
    
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
            
            switch `extension`.lowercased() {
            case "jpg", "jpeg":
                fileType = .jpeg
                properties = [.compressionFactor: 0.9]
            case "png":
                fileType = .png
                properties = [:]
            case "tiff", "tif":
                fileType = .tiff
                properties = [:]
            case "bmp":
                fileType = .bmp
                properties = [:]
            case "gif":
                fileType = .gif
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
    
    // MARK: - Image to Image Conversion Tests
    
    @Test("Convert JPEG to PNG successfully")
    func testConvertJPEGToPNG() async throws {
        let testName = "test_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "jpg")
        let format = ConversionFormat.png
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName == "\(testName).png")
        #expect(!result.data.isEmpty)
        
        guard let convertedImage = NSImage(data: result.data) else {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Converted data is not a valid image"])
        }
        #expect(convertedImage.isValid)
        
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
        
        guard let convertedImage = NSImage(data: result.data) else {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Converted data is not a valid image"])
        }
        #expect(convertedImage.isValid)
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Convert JPEG to TIFF successfully")
    func testConvertJPEGToTIFF() async throws {
        let testName = "test_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "jpg")
        let format = ConversionFormat.tiff
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName == "\(testName).tiff")
        #expect(!result.data.isEmpty)
        
        guard let convertedImage = NSImage(data: result.data) else {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Converted data is not a valid image"])
        }
        #expect(convertedImage.isValid)
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Convert PNG to BMP successfully")
    func testConvertPNGToBMP() async throws {
        let testName = "test_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "png")
        let format = ConversionFormat.bmp
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName == "\(testName).bmp")
        #expect(!result.data.isEmpty)
        
        guard let convertedImage = NSImage(data: result.data) else {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Converted data is not a valid image"])
        }
        #expect(convertedImage.isValid)
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Convert TIFF to GIF successfully")
    func testConvertTIFFToGIF() async throws {
        let testName = "test_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "tiff")
        let format = ConversionFormat.gif
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName == "\(testName).gif")
        #expect(!result.data.isEmpty)
        
        guard let convertedImage = NSImage(data: result.data) else {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Converted data is not a valid image"])
        }
        #expect(convertedImage.isValid)
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Multi-format conversion chain")
    func testMultiFormatConversionChain() async throws {
        // Test converting through multiple formats: JPEG -> PNG -> TIFF -> BMP
        let testName = "chain_test_\(UUID().uuidString)"
        let originalFileItem = try createTestFileItem(name: testName, extension: "jpg")
        
        // JPEG to PNG
        let pngResult = try await service.convertFile(originalFileItem, to: .png)
        let pngFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(pngResult.newFileName)
        try pngResult.data.write(to: pngFileURL)
        let pngFileItem = FileItem(name: pngResult.newFileName, path: pngFileURL, type: .image, size: Int64(pngResult.data.count))
        
        // PNG to TIFF
        let tiffResult = try await service.convertFile(pngFileItem, to: .tiff)
        let tiffFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(tiffResult.newFileName)
        try tiffResult.data.write(to: tiffFileURL)
        let tiffFileItem = FileItem(name: tiffResult.newFileName, path: tiffFileURL, type: .image, size: Int64(tiffResult.data.count))
        
        // TIFF to BMP
        let bmpResult = try await service.convertFile(tiffFileItem, to: .bmp)
        
        // Verify final conversion
        #expect(bmpResult.format == .bmp)
        #expect(bmpResult.newFileName == "\(testName).bmp")
        #expect(NSImage(data: bmpResult.data) != nil)
        
        // Clean up
        try? FileManager.default.removeItem(at: originalFileItem.path)
        try? FileManager.default.removeItem(at: pngFileURL)
        try? FileManager.default.removeItem(at: tiffFileURL)
    }
    
    @Test("Handle case insensitive extensions")
    func testCaseInsensitiveExtensions() async throws {
        let testName = "test_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "JPG")
        let format = ConversionFormat.png
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName == "\(testName).png")
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
} 