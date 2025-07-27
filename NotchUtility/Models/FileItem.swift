//
//  FileItem.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Foundation
import AppKit

struct FileItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let path: URL
    let type: FileType
    let size: Int64
    let dateAdded: Date
    let contentHash: String
    
    // Non-codable properties (not persisted)
    var thumbnail: NSImage? {
        generateThumbnail()
    }
    
    init(id: UUID = UUID(), name: String, path: URL, type: FileType, size: Int64, dateAdded: Date = Date(), contentHash: String = "") {
        self.id = id
        self.name = name
        self.path = path
        self.type = type
        self.size = size
        self.dateAdded = dateAdded
        self.contentHash = contentHash
    }
    
    private func generateThumbnail() -> NSImage? {
        let workspace = NSWorkspace.shared
        return workspace.icon(forFile: path.path)
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var fileExtension: String {
        path.pathExtension.lowercased()
    }
    
    var supportedConversions: [ConversionFormat] {
        ConversionFormat.supportedConversions(for: fileExtension)
    }
    
    var canBeConverted: Bool {
        !supportedConversions.isEmpty
    }
    
    func canBeConverted(to format: ConversionFormat) -> Bool {
        supportedConversions.contains(format)
    }
}

enum FileType: String, CaseIterable, Codable {
    case document
    case image
    case archive
    case code
    case other
    
    static func from(fileExtension: String) -> FileType {
        let ext = fileExtension.lowercased()
        
        // TODO: Add more file types
        switch ext {
        case "pdf", "doc", "docx", "txt", "rtf", "pages":
            return .document
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp":
            return .image
        case "zip", "rar", "7z", "tar", "gz", "dmg", "pkg":
            return .archive
        case "swift", "py", "js", "ts", "html", "css", "json", "xml", "java", "cpp", "c", "h":
            return .code
        default:
            return .other
        }
    }
    
    var displayName: String {
        switch self {
        case .document: return "Document"
        case .image: return "Image"
        case .archive: return "Archive"
        case .code: return "Code"
        case .other: return "Other"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .document: return "doc.text"
        case .image: return "photo"
        case .archive: return "archivebox"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .other: return "questionmark.circle"
        }
    }
}

// MARK: - Document Conversion Support

enum ConversionFormat: String, CaseIterable, Equatable, Hashable, Identifiable {
    // Image formats
    case jpeg = "jpg"
    case png = "png"
    case tiff = "tiff"
    case bmp = "bmp"
    case gif = "gif"
    case webp = "webp"
    
    // Document formats
    case pdf = "pdf"
    case txt = "txt"
    case rtf = "rtf"
    
    var id: String { rawValue }
    
    var targetExtension: String {
        rawValue
    }
    
    var displayName: String {
        switch self {
        case .jpeg: return "JPEG"
        case .png: return "PNG"
        case .tiff: return "TIFF"
        case .bmp: return "BMP"
        case .gif: return "GIF"
        case .webp: return "WebP"
        case .pdf: return "PDF"
        case .txt: return "Plain Text"
        case .rtf: return "Rich Text"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .jpeg, .png, .tiff, .bmp, .gif, .webp: 
            return "photo"
        case .pdf: 
            return "doc.text"
        case .txt, .rtf: 
            return "doc.plaintext"
        }
    }
    
    var isImageFormat: Bool {
        switch self {
        case .jpeg, .png, .tiff, .bmp, .gif, .webp:
            return true
        case .pdf, .txt, .rtf:
            return false
        }
    }
    
    var isDocumentFormat: Bool {
        switch self {
        case .pdf, .txt, .rtf:
            return true
        case .jpeg, .png, .tiff, .bmp, .gif, .webp:
            return false
        }
    }
    
    static func supportedConversions(for fileExtension: String) -> [ConversionFormat] {
        let ext = fileExtension.lowercased()
        
        switch ext {
        // Image to image conversions
        case "jpg", "jpeg":
            return [.png, .tiff, .bmp, .gif, .webp, .pdf]
        case "png":
            return [.jpeg, .tiff, .bmp, .gif, .webp, .pdf]
        case "tiff", "tif":
            return [.jpeg, .png, .bmp, .gif, .webp, .pdf]
        case "bmp":
            return [.jpeg, .png, .tiff, .gif, .webp, .pdf]
        case "gif":
            return [.jpeg, .png, .tiff, .bmp, .webp, .pdf]
        case "webp":
            return [.jpeg, .png, .tiff, .bmp, .gif, .pdf]
            
        // Document conversions
        case "txt":
            return [.rtf, .pdf]
        case "rtf":
            return [.txt, .pdf]
        case "pdf":
            return [.jpeg, .png, .tiff] // PDF to image
            
        // Other document formats to basic formats
        case "doc", "docx":
            return [.txt, .rtf, .pdf]
        case "pages":
            return [.txt, .rtf, .pdf]
            
        default:
            return []
        }
    }
} 
