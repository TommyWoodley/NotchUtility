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
    case convert(ConversionFormat)
}

struct CompactFileItemView: View {
    let file: FileItem
    let isConverting: Bool
    let onAction: (FileAction, FileItem) -> Void
    
    @State private var isHovered = false
    @State private var fileExists = true
    
    var body: some View {
        VStack(spacing: 2) {
            // File thumbnail/icon with conversion overlay
            ZStack {
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
                .opacity(isConverting ? 0.6 : 1.0)
                
                // Conversion progress overlay
                if isConverting {
                    conversionOverlay
                }
            }
            
            // File name (truncated)
            Text(file.name)
                .font(.caption2)
                .lineLimit(1)
                .foregroundColor(.primary)
                .opacity(isConverting ? 0.6 : 1.0)
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
            contextMenuContent
        }
        .onTapGesture(count: 2) {
            if !isConverting {
                onAction(.open, file)
            }
        }
        .help(isConverting ? "Converting..." : file.name)
        .disabled(isConverting)
    }
    
    private var conversionOverlay: some View {
        VStack(spacing: 2) {
            ProgressView()
                .scaleEffect(0.6)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
        .padding(4)
        .cornerRadius(4)
    }
    
    @ViewBuilder private var contextMenuContent: some View {
        if !isConverting {
            Button("Open") { onAction(.open, file) }
            Button("Reveal in Finder") { onAction(.revealInFinder, file) }
            Button("Copy Path") { onAction(.copyPath, file) }
            
            // Conversion options
            if file.canBeConverted {
                Divider()
                
                Menu("Convert To") {
                    ForEach(file.supportedConversions) { format in
                        Button {
                            onAction(.convert(format), file)
                        } label: {
                            Label(format.displayName, systemImage: format.systemIcon)
                        }
                    }
                }
            }
            
            Divider()
            Button("Remove", role: .destructive) { onAction(.remove, file) }
        } else {
            Button("Converting...") { }
                .disabled(true)
        }
    }
}

// MARK: - Preview Components

#Preview("File Item - PDF") {
    CompactFileItemView(file: createMockFile(name: "Document.pdf", type: .document), isConverting: false) { action, file in
        print("Action: \(action) on file: \(file.name)")
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("File Item - Image") {
    CompactFileItemView(file: createMockFile(name: "Photo.jpg", type: .image), isConverting: false) { action, file in
        print("Action: \(action) on file: \(file.name)")
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("File Item - Converting") {
    CompactFileItemView(
        file: createMockFile(name: "Photo.jpg", type: .image),
        isConverting: true
    ) { action, file in
        print("Action: \(action) on file: \(file.name)")
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("File Item - Document") {
    CompactFileItemView(file: createMockFile(name: "Report.docx", type: .document), isConverting: false) { action, file in
        print("Action: \(action) on file: \(file.name)")
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("File Item - Archive") {
    CompactFileItemView(file: createMockFile(name: "Archive.zip", type: .archive), isConverting: false) { action, file in
        print("Action: \(action) on file: \(file.name)")
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("File Item - Long Name") {
    CompactFileItemView(file: createMockFile(name: "Very Long File Name That Should Be Truncated.pdf", type: .document), isConverting: false) { action, file in
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
            CompactFileItemView(file: file, isConverting: false) { action, file in
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
