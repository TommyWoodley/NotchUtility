import Foundation
import AppKit
import PDFKit
import UniformTypeIdentifiers

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
            throw ConversionError.unsupportedConversion
        }
        
        return try await performConversion(fileItem: fileItem, to: format)
    }
    
    // MARK: - Private Methods
    
    private func performConversion(fileItem: FileItem, to format: ConversionFormat) async throws -> ConversionResult {
        let sourceType = FileType.from(fileExtension: fileItem.fileExtension)
        
        switch (sourceType, format.isImageFormat, format.isDocumentFormat) {
        case (.image, true, false):
            // Image to image conversion
            return try convertImageFile(fileItem: fileItem, to: format)
            
        case (.image, false, true) where format == .pdf:
            // Image to PDF conversion
            return try convertImageToPDF(fileItem: fileItem)
            
        case (.document, true, false):
            // Document to image conversion (PDF to image)
            return try convertDocumentToImage(fileItem: fileItem, to: format)
            
        case (.document, false, true):
            // Document to document conversion
            return try await convertDocumentToDocument(fileItem: fileItem, to: format)
            
        default:
            throw ConversionError.unsupportedConversion
        }
    }
    
    // MARK: - Image Conversions
    
    private func convertImageFile(fileItem: FileItem, to format: ConversionFormat) throws -> ConversionResult {
        // Load and process image (must be on main thread)
        let (_, bitmapRep) = try DispatchQueue.main.sync {
            guard let image = NSImage(contentsOf: fileItem.path) else {
                throw ConversionError.invalidSourceFile
            }
            
            guard let tiffData = image.tiffRepresentation,
                  let bitmapRep = NSBitmapImageRep(data: tiffData) else {
                throw ConversionError.conversionFailed
            }
            
            return (tiffData, bitmapRep)
        }
        
        let convertedData = try generateImageData(from: bitmapRep, format: format)
        let newFileName = generateNewFileName(from: fileItem.name, to: format)
        
        return ConversionResult(
            data: convertedData,
            newFileName: newFileName,
            format: format
        )
    }
    
    private func generateImageData(from bitmapRep: NSBitmapImageRep, format: ConversionFormat) throws -> Data {
        let fileType: NSBitmapImageRep.FileType
        let properties: [NSBitmapImageRep.PropertyKey: Any]
        
        switch format {
        case .jpeg:
            fileType = .jpeg
            properties = [NSBitmapImageRep.PropertyKey.compressionFactor: 0.9]
        case .png:
            fileType = .png
            properties = [:]
        case .tiff:
            fileType = .tiff
            properties = [:]
        case .bmp:
            fileType = .bmp
            properties = [:]
        case .gif:
            fileType = .gif
            properties = [:]
        default:
            throw ConversionError.unsupportedFormat
        }
        
        guard let convertedData = bitmapRep.representation(using: fileType, properties: properties) else {
            throw ConversionError.conversionFailed
        }
        
        return convertedData
    }
    
    private func convertImageToPDF(fileItem: FileItem) throws -> ConversionResult {
        // Create PDF from image (must be on main thread)
        let pdfData = try DispatchQueue.main.sync {
            guard let image = NSImage(contentsOf: fileItem.path) else {
                throw ConversionError.invalidSourceFile
            }
            
            let pdfDocument = PDFDocument()
            let page = PDFPage(image: image)
            guard let pdfPage = page else {
                throw ConversionError.conversionFailed
            }
            
            pdfDocument.insert(pdfPage, at: 0)
            
            guard let pdfData = pdfDocument.dataRepresentation() else {
                throw ConversionError.conversionFailed
            }
            
            return pdfData
        }
        
        let newFileName = generateNewFileName(from: fileItem.name, to: .pdf)
        
        return ConversionResult(
            data: pdfData,
            newFileName: newFileName,
            format: .pdf
        )
    }
    
    // MARK: - Document Conversions
    
    private func convertDocumentToImage(fileItem: FileItem, to format: ConversionFormat) throws -> ConversionResult {
        // Only support PDF to image for now
        guard fileItem.fileExtension.lowercased() == "pdf" else {
            throw ConversionError.unsupportedConversion
        }
        
        guard let pdfDocument = PDFDocument(url: fileItem.path),
              let firstPage = pdfDocument.page(at: 0) else {
            throw ConversionError.invalidSourceFile
        }
        
        let pageBounds = firstPage.bounds(for: .mediaBox)
        
        // Create image and draw PDF content (must be on main thread)
        let (_, bitmapRep) = try DispatchQueue.main.sync {
            let image = NSImage(size: pageBounds.size)
            
            image.lockFocus()
            if let context = NSGraphicsContext.current?.cgContext {
                context.saveGState()
                context.translateBy(x: 0, y: pageBounds.size.height)
                context.scaleBy(x: 1.0, y: -1.0)
                firstPage.draw(with: .mediaBox, to: context)
                context.restoreGState()
            }
            image.unlockFocus()
            
            // Convert NSImage to the target format
            guard let tiffData = image.tiffRepresentation,
                  let bitmapRep = NSBitmapImageRep(data: tiffData) else {
                throw ConversionError.conversionFailed
            }
            
            return (tiffData, bitmapRep)
        }
        
        let convertedData = try generateImageData(from: bitmapRep, format: format)
        let newFileName = generateNewFileName(from: fileItem.name, to: format)
        
        return ConversionResult(
            data: convertedData,
            newFileName: newFileName,
            format: format
        )
    }
    
    private func convertDocumentToDocument(fileItem: FileItem, to format: ConversionFormat) async throws -> ConversionResult {
        let sourceExt = fileItem.fileExtension.lowercased()
        
        switch (sourceExt, format) {
        case ("txt", .rtf):
            return try convertTextToRTF(fileItem: fileItem)
        case ("rtf", .txt):
            return try convertRTFToText(fileItem: fileItem)
        case ("txt", .pdf), ("rtf", .pdf):
            return try convertTextToPDF(fileItem: fileItem)
        case ("doc", _), ("docx", _), ("pages", _):
            // For complex document formats, we'd need more sophisticated conversion
            // For now, try to extract text and convert to target format
            return try convertComplexDocumentToBasicFormat(fileItem: fileItem, to: format)
        default:
            throw ConversionError.unsupportedConversion
        }
    }
    
    private func convertTextToRTF(fileItem: FileItem) throws -> ConversionResult {
        guard let textContent = try? String(contentsOf: fileItem.path, encoding: .utf8) else {
            throw ConversionError.invalidSourceFile
        }
        
        let attributedString = NSAttributedString(
            string: textContent,
            attributes: [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.textColor
            ]
        )
        
        let rtfData = try attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        
        let newFileName = generateNewFileName(from: fileItem.name, to: .rtf)
        
        return ConversionResult(
            data: rtfData,
            newFileName: newFileName,
            format: .rtf
        )
    }
    
    private func convertRTFToText(fileItem: FileItem) throws -> ConversionResult {
        guard let rtfData = try? Data(contentsOf: fileItem.path) else {
            throw ConversionError.invalidSourceFile
        }
        
        let attributedString = try NSAttributedString(
            data: rtfData,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
        
        let plainText = attributedString.string
        guard let textData = plainText.data(using: .utf8) else {
            throw ConversionError.conversionFailed
        }
        
        let newFileName = generateNewFileName(from: fileItem.name, to: .txt)
        
        return ConversionResult(
            data: textData,
            newFileName: newFileName,
            format: .txt
        )
    }
    
    private func convertTextToPDF(fileItem: FileItem) throws -> ConversionResult {
        let textContent: String
        let sourceExt = fileItem.fileExtension.lowercased()
        
        if sourceExt == "txt" {
            guard let content = try? String(contentsOf: fileItem.path, encoding: .utf8) else {
                throw ConversionError.invalidSourceFile
            }
            textContent = content
        } else if sourceExt == "rtf" {
            guard let rtfData = try? Data(contentsOf: fileItem.path) else {
                throw ConversionError.invalidSourceFile
            }
            
            let attributedString = try NSAttributedString(
                data: rtfData,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )
            textContent = attributedString.string
        } else {
            throw ConversionError.unsupportedConversion
        }
        
        // Create PDF from text
        let pageSize = CGSize(width: 612, height: 792) // Standard letter size
        
        let attributedString = NSAttributedString(
            string: textContent,
            attributes: [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.black
            ]
        )
        
        // Create PDF page with text (must be on main thread)
        let pdfData = DispatchQueue.main.sync {
            let textView = NSTextView(frame: CGRect(origin: .zero, size: pageSize))
            textView.textStorage?.setAttributedString(attributedString)
            return textView.dataWithPDF(inside: textView.bounds)
        }
        
        let newFileName = generateNewFileName(from: fileItem.name, to: .pdf)
        
        return ConversionResult(
            data: pdfData,
            newFileName: newFileName,
            format: .pdf
        )
    }
    
    private func convertComplexDocumentToBasicFormat(fileItem: FileItem, to format: ConversionFormat) throws -> ConversionResult {
        // This is a simplified implementation for complex document formats
        // In a real application, you might want to use more sophisticated document processing libraries
        
        let extractedText = try extractTextFromComplexDocument(fileItem: fileItem)
        return try convertExtractedTextToTargetFormat(extractedText, originalName: fileItem.name, targetFormat: format)
    }
    
    private func extractTextFromComplexDocument(fileItem: FileItem) throws -> String {
        guard let documentData = try? Data(contentsOf: fileItem.path) else {
            throw ConversionError.invalidSourceFile
        }
        
        // Try to read as various document types
        let documentTypes: [NSAttributedString.DocumentType] = [.docFormat, .rtf, .html]
        var extractedText = ""
        
        for docType in documentTypes {
            do {
                let attributedString = try NSAttributedString(
                    data: documentData,
                    options: [.documentType: docType],
                    documentAttributes: nil
                )
                extractedText = attributedString.string
                break
            } catch {
                continue
            }
        }
        
        if extractedText.isEmpty {
            throw ConversionError.invalidSourceFile
        }
        
        return extractedText
    }
    
    private func convertExtractedTextToTargetFormat(_ text: String, originalName: String, targetFormat: ConversionFormat) throws -> ConversionResult {
        switch targetFormat {
        case .txt:
            return try createTextResult(from: text, originalName: originalName)
        case .rtf:
            return try createRTFResult(from: text, originalName: originalName)
        case .pdf:
            return try createPDFResultFromText(text, originalName: originalName)
        default:
            throw ConversionError.unsupportedConversion
        }
    }
    
    private func createTextResult(from text: String, originalName: String) throws -> ConversionResult {
        guard let textData = text.data(using: .utf8) else {
            throw ConversionError.conversionFailed
        }
        let newFileName = generateNewFileName(from: originalName, to: .txt)
        return ConversionResult(data: textData, newFileName: newFileName, format: .txt)
    }
    
    private func createRTFResult(from text: String, originalName: String) throws -> ConversionResult {
        let attributedString = NSAttributedString(
            string: text,
            attributes: [.font: NSFont.systemFont(ofSize: 12)]
        )
        let rtfData = try attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        let newFileName = generateNewFileName(from: originalName, to: .rtf)
        return ConversionResult(data: rtfData, newFileName: newFileName, format: .rtf)
    }
    
    private func createPDFResultFromText(_ text: String, originalName: String) throws -> ConversionResult {
        // Create a temporary text file and convert to PDF
        let tempFileItem = FileItem(
            name: "temp.txt",
            path: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.txt"),
            type: .document,
            size: Int64(text.count)
        )
        try text.write(to: tempFileItem.path, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFileItem.path) }
        
        return try convertTextToPDF(fileItem: tempFileItem)
    }
    
    // MARK: - Helper Methods
    
    private func generateNewFileName(from originalName: String, to format: ConversionFormat) -> String {
        let nameWithoutExtension = (originalName as NSString).deletingPathExtension
        return "\(nameWithoutExtension).\(format.targetExtension)"
    }
} 
