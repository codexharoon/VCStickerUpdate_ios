//
//  SVGNodeType.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 17/12/2025.
//

import UIKit

enum SVGNodeType {
    case text
    case shape
}

struct SVGNode {
    let type: SVGNodeType
    let frame: CGRect
    let transform: CGAffineTransform

    // Text properties (from SVGTextProperties)
    let text: String?
    let fontSize: CGFloat?
    let fontName: String?
    let textColor: UIColor?
    let textAlignment: NSTextAlignment?
    let isBold: Bool
    let isItalic: Bool

    // Shape only
    let layer: CALayer?
    
    // MARK: - Convenience Initializers
    
    /// Create a text node from SVGTextProperties
    static func textNode(from properties: SVGTextProperties, transform: CGAffineTransform) -> SVGNode {
        return SVGNode(
            type: .text,
            frame: properties.frame,
            transform: transform,
            text: properties.text,
            fontSize: properties.fontSize,
            fontName: properties.fontName,
            textColor: properties.textColor,
            textAlignment: properties.alignment,
            isBold: properties.isBold,
            isItalic: properties.isItalic,
            layer: nil
        )
    }
    
    /// Create a shape node
    static func shapeNode(frame: CGRect, transform: CGAffineTransform, layer: CALayer) -> SVGNode {
        return SVGNode(
            type: .shape,
            frame: frame,
            transform: transform,
            text: nil,
            fontSize: nil,
            fontName: nil,
            textColor: nil,
            textAlignment: nil,
            isBold: false,
            isItalic: false,
            layer: layer
        )
    }
}
