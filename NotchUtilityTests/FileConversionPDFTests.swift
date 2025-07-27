//
//  FileConversionPDFTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 27/07/2025.
//

import Testing
import Foundation
import AppKit
import PDFKit
@testable import NotchUtility

struct FileConversionPDFTests {
    
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
    
    private func createTestPDFFile(name: String) throws -> FileItem {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(name)
        
        let pdfDocument = PDFDocument()
        let image = createTestImage()
        guard let page = PDFPage(image: image) else {
            throw NSError(domain: "TestError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF page"])
        }
        pdfDocument.insert(page, at: 0)
        
        guard let pdfData = pdfDocument.dataRepresentation() else {
            throw NSError(domain: "TestError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF data"])
        }
        try pdfData.write(to: fileURL)
        
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        return FileItem(
            name: fileURL.lastPathComponent,
            path: fileURL,
            type: .document,
            size: fileSize
        )
    }
    
    // MARK: - Image to PDF Conversion Tests
    
    @Test("Convert JPEG to PDF successfully")
    func testConvertJPEGToPDF() async throws {
        let testName = "test_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "jpg")
        let format = ConversionFormat.pdf
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName == "\(testName).pdf")
        #expect(!result.data.isEmpty)
        
        guard let pdfDocument = PDFDocument(data: result.data) else {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Converted data is not a valid PDF"])
        }
        #expect(pdfDocument.pageCount == 1)
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Convert PNG to PDF successfully")
    func testConvertPNGToPDF() async throws {
        let testName = "test_\(UUID().uuidString)"
        let fileItem = try createTestFileItem(name: testName, extension: "png")
        let format = ConversionFormat.pdf
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName == "\(testName).pdf")
        #expect(!result.data.isEmpty)
        
        guard let pdfDocument = PDFDocument(data: result.data) else {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Converted data is not a valid PDF"])
        }
        #expect(pdfDocument.pageCount == 1)
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
} 
