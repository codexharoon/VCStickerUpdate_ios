//
//  DraftModel.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 05/01/2026.
//

import UIKit

// MARK: - Main Draft Model

struct DraftModel: Codable {
    let id: UUID
    let svgName: String
    let createdAt: Date
    var updatedAt: Date
    let stickers: [StickerData]
}

// MARK: - Sticker Type Enum

enum StickerType: String, Codable {
    case svgText
    case svgImage
    case vcText
    case vcImage
}

// MARK: - Sticker Data (Common + Type-Specific)

struct StickerData: Codable {
    let type: StickerType
    
    // Layout properties (critical for pixel-perfect restoration)
    let boundsX: CGFloat
    let boundsY: CGFloat
    let boundsWidth: CGFloat
    let boundsHeight: CGFloat
    let centerX: CGFloat
    let centerY: CGFloat
    let transform: [CGFloat]  // [a, b, c, d, tx, ty]
    
    // Z-order index
    let zIndex: Int
    
    // State properties
    let isLocked: Bool
    let isHidden: Bool
    
    // Type-specific properties
    var svgText: SVGTextData?
    var svgImage: SVGImageData?
    var vcText: VCTextData?
    var vcImage: VCImageData?
    
    // Computed properties for convenience
    var bounds: CGRect {
        CGRect(x: boundsX, y: boundsY, width: boundsWidth, height: boundsHeight)
    }
    
    var center: CGPoint {
        CGPoint(x: centerX, y: centerY)
    }
    
    var affineTransform: CGAffineTransform {
        guard transform.count == 6 else { return .identity }
        return CGAffineTransform(
            a: transform[0],
            b: transform[1],
            c: transform[2],
            d: transform[3],
            tx: transform[4],
            ty: transform[5]
        )
    }
    
    // Initializer from sticker
    init(from sticker: VCBaseSticker, zIndex: Int) {
        self.boundsX = sticker.bounds.origin.x
        self.boundsY = sticker.bounds.origin.y
        self.boundsWidth = sticker.bounds.width
        self.boundsHeight = sticker.bounds.height
        self.centerX = sticker.center.x
        self.centerY = sticker.center.y
        self.transform = [
            sticker.transform.a,
            sticker.transform.b,
            sticker.transform.c,
            sticker.transform.d,
            sticker.transform.tx,
            sticker.transform.ty
        ]
        self.zIndex = zIndex
        self.isLocked = sticker.isLocked
        self.isHidden = sticker.isHidden
        
        // Determine type and extract properties
        if let svgTextSticker = sticker as? SVGTextSticker {
            self.type = .svgText
            self.svgText = SVGTextData(from: svgTextSticker)
            self.svgImage = nil
            self.vcText = nil
            self.vcImage = nil
        } else if let svgImageSticker = sticker as? SVGImageSticker {
            self.type = .svgImage
            self.svgText = nil
            self.svgImage = SVGImageData(from: svgImageSticker, zIndex: zIndex)
            self.vcText = nil
            self.vcImage = nil
        } else if let vcTextSticker = sticker as? VCTextViewSticker {
            self.type = .vcText
            self.svgText = nil
            self.svgImage = nil
            self.vcText = VCTextData(from: vcTextSticker)
            self.vcImage = nil
        } else if let vcImageSticker = sticker as? VCImageSticker {
            self.type = .vcImage
            self.svgText = nil
            self.svgImage = nil
            self.vcText = nil
            self.vcImage = VCImageData(from: vcImageSticker, zIndex: zIndex)
        } else {
            // Fallback - shouldn't happen but handle gracefully
            self.type = .vcImage
            self.svgText = nil
            self.svgImage = nil
            self.vcText = nil
            self.vcImage = nil
        }
    }
}

// MARK: - SVGTextSticker Data

