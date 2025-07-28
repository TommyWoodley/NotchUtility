//
//  BindingExtensionTests.swift
//  NotchUtilityTests
//
//  Created by thwoodle on 28/07/2025.
//

import XCTest
import SwiftUI
@testable import NotchUtility

/// Unit tests for the Binding+IsPresent extension
final class BindingExtensionTests: XCTestCase {
    
    // MARK: - Test Data Types
    
    private struct TestItem: Equatable {
        let id: Int
        let name: String
    }
    
    // MARK: - Tests for String Optional
    
    func testIsPresentWithStringValue() {
        // Given
        var optionalString: String? = "Hello World"
        let binding = Binding(
            get: { optionalString },
            set: { optionalString = $0 }
        )
        
        // When
        let isPresentBinding = binding.isPresent()
        
        // Then
        XCTAssertTrue(isPresentBinding.wrappedValue, "isPresent should return true when optional has a value")
    }
    
    func testIsPresentWithNilString() {
        // Given
        var optionalString: String?
        let binding = Binding(
            get: { optionalString },
            set: { optionalString = $0 }
        )
        
        // When
        let isPresentBinding = binding.isPresent()
        
        // Then
        XCTAssertFalse(isPresentBinding.wrappedValue, "isPresent should return false when optional is nil")
    }
    
    func testSetToFalseNilsStringValue() {
        // Given
        var optionalString: String? = "Hello World"
        let binding = Binding(
            get: { optionalString },
            set: { optionalString = $0 }
        )
        let isPresentBinding = binding.isPresent()
        
        // When
        isPresentBinding.wrappedValue = false
        
        // Then
        XCTAssertNil(optionalString, "Setting isPresent to false should nil the optional value")
        XCTAssertFalse(isPresentBinding.wrappedValue, "isPresent should now return false")
    }
    
    func testSetToTrueDoesNotChangeStringValue() {
        // Given
        var optionalString: String? = "Hello World"
        let originalValue = optionalString
        let binding = Binding(
            get: { optionalString },
            set: { optionalString = $0 }
        )
        let isPresentBinding = binding.isPresent()
        
        // When
        isPresentBinding.wrappedValue = true
        
        // Then
        XCTAssertEqual(optionalString, originalValue, "Setting isPresent to true should not change the optional value")
        XCTAssertTrue(isPresentBinding.wrappedValue, "isPresent should still return true")
    }
    
    // MARK: - Tests for Custom Type Optional
    
    func testIsPresentWithCustomTypeValue() {
        // Given
        var optionalItem: TestItem? = TestItem(id: 1, name: "Test Item")
        let binding = Binding(
            get: { optionalItem },
            set: { optionalItem = $0 }
        )
        
        // When
        let isPresentBinding = binding.isPresent()
        
        // Then
        XCTAssertTrue(isPresentBinding.wrappedValue, "isPresent should return true when custom type optional has a value")
    }
    
    func testIsPresentWithNilCustomType() {
        // Given
        var optionalItem: TestItem?
        let binding = Binding(
            get: { optionalItem },
            set: { optionalItem = $0 }
        )
        
        // When
        let isPresentBinding = binding.isPresent()
        
        // Then
        XCTAssertFalse(isPresentBinding.wrappedValue, "isPresent should return false when custom type optional is nil")
    }
    
    func testSetToFalseNilsCustomTypeValue() {
        // Given
        var optionalItem: TestItem? = TestItem(id: 1, name: "Test Item")
        let binding = Binding(
            get: { optionalItem },
            set: { optionalItem = $0 }
        )
        let isPresentBinding = binding.isPresent()
        
        // When
        isPresentBinding.wrappedValue = false
        
        // Then
        XCTAssertNil(optionalItem, "Setting isPresent to false should nil the custom type optional value")
        XCTAssertFalse(isPresentBinding.wrappedValue, "isPresent should now return false")
    }
    
    // MARK: - Tests for Integer Optional
    
    func testIsPresentWithIntegerValue() {
        // Given
        var optionalInt: Int? = 42
        let binding = Binding(
            get: { optionalInt },
            set: { optionalInt = $0 }
        )
        
        // When
        let isPresentBinding = binding.isPresent()
        
        // Then
        XCTAssertTrue(isPresentBinding.wrappedValue, "isPresent should return true when integer optional has a value")
    }
    
    func testIsPresentWithZeroInteger() {
        // Given
        var optionalInt: Int? = 0
        let binding = Binding(
            get: { optionalInt },
            set: { optionalInt = $0 }
        )
        
        // When
        let isPresentBinding = binding.isPresent()
        
        // Then
        XCTAssertTrue(isPresentBinding.wrappedValue, "isPresent should return true even when integer value is 0")
    }
    
    // MARK: - State Change Tests
    
    func testTransitionFromNilToValue() {
        // Given
        var optionalString: String?
        let binding = Binding(
            get: { optionalString },
            set: { optionalString = $0 }
        )
        let isPresentBinding = binding.isPresent()
        
        // Initially nil
        XCTAssertFalse(isPresentBinding.wrappedValue)
        
        // When
        optionalString = "New Value"
        
        // Then
        XCTAssertTrue(isPresentBinding.wrappedValue, "isPresent should return true after value is set")
    }
    
    func testTransitionFromValueToNil() {
        // Given
        var optionalString: String? = "Initial Value"
        let binding = Binding(
            get: { optionalString },
            set: { optionalString = $0 }
        )
        let isPresentBinding = binding.isPresent()
        
        // Initially has value
        XCTAssertTrue(isPresentBinding.wrappedValue)
        
        // When
        optionalString = nil
        
        // Then
        XCTAssertFalse(isPresentBinding.wrappedValue, "isPresent should return false after value is set to nil")
    }
    
    // MARK: - Multiple Binding Operations Tests
    
    func testMultipleOperations() {
        // Given
        var optionalString: String? = "Initial"
        let binding = Binding(
            get: { optionalString },
            set: { optionalString = $0 }
        )
        let isPresentBinding = binding.isPresent()
        
        // Test sequence of operations
        XCTAssertTrue(isPresentBinding.wrappedValue, "Should start as true")
        
        // Set to false (should nil the value)
        isPresentBinding.wrappedValue = false
        XCTAssertNil(optionalString)
        XCTAssertFalse(isPresentBinding.wrappedValue)
        
        // Set original value back
        optionalString = "Restored"
        XCTAssertTrue(isPresentBinding.wrappedValue)
        
        // Set to true (should not change value)
        isPresentBinding.wrappedValue = true
        XCTAssertEqual(optionalString, "Restored")
        XCTAssertTrue(isPresentBinding.wrappedValue)
        
        // Set to false again
        isPresentBinding.wrappedValue = false
        XCTAssertNil(optionalString)
        XCTAssertFalse(isPresentBinding.wrappedValue)
    }
} 