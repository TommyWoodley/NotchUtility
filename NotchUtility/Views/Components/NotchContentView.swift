//
//  NotchContentView.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI

struct NotchContentView: View {
    @StateObject var vm: NotchViewModel
    let selectedTab: NotchTab
    
    var body: some View {
        VStack(spacing: 8) {
            // Content based on selected tab
            switch selectedTab {
            case .files:
                filesContent
            case .clipboard:
                clipboardContent
            }
        }
        .dropZone(
            isTargeted: $vm.contentViewModel.isDropTargetActive,
            onFilesDropped: vm.contentViewModel.handleFilesDrop
        )
    }
    
    private var filesContent: some View {
        VStack(spacing: 8) {
            if !vm.contentViewModel.hasFiles {
                compactDropZone
            } else {
                ZStack {
                    compactFileGrid
                    
                    if vm.contentViewModel.isDropTargetActive {
                        DropZoneView(style: .overlay, isActive: true)
                            .transition(.opacity)
                    }
                }
            }
            
            if vm.contentViewModel.hasFiles {
                quickActions
            }
        }
    }
    
    private var clipboardContent: some View {
        VStack(spacing: 8) {
            if vm.contentViewModel.clipboardService.clipboardHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("No clipboard history")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 60)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(vm.contentViewModel.clipboardService.clipboardHistory) { item in
                            CompactClipboardItemView(
                                item: item,
                                onTapped: { vm.contentViewModel.copyClipboardItem(item) },
                                onRemoved: { vm.contentViewModel.removeClipboardItem(item) }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 80)
            }
        }
    }
    
    private var compactDropZone: some View {
        DropZoneView(style: .standard, isActive: vm.contentViewModel.isDropTargetActive)
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var compactFileGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 60, maximum: 70), spacing: 6)
            ], spacing: 6) {
                ForEach(vm.contentViewModel.storageManager.storedFiles.prefix(8)) { file in
                    CompactFileItemView(file: file) { action, file in
                        handleFileAction(action, file)
                    }
                }
                
                if vm.contentViewModel.storageManager.storedFiles.count > 8 {
                    moreFilesIndicator
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxHeight: 80)
    }
    
    private var moreFilesIndicator: some View {
        VStack(spacing: 2) {
            Image(systemName: "ellipsis")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("+\(vm.contentViewModel.storageManager.storedFiles.count - 8)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 30, height: 30)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private var quickActions: some View {
        HStack(spacing: 12) {
            Button(action: vm.contentViewModel.removeAllFiles) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.caption2)
                    Text("Clear All")
                        .font(.caption2)
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
    }
    
    private func handleFileAction(_ action: FileAction, _ file: FileItem) {
        switch action {
        case .open:
            vm.contentViewModel.openFile(file)
        case .revealInFinder:
            vm.contentViewModel.revealInFinder(file)
        case .copyPath:
            vm.contentViewModel.copyPathToClipboard(file)
        case .remove:
            vm.contentViewModel.removeFile(file)
        }
    }
}

// MARK: - Preview Components

#Preview("Content - Empty Files") {
    NotchContentView(
        vm: createMockContentViewModel(hasFiles: false, hasClipboard: false),
        selectedTab: .files
    )
        .frame(width: 300, height: 200)
        .background(Color.black)
        .preferredColorScheme(.dark)
}

#Preview("Content - With Files") {
    NotchContentView(
        vm: createMockContentViewModel(hasFiles: true, hasClipboard: false),
        selectedTab: .files
    )
        .frame(width: 300, height: 200)
        .background(Color.black)
        .preferredColorScheme(.dark)
}

#Preview("Content - Many Files") {
    NotchContentView(
        vm: createMockContentViewModel(hasFiles: true, hasClipboard: false, fileCount: 12),
        selectedTab: .files
    )
        .frame(width: 300, height: 200)
        .background(Color.black)
        .preferredColorScheme(.dark)
}

#Preview("Content - Empty Clipboard") {
    NotchContentView(
        vm: createMockContentViewModel(hasFiles: false, hasClipboard: false),
        selectedTab: .clipboard
    )
    .frame(width: 300, height: 200)
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Content - With Clipboard") {
    NotchContentView(
        vm: createMockContentViewModel(hasFiles: false, hasClipboard: true),
        selectedTab: .clipboard
    )
        .frame(width: 300, height: 200)
        .background(Color.black)
        .preferredColorScheme(.dark)
}

#Preview("Content - Both Files and Clipboard") {
    NotchContentView(
        vm: createMockContentViewModel(hasFiles: true, hasClipboard: true),
        selectedTab: .files
    )
        .frame(width: 300, height: 250)
        .background(Color.black)
        .preferredColorScheme(.dark)
}

