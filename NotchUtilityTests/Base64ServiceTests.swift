//
//  Base64ServiceTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 28/07/2025.
//

import Testing
import Foundation
@testable import NotchUtility
@MainActor
struct Base64ServiceTests {
    
    let service = Base64ToolService()
    
    // MARK: - Encoding Tests
    
    @Test("Encode simple text to Base64")
    func testEncodeSimpleText() async throws {
        let result = service.encode("Hello, World!")
        
        switch result {
        case .success(let encoded):
            #expect(encoded == "SGVsbG8sIFdvcmxkIQ==")
        case .failure:
            Issue.record("Encoding should succeed for valid input")
        }
    }
    
    @Test("Encode empty string returns error")
    func testEncodeEmptyString() async throws {
        let result = service.encode("")
        
        switch result {
        case .success:
            Issue.record("Encoding empty string should fail")
        case .failure(let error):
            #expect(error == Base64ToolService.Base64Error.invalidInput)
        }
    }
    
    @Test("Encode Unicode text correctly")
    func testEncodeUnicodeText() async throws {
        let result = service.encode("Swift is awesome! 🚀")
        
        switch result {
        case .success(let encoded):
            #expect(encoded == "U3dpZnQgaXMgYXdlc29tZSEg8J+agA==")
        case .failure:
            Issue.record("Encoding should succeed for Unicode text")
        }
    }
    
    @Test("Encode multiline text with special characters")
    func testEncodeMultilineText() async throws {
        let input = "Multi-line text\nwith\nnewlines\nand\ttabs"
        let result = service.encode(input)
        
        switch result {
        case .success(let encoded):
            #expect(encoded == "TXVsdGktbGluZSB0ZXh0CndpdGgKbmV3bGluZXMKYW5kCXRhYnM=")
        case .failure:
            Issue.record("Encoding should succeed for multiline text")
        }
    }
    
    @Test("Encode various text samples", arguments: [
        "Hello, World!",
        "The quick brown fox jumps over the lazy dog.",
        "Swift is awesome! 🚀",
        "Base64 encoding test with special chars: !@#$%^&*()_+-={}[]|\\:;\"'<>?,./ ` ~",
        "Multi-line text\nwith\nnewlines\nand\ttabs",
        "Unicode test: こんにちは 🌍 🎉 émojis",
        "Numbers: 1234567890",
        "Mixed: Hello123!@# 世界 🎯"
    ])
    func testEncodeTextSamples(plainText: String) async throws {
        let result = service.encode(plainText)
        
        switch result {
        case .success(let encoded):
            #expect(!encoded.isEmpty, "Encoded result should not be empty")
            // Verify it's valid Base64
            #expect(Data(base64Encoded: encoded) != nil, "Result should be valid Base64")
        case .failure:
            Issue.record("Encoding should succeed for: '\(plainText)'")
        }
    }
    
    // MARK: - Decoding Tests
    
    @Test("Decode simple Base64 to text")
    func testDecodeSimpleBase64() async throws {
        let result = service.decode("SGVsbG8sIFdvcmxkIQ==")
        
        switch result {
        case .success(let decoded):
            #expect(decoded == "Hello, World!")
        case .failure:
            Issue.record("Decoding should succeed for valid Base64")
        }
    }
    
    @Test("Decode empty string returns error")
    func testDecodeEmptyString() async throws {
        let result = service.decode("")
        
        switch result {
        case .success:
            Issue.record("Decoding empty string should fail")
        case .failure(let error):
            #expect(error == Base64ToolService.Base64Error.invalidInput)
        }
    }
    
    @Test("Decode Unicode Base64 correctly")
    func testDecodeUnicodeBase64() async throws {
        let result = service.decode("U3dpZnQgaXMgYXdlc29tZSEg8J+agA==")
        
        switch result {
        case .success(let decoded):
            #expect(decoded == "Swift is awesome! 🚀")
        case .failure:
            Issue.record("Decoding should succeed for Unicode Base64")
        }
    }
    
    @Test("Decode Base64 with whitespace and newlines")
    func testDecodeWithWhitespace() async throws {
        let base64WithWhitespace = "  SGVsbG8sIFdvcmxkIQ==  \n\t"
        let result = service.decode(base64WithWhitespace)
        
        switch result {
        case .success(let decoded):
            #expect(decoded == "Hello, World!")
        case .failure:
            Issue.record("Decoding should succeed after trimming whitespace")
        }
    }
    
