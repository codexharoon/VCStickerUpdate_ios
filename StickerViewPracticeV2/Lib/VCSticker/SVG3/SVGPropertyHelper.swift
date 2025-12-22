//
//  SVGPropertyHelper.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 18/12/2025.
//

import UIKit

// MARK: - SVG Text Properties Container

/// Contains all extracted text properties from an SVG text layer
struct SVGTextProperties {
    let text: String
    let fontSize: CGFloat
    let fontName: String?       // nil = use default font
    let textColor: UIColor
    let alignment: NSTextAlignment
    let isBold: Bool
    let isItalic: Bool
    let frame: CGRect
}

// MARK: - SVG Property Helper

/// Helper class for extracting and validating SVG properties
final class SVGPropertyHelper {
    
    // MARK: - System Font Registry
    
    /// Cache of available system font family names
    private static let availableFontFamilies: Set<String> = {
        Set(UIFont.familyNames)
    }()
    
    /// Cache of all available font names
    private static let availableFontNames: Set<String> = {
        var names = Set<String>()
        for family in UIFont.familyNames {
            for fontName in UIFont.fontNames(forFamilyName: family) {
                names.insert(fontName)
            }
        }
        return names
    }()
    
    // MARK: - Complete Text Extraction
    
    /// Extract all text properties from a CATextLayer
    static func extractTextProperties(from textLayer: CATextLayer) -> SVGTextProperties {
        let text = extractText(from: textLayer) ?? ""
        let (fontSize, fontName, isBold, isItalic) = extractFontProperties(from: textLayer)
        let textColor = extractColor(from: textLayer)
        let alignment = extractAlignment(from: textLayer)
        let frame = textLayer.frame
        
        return SVGTextProperties(
            text: text,
            fontSize: fontSize,
            fontName: fontName,
            textColor: textColor,
            alignment: alignment,
            isBold: isBold,
            isItalic: isItalic,
            frame: frame
        )
    }
    
    // MARK: - Text Extraction
    
    /// Extract text content from a CATextLayer
    static func extractText(from textLayer: CATextLayer) -> String? {
        if let plainString = textLayer.string as? String {
            return plainString
        } else if let attributedString = textLayer.string as? NSAttributedString {
            return attributedString.string
        }
        return nil
    }
    
    // MARK: - Font Extraction
    
    /// Extract font properties (size, name, bold, italic) from a CATextLayer
    /// Returns: (fontSize, fontName or nil for system, isBold, isItalic)
    static func extractFontProperties(from textLayer: CATextLayer) -> (CGFloat, String?, Bool, Bool) {
        var fontSize: CGFloat = 24
        var fontName: String? = nil
        var isBold = false
        var isItalic = false
        
        // Try to get font from attributed string
        if let attributedString = textLayer.string as? NSAttributedString,
           attributedString.length > 0 {
            let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
            
            if let font = attributes[.font] as? UIFont {
                fontSize = font.pointSize
                
                // Detect bold/italic from font traits
                let traits = font.fontDescriptor.symbolicTraits
                isBold = traits.contains(.traitBold)
                isItalic = traits.contains(.traitItalic)
                
                // Try to get a valid font name
                fontName = validateAndMapFont(font)
            }
        } else {
            // Fall back to layer's fontSize property
            let layerFontSize = textLayer.fontSize
            if layerFontSize > 0 {
                fontSize = layerFontSize
            }
        }
        
        return (fontSize, fontName, isBold, isItalic)
    }
    
    /// Validate if a font exists in the system and return a valid font name
    /// Returns nil if we should use system font
    private static func validateAndMapFont(_ font: UIFont) -> String? {
        let fontName = font.fontName
        let familyName = font.familyName
        
        // Skip private/system fonts (start with a dot)
        if fontName.hasPrefix(".") || familyName.hasPrefix(".") {
            return nil
        }
        
        // Check if exact font name exists
        if availableFontNames.contains(fontName) {
            return fontName
        }
        
        // Check if font family exists
        if availableFontFamilies.contains(familyName) {
            // Return the family name - let the sticker resolve the actual font
            return familyName
        }
        
        // Try common font mappings for SVG fonts
        let mappedFont = mapSVGFontToSystem(familyName)
        if let mapped = mappedFont, availableFontFamilies.contains(mapped) {
            return mapped
        }
        
        // No valid font found - will use system font
        return nil
    }
    
