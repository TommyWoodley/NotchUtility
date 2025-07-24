//
//  NotchOverlayView.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI

struct NotchOverlayView: View {
    @StateObject var vm: NotchViewModel
    @State var dropTargeting: Bool = false

    var notchSize: CGSize {
        switch vm.status {
        case .closed:
            var ans = CGSize(
                width: vm.deviceNotchRect.width - 4,
                height: vm.deviceNotchRect.height - 4
            )
            if ans.width < 0 { ans.width = 0 }
            if ans.height < 0 { ans.height = 0 }
            return ans
        case .opened:
            return vm.notchOpenedSize
        case .popping:
            return .init(
                width: vm.deviceNotchRect.width,
                height: vm.deviceNotchRect.height + 4
            )
        }
    }

    var notchCornerRadius: CGFloat {
        switch vm.status {
        case .closed: 8
        case .opened: 32
        case .popping: 10
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            notch
                .zIndex(0)
                .disabled(true)
                .opacity(vm.notchVisible ? 1 : 0.3)
            Group {
                if vm.status == .opened {
                    VStack(spacing: vm.spacing) {
                        NotchHeaderView(vm: vm)
                        NotchContentView(vm: vm)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(vm.spacing)
                    .frame(maxWidth: vm.notchOpenedSize.width, maxHeight: vm.notchOpenedSize.height)
                    .zIndex(1)
                }
            }
            .transition(
                .scale.combined(
                    with: .opacity
                ).combined(
                    with: .offset(y: -vm.notchOpenedSize.height / 2)
                ).animation(vm.animation)
            )
        }
        .background(dragDetector)
        .animation(vm.animation, value: vm.status)
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    var notch: some View {
        Rectangle()
            .foregroundStyle(.black)
            .mask(notchBackgroundMaskGroup)
            .frame(
                width: notchSize.width + notchCornerRadius * 2,
                height: notchSize.height
            )
            .shadow(
                color: .black.opacity(([.opened, .popping].contains(vm.status)) ? 1 : 0),
                radius: 8
            )
    }

    var notchBackgroundMaskGroup: some View {
        Rectangle()
            .foregroundStyle(.black)
            .frame(
                width: notchSize.width,
                height: notchSize.height
            )
            .clipShape(.rect(
                bottomLeadingRadius: notchCornerRadius,
                bottomTrailingRadius: notchCornerRadius
            ))
            .overlay {
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .frame(width: notchCornerRadius, height: notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topTrailingRadius: notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchCornerRadius + vm.spacing,
                            height: notchCornerRadius + vm.spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -notchCornerRadius - vm.spacing + 0.5, y: -0.5)
            }
            .overlay {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .frame(width: notchCornerRadius, height: notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topLeadingRadius: notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchCornerRadius + vm.spacing,
                            height: notchCornerRadius + vm.spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: notchCornerRadius + vm.spacing - 0.5, y: -0.5)
            }
    }

    @ViewBuilder
    var dragDetector: some View {
        RoundedRectangle(cornerRadius: notchCornerRadius)
            .foregroundStyle(Color.black.opacity(0.001))
            .contentShape(Rectangle())
            .frame(width: notchSize.width + vm.dropDetectorRange, height: notchSize.height + vm.dropDetectorRange)
            .onDrop(of: [.data], isTargeted: $dropTargeting) { _ in true }
            .onChange(of: dropTargeting) { isTargeted in
                if isTargeted, vm.status == .closed {
                    vm.notchOpen(.drag)
                    vm.hapticSender.send()
                } else if !isTargeted {
                    let mouseLocation: NSPoint = NSEvent.mouseLocation
                    if !vm.notchOpenedRect.insetBy(dx: vm.inset, dy: vm.inset).contains(mouseLocation) {
                        vm.notchClose()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct NotchHeaderView: View {
    @StateObject var vm: NotchViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("NotchUtility")
                    .font(.headline)
                    .foregroundColor(.white)
//                
                Text(vm.contentViewModel.formattedStorageUsage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if vm.contentViewModel.hasFiles {
                Text("\(vm.contentViewModel.storageManager.storedFiles.count) files")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct NotchContentView: View {
    @StateObject var vm: NotchViewModel
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
        VStack(spacing: 8) {
            // Tab selector
            Picker("Content Type", selection: $selectedTab) {
                ForEach(NotchTab.allCases, id: \.self) { tab in
                    Image(systemName: tab.icon)
                        .font(.caption2)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            
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
                GridItem(.adaptive(minimum: 30, maximum: 40), spacing: 6)
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

// MARK: - Compact Components

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
            .frame(width: 24, height: 24)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(4)
            
            // File name (truncated)
            Text(file.name)
                .font(.caption2)
                .lineLimit(1)
                .foregroundColor(.primary)
        }
        .frame(width: 30, height: 30)
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

struct CompactClipboardItemView: View {
    let item: ClipboardItem
    let onTapped: () -> Void
    let onRemoved: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 6) {
            // Type icon
            Image(systemName: item.type.systemIcon)
                .foregroundColor(.secondary)
                .font(.caption2)
                .frame(width: 12)
            
            // Content
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displayContent)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(item.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 0)
            
            // Remove button (only shown on hover)
            if isHovered {
                Button(action: onRemoved) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                }
                .buttonStyle(BorderlessButtonStyle())
                .transition(.opacity)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(isHovered ? Color(nsColor: .selectedControlColor).opacity(0.3) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onTapped()
        }
        .help("Click to copy to clipboard")
    }
} 

#Preview("NotchOverlayView - Closed") {
    NotchOverlayView(vm: createMockViewModel(status: .closed))
        .frame(width: 400, height: 200)
        .background(Color.blue.opacity(0.3)) // Background to visualize the notch
}

#Preview("NotchOverlayView - Opened") {
    NotchOverlayView(vm: createMockViewModel(status: .opened))
        .frame(width: 700, height: 500)
        .background(Color.blue.opacity(0.3))
}

#Preview("NotchOverlayView - Popping") {
    NotchOverlayView(vm: createMockViewModel(status: .popping))
        .frame(width: 400, height: 200)
        .background(Color.blue.opacity(0.3))
}

// MARK: - Preview Helper Functions

@MainActor
private func createMockViewModel(status: NotchViewModel.Status) -> NotchViewModel {
    let vm = PreviewNotchViewModel(targetStatus: status)
    return vm
}

// MARK: - Preview-specific ViewModel

@MainActor
private class PreviewNotchViewModel: NotchViewModel {
    private let targetStatus: Status
    private var isLocked = false
    
    init(targetStatus: Status) {
        self.targetStatus = targetStatus
        super.init(inset: -4)
        
        // Set up mock geometry
        deviceNotchRect = CGRect(x: 0, y: 0, width: 200, height: 30)
        screenRect = CGRect(x: 0, y: 0, width: 400, height: 250)
        
        // Set the target status using public methods
        switch targetStatus {
        case .closed:
            notchClose()
        case .opened:
            notchOpen(.click)
        case .popping:
            notchPop()
        }
        
        // Now lock the state and disable event handling
        isLocked = true
        destroy()
    }
    
    // Prevent any state changes in previews after locking
    override func notchOpen(_ reason: OpenReason) {
        if isLocked { return }
        super.notchOpen(reason)
    }
    
    override func notchClose() {
        if isLocked { return }
        super.notchClose()
    }
    
    override func notchPop() {
        if isLocked { return }
        super.notchPop()
    }
} 