struct SVGTextData: Codable {
    let text: String
    let fontName: String?
    let fontSize: CGFloat
    let textColorHex: String
    let isBold: Bool
    let isItalic: Bool
    let textAlignment: Int  // NSTextAlignment raw value
    let strokeEnabled: Bool
    let strokeColorHex: String
    let strokeWidth: CGFloat
    let textShadowEnabled: Bool
    let textShadowColorHex: String
    let textShadowOffsetWidth: CGFloat
    let textShadowOffsetHeight: CGFloat
    let textShadowBlur: CGFloat
    let textShadowOpacity: Float
    let textOpacity: Float
    
    init(from sticker: SVGTextSticker) {
        self.text = sticker.text
        self.fontName = sticker.fontName
        self.fontSize = sticker.fontSize
        self.textColorHex = sticker.textColor.toHex()
        self.isBold = sticker.isBold
        self.isItalic = sticker.isItalic
        self.textAlignment = sticker.textAlignment.rawValue
        self.strokeEnabled = sticker.strokeEnabled
        self.strokeColorHex = sticker.strokeColor.toHex()
        self.strokeWidth = sticker.strokeWidth
        self.textShadowEnabled = sticker.textShadowEnabled
        self.textShadowColorHex = sticker.textShadowColor.toHex()
        self.textShadowOffsetWidth = sticker.textShadowOffset.width
        self.textShadowOffsetHeight = sticker.textShadowOffset.height
        self.textShadowBlur = sticker.textShadowBlur
        self.textShadowOpacity = sticker.textShadowOpacity
        self.textOpacity = sticker.textOpacity
    }
}

// MARK: - SVGImageSticker Data

struct SVGImageData: Codable {
    let nodeIndex: Int  // Position in allStickers array (to identify which SVG node)
    let imageOpacity: Float
    let shapeTintColorHex: String?
    
    init(from sticker: SVGImageSticker, zIndex: Int) {
        self.nodeIndex = sticker.originalNodeIndex
        self.imageOpacity = sticker.imageOpacity
        self.shapeTintColorHex = sticker.currentTintColor?.toHex()
    }
}

// MARK: - VCTextViewSticker Data

struct VCTextData: Codable {
    let text: String
    let stickerTextColorHex: String
    let stickerFontName: String
    let stickerIsBold: Bool
    let stickerIsItalic: Bool
    let stickerAlignment: Int
    let lineSpacing: CGFloat
    let letterSpacing: CGFloat
    let stickerOpacity: CGFloat
    let shadowEnable: Bool
    let stickerShadowColorHex: String
    let stickerShadowOffsetWidth: CGFloat
    let stickerShadowOffsetHeight: CGFloat
    let stickerShadowOpacity: Float
    let stickerShadowRadius: CGFloat
    
    init(from sticker: VCTextViewSticker) {
        self.text = sticker.text ?? ""
        self.stickerTextColorHex = sticker.stickerTextColor.toHex()
        self.stickerFontName = sticker.stickerFontName
        self.stickerIsBold = sticker.stickerIsBold
        self.stickerIsItalic = sticker.stickerIsItalic
        self.stickerAlignment = sticker.stickerAlignment.rawValue
        self.lineSpacing = sticker.lineSpacing
        self.letterSpacing = sticker.letterSpacing
        self.stickerOpacity = sticker.stickerOpacity
        self.shadowEnable = sticker.shadowEnable
        self.stickerShadowColorHex = sticker.stickerShadowColor.toHex()
        self.stickerShadowOffsetWidth = sticker.stickerShadowOffset.width
        self.stickerShadowOffsetHeight = sticker.stickerShadowOffset.height
        self.stickerShadowOpacity = sticker.stickerShadowOpacity
        self.stickerShadowRadius = sticker.stickerShadowRadius
    }
}

// MARK: - VCImageSticker Data

struct VCImageData: Codable {
    let imageFileName: String  // "userImage_0.png"
    let alpha: CGFloat
    let tintColorHex: String?
    let isTemplateMode: Bool
    
    init(from sticker: VCImageSticker, zIndex: Int) {
        self.imageFileName = "userImage_\(zIndex).png"
        self.alpha = sticker.imageView.alpha
        self.tintColorHex = sticker.imageView.tintColor?.toHex()
        self.isTemplateMode = sticker.imageView.image?.renderingMode == .alwaysTemplate
    }
}