    @Test("Decode various Base64 samples", arguments: [
        "SGVsbG8sIFdvcmxkIQ==",
        "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4=",
        "U3dpZnQgaXMgYXdlc29tZSEg8J+agA==",
        "QmFzZTY0IGVuY29kaW5nIHRlc3Qgd2l0aCBzcGVjaWFsIGNoYXJzOiAhQCMkJV4mKigpXystPXt9W118XFw6O1wiJzw+PywuLyBgIH4=",
        "TXVsdGktbGluZSB0ZXh0XG53aXRoXG5uZXdsaW5lc1xuYW5kXHR0YWJz",
        "VW5pY29kZSB0ZXN0OiDjgZPjgpPjgavjgaHjga8g8J+MjSDwn46JIMOpbW9qaXM="
    ])
    func testDecodeBase64Samples(base64Text: String) async throws {
        let result = service.decode(base64Text)
        
        switch result {
        case .success(let decoded):
            #expect(!decoded.isEmpty, "Decoded result should not be empty")
        case .failure:
            Issue.record("Decoding should succeed for: '\(base64Text)'")
        }
    }
    
    @Test("Decode invalid Base64 returns error", arguments: [
        "Invalid!Base64!",
        "SGVsbG8gV29ybGQ!", // Invalid padding
        "123",              // Too short
        "SGVsbG8@V29ybGQ=", // Invalid character @
        "SGVsbG8 V29ybGQ=", // Space in middle
        "=SGVsbG9Xb3JsZA=="  // Padding at beginning
    ])
    func testDecodeInvalidBase64(invalidBase64: String) async throws {
        let result = service.decode(invalidBase64)
        
        switch result {
        case .success:
            Issue.record("Decoding should fail for invalid Base64: '\(invalidBase64)'")
        case .failure(let error):
            #expect(error == Base64ToolService.Base64Error.decodingFailed, "Should return decodingFailed error for '\(invalidBase64)'")
        }
    }
    
    // MARK: - Round-trip Tests
    
    @Test("Round-trip encoding and decoding preserves data", arguments: [
        "Hello, World!",
        "The quick brown fox jumps over the lazy dog.",
        "Swift is awesome! 🚀",
        "Base64 encoding test with special chars: !@#$%^&*()_+-={}[]|\\:;\"'<>?,./ ` ~",
        "Multi-line text\nwith\nnewlines\nand\ttabs",
        "Unicode test: こんにちは 🌍 🎉 émojis",
        "Numbers: 1234567890",
        "Mixed: Hello123!@# 世界 🎯"
    ])
    func testRoundTripEncodeAndDecode(originalText: String) async throws {
        // Encode
        let encodeResult = service.encode(originalText)
        guard case .success(let encoded) = encodeResult else {
            Issue.record("Encoding should succeed")
            return
        }
        
        // Decode
        let decodeResult = service.decode(encoded)
        guard case .success(let decoded) = decodeResult else {
            Issue.record("Decoding should succeed")
            return
        }
        
        #expect(decoded == originalText, "Round-trip should preserve original text")
    }
    
    @Test("Round-trip with known Base64 pairs", arguments: [
        ("Hello, World!", "SGVsbG8sIFdvcmxkIQ=="),
        ("The quick brown fox jumps over the lazy dog.", "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4="),
        ("Swift is awesome! 🚀", "U3dpZnQgaXMgYXdlc29tZSEg8J+agA=="),
        ("Base64 encoding test with special chars: !@#$%^&*()_+-={}[]|\\:;\"'<>?,./ ` ~", "QmFzZTY0IGVuY29kaW5nIHRlc3Qgd2l0aCBzcGVjaWFsIGNoYXJzOiAhQCMkJV4mKigpXystPXt9W118XDo7Iic8Pj8sLi8gYCB+"),
        ("Multi-line text\nwith\nnewlines\nand\ttabs", "TXVsdGktbGluZSB0ZXh0CndpdGgKbmV3bGluZXMKYW5kCXRhYnM="),
        ("Unicode test: こんにちは 🌍 🎉 émojis", "VW5pY29kZSB0ZXN0OiDjgZPjgpPjgavjgaHjga8g8J+MjSDwn46JIMOpbW9qaXM=")
    ])
    func testRoundTripKnownPairs(plainText: String, expectedBase64: String) async throws {
        // Test encoding
        let encodeResult = service.encode(plainText)
        guard case .success(let encoded) = encodeResult else {
            Issue.record("Encoding should succeed")
            return
        }
        #expect(encoded == expectedBase64, "Encoded result should match expected")
        
        // Test decoding
        let decodeResult = service.decode(expectedBase64)
        guard case .success(let decoded) = decodeResult else {
            Issue.record("Decoding should succeed")
            return
        }
        #expect(decoded == plainText, "Decoded result should match original")
    }
    
