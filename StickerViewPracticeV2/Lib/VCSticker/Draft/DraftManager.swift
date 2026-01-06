//
//  DraftManager.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 05/01/2026.
//

import UIKit

final class DraftManager {
    
    static let shared = DraftManager()
    
    private let fileManager = FileManager.default
    private let thumbnailCache = NSCache<NSString, UIImage>()
    
    private var draftsDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let draftsPath = documentsPath.appendingPathComponent("Drafts", isDirectory: true)
        
        // Create directory if doesn't exist
        if !fileManager.fileExists(atPath: draftsPath.path) {
            try? fileManager.createDirectory(at: draftsPath, withIntermediateDirectories: true)
        }
        
        return draftsPath
    }
    
    private init() {}
    
    // MARK: - Save Draft
    
    /// Saves a draft with all stickers and returns the draft ID
    func saveDraft(
        svgName: String,
        stickers: [VCBaseSticker],
        thumbnail: UIImage,
        canvas: UIView,
        existingDraftId: UUID? = nil
    ) -> UUID {
        let draftId = existingDraftId ?? UUID()
        let draftFolder = draftsDirectory.appendingPathComponent(draftId.uuidString, isDirectory: true)
        
        // Remove existing folder if updating
        if existingDraftId != nil && fileManager.fileExists(atPath: draftFolder.path) {
            try? fileManager.removeItem(at: draftFolder)
        }
        
        // Create draft folder
        try? fileManager.createDirectory(at: draftFolder, withIntermediateDirectories: true)
        
        // Create images subfolder
        let imagesFolder = draftFolder.appendingPathComponent("images", isDirectory: true)
        try? fileManager.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
        
        // Copy SVG file to draft folder for independence
        copySVGFile(named: svgName, to: draftFolder)
        
        // Save thumbnail
        let thumbnailURL = draftFolder.appendingPathComponent("thumbnail.png")
        if let thumbnailData = thumbnail.pngData() {
            try? thumbnailData.write(to: thumbnailURL)
        }
        
        // Convert stickers to data and save images
        var stickerDataList: [StickerData] = []
        
        for (index, sticker) in stickers.enumerated() {
            let stickerData = StickerData(from: sticker, zIndex: index)
            stickerDataList.append(stickerData)
            
            // Save user-added images (VCImageSticker)
            if let imageSticker = sticker as? VCImageSticker,
               let image = imageSticker.imageView.image {
                let imageFileName = "userImage_\(index).png"
                let imageURL = imagesFolder.appendingPathComponent(imageFileName)
                if let imageData = image.pngData() {
                    try? imageData.write(to: imageURL)
                }
            }
        }
        
        // Create draft model
        let draft = DraftModel(
            id: draftId,
            svgName: svgName,
            createdAt: existingDraftId == nil ? Date() : Date(),
            updatedAt: Date(),
            stickers: stickerDataList
        )
        
        // Save draft.json
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        if let jsonData = try? encoder.encode(draft) {
            let jsonURL = draftFolder.appendingPathComponent("draft.json")
            try? jsonData.write(to: jsonURL)
        }
        
        return draftId
    }
    
    // MARK: - Load Draft
    
    /// Loads a draft by ID
    func loadDraft(id: UUID) -> DraftModel? {
        let draftFolder = draftsDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        let jsonURL = draftFolder.appendingPathComponent("draft.json")
        
        guard let jsonData = try? Data(contentsOf: jsonURL) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try? decoder.decode(DraftModel.self, from: jsonData)
    }
    
    // MARK: - Get All Drafts
    
    /// Returns all drafts sorted by update date (newest first)
    func getAllDrafts() -> [DraftModel] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: draftsDirectory,
            includingPropertiesForKeys: nil
        ) else { return [] }
        
        var drafts: [DraftModel] = []
        
        for folder in contents {
            guard folder.hasDirectoryPath else { continue }
            
            if let uuid = UUID(uuidString: folder.lastPathComponent),
               let draft = loadDraft(id: uuid) {
                drafts.append(draft)
            }
        }
        
        // Sort by update date, newest first
        return drafts.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // MARK: - Delete Draft
    
    /// Deletes a draft by ID
    func deleteDraft(id: UUID) {
        let draftFolder = draftsDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        try? fileManager.removeItem(at: draftFolder)
    }
    
    // MARK: - Load Assets
    
    /// Loads thumbnail for a draft (with caching)
    func getThumbnail(forDraftId id: UUID) -> UIImage? {
        let cacheKey = id.uuidString as NSString
        
        // Check cache first
        if let cached = thumbnailCache.object(forKey: cacheKey) {
            return cached
        }
        
        let draftFolder = draftsDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        let thumbnailURL = draftFolder.appendingPathComponent("thumbnail.png")
        
        guard let data = try? Data(contentsOf: thumbnailURL),
              let image = UIImage(data: data) else { return nil }
        
        // Cache for next time
        thumbnailCache.setObject(image, forKey: cacheKey)
        return image
    }
    
    /// Loads a user image from a draft
    func loadUserImage(draftId: UUID, fileName: String) -> UIImage? {
        let draftFolder = draftsDirectory.appendingPathComponent(draftId.uuidString, isDirectory: true)
        let imageURL = draftFolder.appendingPathComponent("images").appendingPathComponent(fileName)
        
        guard let data = try? Data(contentsOf: imageURL) else { return nil }
        return UIImage(data: data)
    }
    
    /// Gets the path to the copied SVG file in a draft
    func getSVGPath(forDraftId id: UUID, svgName: String) -> String? {
        let draftFolder = draftsDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        let svgURL = draftFolder.appendingPathComponent("\(svgName).svg")
        
        if fileManager.fileExists(atPath: svgURL.path) {
            return svgURL.path
        }
        return nil
    }
    
    // MARK: - Helpers
    
    private func copySVGFile(named name: String, to folder: URL) {
        guard let sourcePath = Bundle.main.path(forResource: name, ofType: "svg") else { return }
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let destinationURL = folder.appendingPathComponent("\(name).svg")
        
        try? fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
}

