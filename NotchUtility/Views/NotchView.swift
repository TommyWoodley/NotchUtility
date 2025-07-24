//
//  NotchView.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI

struct NotchView: View {
    @StateObject private var viewModel = ContentViewModel()
    @EnvironmentObject var windowManager: WindowManager
    @StateObject private var notchDetector = NotchDetector()
    
    @State private var isExpanded = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact notch bar
            notchBar
            
            // Expandable content area
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
        .frame(width: 250, height: 200, alignment: .top)
    }
    
    private var notchBar: some View {
        HStack(spacing: 8) {
            // Storage indicator
            storageIndicator
            
            Spacer()
            
            // File count badge
            if viewModel.hasFiles {
                fileCountBadge
            }
            
            // Expand/collapse indicator
            expandIndicator
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(isHovered ? 0.1 : 0.05))
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Move the window as the user drags
                    if let window = NSApplication.shared.windows.first {
                        let currentLocation = window.frame.origin
                        let newLocation = CGPoint(
                            x: currentLocation.x + value.translation.width,
                            y: currentLocation.y - value.translation.height // Invert Y coordinate
                        )
                        window.setFrameOrigin(newLocation)
                    }
                }
        )
    }
    
    private var storageIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "internaldrive")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(viewModel.formattedStorageUsage)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var fileCountBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.on.doc")
                .font(.caption2)
            
            Text("\(viewModel.storageManager.storedFiles.count)")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.accentColor.opacity(0.8))
        .foregroundColor(.white)
        .clipShape(Capsule())
    }
    
    private var expandIndicator: some View {
        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.caption2)
            .foregroundColor(.secondary)
            .rotationEffect(.degrees(isExpanded ? 180 : 0))
    }
    
    private var expandedContent: some View {
        VStack(spacing: 12) {
            // Drop zone when no files
            if !viewModel.hasFiles {
                compactDropZone
            } else {
                // Compact file grid with overlay feedback
                ZStack {
                    compactFileGrid
                    
                    // Drop overlay when active
                    if viewModel.isDropTargetActive {
                        DropZoneView(style: .overlay, isActive: true)
                            .transition(.opacity)
                    }
                }
            }
            
            // Quick actions
            quickActions
        }
        .padding(12)
        .dropZone(
            isTargeted: $viewModel.isDropTargetActive,
            onFilesDropped: viewModel.handleFilesDrop
        )
    }
    
    private var compactDropZone: some View {
        DropZoneView(style: .standard, isActive: viewModel.isDropTargetActive)
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var compactFileGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 40, maximum: 60), spacing: 8)
            ], spacing: 8) {
                ForEach(viewModel.storageManager.storedFiles.prefix(6)) { file in
                    CompactFileItemView(file: file) { action, file in
                        handleFileAction(action, file)
                    }
                }
                
                if viewModel.storageManager.storedFiles.count > 6 {
                    moreFilesIndicator
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxHeight: 120)
    }
    
    private var moreFilesIndicator: some View {
        VStack(spacing: 2) {
            Image(systemName: "ellipsis")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("+\(viewModel.storageManager.storedFiles.count - 6)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 40, height: 40)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private var quickActions: some View {
        HStack(spacing: 12) {
            // Clear all button (if files exist)
            if viewModel.hasFiles {
                Button(action: viewModel.removeAllFiles) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("Clear All")
                            .font(.caption2)
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleFileAction(_ action: FileAction, _ file: FileItem) {
        switch action {
        case .open:
            viewModel.openFile(file)
        case .revealInFinder:
            viewModel.revealInFinder(file)
        case .copyPath:
            viewModel.copyPathToClipboard(file)
        case .remove:
            viewModel.removeFile(file)
        }
    }
}

// MARK: - CompactFileItemView

struct CompactFileItemView: View {
    let file: FileItem
    let onAction: (FileAction, FileItem) -> Void
    
    @State private var isHovered = false
    @State private var fileExists = true
    
    var body: some View {
        if fileExists {
            VStack(spacing: 4) {
                // File icon
                if let thumbnail = file.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: file.type.systemIcon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                }
                
                // File name (truncated)
                Text(file.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
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
            .onTapGesture(count: 2) {
                onAction(.open, file)
            }
            .contextMenu {
                Button("Open") { onAction(.open, file) }
                Button("Reveal in Finder") { onAction(.revealInFinder, file) }
                Button("Copy Path") { onAction(.copyPath, file) }
                Divider()
                Button("Remove", role: .destructive) { onAction(.remove, file) }
            }
            .help(file.name)
            .onAppear {
                checkFileExists()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                checkFileExists()
            }
        }
    }
    
    private func checkFileExists() {
        fileExists = FileManager.default.fileExists(atPath: file.path.path)
    }
}

#Preview {
    NotchView()
        .frame(width: 320, height: 200, alignment: .top)
        .background(Color.black.opacity(0.1))
}
