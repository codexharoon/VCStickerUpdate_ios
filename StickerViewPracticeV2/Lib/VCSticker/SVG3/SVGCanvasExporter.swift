//
//  SVGCanvasExporter.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 24/12/2025.
//

import UIKit

/// Utility class for exporting sticker canvas in various formats and qualities
final class SVGCanvasExporter {
    
    static let defaultExportSize = CGSize(width: 1050, height: 1050)
    
    // MARK: - Unified Export Method
    
    /// Exports the canvas with the specified configuration
    /// - Returns: ExportResult containing either an image or PDF data
    static func exportCanvas(
        _ canvasView: UIView,
        stickers: [VCBaseSticker],
        configuration: ExportConfiguration
    ) -> ExportResult? {
        if stickers.isEmpty { return nil }
        
        let exportSize = configuration.quality.exportSize
        
        switch configuration.format {
        case .png:
            if let image = exportCanvasAsPNG(canvasView, stickers: stickers, exportSize: exportSize) {
                return .image(image)
            }
        case .jpeg:
            if let image = exportCanvasAsJPEG(canvasView, stickers: stickers, quality: configuration.quality, exportSize: exportSize) {
                return .image(image)
            }
        case .pdf:
            if let data = exportCanvasAsPDF(canvasView, stickers: stickers, exportSize: exportSize) {
                return .pdfData(data)
            }
        }
        
        return nil
    }
    
    // MARK: - PNG Export
    
    static func exportCanvasAsPNG(
        _ canvasView: UIView,
        stickers: [VCBaseSticker],
        exportSize: CGSize = defaultExportSize
    ) -> UIImage? {
        if stickers.isEmpty { return nil }
        
        // 1. Finish editing on all stickers to hide control elements and borders
        for sticker in stickers {
            sticker.finishEditing()
        }
        
        // 2. Create renderer with fixed pixel size (scale = 1.0 means size is in pixels)
        let renderer = UIGraphicsImageRenderer(size: exportSize, format: {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0  // Size is exact pixels
            format.opaque = false  // Transparent background
            return format
        }())
        
        // 3. Render the canvas scaled to the target size
        let exportedImage = renderer.image { context in
            // Calculate scale to fit canvasView into fixed export size
            let scaleX = exportSize.width / canvasView.bounds.width
            let scaleY = exportSize.height / canvasView.bounds.height
            
            // Apply scaling transform
            context.cgContext.scaleBy(x: scaleX, y: scaleY)
            
            // Draw the canvasView scaled to fit the fixed size
            canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)
        }
        