    /// Map common SVG font names to iOS system fonts
    private static func mapSVGFontToSystem(_ fontFamily: String) -> String? {
        let lowercased = fontFamily.lowercased()
        
        // Serif fonts
        if lowercased.contains("serif") && !lowercased.contains("sans") {
            return "Georgia"
        }
        if lowercased.contains("times") {
            return "Times New Roman"
        }
        if lowercased.contains("georgia") {
            return "Georgia"
        }
        
        // Sans-serif fonts
        if lowercased.contains("arial") || lowercased.contains("helvetica") {
            return "Helvetica Neue"
        }
        if lowercased.contains("sans") {
            return "Helvetica Neue"
        }
        
        // Monospace fonts
        if lowercased.contains("mono") || lowercased.contains("courier") {
            return "Courier New"
        }
        
        // Script/cursive fonts
        if lowercased.contains("script") || lowercased.contains("cursive") {
            return "Snell Roundhand"
        }
        
        return nil
    }
    
    // MARK: - Color Extraction
    
    /// Extract color from a CATextLayer, with fallback to default
    static func extractColor(from textLayer: CATextLayer, defaultColor: UIColor = .label) -> UIColor {
        
        // Try to get color from attributed string first
        if let attributedString = textLayer.string as? NSAttributedString,
           attributedString.length > 0 {
            
            let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
            
            // Try foregroundColor key
            if let colorValue = attributes[.foregroundColor] {
                if let uiColor = colorValue as? UIColor {
                    return uiColor
                }
                // Handle CGColor wrapped in AnyObject
                if CFGetTypeID(colorValue as CFTypeRef) == CGColor.typeID {
                    return UIColor(cgColor: colorValue as! CGColor)
                }
            }
        }
        
        // Try foregroundColor property
        if let fgColor = textLayer.foregroundColor {
            return UIColor(cgColor: fgColor)
        }
        
        return defaultColor
    }
    
    // MARK: - Alignment Extraction
    
    /// Extract text alignment from a CATextLayer
    static func extractAlignment(from textLayer: CATextLayer) -> NSTextAlignment {
        switch textLayer.alignmentMode {
        case .left:
            return .left
        case .right:
            return .right
        case .center:
            return .center
        case .justified:
            return .justified
        case .natural:
            return .natural
        default:
            return .center
        }
    }
    
    // MARK: - Frame Validation
    
    /// Validate and fix a frame to ensure it has positive dimensions
    static func validateFrame(_ frame: CGRect, minSize: CGFloat = 10) -> CGRect {
        var result = frame
        
        if result.width < minSize {
            result.size.width = minSize
        }
        if result.height < minSize {
            result.size.height = minSize
        }
        
        return result
    }
    
    // MARK: - Font Creation Helper
    
    /// Create a UIFont with the specified properties
    static func createFont(
        name: String?,
        size: CGFloat,
        isBold: Bool = false,
        isItalic: Bool = false
    ) -> UIFont {
        var font: UIFont
        
        if let fontName = name, let customFont = UIFont(name: fontName, size: size) {
            font = customFont
        } else {
            // Use system font with appropriate weight
            let weight: UIFont.Weight = isBold ? .bold : .regular
            font = UIFont.systemFont(ofSize: size, weight: weight)
        }
        
        // Build combined traits
        var traits: UIFontDescriptor.SymbolicTraits = font.fontDescriptor.symbolicTraits
        
        if isBold {
            traits.insert(.traitBold)
        }
        
        if isItalic {
            traits.insert(.traitItalic)
        }
        
        // Apply combined traits if different from current
        if traits != font.fontDescriptor.symbolicTraits {
            if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                font = UIFont(descriptor: descriptor, size: size)
            }
        }
        
        return font
    }
}
