//
//  FormatterServiceTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 28/07/2025.
//

import Testing
import Foundation
@testable import NotchUtility

@MainActor
struct FormatterServiceTests {
    
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
    
    // MARK: - XML Formatting Tests
    
    @Test("Format simple XML")
    func testFormatSimpleXML() async throws {
        let input = "<root><name>John</name><age>30</age></root>"
        let result = service.formatXML(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("<root>"))
            #expect(formatted.contains("<name>John</name>"))
            #expect(formatted.contains("<age>30</age>"))
            #expect(formatted.contains("</root>"))
            #expect(formatted.contains("\n")) // Should have pretty printing
        case .failure:
            Issue.record("Simple XML formatting should succeed")
        }
    }
    
    @Test("Format nested XML")
    func testFormatNestedXML() async throws {
        let input = "<users><user><name>John</name><details><age>30</age><city>New York</city></details></user></users>"
        let result = service.formatXML(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("<users>"))
            #expect(formatted.contains("<user>"))
            #expect(formatted.contains("<details>"))
            #expect(formatted.contains("<name>John</name>"))
            #expect(formatted.contains("<age>30</age>"))
            #expect(formatted.contains("<city>New York</city>"))
            let lines = formatted.components(separatedBy: .newlines)
            #expect(lines.count > 1) // Multiple lines for pretty printing
        case .failure:
            Issue.record("Nested XML formatting should succeed")
        }
    }
    
    @Test("Format XML with attributes")
    func testFormatXMLWithAttributes() async throws {
        let input = #"<user id="123" active="true"><name>John</name></user>"#
        let result = service.formatXML(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("id=\"123\""))
            #expect(formatted.contains("active=\"true\""))
            #expect(formatted.contains("<name>John</name>"))
        case .failure:
            Issue.record("XML with attributes should format successfully")
        }
    }
    
    @Test("Format XML with CDATA")
    func testFormatXMLWithCDATA() async throws {
        let input = "<root><content><![CDATA[Some <special> content & data]]></content></root>"
        let result = service.formatXML(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("<![CDATA[Some <special> content & data]]>"))
            #expect(formatted.contains("<content>"))
        case .failure:
            Issue.record("XML with CDATA should format successfully")
        }
    }
    
    @Test("Format XML with Unicode characters")
    func testFormatXMLWithUnicode() async throws {
        let input = "<message>Hello 🌍</message><emoji>🚀</emoji><chinese>你好</chinese>"
        let result = service.formatXML(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("🌍"))
            #expect(formatted.contains("🚀"))
            #expect(formatted.contains("你好"))
        case .failure:
            Issue.record("XML with Unicode should format successfully")
        }
    }
    
    @Test("Handle invalid XML strings", arguments: [
        "<unclosed>",                    // Unclosed tag
        "<root><unclosed></root>",       // Mismatched tags
        "<root><child></wrong></root>",  // Wrong closing tag
        "<>empty tag</>",                // Empty tag name
        "<root><child><grandchild></child></root>", // Unclosed grandchild
        "not xml content",               // Not XML
        "<root attribute=value></root>"  // Unquoted attribute value
    ])
    func testFormatInvalidXML(invalidXML: String) async throws {
        let result = service.formatXML(invalidXML)
        
        switch result {
        case .success:
            Issue.record("Invalid XML should fail formatting: '\(invalidXML)'")
        case .failure(let error):
            #expect(error == FormatterService.FormatterError.invalidXML)
        }
    }
    
    // MARK: - Convert Method Tests
    
    @Test("Convert method with JSON mode")
    func testConvertJSONMode() async throws {
        let input = #"{"name":"John","age":30}"#
        let result = service.convert(input, mode: .json)
        
        switch result {
        case .success(let converted):
            #expect(converted.contains("\"name\" : \"John\""))
            #expect(converted.contains("\"age\" : 30"))
        case .failure:
            Issue.record("Convert with JSON mode should succeed")
        }
    }
    
    @Test("Convert method with XML mode")
    func testConvertXMLMode() async throws {
        let input = "<root><name>John</name></root>"
        let result = service.convert(input, mode: .xml)
        
        switch result {
        case .success(let converted):
            #expect(converted.contains("<root>"))
            #expect(converted.contains("<name>John</name>"))
        case .failure:
            Issue.record("Convert with XML mode should succeed")
        }
    }
    
    @Test("Convert method with invalid JSON")
    func testConvertInvalidJSON() async throws {
        let result = service.convert(#"{"invalid":}"#, mode: .json)
        
        switch result {
        case .success:
            Issue.record("Convert should fail for invalid JSON")
        case .failure(let error):
            #expect(error == FormatterService.FormatterError.invalidJSON)
        }
    }
    
    @Test("Convert method with invalid XML")
    func testConvertInvalidXML() async throws {
        let result = service.convert("<unclosed>", mode: .xml)
        
        switch result {
        case .success:
            Issue.record("Convert should fail for invalid XML")
        case .failure(let error):
            #expect(error == FormatterService.FormatterError.invalidXML)
        }
    }
    
    // MARK: - Validation Tests
    
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
    
    @Test("Validate correct XML strings", arguments: [
        "<root></root>",
        "<root><child>value</child></root>",
        #"<root id="123"></root>"#,
        "<empty/>",
        "<?xml version=\"1.0\"?><root></root>"
    ])
    func testIsValidXMLPositive(xmlString: String) async throws {
        #expect(service.isValidXML(xmlString), "'\(xmlString)' should be valid XML")
    }
    
    @Test("Validate incorrect XML strings", arguments: [
        "<unclosed>",
        "<root><unclosed></root>",
        "<root><child></wrong></root>",
        "not xml content"
    ])
    func testIsValidXMLNegative(invalidXML: String) async throws {
        #expect(!service.isValidXML(invalidXML), "'\(invalidXML)' should be invalid XML")
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
    
    // MARK: - Edge Cases
    
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
    
    @Test("Handle very large XML formatting")
    func testVeryLargeXMLFormatting() async throws {
        var xmlString = "<root>"
        for index in 0..<1000 {
            xmlString += "<item\(index)>value\(index)</item\(index)>"
        }
        xmlString += "</root>"
        
        let result = service.formatXML(xmlString)
        
        switch result {
        case .success(let formatted):
            #expect(!formatted.isEmpty, "Should format very large XML")
            #expect(formatted.contains("<item0>"), "Should contain first item")
            #expect(formatted.contains("<item999>"), "Should contain last item")
        case .failure:
            Issue.record("Should successfully format very large XML")
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
    
    @Test("Handle XML with special characters")
    func testXMLWithSpecialCharacters() async throws {
        let input = "<root><content>&lt;special&gt; &amp; encoded</content></root>"
        let result = service.formatXML(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("&lt;special&gt;"))
            #expect(formatted.contains("&amp; encoded"))
        case .failure:
            Issue.record("Should successfully format XML with special characters")
        }
    }
    
} 