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
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .base64: return "Base64"
        }
    }
    
    var icon: String {
        switch self {
        case .base64: return "arrow.left.arrow.right.square"
        }
    }
    
    var description: String {
        switch self {
        case .base64: return "Encode & Decode"
        }
    }
    
    var color: Color {
        switch self {
        case .base64: return .blue
        }
    }
} 