//
//  ClipboardComponents.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI

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

// MARK: - Preview Components

#Preview("Clipboard Item - Text") {
    CompactClipboardItemView(
        item: createMockClipboardItem(content: "Hello, this is some sample text content", type: .text),
        onTapped: { print("Tapped text item") },
        onRemoved: { print("Removed text item") }
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Clipboard Item - URL") {
    CompactClipboardItemView(
        item: createMockClipboardItem(content: "https://www.apple.com/macos", type: .url),
        onTapped: { print("Tapped URL item") },
        onRemoved: { print("Removed URL item") }
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Clipboard Item - Image") {
    CompactClipboardItemView(
        item: createMockClipboardItem(content: "Screenshot_2024.png", type: .image),
        onTapped: { print("Tapped image item") },
        onRemoved: { print("Removed image item") }
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Clipboard Item - Long Text") {
    CompactClipboardItemView(
        item: createMockClipboardItem(
            content: "This is a very long piece of text that should be truncated when displayed in the compact view because it exceeds the normal length",
            type: .text
        ),
        onTapped: { print("Tapped long text item") },
        onRemoved: { print("Removed long text item") }
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Clipboard Item - Code") {
    CompactClipboardItemView(
        item: createMockClipboardItem(
            content: "func calculateTotal() -> Double { return items.reduce(0) { $0 + $1.price } }",
            type: .other
        ),
        onTapped: { print("Tapped code item") },
        onRemoved: { print("Removed code item") }
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Clipboard Items - List") {
    ScrollView {
        LazyVStack(spacing: 4) {
            ForEach(createMockClipboardItems()) { item in
                CompactClipboardItemView(
                    item: item,
                    onTapped: { print("Tapped: \(item.displayContent)") },
                    onRemoved: { print("Removed: \(item.displayContent)") }
                )
            }
        }
        .padding(.horizontal, 4)
    }
    .frame(height: 200)
    .background(Color.black)
    .preferredColorScheme(.dark)
}

// MARK: - Preview Helper Functions

private func createMockClipboardItem(content: String, type: ClipboardType, date: Date = Date()) -> ClipboardItem {
    ClipboardItem(
        id: UUID(),
        content: content,
        type: type,
        dateAdded: date,
        changeCount: 1
    )
}

private func createMockClipboardItems() -> [ClipboardItem] {
    let now = Date()
    return [
        createMockClipboardItem(
            content: "Hello, world!",
            type: .text,
            date: now.addingTimeInterval(-60) // 1 minute ago
        ),
        createMockClipboardItem(
            content: "https://github.com/apple/swift",
            type: .url,
            date: now.addingTimeInterval(-300) // 5 minutes ago
        ),
        createMockClipboardItem(
            content: "screenshot_2024_01_15.png",
            type: .image,
            date: now.addingTimeInterval(-600) // 10 minutes ago
        ),
        createMockClipboardItem(
            content: "import SwiftUI\n\nstruct ContentView: View {\n    var body: some View {\n        Text(\"Hello\")\n    }\n}",
            type: .other,
            date: now.addingTimeInterval(-900) // 15 minutes ago
        ),
        createMockClipboardItem(
            content: "user@example.com",
            type: .text,
            date: now.addingTimeInterval(-1800) // 30 minutes ago
        ),
        createMockClipboardItem(
            content: "This is a longer piece of text that might get truncated in the compact view format",
            type: .text,
            date: now.addingTimeInterval(-3600) // 1 hour ago
        )
    ]
} 