    // MARK: - Convert Method Tests
    
    @Test("Convert method with encode mode")
    func testConvertEncodeMode() async throws {
        let result = service.convert("Hello, World!", mode: .encode)
        
        switch result {
        case .success(let converted):
            #expect(converted == "SGVsbG8sIFdvcmxkIQ==")
        case .failure:
            Issue.record("Convert with encode mode should succeed")
        }
    }
    
    @Test("Convert method with decode mode")
    func testConvertDecodeMode() async throws {
        let result = service.convert("SGVsbG8sIFdvcmxkIQ==", mode: .decode)
        
        switch result {
        case .success(let converted):
            #expect(converted == "Hello, World!")
        case .failure:
            Issue.record("Convert with decode mode should succeed")
        }
    }
    
    @Test("Convert method with invalid input for encode mode")
    func testConvertInvalidInputEncodeMode() async throws {
        let result = service.convert("", mode: .encode)
        
        switch result {
        case .success:
            Issue.record("Convert should fail for empty input in encode mode")
        case .failure(let error):
            #expect(error == Base64ToolService.Base64Error.invalidInput)
        }
    }
    
    @Test("Convert method with invalid input for decode mode")
    func testConvertInvalidInputDecodeMode() async throws {
        let result = service.convert("Invalid!Base64!", mode: .decode)
        
        switch result {
        case .success:
            Issue.record("Convert should fail for invalid Base64 in decode mode")
        case .failure(let error):
            #expect(error == Base64ToolService.Base64Error.decodingFailed)
        }
    }
    
    // MARK: - Validation Tests
    
    @Test("Validate correct Base64 strings", arguments: [
        "SGVsbG8sIFdvcmxkIQ==",
        "VGVzdA==",
        "QQ==",
        "QWxhZGRpbjpvcGVuIHNlc2FtZQ==",
        "TWFueSBoYW5kcyBtYWtlIGxpZ2h0IHdvcmsu"
    ])
    func testIsValidBase64Positive(base64String: String) async throws {
        #expect(service.isValidBase64(base64String), "'\(base64String)' should be valid Base64")
    }
    
    @Test("Validate incorrect Base64 strings", arguments: [
        "Invalid!Base64!",
        "SGVsbG8gV29ybGQ!", // Invalid padding
        "123",              // Too short
        "SGVsbG8@V29ybGQ=", // Invalid character @
        "SGVsbG8 V29ybGQ=", // Space in middle
        "=SGVsbG9Xb3JsZA=="  // Padding at beginning
    ])
    func testIsValidBase64Negative(invalidBase64: String) async throws {
        #expect(!service.isValidBase64(invalidBase64), "'\(invalidBase64)' should be invalid Base64")
    }
    
    @Test("Validate Base64 with whitespace")
    func testIsValidBase64WithWhitespace() async throws {
        let base64WithWhitespace = "  SGVsbG8sIFdvcmxkIQ==  \n\t"
        #expect(service.isValidBase64(base64WithWhitespace), "Base64 with whitespace should be valid after trimming")
    }
    
    @Test("Validate empty string as invalid Base64")
    func testIsValidBase64EmptyString() async throws {
        #expect(service.isValidBase64(""), "Empty string should be valid Base64")
    }
    
    // MARK: - Edge Cases
    
    @Test("Handle very long text encoding")
    func testVeryLongTextEncoding() async throws {
        let longText = String(repeating: "A", count: 10000)
        let result = service.encode(longText)
        
        switch result {
        case .success(let encoded):
            #expect(!encoded.isEmpty, "Should encode very long text")
            #expect(service.isValidBase64(encoded), "Result should be valid Base64")
        case .failure:
            Issue.record("Should successfully encode very long text")
        }
    }
    
