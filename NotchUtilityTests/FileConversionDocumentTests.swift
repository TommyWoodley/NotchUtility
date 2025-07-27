//
//  FileConversionDocumentTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 27/07/2025.
//

import Testing
import Foundation
import AppKit
import PDFKit
@testable import NotchUtility

struct FileConversionDocumentTests {
    
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
    
    private func createTestTextFile(name: String, content: String) throws -> FileItem {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(name)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        return FileItem(
            name: fileURL.lastPathComponent,
            path: fileURL,
            type: .document,
            size: fileSize
        )
    }
    
    private func createTestRTFFile(name: String, content: String) throws -> FileItem {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(name)
        
        let attributedString = NSAttributedString(
            string: content,
            attributes: [.font: NSFont.systemFont(ofSize: 12)]
        )
        
        let rtfData = try attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        
        try rtfData.write(to: fileURL)
        
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        return FileItem(
            name: fileURL.lastPathComponent,
            path: fileURL,
            type: .document,
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
    

    
    // MARK: - Document to Document Conversion Tests
    
    @Test("Convert TXT to RTF successfully")
    func testConvertTXTToRTF() async throws {
        let testContent = "This is a test document with some sample text content."
        let testName = "test_\(UUID().uuidString).txt"
        let fileItem = try createTestTextFile(name: testName, content: testContent)
        let format = ConversionFormat.rtf
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName.hasSuffix(".rtf"))
        #expect(!result.data.isEmpty)
        
        let attributedString = try NSAttributedString(
            data: result.data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
        #expect(attributedString.string.contains("test document"))
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Convert RTF to TXT successfully")
    func testConvertRTFToTXT() async throws {
        let testContent = "This is a test RTF document with formatted text."
        let testName = "test_\(UUID().uuidString).rtf"
        let fileItem = try createTestRTFFile(name: testName, content: testContent)
        let format = ConversionFormat.txt
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName.hasSuffix(".txt"))
        #expect(!result.data.isEmpty)
        
        let convertedText = String(data: result.data, encoding: .utf8)
        #expect(convertedText?.contains("test RTF document") == true)
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Convert TXT to PDF successfully")
    func testConvertTXTToPDF() async throws {
        let testContent = "This is a test document that will be converted to PDF format."
        let testName = "test_\(UUID().uuidString).txt"
        let fileItem = try createTestTextFile(name: testName, content: testContent)
        let format = ConversionFormat.pdf
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName.hasSuffix(".pdf"))
        #expect(!result.data.isEmpty)
        
        guard let pdfDocument = PDFDocument(data: result.data) else {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Converted data is not a valid PDF"])
        }
        #expect(pdfDocument.pageCount >= 1)
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
    
    @Test("Convert RTF to PDF successfully")
    func testConvertRTFToPDF() async throws {
        let testContent = "This is a test RTF document that will be converted to PDF format."
        let testName = "test_\(UUID().uuidString).rtf"
        let fileItem = try createTestRTFFile(name: testName, content: testContent)
        let format = ConversionFormat.pdf
        
        let result = try await service.convertFile(fileItem, to: format)
        
        #expect(result.format == format)
        #expect(result.newFileName.hasSuffix(".pdf"))
        #expect(!result.data.isEmpty)
        
        guard let pdfDocument = PDFDocument(data: result.data) else {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Converted data is not a valid PDF"])
        }
        #expect(pdfDocument.pageCount >= 1)
        
        try? FileManager.default.removeItem(at: fileItem.path)
    }
} 