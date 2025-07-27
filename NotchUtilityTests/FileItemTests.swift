//
//  FileItemTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 24/07/2025.
//

import Testing
import Foundation
@testable import NotchUtility

struct FileItemTests {
    
    @Test("FileItem Codable conformance")
    func testFileItemCodable() async throws {
        let uniqueId = UUID().uuidString
        let fileName = "test_\(uniqueId).pdf"
        let originalItem = FileItem(
            name: fileName,
            path: URL(fileURLWithPath: "/tmp/\(fileName)"),
            type: .document,
            size: 1024
        )
        
        // Test encoding
        let encoded = try JSONEncoder().encode(originalItem)
        #expect(!encoded.isEmpty)
        
        // Test decoding
        let decoded = try JSONDecoder().decode(FileItem.self, from: encoded)
        
        #expect(decoded.id == originalItem.id)
        #expect(decoded.name == originalItem.name)
        #expect(decoded.path == originalItem.path)
        #expect(decoded.type == originalItem.type)
        #expect(decoded.size == originalItem.size)
        #expect(decoded.dateAdded.timeIntervalSince1970.rounded() == originalItem.dateAdded.timeIntervalSince1970.rounded())
    }
    
    @Test("FileType display names")
    func testFileTypeDisplayNames() async throws {
        #expect(FileType.document.displayName == "Document")
        #expect(FileType.image.displayName == "Image")
        #expect(FileType.archive.displayName == "Archive")
        #expect(FileType.code.displayName == "Code")
        #expect(FileType.other.displayName == "Other")
    }
    
    @Test("FileType system icons")
    func testFileTypeSystemIcons() async throws {
        #expect(FileType.document.systemIcon == "doc.text")
        #expect(FileType.image.systemIcon == "photo")
        #expect(FileType.archive.systemIcon == "archivebox")
        #expect(FileType.code.systemIcon == "chevron.left.forwardslash.chevron.right")
        #expect(FileType.other.systemIcon == "questionmark.circle")
    }
    
    @Test("FileType comprehensive extension mapping")
    func testFileTypeExtensiveMapping() async throws {
        // Document types
        let documentExtensions = ["pdf", "doc", "docx", "txt", "rtf", "pages"]
        for ext in documentExtensions {
            #expect(FileType.from(fileExtension: ext) == .document)
        }
        
        // Image types
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
        for ext in imageExtensions {
            #expect(FileType.from(fileExtension: ext) == .image)
        }
        
        // Archive types
        let archiveExtensions = ["zip", "rar", "7z", "tar", "gz", "dmg", "pkg"]
        for ext in archiveExtensions {
            #expect(FileType.from(fileExtension: ext) == .archive)
        }
        
        // Code types
        let codeExtensions = ["swift", "py", "js", "ts", "html", "css", "json", "xml", "java", "cpp", "c", "h"]
        for ext in codeExtensions {
            #expect(FileType.from(fileExtension: ext) == .code)
        }
        
        // Unknown types
        let unknownExtensions = ["unknown", "xyz", "random"]
        for ext in unknownExtensions {
            #expect(FileType.from(fileExtension: ext) == .other)
        }
    }
    
    @Test("FileItem properties with various file types")
    func testFileItemWithVariousTypes() async throws {
        let testCases = [
            ("document.pdf", FileType.document),
            ("photo.jpg", FileType.image),
            ("archive.zip", FileType.archive),
            ("script.swift", FileType.code),
            ("unknown.xyz", FileType.other)
        ]
        
        for (fileName, expectedType) in testCases {
            let url = URL(fileURLWithPath: "/tmp/\(fileName)")
            let fileItem = FileItem(
                name: fileName,
                path: url,
                type: expectedType,
                size: 1024
            )
            
            #expect(fileItem.name == fileName)
            #expect(fileItem.type == expectedType)
            #expect(fileItem.fileExtension == url.pathExtension.lowercased())
            #expect(fileItem.formattedSize.contains("KB"))
        }
    }
} 