//
//  JSONFormatterServiceTests.swift
//  NotchUtilityTests
//

import Testing
import Foundation
@testable import NotchUtility

@MainActor
struct JSONFormatterServiceTests {
    
    let service = JSONFormatterService()
    
    // MARK: - Beautify Tests
    
    @Test("Beautify simple JSON object")
    func testBeautifySimpleObject() async throws {
        let input = """
        {"name":"John","age":30}
        """
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("\n"))
            #expect(formatted.contains("  "))
        case .failure:
            Issue.record("Beautify should succeed for valid JSON")
        }
    }
    
    @Test("Beautify nested JSON object")
    func testBeautifyNestedObject() async throws {
        let input = """
        {"person":{"name":"John","address":{"city":"NYC","zip":"10001"}}}
        """
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("\n"))
            #expect(formatted.contains("person"))
            #expect(formatted.contains("address"))
        case .failure:
            Issue.record("Beautify should succeed for nested JSON")
        }
    }
    
    @Test("Beautify JSON array")
    func testBeautifyArray() async throws {
        let input = """
        [1,2,3,4,5]
        """
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("\n"))
        case .failure:
            Issue.record("Beautify should succeed for JSON array")
        }
    }
    
    @Test("Beautify empty string returns error")
    func testBeautifyEmptyString() async throws {
        let result = service.beautify("")
        
        switch result {
        case .success:
            Issue.record("Beautify should fail for empty string")
        case .failure(let error):
            #expect(error == JSONFormatterService.JSONFormatterError.invalidInput)
        }
    }
    
    @Test("Beautify whitespace-only string returns error")
    func testBeautifyWhitespaceOnly() async throws {
        let result = service.beautify("   \n\t  ")
        
        switch result {
        case .success:
            Issue.record("Beautify should fail for whitespace-only string")
        case .failure(let error):
            #expect(error == JSONFormatterService.JSONFormatterError.invalidInput)
        }
    }
    
    @Test("Beautify invalid JSON returns error")
    func testBeautifyInvalidJSON() async throws {
        let result = service.beautify("{invalid json}")
        
        switch result {
        case .success:
            Issue.record("Beautify should fail for invalid JSON")
        case .failure(let error):
            if case .invalidJSON = error {
            } else {
                Issue.record("Should return invalidJSON error")
            }
        }
    }
    
    // MARK: - Minify Tests
    
    @Test("Minify formatted JSON object")
    func testMinifyFormattedObject() async throws {
        let input = """
        {
          "name": "John",
          "age": 30
        }
        """
        let result = service.minify(input)
        
        switch result {
        case .success(let minified):
            #expect(!minified.contains("\n"))
            #expect(!minified.contains("  "))
        case .failure:
            Issue.record("Minify should succeed for valid JSON")
        }
    }
    
    @Test("Minify nested JSON object")
    func testMinifyNestedObject() async throws {
        let input = """
        {
          "person": {
            "name": "John",
            "address": {
              "city": "NYC"
            }
          }
        }
        """
        let result = service.minify(input)
        
        switch result {
        case .success(let minified):
            #expect(!minified.contains("\n"))
        case .failure:
            Issue.record("Minify should succeed for nested JSON")
        }
    }
    
    @Test("Minify empty string returns error")
    func testMinifyEmptyString() async throws {
        let result = service.minify("")
        
        switch result {
        case .success:
            Issue.record("Minify should fail for empty string")
        case .failure(let error):
            #expect(error == JSONFormatterService.JSONFormatterError.invalidInput)
        }
    }
    
    @Test("Minify invalid JSON returns error")
    func testMinifyInvalidJSON() async throws {
        let result = service.minify("{not valid}")
        
        switch result {
        case .success:
            Issue.record("Minify should fail for invalid JSON")
        case .failure(let error):
            if case .invalidJSON = error {
            } else {
                Issue.record("Should return invalidJSON error")
            }
        }
    }
    
    // MARK: - Validate Tests
    
    @Test("Validate valid JSON object")
    func testValidateValidObject() async throws {
        let input = """
        {"name":"John","age":30}
        """
        let result = service.validate(input)
        
        switch result {
        case .success(let message):
            #expect(message.contains("Valid"))
        case .failure:
            Issue.record("Validate should succeed for valid JSON")
        }
    }
    
    @Test("Validate valid JSON array")
    func testValidateValidArray() async throws {
        let input = "[1, 2, 3]"
        let result = service.validate(input)
        
        switch result {
        case .success(let message):
            #expect(message.contains("Valid"))
        case .failure:
            Issue.record("Validate should succeed for valid JSON array")
        }
    }
    
    @Test("Validate empty string returns error")
    func testValidateEmptyString() async throws {
        let result = service.validate("")
        
        switch result {
        case .success:
            Issue.record("Validate should fail for empty string")
        case .failure(let error):
            #expect(error == JSONFormatterService.JSONFormatterError.invalidInput)
        }
    }
    
    @Test("Validate invalid JSON returns error")
    func testValidateInvalidJSON() async throws {
        let result = service.validate("{missing: quotes}")
        
        switch result {
        case .success:
            Issue.record("Validate should fail for invalid JSON")
        case .failure(let error):
            if case .invalidJSON = error {
            } else {
                Issue.record("Should return invalidJSON error")
            }
        }
    }
}

