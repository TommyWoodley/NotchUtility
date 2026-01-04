//
//  XMLFormatterServiceTests.swift
//  NotchUtilityTests
//

import Testing
import Foundation
@testable import NotchUtility

@MainActor
struct XMLFormatterServiceTests {
    
    let service = XMLFormatterService()
    
    // MARK: - Beautify Tests
    
    @Test("Beautify simple XML element")
    func testBeautifySimpleElement() async throws {
        let input = "<root><child>value</child></root>"
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("\n"))
            #expect(formatted.contains("root"))
            #expect(formatted.contains("child"))
        case .failure:
            Issue.record("Beautify should succeed for valid XML")
        }
    }
    
    @Test("Beautify nested XML elements")
    func testBeautifyNestedElements() async throws {
        let input = "<root><parent><child>value</child></parent></root>"
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("\n"))
            #expect(formatted.contains("parent"))
            #expect(formatted.contains("child"))
        case .failure:
            Issue.record("Beautify should succeed for nested XML")
        }
    }
    
    @Test("Beautify XML with attributes")
    func testBeautifyWithAttributes() async throws {
        let input = """
        <root id="1" name="test"><child attr="value">content</child></root>
        """
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("id=\"1\""))
            #expect(formatted.contains("name=\"test\""))
        case .failure:
            Issue.record("Beautify should succeed for XML with attributes")
        }
    }
    
    @Test("Beautify empty string returns error")
    func testBeautifyEmptyString() async throws {
        let result = service.beautify("")
        
        switch result {
        case .success:
            Issue.record("Beautify should fail for empty string")
        case .failure(let error):
            #expect(error == XMLFormatterService.XMLFormatterError.invalidInput)
        }
    }
    
    @Test("Beautify whitespace-only string returns error")
    func testBeautifyWhitespaceOnly() async throws {
        let result = service.beautify("   \n\t  ")
        
        switch result {
        case .success:
            Issue.record("Beautify should fail for whitespace-only string")
        case .failure(let error):
            #expect(error == XMLFormatterService.XMLFormatterError.invalidInput)
        }
    }
    
    @Test("Beautify invalid XML returns error")
    func testBeautifyInvalidXML() async throws {
        let result = service.beautify("<root><unclosed>")
        
        switch result {
        case .success:
            Issue.record("Beautify should fail for invalid XML")
        case .failure(let error):
            if case .invalidXML = error {
            } else {
                Issue.record("Should return invalidXML error")
            }
        }
    }
    
    // MARK: - Minify Tests
    
    @Test("Minify formatted XML")
    func testMinifyFormattedXML() async throws {
        let input = """
        <root>
          <child>value</child>
        </root>
        """
        let result = service.minify(input)
        
        switch result {
        case .success(let minified):
            #expect(!minified.contains("\n"))
        case .failure:
            Issue.record("Minify should succeed for valid XML")
        }
    }
    
    @Test("Minify nested XML")
    func testMinifyNestedXML() async throws {
        let input = """
        <root>
          <parent>
            <child>value</child>
          </parent>
        </root>
        """
        let result = service.minify(input)
        
        switch result {
        case .success(let minified):
            #expect(!minified.contains("\n"))
            #expect(minified.contains("root"))
        case .failure:
            Issue.record("Minify should succeed for nested XML")
        }
    }
    
    @Test("Minify empty string returns error")
    func testMinifyEmptyString() async throws {
        let result = service.minify("")
        
        switch result {
        case .success:
            Issue.record("Minify should fail for empty string")
        case .failure(let error):
            #expect(error == XMLFormatterService.XMLFormatterError.invalidInput)
        }
    }
    
    @Test("Minify invalid XML returns error")
    func testMinifyInvalidXML() async throws {
        let result = service.minify("<root><broken")
        
        switch result {
        case .success:
            Issue.record("Minify should fail for invalid XML")
        case .failure(let error):
            if case .invalidXML = error {
            } else {
                Issue.record("Should return invalidXML error")
            }
        }
    }
    
    // MARK: - Validate Tests
    
    @Test("Validate valid XML")
    func testValidateValidXML() async throws {
        let input = "<root><child>value</child></root>"
        let result = service.validate(input)
        
        switch result {
        case .success(let message):
            #expect(message.contains("Valid"))
        case .failure:
            Issue.record("Validate should succeed for valid XML")
        }
    }
    
    @Test("Validate XML with declaration")
    func testValidateWithDeclaration() async throws {
        let input = """
        <?xml version="1.0" encoding="UTF-8"?>
        <root>content</root>
        """
        let result = service.validate(input)
        
        switch result {
        case .success(let message):
            #expect(message.contains("Valid"))
        case .failure:
            Issue.record("Validate should succeed for XML with declaration")
        }
    }
    
    @Test("Validate empty string returns error")
    func testValidateEmptyString() async throws {
        let result = service.validate("")
        
        switch result {
        case .success:
            Issue.record("Validate should fail for empty string")
        case .failure(let error):
            #expect(error == XMLFormatterService.XMLFormatterError.invalidInput)
        }
    }
    
    @Test("Validate invalid XML returns error")
    func testValidateInvalidXML() async throws {
        let result = service.validate("<root><mismatched></wrong>")
        
        switch result {
        case .success:
            Issue.record("Validate should fail for invalid XML")
        case .failure(let error):
            if case .invalidXML = error {
            } else {
                Issue.record("Should return invalidXML error")
            }
        }
    }
}

