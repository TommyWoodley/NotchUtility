//
//  NotchUtilityTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 24/07/2025.
//

import Testing
import Foundation
@testable import NotchUtility

struct NotchUtilityTests {

    // MARK: - FileItem Tests
    
    @Test("FileItem initialization")
    func testFileItemInitialization() async throws {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let fileItem = FileItem(
            name: "test.pdf",
            path: url,
            type: .document,
            size: 1024
        )
        
        #expect(fileItem.name == "test.pdf")
        #expect(fileItem.path == url)
        #expect(fileItem.type == .document)
        #expect(fileItem.size == 1024)
        #expect(fileItem.id != UUID())
        #expect(fileItem.dateAdded <= Date())
    }
    
    @Test("FileType detection from file extensions")
    func testFileTypeDetection() async throws {
        #expect(FileType.from(fileExtension: "pdf") == .document)
        #expect(FileType.from(fileExtension: "jpg") == .image)
        #expect(FileType.from(fileExtension: "zip") == .archive)
        #expect(FileType.from(fileExtension: "swift") == .code)
        #expect(FileType.from(fileExtension: "unknown") == .other)
        
        // Test case insensitivity
        #expect(FileType.from(fileExtension: "PDF") == .document)
        #expect(FileType.from(fileExtension: "JPG") == .image)
    }
    
    @Test("FileItem formatted size")
    func testFileItemFormattedSize() async throws {
        let fileItem = FileItem(
            name: "test.txt",
            path: URL(fileURLWithPath: "/tmp/test.txt"),
            type: .document,
            size: 1024
        )
        
        #expect(fileItem.formattedSize.contains("KB"))
    }
    
    @Test("FileItem file extension")
    func testFileItemExtension() async throws {
        let fileItem = FileItem(
            name: "test.PDF",
            path: URL(fileURLWithPath: "/tmp/test.PDF"),
            type: .document,
            size: 1024
        )
        
        #expect(fileItem.fileExtension == "pdf")
    }
    
    // MARK: - StorageManager Tests
    
    @Test("StorageManager initialization")
    func testStorageManagerInitialization() async throws {
        let storageManager = StorageManager()
        
        #expect(storageManager.storedFiles.isEmpty)
        #expect(storageManager.totalStorageUsed == 0)
    }
    
    @Test("StorageManager add file")
    func testStorageManagerAddFile() async throws {
        let storageManager = StorageManager()
        
        // Create a temporary test file
        let tempDirectory = FileManager.default.temporaryDirectory
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        let testContent = "Hello, World!"
        
        try testContent.write(to: testFile, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // Test adding file
        let fileItem = try storageManager.addFile(from: testFile)
        
        #expect(storageManager.storedFiles.count == 1)
        #expect(storageManager.storedFiles.first?.name == "test.txt")
        #expect(storageManager.storedFiles.first?.type == .other)
        #expect(storageManager.totalStorageUsed > 0)
        
        // Clean up
        try storageManager.removeFile(fileItem)
    }
    
    @Test("StorageManager remove file")
    func testStorageManagerRemoveFile() async throws {
        let storageManager = StorageManager()
        
        // Create a temporary test file
        let tempDirectory = FileManager.default.temporaryDirectory
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        let testContent = "Hello, World!"
        
        try testContent.write(to: testFile, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // Add file then remove it
        let fileItem = try storageManager.addFile(from: testFile)
        #expect(storageManager.storedFiles.count == 1)
        
        try storageManager.removeFile(fileItem)
        #expect(storageManager.storedFiles.isEmpty)
        #expect(storageManager.totalStorageUsed == 0)
    }
    
    @Test("StorageManager storage limit enforcement")
    func testStorageLimitEnforcement() async throws {
        let storageManager = StorageManager()
        let originalLimit = storageManager.storageLimit
        storageManager.storageLimit = 1 // 1MB limit for test
        
        // Create a large temporary test file (2MB)
        let tempDirectory = FileManager.default.temporaryDirectory
        let testFile = tempDirectory.appendingPathComponent("large_test.txt")
        let largeContent = String(repeating: "A", count: 2 * 1024 * 1024) // 2MB
        
        try largeContent.write(to: testFile, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // Should throw storage limit exceeded error
        #expect(throws: StorageError.self) {
            try storageManager.addFile(from: testFile)
        }
        
        // Restore original limit to not affect other tests
        storageManager.storageLimit = originalLimit
    }
    
    @Test("StorageManager unique filename generation")
    func testUniqueFilenameGeneration() async throws {
        let storageManager = StorageManager()
        
        // Create multiple files with the same name
        let tempDirectory = FileManager.default.temporaryDirectory
        let testFile1 = tempDirectory.appendingPathComponent("duplicate.txt")
        let testFile2 = tempDirectory.appendingPathComponent("duplicate.txt")
        
        try "Content 1".write(to: testFile1, atomically: true, encoding: .utf8)
        try "Content 2".write(to: testFile2, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: testFile1)
            try? FileManager.default.removeItem(at: testFile2)
        }
        
        // Add both files
        let fileItem1 = try storageManager.addFile(from: testFile1)
        let fileItem2 = try storageManager.addFile(from: testFile2)
        
        #expect(storageManager.storedFiles.count == 2)
        #expect(fileItem1.name == "duplicate.txt")
        #expect(fileItem2.name == "duplicate.txt") // Original name preserved
        #expect(fileItem1.path != fileItem2.path) // Different paths
        
        // Clean up
        try storageManager.removeFile(fileItem1)
        try storageManager.removeFile(fileItem2)
    }
}

// MARK: - ContentViewModel Tests

@MainActor
struct ContentViewModelTests {
    
    @Test("ContentViewModel initialization")
    func testContentViewModelInitialization() async throws {
        let viewModel = ContentViewModel()
        
        #expect(!viewModel.isDropTargetActive)
        #expect(!viewModel.showingError)
        #expect(!viewModel.showingSettings)
        #expect(viewModel.errorMessage.isEmpty)
        #expect(!viewModel.hasFiles)
    }
    
    @Test("ContentViewModel drop target state management")
    func testDropTargetStateManagement() async throws {
        let viewModel = ContentViewModel()
        
        viewModel.setDropTargetActive(true)
        #expect(viewModel.isDropTargetActive)
        
        viewModel.setDropTargetActive(false)
        #expect(!viewModel.isDropTargetActive)
    }
    
    @Test("ContentViewModel settings management")
    func testSettingsManagement() async throws {
        let viewModel = ContentViewModel()
        
        viewModel.showSettings()
        #expect(viewModel.showingSettings)
        
        viewModel.hideSettings()
        #expect(!viewModel.showingSettings)
    }
    
    @Test("ContentViewModel storage percentage calculation")
    func testStoragePercentageCalculation() async throws {
        let viewModel = ContentViewModel()
        
        let percentage = viewModel.storagePercentage
        #expect(percentage >= 0.0)
        #expect(percentage <= 1.0)
    }
    
    @Test("ContentViewModel formatted storage usage")
    func testFormattedStorageUsage() async throws {
        let viewModel = ContentViewModel()
        
        let formattedUsage = viewModel.formattedStorageUsage
        #expect(formattedUsage.contains("MB"))
        #expect(formattedUsage.contains("/"))
    }
}
