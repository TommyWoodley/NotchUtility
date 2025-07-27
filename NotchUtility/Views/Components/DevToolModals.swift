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
                    Base64Tool()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 500, height: 400)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Base64 Tool Implementation
struct Base64Tool: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isEncoding: Bool = true
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    
    @StateObject private var base64Service = Base64ToolService()
    
    var body: some View {
        VStack(spacing: 16) {
            // Mode Toggle
            HStack {
                Button(
                    action: {
                        isEncoding = true
                        convertText()
                    },
                    label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.square")
                                .font(.caption)
                            Text("Encode")
                                .font(.callout)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isEncoding ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                        )
                        .foregroundColor(isEncoding ? .white : .primary)
                    }
                )
                .buttonStyle(PlainButtonStyle())
                
                Button(
                    action: {
                        isEncoding = false
                        convertText()
                    }, label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.square")
                                .font(.caption)
                            Text("Decode")
                                .font(.callout)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(!isEncoding ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                        )
                        .foregroundColor(!isEncoding ? .white : .primary)
                    }
                )
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Quick Actions
                HStack(spacing: 12) {
                    Button(action: clearAll) {
                        Label("Clear", systemImage: "trash")
                            .font(.callout)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: copyOutput) {
                        Label("Copy", systemImage: "doc.on.clipboard")
                            .font(.callout)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(outputText.isEmpty)
                }
            }
            
            // Input Field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(isEncoding ? "Input Text:" : "Base64 Input:")
                        .font(.callout)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if showingError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                TextEditor(text: $inputText)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            )
                    )
                    .frame(minHeight: 100, maxHeight: 120)
                    .onChange(of: inputText) { _ in
                        convertText()
                    }
            }
            
            // Output Field
            VStack(alignment: .leading, spacing: 8) {
                Text(isEncoding ? "Base64 Output:" : "Decoded Text:")
                    .font(.callout)
                    .fontWeight(.medium)
                
                TextEditor(text: .constant(outputText))
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            )
                    )
                    .frame(minHeight: 100, maxHeight: 120)
                    .disabled(true)
            }
        }
        .padding(20)
    }
    
    private func convertText() {
        showingError = false
        errorMessage = ""
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            outputText = ""
            return
        }
        
        let result = isEncoding ? 
            base64Service.encode(inputText) : 
            base64Service.decode(inputText)
        
        switch result {
        case .success(let convertedText):
            outputText = convertedText
        case .failure(let error):
            outputText = ""
            showError(error.localizedDescription)
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        
        // Auto-hide error after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingError = false
            }
        }
    }
    
    private func clearAll() {
        inputText = ""
        outputText = ""
        showingError = false
    }
    
    private func copyOutput() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(outputText, forType: .string)
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
    Base64Tool()
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(.dark)
        .frame(width: 500, height: 400)
}

#Preview("Base64 Tool - Light Mode") {
    Base64Tool()
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(.light)
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