// MARK: - Sticker Restoration

extension DraftManager {
    
    /// Loads/Parses SVG nodes (Heavy operation - run on background thread)
    func loadNodes(for draft: DraftModel) -> [SVGNode] {
        if let path = getSVGPath(forDraftId: draft.id, svgName: draft.svgName),
           let svg = SVGAssetLoader.loadSVG(fromPath: path) {
            return SVGNodeExtractor.extract(from: svg)
        }
        return []
    }

    /// Restores stickers from a draft into the canvas
    func restoreStickers(
        from draft: DraftModel,
        into canvas: UIView,
        nodes: [SVGNode],
        wireCallback: (VCBaseSticker) -> Void
    ) -> [VCBaseSticker] {
        var restoredStickers: [VCBaseSticker] = []
        
        // Sort by z-index to maintain layer order
        let sortedData = draft.stickers.sorted { $0.zIndex < $1.zIndex }
        
        for stickerData in sortedData {
            guard let sticker = createSticker(from: stickerData, draft: draft, nodes: nodes) else { continue }
            
            // Apply state (must be done before callbacks potentially)
            sticker.isLocked = stickerData.isLocked
            sticker.isHidden = stickerData.isHidden
            
            // Wire callbacks
            sticker.borderStyle = .dotted
            wireCallback(sticker)
            
            // Add to canvas FIRST to ensure it's in hierarchy
            // This is critical because some stickers (like SVGTextSticker) need superview to layout correctly
            canvas.addSubview(sticker)
            
            // Force initial layout pass while transform is still Identity
            // This runs customInit() which modifies frame. Doing this on a rotated view would break layout.
            sticker.bounds = stickerData.bounds
            sticker.layoutIfNeeded()
            
            // NOW apply transform and center (after initial layout)
            // Re-apply bounds to ensure exact saved size overrides any auto-sizing
            sticker.bounds = stickerData.bounds
            sticker.transform = stickerData.affineTransform
            sticker.center = stickerData.center
            
            restoredStickers.append(sticker)
        }
        
        return restoredStickers
    }
    
    private func createSticker(from data: StickerData, draft: DraftModel, nodes: [SVGNode]) -> VCBaseSticker? {
        switch data.type {
        case .svgText:
            return createSVGTextSticker(from: data)
        case .svgImage:
            return createSVGImageSticker(from: data, draft: draft, nodes: nodes)
        case .vcText:
            return createVCTextSticker(from: data)
        case .vcImage:
            return createVCImageSticker(from: data, draft: draft)
        }
    }
    
    // MARK: - Create SVGTextSticker
    
