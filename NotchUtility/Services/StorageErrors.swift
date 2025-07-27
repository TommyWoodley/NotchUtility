import Foundation

// MARK: - Storage Errors

enum StorageError: LocalizedError {
    case storageLimitExceeded
    case fileNotFound
    case copyFailed
    case duplicateFile(String)
    case hiddenFileNotSupported
    
    var errorDescription: String? {
        switch self {
        case .storageLimitExceeded:
            return "Storage limit exceeded. Please remove some files."
        case .fileNotFound:
            return "File not found."
        case .copyFailed:
            return "Failed to copy file to storage."
        case .duplicateFile(let fileName):
            return "File '\(fileName)' already exists in storage."
        case .hiddenFileNotSupported:
            return "Hidden files (starting with '.') are not supported."
        }
    }
}

enum ConversionError: LocalizedError {
    case unsupportedConversion
    case unsupportedFormat
    case invalidSourceFile
    case conversionFailed
    
    var errorDescription: String? {
        switch self {
        case .unsupportedConversion:
            return "This file type cannot be converted."
        case .unsupportedFormat:
            return "Target format is not supported."
        case .invalidSourceFile:
            return "Source file is invalid or corrupted."
        case .conversionFailed:
            return "Conversion failed. Please try again."
        }
    }
} 