@MainActor
struct XMLFormatterServiceExtendedTests {
    
    let service = XMLFormatterService()
    
    // MARK: - Convert Method Tests
    
    @Test("Convert method with beautify mode")
    func testConvertBeautifyMode() async throws {
        let input = "<root><child>value</child></root>"
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
        <root>
          <child>value</child>
        </root>
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
        let input = "<root><valid/></root>"
        let result = service.convert(input, mode: .validate)
        
        switch result {
        case .success(let output):
            #expect(output.contains("Valid"))
        case .failure:
            Issue.record("Convert with validate mode should succeed")
        }
    }
    
    // MARK: - Round-trip Tests
    
    @Test("Round-trip beautify then minify preserves structure")
    func testRoundTripBeautifyMinify() async throws {
        let original = "<root><child attr=\"val\">text</child></root>"
        
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
        
        #expect(minified.contains("root"))
        #expect(minified.contains("child"))
        #expect(minified.contains("text"))
    }
    
    // MARK: - Mode Properties Tests
    
    @Test("XMLFormatterMode.id returns self")
    func testModeId() async throws {
        #expect(XMLFormatterMode.beautify.id == .beautify)
        #expect(XMLFormatterMode.minify.id == .minify)
        #expect(XMLFormatterMode.validate.id == .validate)
    }
    
    @Test("XMLFormatterMode properties are correct")
    func testModeProperties() async throws {
        #expect(XMLFormatterMode.beautify.title == "Beautify")
        #expect(XMLFormatterMode.minify.title == "Minify")
        #expect(XMLFormatterMode.validate.title == "Validate")
        
        #expect(XMLFormatterMode.beautify.inputLabel == "XML Input:")
        #expect(XMLFormatterMode.minify.inputLabel == "XML Input:")
        #expect(XMLFormatterMode.validate.inputLabel == "XML Input:")
        
        #expect(XMLFormatterMode.beautify.outputLabel == "Formatted XML:")
        #expect(XMLFormatterMode.minify.outputLabel == "Minified XML:")
        #expect(XMLFormatterMode.validate.outputLabel == "Validation Result:")
        
        #expect(XMLFormatterMode.allCases.count == 3)
    }
    
    // MARK: - Error Description Tests
    
    @Test("XMLFormatterError.invalidInput has correct description")
    func testInvalidInputErrorDescription() async throws {
        let error = XMLFormatterService.XMLFormatterError.invalidInput
        #expect(error.errorDescription == "Invalid input provided")
    }
    
    @Test("XMLFormatterError.formattingFailed has correct description")
    func testFormattingFailedErrorDescription() async throws {
        let error = XMLFormatterService.XMLFormatterError.formattingFailed
        #expect(error.errorDescription == "Failed to format XML")
    }
    
    @Test("XMLFormatterError.invalidXML has correct description")
    func testInvalidXMLErrorDescription() async throws {
        let error = XMLFormatterService.XMLFormatterError.invalidXML("test message")
        #expect(error.errorDescription == "Invalid XML: test message")
    }
    
    // MARK: - Edge Cases
    
    @Test("Handle XML with CDATA")
    func testCDATASection() async throws {
        let input = "<root><![CDATA[Some <special> content]]></root>"
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("CDATA"))
        case .failure:
            Issue.record("Should handle CDATA sections")
        }
    }
    
    @Test("Handle XML with comments")
    func testXMLComments() async throws {
        let input = "<root><!-- A comment --><child/></root>"
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("root"))
        case .failure:
            Issue.record("Should handle XML comments")
        }
    }
    
    @Test("Handle XML with namespaces")
    func testXMLNamespaces() async throws {
        let input = """
        <root xmlns:ns="http://example.com"><ns:child>value</ns:child></root>
        """
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("ns:child"))
        case .failure:
            Issue.record("Should handle XML namespaces")
        }
    }
    
    @Test("Handle self-closing tags")
    func testSelfClosingTags() async throws {
        let input = "<root><empty/><also-empty /></root>"
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("empty"))
        case .failure:
            Issue.record("Should handle self-closing tags")
        }
    }
    
    @Test("Handle XML with special characters in content")
    func testSpecialCharactersInContent() async throws {
        let input = "<root><text>Hello &amp; goodbye &lt;world&gt;</text></root>"
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("root"))
        case .failure:
            Issue.record("Should handle escaped special characters")
        }
    }
    
    @Test("Handle deeply nested XML")
    func testDeeplyNestedXML() async throws {
        let input = "<a><b><c><d><e>deep</e></d></c></b></a>"
        let result = service.beautify(input)
        
        switch result {
        case .success(let formatted):
            #expect(formatted.contains("deep"))
        case .failure:
            Issue.record("Should handle deeply nested XML")
        }
    }
}
