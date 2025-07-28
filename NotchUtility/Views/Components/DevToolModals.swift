//
//  DevToolModals.swift
//  NotchUtility
//
//  Created by thwoodle on 27/07/2025.
//

import SwiftUI

// MARK: - Tool Modal View
struct ToolModalView: View {
    let tool: DevTool
    @Environment(\.dismiss)
    private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Modal Header
            HStack {
                Image(systemName: tool.icon)
                    .foregroundColor(tool.color)
                    .font(.title2)
                
                Text(tool.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { dismiss() }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                })
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
            
            // Tool Content
            ScrollView {
                switch tool {
                case .base64:
                    PlaceholderTool(
                        name: "JSON Formatter",
                        description: "Format and validate JSON data"
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 500, height: 400)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Placeholder Tool
struct PlaceholderTool: View {
    let name: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Coming Soon")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("\(name) - \(description)")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews
#Preview("Base64 Tool Modal") {
    ToolModalView(tool: .base64)
        .preferredColorScheme(.dark)
}

#Preview("Base64 Tool - Standalone") {
    PlaceholderTool(
        name: "JSON Formatter",
        description: "Format and validate JSON data"
    )
    .background(Color(nsColor: .windowBackgroundColor))
    .preferredColorScheme(.dark)
    .frame(width: 500, height: 400)
}

#Preview("Base64 Tool - Light Mode") {
    PlaceholderTool(
        name: "JSON Formatter",
        description: "Format and validate JSON data"
    )
    .background(Color(nsColor: .windowBackgroundColor))
    .preferredColorScheme(.dark)
    .frame(width: 500, height: 400)
}

#Preview("Placeholder Tool - JSON") {
    PlaceholderTool(
        name: "JSON Formatter",
        description: "Format and validate JSON data"
    )
    .background(Color(nsColor: .windowBackgroundColor))
    .preferredColorScheme(.dark)
    .frame(width: 500, height: 400)
}

#Preview("Placeholder Tool - URL") {
    PlaceholderTool(
        name: "URL Encoder",
        description: "Encode and decode URLs"
    )
    .background(Color(nsColor: .windowBackgroundColor))
    .preferredColorScheme(.light)
    .frame(width: 500, height: 400)
}

#Preview("Modal in Light Mode") {
    ToolModalView(tool: .base64)
        .preferredColorScheme(.light)
} 
