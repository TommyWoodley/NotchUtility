//
//  DropZoneHandler.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

// MARK: - Drop Zone Handler (Logic)
struct DropZoneHandler: ViewModifier {
    let isTargeted: Binding<Bool>
    let onFilesDropped: ([URL]) -> Void
    
    func body(content: Content) -> some View {
        content
            .onDrop(of: [.fileURL], isTargeted: isTargeted) { providers in
                handleDrop(providers: providers)
            }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        DropUtility.extractURLs(from: providers) { urls in
            if !urls.isEmpty {
                onFilesDropped(urls)
            }
            isTargeted.wrappedValue = false
        }
        
        return !providers.isEmpty
    }
}

// MARK: - Drag Out Handler
struct DragOutHandler: ViewModifier {
    let file: FileItem
    let onDragStarted: (FileItem) -> Void
    let onDragEnded: () -> Void
    let onDragCompleted: (FileItem, URL?) -> Void
    
    func body(content: Content) -> some View {
        content
            .onDrag {
                // Called when drag starts
                DispatchQueue.main.async {
                    onDragStarted(file)
                }
                
                // Create drag provider with completion callback
                return DropUtility.createDragProvider(for: file) {
                    // This gets called when the drag operation completes
                    DispatchQueue.main.async {
                        onDragEnded()
                        onDragCompleted(file, nil)
                    }
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func dropZone(
        isTargeted: Binding<Bool>,
        onFilesDropped: @escaping ([URL]) -> Void
    ) -> some View {
        self.modifier(DropZoneHandler(
            isTargeted: isTargeted,
            onFilesDropped: onFilesDropped
        ))
    }
    
    func dragOut(
        file: FileItem,
        onDragStarted: @escaping (FileItem) -> Void = { _ in },
        onDragEnded: @escaping () -> Void = { },
        onDragCompleted: @escaping (FileItem, URL?) -> Void = { _, _ in }
    ) -> some View {
        self.modifier(DragOutHandler(
            file: file,
            onDragStarted: onDragStarted,
            onDragEnded: onDragEnded,
            onDragCompleted: onDragCompleted
        ))
    }
} 
