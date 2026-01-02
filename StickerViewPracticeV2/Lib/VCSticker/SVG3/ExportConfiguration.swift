//
//  ExportConfiguration.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 02/01/2026.
//

import UIKit

/// Supported export formats
enum ExportFormat: String, CaseIterable {
    case png = "PNG"
    case jpeg = "JPEG"
    case pdf = "PDF"
    
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .pdf: return "pdf"
        }
    }
    
    var mimeType: String {
        switch self {
        case .png: return "image/png"
        case .jpeg: return "image/jpeg"
        case .pdf: return "application/pdf"
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}

/// Export quality levels with corresponding size/compression settings
enum ExportQuality: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    /// Export pixel dimensions
    var exportSize: CGSize {
        switch self {
        case .low: return CGSize(width: 512, height: 512)
        case .medium: return CGSize(width: 1024, height: 1024)
        case .high: return CGSize(width: 2048, height: 2048)
        }
    }
    
    /// JPEG compression quality (0.0 to 1.0)
    var jpegCompressionQuality: CGFloat {
        switch self {
        case .low: return 0.5
        case .medium: return 0.75
        case .high: return 1.0
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
    
    var sizeDescription: String {
        let size = exportSize
        return "\(Int(size.width)) × \(Int(size.height)) px"
    }
}

/// Complete export configuration
struct ExportConfiguration {
    let format: ExportFormat
    let quality: ExportQuality
    
    static let `default` = ExportConfiguration(format: .png, quality: .high)
    
    var fileName: String {
        return "Design_\(Int(Date().timeIntervalSince1970)).\(format.fileExtension)"
    }
}

/// Result of an export operation
enum ExportResult {
    case image(UIImage)
    case pdfData(Data)
    
    var data: Data? {
        switch self {
        case .image(_):
            return nil // Handled separately for PNG/JPEG
        case .pdfData(let data):
            return data
        }
    }
}
