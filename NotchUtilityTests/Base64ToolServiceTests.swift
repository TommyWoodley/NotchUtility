//
//  Base64ToolServiceTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 27/07/2025.
//

import Testing
@testable import NotchUtility

struct Base64ToolServiceTests {
    
    let service = Base64ToolService()
    
    // MARK: - Basic Encoding Tests
    
    @Test("Encode simple text returns correct Base64")
    func encodeSimpleText() async throws {
        // Given
        let input = "Hello, World!"
        let expectedOutput = "SGVsbG8sIFdvcmxkIQ=="
        
        // When
        let result = service.encode(input)
        
        // Then
        #expect(result.isSuccess)
        #expect(result.value == expectedOutput)
        #expect(result.error == nil)
    }
    
    @Test("Encode empty string returns empty string")
    func encodeEmptyString() async throws {
        // Given
        let input = ""
        
        // When
        let result = service.encode(input)
        
        // Then
        #expect(result.isSuccess)
        #expect(result.value.isEmpty)
        #expect(result.error == nil)
    }
    
    @Test("Encode unicode text handles correctly")
    func encodeUnicodeText() async throws {
        // Given
        let input = "🚀 Swift is awesome! 🎉"
        
        // When
        let result = service.encode(input)
        
        // Then
        #expect(result.isSuccess)
        #expect(!result.value.isEmpty)
        #expect(result.error == nil)
        
        // Verify we can decode it back
        let decodeResult = service.decode(result.value)
        #expect(decodeResult.isSuccess)
        #expect(decodeResult.value == input)
    }
    
    // MARK: - Basic Decoding Tests
    
    @Test("Decode valid Base64 returns correct text")
    func decodeValidBase64() async throws {
        // Given
        let input = "SGVsbG8sIFdvcmxkIQ=="
        let expectedOutput = "Hello, World!"
        
        // When
        let result = service.decode(input)
        
        // Then
        #expect(result.isSuccess)
        #expect(result.value == expectedOutput)
        #expect(result.error == nil)
    }
    
    @Test("Decode empty string returns empty string")
    func decodeEmptyString() async throws {
        // Given
        let input = ""
        
        // When
        let result = service.decode(input)
        
        // Then
        #expect(result.isSuccess)
        #expect(result.value.isEmpty)
        #expect(result.error == nil)
    }
    
    @Test("Decode Base64 with whitespace trims and decodes")
    func decodeBase64WithWhitespace() async throws {
        // Given
        let input = "  SGVsbG8sIFdvcmxkIQ==  \n"
        let expectedOutput = "Hello, World!"
        
        // When
        let result = service.decode(input)
        
        // Then
        #expect(result.isSuccess)
        #expect(result.value == expectedOutput)
        #expect(result.error == nil)
    }
    
    // MARK: - Parameterized Round Trip Tests
    
    @Test("Round trip encoding and decoding preserves original text", arguments: [
        "Hello, World!",
        "🚀 Unicode test 🎉",
        "Line 1\nLine 2\nLine 3",
        "Special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?",
        "Numbers: 0123456789",
        "Mixed case: AbCdEfGhIjKlMnOpQrStUvWxYz",
        "Empty string test: ",
        "Single char: A",
        "Spaces and tabs: \t  \n  ",
        "JSON-like: {\"key\": \"value\", \"number\": 123}"
    ])
    func roundTripPreservesOriginal(input: String) async throws {
        // When
        let encodeResult = service.encode(input)
        
        // Then
        #expect(encodeResult.isSuccess, "Failed to encode: \(input)")
        
        let decodeResult = service.decode(encodeResult.value)
        #expect(decodeResult.isSuccess, "Failed to decode for input: \(input)")
        #expect(decodeResult.value == input, "Round trip failed for: \(input)")
    }
    
    // MARK: - Parameterized Valid Base64 Tests
    
    @Test("Valid Base64 strings are correctly identified", arguments: [
        "SGVsbG8sIFdvcmxkIQ==",
        "YWJjZGVmZw==",
        "",
        "   ", // Empty after trimming
        "QQ==", // Single character
        "VGVzdA==", // "Test"
        "VGVzdCBzdHJpbmc=", // "Test string"
        "8J+agA==" // Emoji base64
    ])
    func validBase64StringsAreIdentified(base64String: String) async throws {
        // When
        let isValid = service.isValidBase64(base64String)
        
        // Then
        #expect(isValid, "Should be valid Base64: \(base64String)")
    }
    
    // MARK: - Parameterized Invalid Base64 Tests
    
    @Test("Invalid Base64 strings are correctly rejected", arguments: [
        "This is not base64",
        "Invalid!@#$%",
        "SGVsbG8", // Missing padding
        "Not base64 at all!",
        "Contains spaces in middle",
        "123456789", // Numbers only
        "Hello World", // Plain text
        "Base64===" // Extra padding
    ])
    func invalidBase64StringsAreRejected(invalidString: String) async throws {
        // When
        let isValid = service.isValidBase64(invalidString)
        
        // Then
        #expect(!isValid, "Should be invalid Base64: \(invalidString)")
    }
    
    // MARK: - Parameterized Error Tests
    
    @Test("Invalid Base64 input produces correct error", arguments: [
        "This is not base64!",
        "Invalid characters!",
        "SGVsbG8", // Missing padding
        "123!@#abc"
    ])
    func invalidBase64ProducesCorrectError(invalidInput: String) async throws {
        // When
        let result = service.decode(invalidInput)
        
        // Then
        #expect(!result.isSuccess)
        #expect(result.value.isEmpty)
        #expect(result.error == .invalidBase64Format)
    }
    
    // MARK: - Parameterized Error Description Tests
    
    @Test("Error descriptions are correct", arguments: [
        (Base64Error.invalidInputData, "Failed to encode text"),
        (Base64Error.invalidBase64Format, "Invalid Base64 format"),
        (Base64Error.invalidUTF8Data, "Decoded data is not valid UTF-8"),
        (Base64Error.encodingFailed, "Encoding operation failed")
    ])
    func errorDescriptionsAreCorrect(error: Base64Error, expectedDescription: String) async throws {
        // Then
        #expect(error.localizedDescription == expectedDescription)
    }

}