// MARK: - Preview Helper Functions

@MainActor
private func createMockContentViewModel(hasFiles: Bool, hasClipboard: Bool, fileCount: Int = 5) -> NotchViewModel {
    let vm = MockContentNotchViewModel(hasFiles: hasFiles, hasClipboard: hasClipboard, fileCount: fileCount)
    return vm
}

@MainActor
private class MockContentNotchViewModel: NotchViewModel {
    private let mockHasFiles: Bool
    private let mockHasClipboard: Bool
    private let mockFileCount: Int
    private let mockContentViewModel: MockPreviewContentViewModel
    
    init(hasFiles: Bool, hasClipboard: Bool, fileCount: Int) {
        self.mockHasFiles = hasFiles
        self.mockHasClipboard = hasClipboard
        self.mockFileCount = fileCount
        self.mockContentViewModel = MockPreviewContentViewModel(
            hasFiles: hasFiles,
            hasClipboard: hasClipboard,
            fileCount: fileCount
        )
        super.init(inset: -4)
        
        // Set up mock geometry
        deviceNotchRect = CGRect(x: 0, y: 0, width: 200, height: 30)
        screenRect = CGRect(x: 0, y: 0, width: 400, height: 250)
        
        // Replace the content view model with our mock
        contentViewModel = mockContentViewModel
        notchOpen(.click)
        destroy()
    }
}

@MainActor
private class MockPreviewContentViewModel: ContentViewModel {
    private let mockHasFiles: Bool
    private let mockHasClipboard: Bool
    private let mockFileCount: Int
    private let mockStorageManager: MockPreviewStorageManager
    private let mockClipboardService: MockPreviewClipboardService
    
    init(hasFiles: Bool, hasClipboard: Bool, fileCount: Int) {
        self.mockHasFiles = hasFiles
        self.mockHasClipboard = hasClipboard
        self.mockFileCount = fileCount
        self.mockStorageManager = MockPreviewStorageManager(fileCount: hasFiles ? fileCount : 0)
        self.mockClipboardService = MockPreviewClipboardService(hasItems: hasClipboard)
        super.init()
        
        // Replace the services with our mocks
        storageManager = mockStorageManager
        clipboardService = mockClipboardService
    }
    
    override var hasFiles: Bool {
        return mockHasFiles
    }
    
    override var formattedStorageUsage: String {
        return mockHasFiles ? "2.4 MB" : "0 KB"
    }
    
    override var isDropTargetActive: Bool {
        get { false }
        set { }
    }
}

@MainActor
private class MockPreviewStorageManager: StorageManager {
    private let mockFileCount: Int
    
    init(fileCount: Int) {
        self.mockFileCount = fileCount
        super.init()
        
        // Create mock files with variety of types
        let mockFiles = Array(0..<mockFileCount).map { index in
            let types: [FileType] = [.document, .image, .document, .archive, .other, .other, .code, .other]
            let type = types[index % types.count]
            let extensions = ["pdf", "jpg", "docx", "zip", "mp4", "mp3", "swift", "txt"]
            let ext = extensions[index % extensions.count]
            
            return FileItem(
                id: UUID(),
                name: "File\(index + 1).\(ext)",
                path: URL(fileURLWithPath: "/tmp/file\(index + 1).\(ext)"),
                type: type,
                size: Int64(1024 * (index + 1)),
                dateAdded: Date()
            )
        }
        
        // Assign to the existing mutable property
        storedFiles = mockFiles
    }
}

@MainActor
private class MockPreviewClipboardService: ClipboardService {
    private let mockHasItems: Bool
    
    init(hasItems: Bool) {
        self.mockHasItems = hasItems
        super.init()
        
        // Create mock clipboard items if needed
        if mockHasItems {
            let now = Date()
            let mockItems = [
                ClipboardItem(
                    id: UUID(),
                    content: "Hello, world!",
                    type: .text,
                    dateAdded: now.addingTimeInterval(-60),
                    changeCount: 1
                ),
                ClipboardItem(
                    id: UUID(),
                    content: "https://github.com/apple/swift",
                    type: .url,
                    dateAdded: now.addingTimeInterval(-300),
                    changeCount: 2
                ),
                ClipboardItem(
                    id: UUID(),
                    content: "screenshot.png",
                    type: .image,
                    dateAdded: now.addingTimeInterval(-600),
                    changeCount: 3
                )
            ]
            
            // Assign to the existing mutable property
            clipboardHistory = mockItems
        }
    }
} 
