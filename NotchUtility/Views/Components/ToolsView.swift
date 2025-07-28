//
//  ToolsView.swift
//  NotchUtility
//
//  Created by thwoodle on 27/07/2025.
//

import SwiftUI

// MARK: - Main Tools View
struct ToolsView: View {
    @State private var selectedTool: DevTool?
    
    var body: some View {
        VStack(spacing: 8) {
            // Tools Grid
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 8)
            ], spacing: 8) {
                ForEach(DevTool.allCases) { tool in
                    ToolButton(tool: tool) {
                        selectedTool = tool
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        )
        .sheet(isPresented: $selectedTool.isPresent()) {
            ToolModalView(tool: selectedTool ?? .base64)
        }
    }
}

// MARK: - Tool Button Component
struct ToolButton: View {
    let tool: DevTool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: tool.icon)
                    .font(.title2)
                    .foregroundColor(tool.color)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                
                VStack(spacing: 2) {
                    Text(tool.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(tool.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? tool.color.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHovered ? tool.color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .help(tool.description)
    }
}

// MARK: - Preview
#Preview {
    ToolsView()
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
