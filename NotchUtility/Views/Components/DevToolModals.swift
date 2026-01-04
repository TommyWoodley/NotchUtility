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
                case .jsonFormatter:
                    JSONFormatterTool()
                case .xmlFormatter:
                    XMLFormatterTool()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .windowBackgroundColor))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 600, height: 450)
        .background(Color(nsColor: .windowBackgroundColor))
        .presentationBackground(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Conversion Tool Protocol
protocol ConversionMode: CaseIterable, Identifiable {
    var title: String { get }
    var icon: String { get }
    var inputLabel: String { get }
    var outputLabel: String { get }
}

protocol ConversionService: ObservableObject {
    associatedtype Mode: ConversionMode
    associatedtype ConversionError: LocalizedError
    
    func convert(_ input: String, mode: Mode) -> Result<String, ConversionError>
}

// MARK: - Generic Conversion Tool View
struct ConversionToolView<Mode: ConversionMode, Service: ConversionService>: View where Service.Mode == Mode {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var mode: Mode
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    @StateObject private var service: Service
    
    init(defaultMode: Mode, service: Service) {
        self._mode = State(initialValue: defaultMode)
        self._service = StateObject(wrappedValue: service)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Mode Toggle
            HStack {
                ForEach(Array(Mode.allCases), id: \.id) { toggleMode in
                    Button(
                        action: {
                            mode = toggleMode
                            convertText()
                        },
                        label: {
                            HStack(spacing: 6) {
                                Image(systemName: toggleMode.icon)
                                    .font(.caption)
                                Text(toggleMode.title)
                                    .font(.callout)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(mode.id == toggleMode.id ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                            )
                            .foregroundColor(mode.id == toggleMode.id ? .white : .primary)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()
            }

            // Input Field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(mode.inputLabel)
                        .font(.callout)
                        .fontWeight(.medium)

                    Spacer()

                    if showingError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if !inputText.isEmpty {
                        Button(action: clearAll) {
                            Label("Clear", systemImage: "trash")
                                .font(.callout)
                        }
                        .buttonStyle(PlainButtonStyle())
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
                    .onChange(of: inputText) {
                        convertText()
                    }
            }

            // Output Field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(mode.outputLabel)
                        .font(.callout)
                        .fontWeight(.medium)

                    Spacer()

                    if !outputText.isEmpty {
                        Button(action: copyOutput) {
                            Label("Copy", systemImage: "doc.on.clipboard")
                                .font(.callout)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func convertText() {
        showingError = false
        errorMessage = ""

        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            outputText = ""
            return
        }

        let result = service.convert(inputText, mode: mode)

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

// MARK: - Base64 Protocol Conformances
extension Base64Mode: ConversionMode {}

extension Base64ToolService: ConversionService {
    typealias Mode = Base64Mode
    typealias ConversionError = Base64Error
}

// MARK: - Base64 Tool
struct Base64Tool: View {
    var body: some View {
        ConversionToolView(
            defaultMode: Base64Mode.encode,
            service: Base64ToolService()
        )
    }
}

// MARK: - JSON Formatter Protocol Conformances
extension JSONFormatterMode: ConversionMode {}

extension JSONFormatterService: ConversionService {
    typealias Mode = JSONFormatterMode
    typealias ConversionError = JSONFormatterError
}

// MARK: - JSON Formatter Tool
struct JSONFormatterTool: View {
    var body: some View {
        ConversionToolView(
            defaultMode: JSONFormatterMode.beautify,
            service: JSONFormatterService()
        )
    }
}

// MARK: - XML Formatter Protocol Conformances
extension XMLFormatterMode: ConversionMode {}

extension XMLFormatterService: ConversionService {
    typealias Mode = XMLFormatterMode
    typealias ConversionError = XMLFormatterError
}

// MARK: - XML Formatter Tool
struct XMLFormatterTool: View {
    var body: some View {
        ConversionToolView(
            defaultMode: XMLFormatterMode.beautify,
            service: XMLFormatterService()
        )
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
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(.dark)
        .frame(width: 600, height: 500)
}

#Preview("Base64 Tool - Light Mode") {
    Base64Tool()
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(.light)
        .frame(width: 600, height: 500)
} 