    @Test("Handle text with only special characters")
    func testSpecialCharactersOnly() async throws {
        let specialChars = "!@#$%^&*()_+-={}[]|\\:;\"'<>?,./ ` ~"
        let result = service.encode(specialChars)
        
        switch result {
        case .success(let encoded):
            // Verify round-trip
            let decodeResult = service.decode(encoded)
            guard case .success(let decoded) = decodeResult else {
                Issue.record("Should be able to decode the encoded special characters")
                return
            }
            #expect(decoded == specialChars, "Special characters should survive round-trip")
        case .failure:
            Issue.record("Should successfully encode special characters")
        }
    }
    
    @Test("Handle Base64 Mode enum properties")
    func testBase64ModeProperties() async throws {
        // Test encode mode
        #expect(Base64Mode.encode.title == "Encode")
        #expect(Base64Mode.encode.icon == "arrow.up.square")
        #expect(Base64Mode.encode.inputLabel == "Input Text:")
        #expect(Base64Mode.encode.outputLabel == "Base64 Output:")
        
        // Test decode mode
        #expect(Base64Mode.decode.title == "Decode")
        #expect(Base64Mode.decode.icon == "arrow.down.square")
        #expect(Base64Mode.decode.inputLabel == "Base64 Input:")
        #expect(Base64Mode.decode.outputLabel == "Decoded Text:")
        
        // Test that both modes are present in allCases
        #expect(Base64Mode.allCases.count == 2)
        #expect(Base64Mode.allCases.contains(.encode))
        #expect(Base64Mode.allCases.contains(.decode))
    }
}

// MARK: - Extended Base64 Service Tests
@MainActor
struct Base64ServiceExtendedTests {
    
    let service = Base64ToolService()
    
    // MARK: - Base64Mode Identity Tests
    
    @Test("Base64Mode.id returns self")
    func testBase64ModeId() async throws {
        #expect(Base64Mode.encode.id == .encode)
        #expect(Base64Mode.decode.id == .decode)
    }
    
    // MARK: - Error Description Tests
    
    @Test("Base64Error.invalidInput has correct error description")
    func testInvalidInputErrorDescription() async throws {
        let error = Base64ToolService.Base64Error.invalidInput
        #expect(error.errorDescription == "Invalid input provided")
    }
    
    @Test("Base64Error.encodingFailed has correct error description")
    func testEncodingFailedErrorDescription() async throws {
        let error = Base64ToolService.Base64Error.encodingFailed
        #expect(error.errorDescription == "Failed to encode text to Base64")
    }
    
    @Test("Base64Error.decodingFailed has correct error description")
    func testDecodingFailedErrorDescription() async throws {
        let error = Base64ToolService.Base64Error.decodingFailed
        #expect(error.errorDescription == "Failed to decode Base64 string")
    }
    
    // MARK: - Decode Non-UTF8 Data Tests
    
    @Test("Decode valid Base64 containing non-UTF8 bytes returns decodingFailed")
    func testDecodeNonUtf8Data() async throws {
        // This is valid Base64 that decodes to bytes that are not valid UTF-8
        // The bytes 0x80, 0x81, 0x82, 0x83 are not valid UTF-8 sequences
        let invalidUtf8Base64 = "gIGCgw=="  // Decodes to [0x80, 0x81, 0x82, 0x83]
        
        let result = service.decode(invalidUtf8Base64)
        
        switch result {
        case .success:
            Issue.record("Decoding non-UTF8 data should fail")
        case .failure(let error):
            #expect(error == Base64ToolService.Base64Error.decodingFailed)
        }
    }
    
    @Test("Decode valid Base64 with invalid UTF8 sequence")
    func testDecodeInvalidUtf8Sequence() async throws {
        // 0xFF is never valid in UTF-8
        let invalidUtf8Base64 = "/w=="  // Decodes to [0xFF]
        
        let result = service.decode(invalidUtf8Base64)
        
        switch result {
        case .success:
            Issue.record("Decoding invalid UTF-8 sequence should fail")
        case .failure(let error):
            #expect(error == Base64ToolService.Base64Error.decodingFailed)
        }
    }
    
