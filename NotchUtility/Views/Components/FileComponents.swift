//
//  FileComponents.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI

enum FileAction {
    case open
    case revealInFinder
    case copyPath
    case remove
}

struct CompactFileItemView: View {
    let file: FileItem
    let onAction: (FileAction, FileItem) -> Void
    
    @State private var isHovered = false
    @State private var fileExists = true
    
    var body: some View {
        VStack(spacing: 2) {
            // File thumbnail/icon
            Group {
                if let thumbnail = file.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: file.type.systemIcon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 50, height: 50)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(4)
            
            // File name (truncated)
            Text(file.name)
                .font(.caption2)
                .lineLimit(1)
                .foregroundColor(.primary)
        }
        .frame(width: 50, height: 70)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovered ? Color(nsColor: .controlAccentColor).opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Open") { onAction(.open, file) }
            Button("Reveal in Finder") { onAction(.revealInFinder, file) }
            Button("Copy Path") { onAction(.copyPath, file) }
            Divider()
            Button("Remove", role: .destructive) { onAction(.remove, file) }
        }
        .onTapGesture(count: 2) {
            onAction(.open, file)
        }
        .help(file.name)
    }
}

// MARK: - Preview Components

#Preview("File Item - PDF") {
    CompactFileItemView(file: createMockFile(name: "Document.pdf", type: .document)) { action, file in
        print("Action: \(action) on file: \(file.name)")
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("File Item - Image") {
    CompactFileItemView(file: createMockFile(name: "Photo.jpg", type: .image)) { action, file in
        print("Action: \(action) on file: \(file.name)")
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("File Item - Document") {
    CompactFileItemView(file: createMockFile(name: "Report.docx", type: .document)) { action, file in
        print("Action: \(action) on file: \(file.name)")
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("File Item - Archive") {
    CompactFileItemView(file: createMockFile(name: "Archive.zip", type: .archive)) { action, file in
        print("Action: \(action) on file: \(file.name)")
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("File Item - Long Name") {
    CompactFileItemView(file: createMockFile(name: "Very Long File Name That Should Be Truncated.pdf", type: .document)) { action, file in
        print("Action: \(action) on file: \(file.name)")
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("File Items - Grid") {
    LazyVGrid(columns: [
        GridItem(.adaptive(minimum: 30, maximum: 40), spacing: 6)
    ], spacing: 6) {
        ForEach(createMockFiles()) { file in
            CompactFileItemView(file: file) { action, file in
                print("Action: \(action) on file: \(file.name)")
            }
        }
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

// MARK: - Preview Helper Functions

private func createMockFile(name: String, type: FileType) -> FileItem {
    FileItem(
        id: UUID(),
        name: name,
        path: URL(fileURLWithPath: "/tmp/\(name)"),
        type: type,
        size: Int64(Int.random(in: 1024...1048576)), // 1KB to 1MB
        dateAdded: Date()
    )
}

private func createMockFiles() -> [FileItem] {
    [
        createMockFile(name: "Report.pdf", type: .document),
        createMockFile(name: "Photo.jpg", type: .image),
        createMockFile(name: "Data.xlsx", type: .document),
        createMockFile(name: "Archive.zip", type: .archive),
        createMockFile(name: "Video.mp4", type: .other),
        createMockFile(name: "Music.mp3", type: .other),
        createMockFile(name: "Script.py", type: .code),
        createMockFile(name: "Unknown.xyz", type: .other)
    ]
} 
