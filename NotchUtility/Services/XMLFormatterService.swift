//
//  XMLFormatterService.swift
//  NotchUtility
//

import Foundation
import SwiftUI

enum XMLFormatterMode: CaseIterable, Identifiable {
    case beautify
    case minify
    case validate
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .beautify: return "Beautify"
        case .minify: return "Minify"
        case .validate: return "Validate"
        }
    }
    
    var icon: String {
        switch self {
        case .beautify: return "text.alignleft"
        case .minify: return "arrow.down.left.and.arrow.up.right"
        case .validate: return "checkmark.circle"
        }
    }
    
    var inputLabel: String {
        "XML Input:"
    }
    
    var outputLabel: String {
        switch self {
        case .beautify: return "Formatted XML:"
        case .minify: return "Minified XML:"
        case .validate: return "Validation Result:"
        }
    }
}

@MainActor
class XMLFormatterService: ObservableObject {
    
    enum XMLFormatterError: LocalizedError, Equatable {
        case invalidInput
        case invalidXML(String)
        case formattingFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidInput:
                return "Invalid input provided"
            case .invalidXML(let message):
                return "Invalid XML: \(message)"
            case .formattingFailed:
                return "Failed to format XML"
            }
        }
    }
    
    nonisolated func beautify(_ input: String) -> Result<String, XMLFormatterError> {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidInput)
        }
        
        do {
            let xmlDoc = try XMLDocument(xmlString: input, options: [.nodePreserveAll])
            let prettyString = xmlDoc.xmlString(options: [.nodePrettyPrint])
            return .success(prettyString)
        } catch let error as NSError {
            return .failure(.invalidXML(error.localizedDescription))
        }
    }
    
    nonisolated func minify(_ input: String) -> Result<String, XMLFormatterError> {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidInput)
        }
        
        do {
            let xmlDoc = try XMLDocument(xmlString: input, options: [.nodePreserveAll])
            let minifiedString = xmlDoc.xmlString(options: [.nodeCompactEmptyElement])
            let lines = minifiedString.components(separatedBy: .newlines)
            let trimmedLines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
            let result = trimmedLines.joined()
            return .success(result)
        } catch let error as NSError {
            return .failure(.invalidXML(error.localizedDescription))
        }
    }
    
    nonisolated func validate(_ input: String) -> Result<String, XMLFormatterError> {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidInput)
        }
        
        do {
            _ = try XMLDocument(xmlString: input, options: [.nodePreserveAll])
            return .success("✓ Valid XML")
        } catch let error as NSError {
            return .failure(.invalidXML(error.localizedDescription))
        }
    }
    
    nonisolated func convert(_ input: String, mode: XMLFormatterMode) -> Result<String, XMLFormatterError> {
        switch mode {
        case .beautify:
            return beautify(input)
        case .minify:
            return minify(input)
        case .validate:
            return validate(input)
        }
    }
}

