//
//  NotchHeaderView.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI

enum NotchTab: String, CaseIterable {
    case files = "Files"
    case clipboard = "Clipboard"
    case tools = "Tools"
    
    var icon: String {
        switch self {
        case .files: return "tray.fill"
        case .clipboard: return "document.on.clipboard"
        case .tools: return "wrench"
        }
    }
}

struct NotchHeaderView: View {
    @StateObject var vm: NotchViewModel
    @Binding var selectedTab: NotchTab
    
    var body: some View {
        HStack {
            // Small clickable tab icons on the left
            HStack(spacing: 20) {
                ForEach(NotchTab.allCases, id: \.self) { tab in
                    Button(
                        action: {
                            selectedTab = tab
                        },
                        label: {
                            Image(systemName: tab.icon)
                                .font(.headline)
                                .foregroundColor(selectedTab == tab ? .white : .secondary)
                                .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview Components

#Preview("Header - No Files") {
    NotchHeaderView(
        vm: createMockHeaderViewModel(fileCount: 0, storageUsage: "0 KB"),
        selectedTab: .constant(.files)
    )
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}

#Preview("Header - Few Files") {
    NotchHeaderView(
        vm: createMockHeaderViewModel(fileCount: 3, storageUsage: "2.4 MB"),
        selectedTab: .constant(.files)
    )
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}

#Preview("Header - Many Files") {
    NotchHeaderView(
        vm: createMockHeaderViewModel(fileCount: 15, storageUsage: "128 MB"),
        selectedTab: .constant(.clipboard)
    )
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}

#Preview("Header - Large Storage") {
    NotchHeaderView(
        vm: createMockHeaderViewModel(fileCount: 42, storageUsage: "1.2 GB"),
        selectedTab: .constant(.files)
    )
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}

// MARK: - Preview Helper Functions

@MainActor
private func createMockHeaderViewModel(fileCount: Int, storageUsage: String) -> NotchViewModel {
    let vm = MockHeaderNotchViewModel(fileCount: fileCount, storageUsage: storageUsage)
    return vm
}

@MainActor
private class MockHeaderNotchViewModel: NotchViewModel {
    private let mockFileCount: Int
    private let mockStorageUsage: String
    private let mockContentViewModel: MockContentViewModel
    
    init(fileCount: Int, storageUsage: String) {
        self.mockFileCount = fileCount
        self.mockStorageUsage = storageUsage
        self.mockContentViewModel = MockContentViewModel(fileCount: fileCount, storageUsage: storageUsage)
        super.init(inset: -4)
        
        // Set up mock geometry
        deviceNotchRect = CGRect(x: 0, y: 0, width: 200, height: 30)
        screenRect = CGRect(x: 0, y: 0, width: 400, height: 250)
        
        // Replace the content view model with our mock
        contentViewModel = mockContentViewModel
        destroy()
    }
}

@MainActor
private class MockContentViewModel: ContentViewModel {
    private let mockFileCount: Int
    private let mockStorageUsage: String
    private let mockStorageManager: MockStorageManager
    
    init(fileCount: Int, storageUsage: String) {
        self.mockFileCount = fileCount
        self.mockStorageUsage = storageUsage
        self.mockStorageManager = MockStorageManager(fileCount: fileCount)
        super.init()
        
        // Replace the storage manager with our mock
        storageManager = mockStorageManager
    }
    
    override var hasFiles: Bool {
        mockFileCount > 0
    }
    
    override var formattedStorageUsage: String {
        mockStorageUsage
    }
}

@MainActor
private class MockStorageManager: StorageManager {
    private let mockFileCount: Int
    
    init(fileCount: Int) {
        self.mockFileCount = fileCount
        super.init()
        
        // Create mock files and assign them directly
        let mockFiles = Array(0..<mockFileCount).map { index in
            FileItem(
                id: UUID(),
                name: "File\(index + 1).pdf",
                path: URL(fileURLWithPath: "/tmp/file\(index + 1).pdf"),
                type: .document,
                size: Int64(1024 * (index + 1)),
                dateAdded: Date()
            )
        }
        
        // Assign to the existing mutable property
        storedFiles = mockFiles
    }
} 