@MainActor
struct JSONFormatterServiceExtendedTests {
    
    let service = JSONFormatterService()
    
    // MARK: - Convert Method Tests
    
    @Test("Convert method with beautify mode")
    func testConvertBeautifyMode() async throws {
        let input = """
        {"key":"value"}
        """
        let result = service.convert(input, mode: .beautify)
        
        switch result {
        case .success(let output):
            #expect(output.contains("\n"))
        case .failure:
            Issue.record("Convert with beautify mode should succeed")
        }
    }
    
    @Test("Convert method with minify mode")
    func testConvertMinifyMode() async throws {
        let input = """
        {
          "key": "value"
        }
        """
        let result = service.convert(input, mode: .minify)
        
        switch result {
        case .success(let output):
            #expect(!output.contains("\n"))
        case .failure:
            Issue.record("Convert with minify mode should succeed")
        }
    }
    
    @Test("Convert method with validate mode")
    func testConvertValidateMode() async throws {
        let input = """
        {"valid":"json"}
        """
        let result = service.convert(input, mode: .validate)
        
        switch result {
        case .success(let output):
            #expect(output.contains("Valid"))
        case .failure:
            Issue.record("Convert with validate mode should succeed")
        }
    }
    
    // MARK: - Round-trip Tests
    
    @Test("Round-trip beautify then minify preserves data")
    func testRoundTripBeautifyMinify() async throws {
        let original = """
        {"name":"John","items":[1,2,3]}
        """
        
        let beautifyResult = service.beautify(original)
        guard case .success(let beautified) = beautifyResult else {
            Issue.record("Beautify should succeed")
            return
        }
        
        let minifyResult = service.minify(beautified)
        guard case .success(let minified) = minifyResult else {
            Issue.record("Minify should succeed")
            return
        }
        
        #expect(minified.contains("name"))
        #expect(minified.contains("John"))
        #expect(minified.contains("items"))
    }
    
    // MARK: - Mode Properties Tests
    
    @Test("JSONFormatterMode.id returns self")
    func testModeId() async throws {
        #expect(JSONFormatterMode.beautify.id == .beautify)
        #expect(JSONFormatterMode.minify.id == .minify)
        #expect(JSONFormatterMode.validate.id == .validate)
    }
    
    @Test("JSONFormatterMode properties are correct")
    func testModeProperties() async throws {
        #expect(JSONFormatterMode.beautify.title == "Beautify")
        #expect(JSONFormatterMode.minify.title == "Minify")
        #expect(JSONFormatterMode.validate.title == "Validate")
        
        #expect(JSONFormatterMode.beautify.inputLabel == "JSON Input:")
        #expect(JSONFormatterMode.minify.inputLabel == "JSON Input:")
        #expect(JSONFormatterMode.validate.inputLabel == "JSON Input:")
        
        #expect(JSONFormatterMode.beautify.outputLabel == "Formatted JSON:")
        #expect(JSONFormatterMode.minify.outputLabel == "Minified JSON:")
        #expect(JSONFormatterMode.validate.outputLabel == "Validation Result:")
        
        #expect(JSONFormatterMode.allCases.count == 3)
    }
    
    // MARK: - Error Description Tests
    
    @Test("JSONFormatterError.invalidInput has correct description")
    func testInvalidInputErrorDescription() async throws {
        let error = JSONFormatterService.JSONFormatterError.invalidInput
        #expect(error.errorDescription == "Invalid input provided")
    }
    
    @Test("JSONFormatterError.formattingFailed has correct description")
    func testFormattingFailedErrorDescription() async throws {
        let error = JSONFormatterService.JSONFormatterError.formattingFailed
        #expect(error.errorDescription == "Failed to format JSON")
    }
    
    @Test("JSONFormatterError.invalidJSON has correct description")
    func testInvalidJSONErrorDescription() async throws {
        let error = JSONFormatterService.JSONFormatterError.invalidJSON("test message")
        #expect(error.errorDescription == "Invalid JSON: test message")
    }
    
    // MARK: - Edge Cases
    
    @Test("Handle JSON with special characters")
    func testSpecialCharacters() async throws {
        let input = """
        {"text":"Hello\\nWorld","emoji":"🎉"}
        """
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("🎉"))
        case .failure:
            Issue.record("Should handle special characters")
        }
    }
    
    @Test("Handle deeply nested JSON")
    func testDeeplyNestedJSON() async throws {
        let input = """
        {"a":{"b":{"c":{"d":{"e":"deep"}}}}}
        """
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("deep"))
        case .failure:
            Issue.record("Should handle deeply nested JSON")
        }
    }
    
    @Test("Handle JSON with boolean and null values")
    func testBooleanAndNullValues() async throws {
        let input = """
        {"active":true,"inactive":false,"nothing":null}
        """
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("true"))
            #expect(formatted.contains("false"))
            #expect(formatted.contains("null"))
        case .failure:
            Issue.record("Should handle boolean and null values")
        }
    }
    
    @Test("Handle large JSON array")
    func testLargeArray() async throws {
        let numbers = (1...100).map { String($0) }.joined(separator: ",")
        let input = "[\(numbers)]"
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("100"))
        case .failure:
            Issue.record("Should handle large arrays")
        }
    }
}
