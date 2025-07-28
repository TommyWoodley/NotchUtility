//
//  DevTool.swift
//  NotchUtility
//
//  Created by thwoodle on 27/07/2025.
//

import SwiftUI

// MARK: - Developer Tool Definition
enum DevTool: String, CaseIterable, Identifiable {
    case base64
    case formatter
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .base64: return "Base64"
        case .formatter: return "Formatter"
        }
    }
    
    var icon: String {
        switch self {
        case .base64: return "arrow.left.arrow.right.square"
        case .formatter: return "doc.text.below.ecg"
        }
    }
    
    var description: String {
        switch self {
        case .base64: return "Encode & Decode"
        case .formatter: return "JSON & XML Pretty Print"
        }
    }
    
    var color: Color {
        switch self {
        case .base64: return .blue
        case .formatter: return .green
        }
    }
} 