//
//  FormatterErrorTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 28/07/2025.
//

import Testing
import Foundation
@testable import NotchUtility

@MainActor
struct FormatterErrorTests {
    
    let service = FormatterService()
    
    // MARK: - Error Tests
    
    @Test("Test formatter error descriptions")
    func testFormatterErrorDescriptions() async throws {
        #expect(FormatterService.FormatterError.invalidInput.localizedDescription == "Invalid input provided")
        #expect(FormatterService.FormatterError.invalidJSON.localizedDescription == "Invalid JSON format")
        #expect(FormatterService.FormatterError.invalidXML.localizedDescription == "Invalid XML format")
        #expect(FormatterService.FormatterError.formattingFailed.localizedDescription == "Failed to format the input")
    }
    
    @Test("Format empty input returns error")
    func testFormatEmptyInput() async throws {
        // Test JSON
        let jsonResult = service.formatJSON("")
        switch jsonResult {
        case .success:
            Issue.record("Empty JSON input should fail")
        case .failure(let error):
            #expect(error == FormatterService.FormatterError.invalidInput)
        }
        
        // Test XML
        let xmlResult = service.formatXML("")
        switch xmlResult {
        case .success:
            Issue.record("Empty XML input should fail")
        case .failure(let error):
            #expect(error == FormatterService.FormatterError.invalidInput)
        }
    }
    
    @Test("Format whitespace-only input returns error")
    func testFormatWhitespaceOnlyInput() async throws {
        let whitespaceInput = "   \n\t  "
        
        // Test JSON
        let jsonResult = service.formatJSON(whitespaceInput)
        switch jsonResult {
        case .success:
            Issue.record("Whitespace-only JSON input should fail")
        case .failure(let error):
            #expect(error == FormatterService.FormatterError.invalidInput)
        }
        
        // Test XML
        let xmlResult = service.formatXML(whitespaceInput)
        switch xmlResult {
        case .success:
            Issue.record("Whitespace-only XML input should fail")
        case .failure(let error):
            #expect(error == FormatterService.FormatterError.invalidInput)
        }
    }
} 