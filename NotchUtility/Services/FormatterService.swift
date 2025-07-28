//
//  FormatterService.swift
//  NotchUtility
//
//  Created by thwoodle on 28/07/2025.
//

import Foundation
import SwiftUI

// MARK: - Formatter Mode Definition
enum FormatterMode: CaseIterable, Identifiable {
    case json
    case xml
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .json: return "JSON"
        case .xml: return "XML"
        }
    }
    
    var icon: String {
        switch self {
        case .json: return "curlybraces"
        case .xml: return "chevron.left.forwardslash.chevron.right"
        }
    }
    
    var inputLabel: String {
        switch self {
        case .json: return "JSON Input:"
        case .xml: return "XML Input:"
        }
    }
    
    var outputLabel: String {
        switch self {
        case .json: return "Formatted JSON:"
        case .xml: return "Formatted XML:"
        }
    }
}

// Conformance to ConversionMode will be handled via extension in DevToolModals.swift

@MainActor
class FormatterService: ObservableObject {
    
    enum FormatterError: LocalizedError {
        case invalidInput
        case invalidJSON
        case invalidXML
        case formattingFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidInput:
                return "Invalid input provided"
            case .invalidJSON:
                return "Invalid JSON format"
            case .invalidXML:
                return "Invalid XML format"
            case .formattingFailed:
                return "Failed to format the input"
            }
        }
    }
    
    // MARK: - Public Methods
    
    nonisolated func formatJSON(_ jsonString: String) -> Result<String, FormatterError> {
        guard !jsonString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidInput)
        }
        
        guard let data = jsonString.data(using: .utf8) else {
            return .failure(.invalidJSON)
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let formattedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            
            guard let formattedString = String(data: formattedData, encoding: .utf8) else {
                return .failure(.formattingFailed)
            }
            
            return .success(formattedString)
        } catch {
            return .failure(.invalidJSON)
        }
    }
    
    nonisolated func formatXML(_ xmlString: String) -> Result<String, FormatterError> {
        guard !xmlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidInput)
        }
        
        do {
            let xmlDocument = try XMLDocument(xmlString: xmlString, options: .nodePreserveCDATA)
            
            // Set pretty printing options
            xmlDocument.characterEncoding = "UTF-8"
            
            let formattedData = xmlDocument.xmlData(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
            
            guard let formattedString = String(data: formattedData, encoding: .utf8) else {
                return .failure(.formattingFailed)
            }
            
            return .success(formattedString)
        } catch {
            return .failure(.invalidXML)
        }
    }
    
    nonisolated func isValidJSON(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            return true
        } catch {
            return false
        }
    }
    
    nonisolated func isValidXML(_ string: String) -> Bool {
        do {
            _ = try XMLDocument(xmlString: string, options: .nodePreserveCDATA)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - ConversionService Protocol
    nonisolated func convert(_ input: String, mode: FormatterMode) -> Result<String, FormatterError> {
        switch mode {
        case .json:
            return formatJSON(input)
        case .xml:
            return formatXML(input)
        }
    }
} 