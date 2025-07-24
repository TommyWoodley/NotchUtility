//
//  DropZoneView.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let isActive: Bool
    let onFilesDropped: ([URL]) -> Void
    let onDropStateChanged: (Bool) -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isActive ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
                )
            
            VStack(spacing: 5) {
                Image(systemName: isActive ? "arrow.down.circle.fill" : "plus.circle")
                    .font(.system(size: 32))
                    .foregroundColor(isActive ? .accentColor : .secondary)
            }
            .padding()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
        .onDrop(of: [.fileURL], isTargeted: .constant(false)) { providers in
            onDropStateChanged(false)
            return handleDrop(providers: providers)
        }
        .onDrop(of: [.fileURL], isTargeted: .init(
            get: { isActive },
            set: { onDropStateChanged($0) }
        )) { providers in
            return handleDrop(providers: providers)
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
            onDropStateChanged(false)
        }
        
        return !providers.isEmpty
    }
}

#Preview("Very Small Height") {
    DropZoneView(
        isActive: false,
        onFilesDropped: { urls in
            print("Files dropped: \(urls)")
        },
        onDropStateChanged: { isActive in
            print("Drop state changed: \(isActive)")
        }
    )
    .frame(width: 200, height: 70)
    .padding()
}

#Preview("Small Square") {
    DropZoneView(
        isActive: false,
        onFilesDropped: { urls in
            print("Files dropped: \(urls)")
        },
        onDropStateChanged: { isActive in
            print("Drop state changed: \(isActive)")
        }
    )
    .frame(width: 200, height: 200)
    .padding()
}

#Preview("Medium Rectangle") {
    DropZoneView(
        isActive: false,
        onFilesDropped: { urls in
            print("Files dropped: \(urls)")
        },
        onDropStateChanged: { isActive in
            print("Drop state changed: \(isActive)")
        }
    )
    .frame(width: 300, height: 200)
    .padding()
}

#Preview("Large Rectangle (Active)") {
    DropZoneView(
        isActive: true,
        onFilesDropped: { urls in
            print("Files dropped: \(urls)")
        },
        onDropStateChanged: { isActive in
            print("Drop state changed: \(isActive)")
        }
    )
    .frame(width: 400, height: 250)
    .padding()
}

#Preview("Wide Banner") {
    DropZoneView(
        isActive: false,
        onFilesDropped: { urls in
            print("Files dropped: \(urls)")
        },
        onDropStateChanged: { isActive in
            print("Drop state changed: \(isActive)")
        }
    )
    .frame(width: 500, height: 150)
    .padding()
}

#Preview("Tall Vertical (Active)") {
    DropZoneView(
        isActive: true,
        onFilesDropped: { urls in
            print("Files dropped: \(urls)")
        },
        onDropStateChanged: { isActive in
            print("Drop state changed: \(isActive)")
        }
    )
    .frame(width: 200, height: 350)
    .padding()
} 
