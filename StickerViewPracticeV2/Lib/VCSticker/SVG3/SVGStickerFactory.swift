//
//  SVGStickerFactory.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 17/12/2025.
//

import Foundation
import UIKit
import SVGKit

final class SVGStickerFactory {
    
    // Padding used by VCBaseSticker for contentView inset
    private static let stickerPadding: CGFloat = 8
    
    // Extra horizontal padding for text to prevent clipping
    private static let textHorizontalPadding: CGFloat = 12

    static func makeSticker(from node: SVGNode) -> VCBaseSticker {

        switch node.type {

        case .text:
            return createTextSticker(from: node)

        case .shape:
            return createShapeSticker(from: node)
        }
    }
    
    // MARK: - Text Sticker Creation
    
    private static func createTextSticker(from node: SVGNode) -> SVGTextSticker {
        // Expand frame to account for padding
        // Text needs extra horizontal padding to prevent clipping
        let expandedFrame = node.frame.insetBy(
            dx: -(stickerPadding + textHorizontalPadding),
            dy: -stickerPadding
        )
        
        let sticker = SVGTextSticker(frame: expandedFrame)
        
        // Apply all extracted properties
        sticker.text = node.text ?? ""
        sticker.fontSize = node.fontSize ?? 24
        sticker.fontName = node.fontName  // nil = use system font
        sticker.textColor = node.textColor ?? .label
        sticker.textAlignment = node.textAlignment ?? .center
        sticker.isBold = node.isBold
        sticker.isItalic = node.isItalic
        
        // NOTE: Don't apply node.transform to text stickers
        // We're recreating the text layer and the original transform
        // causes positioning issues when combined with canvas scaling
        
        return sticker
    }
    
    // MARK: - Shape Sticker Creation
    
    private static func createShapeSticker(from node: SVGNode) -> SVGImageSticker {
        // Standard padding for shapes
        let expandedFrame = node.frame.insetBy(dx: -stickerPadding, dy: -stickerPadding)
        
        let sticker = SVGImageSticker(frame: expandedFrame)
        
        if let layer = node.layer {
            sticker.setSVGLayer(layer)
        }
        
        sticker.transform = node.transform
        
        return sticker
    }
}
