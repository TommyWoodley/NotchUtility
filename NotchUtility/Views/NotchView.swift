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
    @State private var isPermanentlyExpanded = false
    @State private var isDragHovered = false
    @State private var selectedTab: NotchTab = .files
    
    enum NotchTab: String, CaseIterable {
        case files = "Files"
        case clipboard = "Clipboard"
        
        var icon: String {
            switch self {
            case .files: return "doc.on.doc"
            case .clipboard: return "doc.on.clipboard"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact notch bar with hover detection
            notchBar
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovered = hovering
                        // Only expand on hover if not permanently expanded
                        if !isPermanentlyExpanded {
                            isExpanded = hovering
                        }
                    }
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPermanentlyExpanded.toggle()
                        // If we're toggling to permanently expanded, make sure isExpanded is false
                        // so hover state doesn't interfere
                        if isPermanentlyExpanded {
                            isExpanded = false
                        }
                    }
                }
            
            // Expandable content area with separate hover detection
            if isExpanded || isPermanentlyExpanded || isDragHovered {
                expandedContent
                    .onHover { hovering in
                        // Keep expanded while hovering over content, but only if opened by hover
                        if !isPermanentlyExpanded {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if !hovering {
                                    isExpanded = false
                                    isHovered = false
                                }
                            }
                        }
                    }
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
        .onDrop(of: [.fileURL], isTargeted: $isDragHovered) { providers in
            handleDrop(providers: providers)
            return true
        }
        .frame(width: 280, height: 240, alignment: .top)
    }
    
    private var tabSelector: some View {
        Picker("Content Type", selection: $selectedTab) {
            ForEach(NotchTab.allCases, id: \.self) { tab in
                Image(systemName: tab.icon)
                    .font(.caption2)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
    
    private var filesContent: some View {
        VStack(spacing: 8) {
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
    }
    
    private var clipboardContent: some View {
        VStack(spacing: 8) {
            if viewModel.clipboardService.clipboardHistory.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("No clipboard history")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Copy some text to see it here")
                        .font(.caption2)
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                }
                .frame(height: 80)
            } else {
                // Clipboard items
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.clipboardService.clipboardHistory) { item in
                            CompactClipboardItemView(
                                item: item,
                                onTapped: { viewModel.copyClipboardItem(item) },
                                onRemoved: { viewModel.removeClipboardItem(item) }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 120)
                
                // Clipboard actions
                HStack {
                    Button(action: viewModel.clearClipboardHistory) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.caption)
                            Text("Clear All")
                                .font(.caption2)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    
                    Spacer()
                }
            }
        }
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
            
            // Clipboard indicator
            if !viewModel.clipboardService.clipboardHistory.isEmpty {
                clipboardBadge
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
    
    private var clipboardBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.on.clipboard")
                .font(.caption2)
            
            Text("\(viewModel.clipboardService.clipboardHistory.count)")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.green.opacity(0.8))
        .foregroundColor(.white)
        .clipShape(Capsule())
    }
    
    private var expandIndicator: some View {
        let isCurrentlyExpanded = isExpanded || isPermanentlyExpanded || isDragHovered
        return Image(systemName: isCurrentlyExpanded ? "chevron.up" : "chevron.down")
            .font(.caption2)
            .foregroundColor(isPermanentlyExpanded ? .accentColor : .secondary)
            .rotationEffect(.degrees(isCurrentlyExpanded ? 180 : 0))
    }
    
    private var expandedContent: some View {
        VStack(spacing: 8) {
            // Tab selector
            tabSelector
            
            // Content based on selected tab
            switch selectedTab {
            case .files:
                filesContent
            case .clipboard:
                clipboardContent
            }
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
    
    private func handleDrop(providers: [NSItemProvider]) {
        DropUtility.extractURLs(from: providers) { urls in
            if !urls.isEmpty {
                viewModel.handleFilesDrop(urls)
            }
            isDragHovered = false
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

// MARK: - CompactClipboardItemView

struct CompactClipboardItemView: View {
    let item: ClipboardItem
    let onTapped: () -> Void
    let onRemoved: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Type icon
            Image(systemName: item.type.systemIcon)
                .foregroundColor(.secondary)
                .frame(width: 16, height: 16)
                .font(.caption)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayContent)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(item.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Remove button (only shown on hover)
            if isHovered {
                Button(action: onRemoved) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(BorderlessButtonStyle())
                .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovered ? Color(NSColor.selectedControlColor).opacity(0.3) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onTapped()
        }
        .help("Click to copy to clipboard: \(item.content)")
    }
}

#Preview {
    NotchView()
        .frame(width: 320, height: 280, alignment: .top)
        .background(Color.black.opacity(0.1))
}
