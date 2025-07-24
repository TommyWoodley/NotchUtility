//
//  FileGridView.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileGridView: View {
    let files: [FileItem]
    let onFileAction: (FileAction, FileItem) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(files) { file in
                    FileItemView(file: file, onAction: onFileAction)
                }
            }
            .padding()
        }
    }
}

struct FileItemView: View {
    let file: FileItem
    let onAction: (FileAction, FileItem) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            // File thumbnail/icon
            Group {
                if let thumbnail = file.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: file.type.systemIcon)
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 48, height: 48)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            
            // File name
            Text(file.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            // File size
            Text(file.formattedSize)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 120, height: 150)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(nsColor: .controlAccentColor).opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onDrag {
            // Create drag item provider with the file URL
            let provider = NSItemProvider(object: file.path as NSURL)
            provider.suggestedName = file.name
            return provider
        }
        .contextMenu {
            Button("Open") {
                onAction(.open, file)
            }
            
            Button("Reveal in Finder") {
                onAction(.revealInFinder, file)
            }
            
            Button("Copy Path") {
                onAction(.copyPath, file)
            }
            
            Divider()
            
            Button("Remove", role: .destructive) {
                onAction(.remove, file)
            }
        }
        .onTapGesture(count: 2) {
            onAction(.open, file)
        }
    }
}

enum FileAction {
    case open
    case revealInFinder
    case copyPath
    case remove
}

#Preview {
    FileGridView(files: [
        FileItem(name: "DocumentWithManyImages.pdf", path: URL(fileURLWithPath: "/tmp/DocumentWithManyImages.pdf"), type: .document, size: 1024),
        FileItem(name: "Image.png", path: URL(fileURLWithPath: "/tmp/image.png"), type: .image, size: 2048),
        FileItem(name: "Code.swift", path: URL(fileURLWithPath: "/tmp/code.swift"), type: .code, size: 512)
    ]) { action, file in
        print("Action: \(action) on \(file.name)")
    }
    .frame(width: 300, height: 200)
} 
