//
//  JSONFormatterService.swift
//  NotchUtility
//

import Foundation
import SwiftUI

enum JSONFormatterMode: CaseIterable, Identifiable {
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
        return "JSON Input:"
    }
    
    var outputLabel: String {
        switch self {
        case .beautify: return "Formatted JSON:"
        case .minify: return "Minified JSON:"
        case .validate: return "Validation Result:"
        }
    }
}

@MainActor
class JSONFormatterService: ObservableObject {
    
    enum JSONFormatterError: LocalizedError, Equatable {
        case invalidInput
        case invalidJSON(String)
        case formattingFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidInput:
                return "Invalid input provided"
            case .invalidJSON(let message):
                return "Invalid JSON: \(message)"
            case .formattingFailed:
                return "Failed to format JSON"
            }
        }
    }
    
    nonisolated func beautify(_ input: String) -> Result<String, JSONFormatterError> {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidInput)
        }
        
        guard let data = input.data(using: .utf8) else {
            return .failure(.formattingFailed)
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            let prettyData = try JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            )
            guard let prettyString = String(data: prettyData, encoding: .utf8) else {
                return .failure(.formattingFailed)
            }
            return .success(prettyString)
        } catch let error as NSError {
            return .failure(.invalidJSON(error.localizedDescription))
        }
    }
    
    nonisolated func minify(_ input: String) -> Result<String, JSONFormatterError> {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidInput)
        }
        
        guard let data = input.data(using: .utf8) else {
            return .failure(.formattingFailed)
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            let minifiedData = try JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.withoutEscapingSlashes]
            )
            guard let minifiedString = String(data: minifiedData, encoding: .utf8) else {
                return .failure(.formattingFailed)
            }
            return .success(minifiedString)
        } catch let error as NSError {
            return .failure(.invalidJSON(error.localizedDescription))
        }
    }
    
    nonisolated func validate(_ input: String) -> Result<String, JSONFormatterError> {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidInput)
        }
        
        guard let data = input.data(using: .utf8) else {
            return .failure(.formattingFailed)
        }
        
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            return .success("✓ Valid JSON")
        } catch let error as NSError {
            return .failure(.invalidJSON(error.localizedDescription))
        }
    }
    
    nonisolated func convert(_ input: String, mode: JSONFormatterMode) -> Result<String, JSONFormatterError> {
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