    // MARK: - Additional Edge Cases
    
    @Test("Encode single character")
    func testEncodeSingleCharacter() async throws {
        let result = service.encode("A")
        
        switch result {
        case .success(let encoded):
            #expect(encoded == "QQ==")
        case .failure:
            Issue.record("Should encode single character")
        }
    }
    
    @Test("Decode single character Base64")
    func testDecodeSingleCharacter() async throws {
        let result = service.decode("QQ==")
        
        switch result {
        case .success(let decoded):
            #expect(decoded == "A")
        case .failure:
            Issue.record("Should decode single character Base64")
        }
    }
    
    @Test("Encode whitespace only string")
    func testEncodeWhitespaceOnly() async throws {
        let result = service.encode("   ")
        
        switch result {
        case .success(let encoded):
            #expect(!encoded.isEmpty)
            // Verify round-trip
            let decodeResult = service.decode(encoded)
            guard case .success(let decoded) = decodeResult else {
                Issue.record("Should decode whitespace")
                return
            }
            #expect(decoded == "   ")
        case .failure:
            Issue.record("Should encode whitespace-only string")
        }
    }
    
    @Test("isValidBase64 returns false for whitespace-only string")
    func testIsValidBase64WhitespaceOnly() async throws {
        // Whitespace-only strings after trimming become empty, which is valid Base64
        #expect(service.isValidBase64("   ") == true)
    }
    
    @Test("Convert method handles both modes correctly in sequence")
    func testConvertBothModesInSequence() async throws {
        let originalText = "Test sequence"
        
        // Encode
        let encodeResult = service.convert(originalText, mode: .encode)
        guard case .success(let encoded) = encodeResult else {
            Issue.record("Encoding should succeed")
            return
        }
        
        // Decode
        let decodeResult = service.convert(encoded, mode: .decode)
        guard case .success(let decoded) = decodeResult else {
            Issue.record("Decoding should succeed")
            return
        }
        
        #expect(decoded == originalText)
    }
    
    @Test("Base64Error conforms to LocalizedError")
    func testBase64ErrorConformsToLocalizedError() async throws {
        let errors: [Base64ToolService.Base64Error] = [.invalidInput, .encodingFailed, .decodingFailed]
        
        for error in errors {
            // LocalizedError requires errorDescription to be non-nil
            guard let description = error.errorDescription else {
                Issue.record("Error \(error) should have a description")
                continue
            }
            #expect(!description.isEmpty, "Error description should not be empty")
        }
    }
    
    @Test("Base64Mode is Equatable")
    func testBase64ModeEquatable() async throws {
        #expect(Base64Mode.encode == Base64Mode.encode)
        #expect(Base64Mode.decode == Base64Mode.decode)
        #expect(Base64Mode.encode != Base64Mode.decode)
    }
    
    @Test("Base64Error is Equatable")
    func testBase64ErrorEquatable() async throws {
        #expect(Base64ToolService.Base64Error.invalidInput == Base64ToolService.Base64Error.invalidInput)
        #expect(Base64ToolService.Base64Error.encodingFailed == Base64ToolService.Base64Error.encodingFailed)
        #expect(Base64ToolService.Base64Error.decodingFailed == Base64ToolService.Base64Error.decodingFailed)
        #expect(Base64ToolService.Base64Error.invalidInput != Base64ToolService.Base64Error.decodingFailed)
    }
    
    @Test("Encode and decode preserves null character")
    func testNullCharacter() async throws {
        let textWithNull = "Hello\0World"
        let encodeResult = service.encode(textWithNull)
        
        guard case .success(let encoded) = encodeResult else {
            Issue.record("Should encode text with null character")
            return
        }
        
        let decodeResult = service.decode(encoded)
        guard case .success(let decoded) = decodeResult else {
            Issue.record("Should decode text with null character")
            return
        }
        
        #expect(decoded == textWithNull)
    }
    
    @Test("Decode Base64 with only padding")
    func testDecodeOnlyPadding() async throws {
        // "==" is technically invalid Base64
        let result = service.decode("==")
        
        switch result {
        case .success:
            Issue.record("Decoding only padding should fail or return empty")
        case .failure(let error):
            #expect(error == Base64ToolService.Base64Error.decodingFailed)
        }
    }
} 
