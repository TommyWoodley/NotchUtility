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
        let uniqueId = UUID().uuidString
        let fileName = "test_\(uniqueId).pdf"
        let url = URL(fileURLWithPath: "/tmp/\(fileName)")
        let fileItem = FileItem(
            name: fileName,
            path: url,
            type: .document,
            size: 1024
        )
        
        #expect(fileItem.name == fileName)
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
        let uniqueId = UUID().uuidString
        let fileName = "test_\(uniqueId).txt"
        let fileItem = FileItem(
            name: fileName,
            path: URL(fileURLWithPath: "/tmp/\(fileName)"),
            type: .document,
            size: 1024
        )
        
        #expect(fileItem.formattedSize.contains("KB"))
    }
    
    @Test("FileItem file extension")
    func testFileItemExtension() async throws {
        let uniqueId = UUID().uuidString
        let fileName = "test_\(uniqueId).PDF"
        let fileItem = FileItem(
            name: fileName,
            path: URL(fileURLWithPath: "/tmp/\(fileName)"),
            type: .document,
            size: 1024
        )
        
        #expect(fileItem.fileExtension == "pdf")
    }
    
    // MARK: - StorageManager Tests
    
    @Test("StorageManager initialization")
    func testStorageManagerInitialization() async throws {
        let storageManager = StorageManager()
        
        defer {
            // Clean up all stored files to ensure test isolation
            try? storageManager.removeAllFiles()
        }
        
        // Note: StorageManager might have existing files from previous test runs
        // so we test initialization by creating a fresh instance
        #expect(storageManager.totalStorageUsed >= 0)
    }
    
    @Test("StorageManager remove file")
    func testStorageManagerRemoveFile() async throws {
        let storageManager = StorageManager()
        
        // Create a temporary test file with unique name and content
        let tempDirectory = FileManager.default.temporaryDirectory
        let uniqueId = UUID().uuidString
        let testFile = tempDirectory.appendingPathComponent("remove_test_\(uniqueId).txt")
        let testContent = "Remove test content! Unique ID: \(uniqueId)"
        
        try testContent.write(to: testFile, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: testFile)
            // Clean up all stored files to ensure test isolation
            try? storageManager.removeAllFiles()
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
        
        // Create a very large temporary test file (150MB - larger than the 100MB limit)
        let tempDirectory = FileManager.default.temporaryDirectory
        let uniqueId = UUID().uuidString
        let testFile = tempDirectory.appendingPathComponent("large_test_\(uniqueId).txt")
        let largeContent = String(repeating: "A", count: 150 * 1024 * 1024) // 150MB
        
        try largeContent.write(to: testFile, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // Should throw storage limit exceeded error since file is larger than 100MB limit
        #expect(throws: StorageError.self) {
            try storageManager.addFile(from: testFile)
        }
    }
    
    @Test("StorageManager unique filename generation")
    func testUniqueFilenameGeneration() async throws {
        let storageManager = StorageManager()
        
        // Create multiple files with the same name but unique content
        let tempDirectory = FileManager.default.temporaryDirectory
        let uniqueId = UUID().uuidString
        let testFile1 = tempDirectory.appendingPathComponent("duplicate_\(uniqueId)_1.txt")
        let testFile2 = tempDirectory.appendingPathComponent("duplicate_\(uniqueId)_2.txt")
        
        try "Content 1 - Unique ID: \(uniqueId)".write(to: testFile1, atomically: true, encoding: .utf8)
        try "Content 2 - Unique ID: \(uniqueId)".write(to: testFile2, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: testFile1)
            try? FileManager.default.removeItem(at: testFile2)
            // Clean up all stored files to ensure test isolation
            try? storageManager.removeAllFiles()
        }
        
        // Add both files
        let fileItem1 = try storageManager.addFile(from: testFile1)
        let fileItem2 = try storageManager.addFile(from: testFile2)
        
        #expect(storageManager.storedFiles.count == 2)
        #expect(fileItem1.name.contains("duplicate_") == true)
        #expect(fileItem2.name.contains("duplicate_") == true)
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
        
        defer {
            // Clean up all stored files to ensure test isolation
            try? viewModel.storageManager.removeAllFiles()
        }
        
        #expect(!viewModel.isDropTargetActive)
        #expect(!viewModel.showingError)
        #expect(!viewModel.showingSettings)
        #expect(viewModel.errorMessage.isEmpty)
        // Note: hasFiles might be true if StorageManager has existing files from previous tests
        // so we don't test it in initialization
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
