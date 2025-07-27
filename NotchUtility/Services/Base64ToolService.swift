//
//  Base64ToolService.swift
//  NotchUtility
//
//  Created by thwoodle on 27/07/2025.
//

import Foundation

// MARK: - Base64 Operation Result
enum Base64Result {
    case success(String)
    case failure(Base64Error)
}

// MARK: - Base64 Error Types
enum Base64Error: LocalizedError {
    case invalidInputData
    case invalidBase64Format
    case invalidUTF8Data
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidInputData:
            return "Failed to encode text"
        case .invalidBase64Format:
            return "Invalid Base64 format"
        case .invalidUTF8Data:
            return "Decoded data is not valid UTF-8"
        case .encodingFailed:
            return "Encoding operation failed"
        }
    }
}

// MARK: - Base64 Tool Service
class Base64ToolService: ObservableObject {
    
    /**
     * Encode plain text to Base64 string
     * - Parameter text: The plain text to encode
     * - Returns: Base64Result with encoded string or error
     */
    func encode(_ text: String) -> Base64Result {
        guard !text.isEmpty else {
            return .success("")
        }
        
        guard let data = text.data(using: .utf8) else {
            return .failure(.invalidInputData)
        }
        
        let encodedString = data.base64EncodedString()
        return .success(encodedString)
    }
    
    /**
     * Decode Base64 string to plain text
     * - Parameter base64String: The Base64 string to decode
     * - Returns: Base64Result with decoded string or error
     */
    func decode(_ base64String: String) -> Base64Result {
        let trimmedInput = base64String.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedInput.isEmpty else {
            return .success("")
        }
        
        guard let data = Data(base64Encoded: trimmedInput) else {
            return .failure(.invalidBase64Format)
        }
        
        guard let decodedString = String(data: data, encoding: .utf8) else {
            return .failure(.invalidUTF8Data)
        }
        
        return .success(decodedString)
    }
    
    /**
     * Validate if a string is valid Base64
     * - Parameter string: The string to validate
     * - Returns: Boolean indicating if the string is valid Base64
     */
    func isValidBase64(_ string: String) -> Bool {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else { return true }
        
        return Data(base64Encoded: trimmedString) != nil
    }
}

// MARK: - Extensions
extension Base64Result {
    var value: String {
        switch self {
        case .success(let string):
            return string
        case .failure:
            return ""
        }
    }
    
    var error: Base64Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
} 
