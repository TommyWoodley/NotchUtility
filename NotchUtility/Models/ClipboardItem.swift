//
//  ClipboardItem.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Foundation
import AppKit

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: String
    let type: ClipboardType
    let dateAdded: Date
    let changeCount: Int
    
    init(id: UUID = UUID(), content: String, type: ClipboardType, dateAdded: Date = Date(), changeCount: Int) {
        self.id = id
        self.content = content
        self.type = type
        self.dateAdded = dateAdded
        self.changeCount = changeCount
    }
    
    var displayContent: String {
        // Limit display content to avoid performance issues
        let maxLength = 100
        if content.count > maxLength {
            return String(content.prefix(maxLength)) + "..."
        }
        return content
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: dateAdded)
    }
}

enum ClipboardType: String, CaseIterable, Codable {
    case text = "text"
    case image = "image"
    case url = "url"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .url: return "URL"
        case .other: return "Other"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .url: return "link"
        case .other: return "questionmark.circle"
        }
    }
} 