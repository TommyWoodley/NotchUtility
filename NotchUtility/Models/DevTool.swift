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
    case jsonFormatter
    case xmlFormatter
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .base64: return "Base64"
        case .jsonFormatter: return "JSON"
        case .xmlFormatter: return "XML"
        }
    }
    
    var icon: String {
        switch self {
        case .base64: return "arrow.left.arrow.right.square"
        case .jsonFormatter: return "curlybraces"
        case .xmlFormatter: return "chevron.left.forwardslash.chevron.right"
        }
    }
    
    var description: String {
        switch self {
        case .base64: return "Encode & Decode"
        case .jsonFormatter: return "Format & Validate"
        case .xmlFormatter: return "Format & Validate"
        }
    }
    
    var color: Color {
        switch self {
        case .base64: return .blue
        case .jsonFormatter: return .orange
        case .xmlFormatter: return .green
        }
    }
} 