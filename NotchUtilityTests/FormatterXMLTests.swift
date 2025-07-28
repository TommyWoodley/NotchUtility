//
//  FormatterXMLTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 28/07/2025.
//

import Testing
import Foundation
@testable import NotchUtility

@MainActor
struct FormatterXMLTests {
    
    let service = FormatterService()
    
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
    
    @Test("Format empty XML input returns error")
    func testFormatEmptyXMLInput() async throws {
        let result = service.formatXML("")
        
        switch result {
        case .success:
            Issue.record("Empty input should fail")
        case .failure(let error):
            #expect(error == FormatterService.FormatterError.invalidInput)
        }
    }
    
    @Test("Format whitespace-only XML input returns error")
    func testFormatWhitespaceOnlyXMLInput() async throws {
        let result = service.formatXML("   \n\t  ")
        
        switch result {
        case .success:
            Issue.record("Whitespace-only input should fail")
        case .failure(let error):
            #expect(error == FormatterService.FormatterError.invalidInput)
        }
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