    private func createSVGTextSticker(from data: StickerData) -> SVGTextSticker? {
         guard let props = data.svgText else { return nil }
         
         let sticker = SVGTextSticker(frame: CGRect(origin: .zero, size: data.bounds.size))
         sticker.text = props.text
         sticker.fontName = props.fontName
         sticker.fontSize = props.fontSize
         sticker.textColor = UIColor(hex: props.textColorHex)
         sticker.isBold = props.isBold
         sticker.isItalic = props.isItalic
         sticker.textAlignment = NSTextAlignment(rawValue: props.textAlignment) ?? .center
         
         sticker.strokeEnabled = props.strokeEnabled
         sticker.strokeColor = UIColor(hex: props.strokeColorHex)
         sticker.strokeWidth = props.strokeWidth
         
         sticker.textShadowEnabled = props.textShadowEnabled
         sticker.textShadowColor = UIColor(hex: props.textShadowColorHex)
         sticker.textShadowOffset = CGSize(width: props.textShadowOffsetWidth, height: props.textShadowOffsetHeight)
         sticker.textShadowBlur = props.textShadowBlur
         sticker.textShadowOpacity = props.textShadowOpacity
         sticker.textOpacity = props.textOpacity
         
         return sticker
    }
    
    private func createSVGImageSticker(from data: StickerData, draft: DraftModel, nodes: [SVGNode]) -> SVGImageSticker? {
        guard let props = data.svgImage else { return nil }
        
        // OPTIMIZATION: Use preloaded nodes instead of reloading file
        // props.nodeIndex refers to the original index in these nodes.
        if props.nodeIndex < nodes.count {
            let node = nodes[props.nodeIndex]
            if case .shape = node.type {
                let sticker = SVGStickerFactory.makeSticker(from: node)
                if let svgImageSticker = sticker as? SVGImageSticker {
                     // Apply Saved Properties
                     svgImageSticker.imageOpacity = props.imageOpacity
                     if let tintHex = props.shapeTintColorHex {
                         svgImageSticker.applyTint(UIColor(hex: tintHex))
                     }
                     // RESTORE: Set original index so future saves work correctly
                     svgImageSticker.originalNodeIndex = props.nodeIndex
                     return svgImageSticker
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Create VCTextViewSticker
    
    private func createVCTextSticker(from data: StickerData) -> VCTextViewSticker? {
        guard let props = data.vcText else { return nil }
        
        let sticker = VCTextViewSticker(center: data.center, text: props.text)
        
        // Apply all properties
        sticker.stickerTextColor = UIColor(hex: props.stickerTextColorHex)
        sticker.stickerFontName = props.stickerFontName
        sticker.stickerIsBold = props.stickerIsBold
        sticker.stickerIsItalic = props.stickerIsItalic
        sticker.stickerAlignment = NSTextAlignment(rawValue: props.stickerAlignment) ?? .center
        sticker.lineSpacing = props.lineSpacing
        sticker.letterSpacing = props.letterSpacing
        sticker.stickerOpacity = props.stickerOpacity
        sticker.shadowEnable = props.shadowEnable
        sticker.stickerShadowColor = UIColor(hex: props.stickerShadowColorHex)
        sticker.stickerShadowOffset = CGSize(width: props.stickerShadowOffsetWidth, height: props.stickerShadowOffsetHeight)
        sticker.stickerShadowOpacity = props.stickerShadowOpacity
        sticker.stickerShadowRadius = props.stickerShadowRadius
        
        return sticker
    }
    
    // MARK: - Create VCImageSticker
    
    private func createVCImageSticker(from data: StickerData, draft: DraftModel) -> VCImageSticker? {
        guard let props = data.vcImage else { return nil }
        
        // Load saved image
        guard let image = loadUserImage(draftId: draft.id, fileName: props.imageFileName) else { return nil }
        
        let sticker = VCImageSticker(frame: CGRect(origin: .zero, size: data.bounds.size))
        
        // Apply image with rendering mode
        if props.isTemplateMode {
            sticker.imageView.image = image.withRenderingMode(.alwaysTemplate)
            if let tintHex = props.tintColorHex {
                sticker.imageView.tintColor = UIColor(hex: tintHex)
            }
        } else {
            sticker.imageView.image = image.withRenderingMode(.alwaysOriginal)
        }
        
        sticker.imageView.alpha = props.alpha
        sticker.imageView.contentMode = .scaleToFill
        
        return sticker
    }
}
