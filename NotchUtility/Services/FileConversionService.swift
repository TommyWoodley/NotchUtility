import Foundation
import AppKit

struct ConversionResult {
    let data: Data
    let newFileName: String
    let format: ConversionFormat
}

class FileConversionService {
    
    // MARK: - Public Methods
    
    func convertFile(_ fileItem: FileItem, to format: ConversionFormat) async throws -> ConversionResult {
        guard fileItem.canBeConverted(to: format) else {
            throw ConversionError.unsupportedConversion
        }
        
        guard format.targetExtension != fileItem.fileExtension else {
            throw ConversionError.sameFormat
        }
        
        return try await performConversion(fileItem: fileItem, to: format)
    }
    
    // MARK: - Private Methods
    
    private func performConversion(fileItem: FileItem, to format: ConversionFormat) async throws -> ConversionResult {
        try convertImageFile(fileItem: fileItem, to: format)
    }
    
    private func convertImageFile(fileItem: FileItem, to format: ConversionFormat) throws -> ConversionResult {
        guard let image = NSImage(contentsOf: fileItem.path) else {
            throw ConversionError.invalidSourceFile
        }
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            throw ConversionError.conversionFailed
        }
        
        let fileType: NSBitmapImageRep.FileType
        let properties: [NSBitmapImageRep.PropertyKey: Any]
        
        switch format.targetExtension.lowercased() {
        case "jpg", "jpeg":
            fileType = .jpeg
            properties = [NSBitmapImageRep.PropertyKey.compressionFactor: 0.9]
        case "png":
            fileType = .png
            properties = [:]
        default:
            throw ConversionError.unsupportedFormat
        }
        
        guard let convertedData = bitmapRep.representation(using: fileType, properties: properties) else {
            throw ConversionError.conversionFailed
        }
        
        // Create output filename
        let nameWithoutExtension = (fileItem.name as NSString).deletingPathExtension
        let newFileName = "\(nameWithoutExtension).\(format.targetExtension)"
        
        return ConversionResult(
            data: convertedData,
            newFileName: newFileName,
            format: format
        )
    }
} 