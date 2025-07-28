//
//  Base64Service.swift
//  NotchUtility
//
//  Created by thwoodle on 28/07/2025.
//

import Foundation
import SwiftUI

// MARK: - Base64 Mode Definition
enum Base64Mode: CaseIterable, Identifiable {
    case encode
    case decode
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .encode: return "Encode"
        case .decode: return "Decode"
        }
    }
    
    var icon: String {
        switch self {
        case .encode: return "arrow.up.square"
        case .decode: return "arrow.down.square"
        }
    }
    
    var inputLabel: String {
        switch self {
        case .encode: return "Input Text:"
        case .decode: return "Base64 Input:"
        }
    }
    
    var outputLabel: String {
        switch self {
        case .encode: return "Base64 Output:"
        case .decode: return "Decoded Text:"
        }
    }
}

// Conformance to ConversionMode will be handled via extension in DevToolModals.swift

@MainActor
class Base64ToolService: ObservableObject {
    
    enum Base64Error: LocalizedError {
        case invalidInput
        case encodingFailed
        case decodingFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidInput:
                return "Invalid input provided"
            case .encodingFailed:
                return "Failed to encode text to Base64"
            case .decodingFailed:
                return "Failed to decode Base64 string"
            }
        }
    }
    
    // MARK: - Public Methods
    
    nonisolated func encode(_ text: String) -> Result<String, Base64Error> {
        guard !text.isEmpty else {
            return .failure(.invalidInput)
        }
        
        guard let data = text.data(using: .utf8) else {
            return .failure(.encodingFailed)
        }
        
        return .success(data.base64EncodedString())
    }
    
    nonisolated func decode(_ base64String: String) -> Result<String, Base64Error> {
        guard !base64String.isEmpty else {
            return .failure(.invalidInput)
        }
        
        // Remove whitespace and newlines that might be present
        let cleanedBase64 = base64String.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = Data(base64Encoded: cleanedBase64) else {
            return .failure(.decodingFailed)
        }
        
        guard let decodedString = String(data: data, encoding: .utf8) else {
            return .failure(.decodingFailed)
        }
        
        return .success(decodedString)
    }
    
    nonisolated func isValidBase64(_ string: String) -> Bool {
        let cleanedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return Data(base64Encoded: cleanedString) != nil
    }
    
    // MARK: - ConversionService Protocol
    nonisolated func convert(_ input: String, mode: Base64Mode) -> Result<String, Base64Error> {
        switch mode {
        case .encode:
            return encode(input)
        case .decode:
            return decode(input)
        }
    }
} 