        return exportedImage
    }
    
    // MARK: - JPEG Export
    
    /// Exports the canvas as JPEG with compression quality
    /// - Returns: Rendered UIImage or nil if export fails
    static func exportCanvasAsJPEG(
        _ canvasView: UIView,
        stickers: [VCBaseSticker],
        quality: ExportQuality,
        exportSize: CGSize = defaultExportSize
    ) -> UIImage? {
        if stickers.isEmpty { return nil }
        
        // Finish editing on all stickers
        for sticker in stickers {
            sticker.finishEditing()
        }
        
        // Create renderer with opaque background for JPEG
        let renderer = UIGraphicsImageRenderer(size: exportSize, format: {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = true  // JPEG doesn't support transparency
            return format
        }())
        
        let exportedImage = renderer.image { context in
            // Fill white background for JPEG
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: exportSize))
            
            // Calculate scale
            let scaleX = exportSize.width / canvasView.bounds.width
            let scaleY = exportSize.height / canvasView.bounds.height
            
            context.cgContext.scaleBy(x: scaleX, y: scaleY)
            canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)
        }
        
        return exportedImage
    }
    
    // MARK: - PDF Export
    
    /// Exports the canvas as PDF data
    /// - Returns: PDF data or nil if export fails
    static func exportCanvasAsPDF(
        _ canvasView: UIView,
        stickers: [VCBaseSticker],
        exportSize: CGSize = defaultExportSize
    ) -> Data? {
        if stickers.isEmpty { return nil }
        
        // Finish editing on all stickers
        for sticker in stickers {
            sticker.finishEditing()
        }
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: exportSize))
        
        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            
            let cgContext = context.cgContext
            
            // Calculate scale
            let scaleX = exportSize.width / canvasView.bounds.width
            let scaleY = exportSize.height / canvasView.bounds.height
            
            cgContext.scaleBy(x: scaleX, y: scaleY)
            canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)
        }
        
        return pdfData
    }
    
    // MARK: - Temp File Saving
    
    /// Saves export result to a temporary file
    /// - Returns: URL of the saved file or nil if save fails
    static func saveTempFile(
        _ result: ExportResult,
        fileName: String? = nil,
        configuration: ExportConfiguration
    ) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let name = fileName ?? "StickerDesign_\(Int(Date().timeIntervalSince1970))"
        let fileURL = tempDirectory.appendingPathComponent("\(name).\(configuration.format.fileExtension)")
        
        do {
            switch result {
            case .image(let image):
                let data: Data?
                switch configuration.format {
                case .png:
                    data = image.pngData()
                case .jpeg:
                    data = image.jpegData(compressionQuality: configuration.quality.jpegCompressionQuality)
                case .pdf:
                    return nil // PDF should use pdfData case
                }
                
                guard let imageData = data else { return nil }
                try imageData.write(to: fileURL)
                
            case .pdfData(let pdfData):
                try pdfData.write(to: fileURL)
            }
            
            return fileURL
        } catch {
            print("SVGCanvasExporter: Failed to save temp file - \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Legacy method for backward compatibility
    static func saveTempPNG(_ image: UIImage, fileName: String? = nil) -> URL? {
        guard let pngData = image.pngData() else {
            return nil
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let name = fileName ?? "StickerDesign_\(Int(Date().timeIntervalSince1970))"
        let fileURL = tempDirectory.appendingPathComponent("\(name).png")
        
        do {
            try pngData.write(to: fileURL)
            return fileURL
        } catch {
            print("SVGCanvasExporter: Failed to save temp file - \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Cleans up a temporary file
    /// - Parameter url: The URL of the file to remove
    static func cleanupTempFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}


// MARK: - UIViewController Extension for Export Presentation

extension UIViewController {
    
    func presentExportShareSheet(
        for image: UIImage,
        fileName: String? = nil,
        sourceView: UIView? = nil,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        // Save to temp file for better Files app compatibility
        guard let fileURL = SVGCanvasExporter.saveTempPNG(image, fileName: fileName) else {
            showExportAlert(
                title: "Export Failed",
                message: "Failed to create PNG image"
            )
            return
        }
        
        // Create activity view controller
        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        // Exclude activities that don't make sense for saving/sharing images
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks
        ]
        
        // Handle iPad popover presentation
        if let popoverController = activityVC.popoverPresentationController {
            let anchor = sourceView ?? self.view!
            popoverController.sourceView = anchor
            popoverController.sourceRect = CGRect(
                x: anchor.bounds.midX,
                y: anchor.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }
        
        // Clean up temp file after sharing completes
        activityVC.completionWithItemsHandler = { [weak self] _, completed, _, error in
            // Clean up temporary file
            SVGCanvasExporter.cleanupTempFile(fileURL)
            
            if let _ = error {
                self?.showExportAlert(
                    title: "Export Failed",
                    message: "Export failed, Please try again."
                )
            } else if completed {
                self?.showExportAlert(
                    title: "Exported Successfully",
                    message: "Your design has been saved."
                )
            }
            
            completion?(completed, error)
        }
        
        present(activityVC, animated: true)
    }
    
    /// Presents share sheet for exported file with configuration
    func presentExportShareSheet(
        for fileURL: URL,
        configuration: ExportConfiguration,
        sourceView: UIView? = nil,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        // Create activity view controller
        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        // Exclude activities that don't make sense
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks
        ]
        
        // Handle iPad popover presentation
        if let popoverController = activityVC.popoverPresentationController {
            let anchor = sourceView ?? self.view!
            popoverController.sourceView = anchor
            popoverController.sourceRect = CGRect(
                x: anchor.bounds.midX,
                y: anchor.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }
        
        // Clean up temp file after sharing completes
        activityVC.completionWithItemsHandler = { [weak self] _, completed, _, error in
            // Clean up temporary file
            SVGCanvasExporter.cleanupTempFile(fileURL)
            
            if let _ = error {
                self?.showExportAlert(
                    title: "Export Failed",
                    message: "Export failed, Please try again."
                )
            } else if completed {
                let formatName = configuration.format.displayName
                self?.showExportAlert(
                    title: "Exported Successfully",
                    message: "Your \(formatName) design has been saved."
                )
            }
            
            completion?(completed, error)
        }
        
        present(activityVC, animated: true)
    }
    
    /// Shows an alert with the given title and message
    private func showExportAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

