//
//  FileConversionParameterizedTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 27/07/2025.
//

import Testing
import Foundation
import AppKit
import PDFKit
@testable import NotchUtility

struct FileConversionParameterizedTests {
    
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
            case "webp":
                // WebP is not natively supported by NSBitmapImageRep, use PNG as fallback for test creation
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
    
    private func validateImageConversion(_ result: ConversionResult, expectedFormat: ConversionFormat, originalName: String) throws {
        #expect(result.format == expectedFormat)
        #expect(result.newFileName == "\(originalName).\(expectedFormat.targetExtension)")
        #expect(!result.data.isEmpty)
        
        guard let convertedImage = NSImage(data: result.data) else {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Converted data is not a valid image"])
        }
        #expect(convertedImage.isValid)
        
        // Note: WebP conversions currently fall back to PNG format due to NSBitmapImageRep limitations
        // The result format will still be .webp but the actual data will be PNG-compatible
    }
    
    private func validatePDFConversion(_ result: ConversionResult, originalName: String) throws {
        #expect(result.format == .pdf)
        #expect(result.newFileName == "\(originalName).pdf")
        #expect(!result.data.isEmpty)
        
        guard let pdfDocument = PDFDocument(data: result.data) else {
            throw NSError(domain: "TestError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Converted data is not a valid PDF"])
        }
        #expect(pdfDocument.pageCount == 1)
    }
    
    // MARK: - Parameterized Image-to-Image Conversion Tests
    
    @Test("Image to Image Format Conversions", arguments: [
        // JPEG conversions
        ("jpeg", ConversionFormat.png),
        ("jpeg", ConversionFormat.tiff),
        ("jpeg", ConversionFormat.bmp),
        ("jpeg", ConversionFormat.gif),
        
        // PNG conversions  
        ("png", ConversionFormat.jpeg),
        ("png", ConversionFormat.tiff),
        ("png", ConversionFormat.bmp),
        ("png", ConversionFormat.gif),
        
        // TIFF conversions
        ("tiff", ConversionFormat.jpeg),
        ("tiff", ConversionFormat.png),
        ("tiff", ConversionFormat.bmp),
        ("tiff", ConversionFormat.gif),
        
        // BMP conversions
        ("bmp", ConversionFormat.jpeg),
        ("bmp", ConversionFormat.png),
        ("bmp", ConversionFormat.tiff),
        ("bmp", ConversionFormat.gif),
        
        // GIF conversions
        ("gif", ConversionFormat.jpeg),
        ("gif", ConversionFormat.png),
        ("gif", ConversionFormat.tiff),
        ("gif", ConversionFormat.bmp),
        
        // WebP conversions
        ("webp", ConversionFormat.jpeg),
        ("webp", ConversionFormat.png),
        ("webp", ConversionFormat.tiff),
        ("webp", ConversionFormat.bmp),
        ("webp", ConversionFormat.gif)
    ])
    func testImageToImageConversion(sourceFormat: String, targetFormat: ConversionFormat) async throws {
        let testName = "test_\(sourceFormat)_to_\(targetFormat.rawValue)_\(UUID().uuidString)"
        
        let fileItem = try createTestFileItem(name: testName, extension: sourceFormat)
        
        let result = try await service.convertFile(fileItem, to: targetFormat)
        
        try validateImageConversion(result, expectedFormat: targetFormat, originalName: testName)
        
        // Clean up
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    // MARK: - Parameterized Image-to-PDF Conversion Tests
    
    @Test("Image to PDF Format Conversions", arguments: [
        "jpeg",
        "png", 
        "tiff",
        "bmp",
        "gif",
        "webp"
    ])
    func testImageToPDFConversion(sourceFormat: String) async throws {
        let testName = "test_\(sourceFormat)_to_pdf_\(UUID().uuidString)"
        
        let fileItem = try createTestFileItem(name: testName, extension: sourceFormat)
        
        let result = try await service.convertFile(fileItem, to: .pdf)
        
        try validatePDFConversion(result, originalName: testName)
        
        // Clean up
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Convert image with complex filename and special characters")
    func testComplexFilenameConversion() async throws {
        let testName = "my-test_file (1) with spaces & special chars_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "jpg")
        
        let result = try await service.convertFile(fileItem, to: .png)
        
        #expect(result.newFileName == "\(testName).png")
        #expect(result.format == .png)
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Batch conversion consistency test")
    func testBatchConversionConsistency() async throws {
        let formats = ["jpeg", "png", "tiff", "bmp"]
        var createdFiles: [URL] = []
        
        // Create multiple files and convert them all to GIF
        for format in formats {
            let testName = "batch_test_\(format)_\(UUID().uuidString)"
            let fileItem = try createTestFileItem(name: testName, extension: format)
            createdFiles.append(fileItem.path)
            
            let result = try await service.convertFile(fileItem, to: .gif)
            
            #expect(result.format == .gif)
            #expect(result.newFileName == "\(testName).gif")
            #expect(!result.data.isEmpty)
        }
        
        // Clean up
        for fileURL in createdFiles {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    @Test("Large format conversion matrix test")
    func testLargeFormatMatrix() async throws {
        let formats = ["jpeg", "png", "tiff", "bmp"]
        let targetFormats: [ConversionFormat] = [.jpeg, .png, .tiff, .bmp, .gif]
        
        for sourceFormat in formats {
            for targetFormat in targetFormats {
                // Skip same format conversions
                if sourceFormat == targetFormat.rawValue ||
                   (sourceFormat == "jpeg" && targetFormat == .jpeg) {
                    continue
                }
                
                let testName = "matrix_\(sourceFormat)_to_\(targetFormat.rawValue)_\(UUID().uuidString)"
                let fileItem = try createTestFileItem(name: testName, extension: sourceFormat)
                
                let result = try await service.convertFile(fileItem, to: targetFormat)
                
                #expect(result.format == targetFormat)
                #expect(result.newFileName == "\(testName).\(targetFormat.targetExtension)")
                #expect(!result.data.isEmpty)
                
                // Clean up
                try? FileManager.default.removeItem(at: fileItem.path)
            }
        }
    }
} 
