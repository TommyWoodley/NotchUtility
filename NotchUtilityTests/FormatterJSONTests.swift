//
//  FormatterJSONTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 28/07/2025.
//

import Testing
import Foundation
@testable import NotchUtility

@MainActor
struct FormatterJSONTests {
    
    let service = FormatterService()
    
    // MARK: - JSON Formatting Tests
    
    @Test("Format simple JSON object")
    func testFormatSimpleJSON() async throws {
        let input = #"{"name":"John","age":30}"#
        let result = service.formatJSON(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("\"name\" : \"John\""))
            #expect(formatted.contains("\"age\" : 30"))
            #expect(formatted.contains("\n")) // Should have pretty printing
        case .failure:
            Issue.record("JSON formatting should succeed for valid input")
        }
    }
    
    @Test("Format nested JSON object")
    func testFormatNestedJSON() async throws {
        let input = #"{"user":{"name":"John","details":{"age":30,"city":"New York"}},"active":true}"#
        let result = service.formatJSON(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("\"user\""))
            #expect(formatted.contains("\"details\""))
            #expect(formatted.contains("\"age\" : 30"))
            #expect(formatted.contains("\"city\" : \"New York\""))
            #expect(formatted.contains("\"active\" : true"))
            // Should have proper indentation
            let lines = formatted.components(separatedBy: .newlines)
            #expect(lines.count > 1) // Multiple lines
        case .failure:
            Issue.record("Nested JSON formatting should succeed")
        }
    }
    
    @Test("Format JSON array")
    func testFormatJSONArray() async throws {
        let input = #"[{"name":"John","age":30},{"name":"Jane","age":25}]"#
        let result = service.formatJSON(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("\"name\" : \"John\""))
            #expect(formatted.contains("\"name\" : \"Jane\""))
            #expect(formatted.contains("\"age\" : 30"))
            #expect(formatted.contains("\"age\" : 25"))
            #expect(formatted.contains("\n")) // Should have pretty printing
        case .failure:
            Issue.record("JSON array formatting should succeed")
        }
    }
    
    @Test("Format empty JSON object and array")
    func testFormatEmptyJSON() async throws {
        let inputs = ["{}", "[]"]
        
        for input in inputs {
            let result = service.formatJSON(input)
            switch result {
            case .success(let formatted):
                #expect(!formatted.isEmpty)
            case .failure:
                Issue.record("Empty JSON formatting should succeed for '\(input)'")
            }
        }
    }
    
    @Test("Format JSON with Unicode characters")
    func testFormatJSONWithUnicode() async throws {
        let input = #"{"message":"Hello 🌍","emoji":"🚀","chinese":"你好"}"#
        let result = service.formatJSON(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("🌍"))
            #expect(formatted.contains("🚀"))
            #expect(formatted.contains("你好"))
        case .failure:
            Issue.record("JSON with Unicode should format successfully")
        }
    }
    
    @Test("Handle invalid JSON strings", arguments: [
        #"{"name":"John","age":}"#,  // Missing value
        #"{"name":"John",}"#,         // Trailing comma
        #"{name:"John"}"#,            // Unquoted key
        #"{"name":"John""age":30}"#,  // Missing comma
        #"{'name':'John'}"#,          // Single quotes
        #"undefined"#,                // Not JSON
        #"{"unclosed":"string"#       // Unclosed string
    ])
    func testFormatInvalidJSON(invalidJSON: String) async throws {
        let result = service.formatJSON(invalidJSON)
        
        switch result {
        case .success:
            Issue.record("Invalid JSON should fail formatting: '\(invalidJSON)'")
        case .failure(let error):
            #expect(error == FormatterService.FormatterError.invalidJSON)
        }
    }
    
    @Test("Format empty JSON input returns error")
    func testFormatEmptyJSONInput() async throws {
        let result = service.formatJSON("")
        
        switch result {
        case .success:
            Issue.record("Empty input should fail")
        case .failure(let error):
            #expect(error == FormatterService.FormatterError.invalidInput)
        }
    }
    
    @Test("Format whitespace-only JSON input returns error")
    func testFormatWhitespaceOnlyJSONInput() async throws {
        let result = service.formatJSON("   \n\t  ")
        
        switch result {
        case .success:
            Issue.record("Whitespace-only input should fail")
        case .failure(let error):
            #expect(error == FormatterService.FormatterError.invalidInput)
        }
    }
    
    @Test("Validate correct JSON strings", arguments: [
        #"{"name":"John"}"#,
        #"{"age":30}"#,
        #"[]"#,
        #"{}"#,
        #"[{"name":"John"},{"name":"Jane"}]"#,
        #"{"nested":{"value":true}}"#,
        #"123"#,
        #""string""#,
        #"true"#,
        #"null"#
    ])
    func testIsValidJSONPositive(jsonString: String) async throws {
        #expect(service.isValidJSON(jsonString), "'\(jsonString)' should be valid JSON")
    }
    
    @Test("Validate incorrect JSON strings", arguments: [
        #"{"name":"John","age":}"#,  // Missing value
        #"{"name":"John",}"#,         // Trailing comma
        #"{name:"John"}"#,            // Unquoted key
        #"undefined"#,                // Not JSON
        #"{'name':'John'}"#           // Single quotes
    ])
    func testIsValidJSONNegative(invalidJSON: String) async throws {
        #expect(!service.isValidJSON(invalidJSON), "'\(invalidJSON)' should be invalid JSON")
    }
    
    @Test("Handle very large JSON formatting")
    func testVeryLargeJSONFormatting() async throws {
        // Create a large JSON object
        var jsonObject: [String: Any] = [:]
        for index in 0..<1000 {
            jsonObject["key\(index)"] = "value\(index)"
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            Issue.record("Failed to create test JSON string")
            return
        }
        
        let result = service.formatJSON(jsonString)
        
        switch result {
        case .success(let formatted):
            #expect(!formatted.isEmpty, "Should format very large JSON")
            #expect(formatted.contains("\"key0\""), "Should contain first key")
            #expect(formatted.contains("\"key999\""), "Should contain last key")
        case .failure:
            Issue.record("Should successfully format very large JSON")
        }
    }
    
    @Test("Handle JSON with all data types")
    func testJSONWithAllDataTypes() async throws {
        let input = #"""
        {
            "string": "Hello",
            "number": 42,
            "float": 3.14,
            "boolean": true,
            "null_value": null,
            "array": [1, 2, 3],
            "object": {"nested": "value"}
        }
        """#
        
        let result = service.formatJSON(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("\"string\" : \"Hello\""))
            #expect(formatted.contains("\"number\" : 42"))
            #expect(formatted.contains("\"float\" : 3.14"))
            #expect(formatted.contains("\"boolean\" : true"))
            #expect(formatted.contains("\"null_value\" : null"))
            #expect(formatted.contains("\"array\""))
            #expect(formatted.contains("\"object\""))
        case .failure:
            Issue.record("Should successfully format JSON with all data types")
        }
    }
    
    // MARK: - FormatterMode Enum Tests
    
    @Test("FormatterMode enum properties")
    func testFormatterModeProperties() async throws {
        // Test JSON mode
        #expect(FormatterMode.json.title == "JSON")
        #expect(FormatterMode.json.icon == "curlybraces")
        #expect(FormatterMode.json.inputLabel == "JSON Input:")
        #expect(FormatterMode.json.outputLabel == "Formatted JSON:")
        
        // Test XML mode
        #expect(FormatterMode.xml.title == "XML")
        #expect(FormatterMode.xml.icon == "chevron.left.forwardslash.chevron.right")
        #expect(FormatterMode.xml.inputLabel == "XML Input:")
        #expect(FormatterMode.xml.outputLabel == "Formatted XML:")
        
        // Test that both modes are present in allCases
        #expect(FormatterMode.allCases.count == 2)
        #expect(FormatterMode.allCases.contains(.json))
        #expect(FormatterMode.allCases.contains(.xml))
    }
    
    // MARK: - Error Tests
    
    @Test("Test formatter error descriptions")
    func testFormatterErrorDescriptions() async throws {
        #expect(FormatterService.FormatterError.invalidInput.localizedDescription == "Invalid input provided")
        #expect(FormatterService.FormatterError.invalidJSON.localizedDescription == "Invalid JSON format")
        #expect(FormatterService.FormatterError.invalidXML.localizedDescription == "Invalid XML format")
        #expect(FormatterService.FormatterError.formattingFailed.localizedDescription == "Failed to format the input")
    }
} 