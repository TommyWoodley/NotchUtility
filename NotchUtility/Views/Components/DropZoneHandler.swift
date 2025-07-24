//
//  DropZoneHandler.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Drop Zone Handler (Logic)
struct DropZoneHandler: ViewModifier {
    let isTargeted: Binding<Bool>
    let onFilesDropped: ([URL]) -> Void
    
    func body(content: Content) -> some View {
        content
            .onDrop(of: [.fileURL], isTargeted: isTargeted) { providers in
                handleDrop(providers: providers)
                return true
            }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let group = DispatchGroup()
        var urls: [URL] = []
        
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                group.enter()
                provider.loadObject(ofClass: URL.self) { url, error in
                    defer { group.leave() }
                    
                    if let url = url, url.isFileURL {
                        urls.append(url)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                onFilesDropped(urls)
            }
            isTargeted.wrappedValue = false
        }
        
        return !providers.isEmpty
    }
}

// MARK: - View Extension
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
} 