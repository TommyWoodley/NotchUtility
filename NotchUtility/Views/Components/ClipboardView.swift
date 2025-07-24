//
//  ClipboardView.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI

struct ClipboardView: View {
    let clipboardItems: [ClipboardItem]
    let onItemTapped: (ClipboardItem) -> Void
    let onItemRemoved: (ClipboardItem) -> Void
    let onClearAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            
            if clipboardItems.isEmpty {
                emptyStateView
            } else {
                clipboardItemsList
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var headerView: some View {
        HStack {
            Label("Clipboard History", systemImage: "doc.on.clipboard")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            if !clipboardItems.isEmpty {
                Button(action: onClearAll) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Clear clipboard history")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No clipboard history")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Copy some text to see it here")
                .font(.caption2)
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var clipboardItemsList: some View {
        LazyVStack(spacing: 4) {
            ForEach(clipboardItems) { item in
                ClipboardItemRow(
                    item: item,
                    onTapped: { onItemTapped(item) },
                    onRemoved: { onItemRemoved(item) }
                )
            }
        }
    }
}

// MARK: - Clipboard Item Row
struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onTapped: () -> Void
    let onRemoved: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Type icon
            Image(systemName: item.type.systemIcon)
                .foregroundColor(.secondary)
                .frame(width: 12)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayContent)
                    .font(.caption)
                    .lineLimit(2)
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
        .help("Click to copy to clipboard")
    }
}

#Preview {
    ClipboardView(
        clipboardItems: [
            ClipboardItem(content: "Hello, world!", type: .text, changeCount: 1),
            ClipboardItem(content: "https://example.com", type: .url, changeCount: 2),
            ClipboardItem(content: "Some very long text that should be truncated to avoid taking up too much space in the UI and making it hard to read", type: .text, changeCount: 3)
        ],
        onItemTapped: { _ in },
        onItemRemoved: { _ in },
        onClearAll: { }
    )
    .frame(width: 300)
} 