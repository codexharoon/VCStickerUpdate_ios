//
//  SVGTextSticker.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 17/12/2025.
//

import UIKit

public final class SVGTextSticker: VCBaseSticker {

    // MARK: - Core Layer
    public let textLayer = CATextLayer()

    // MARK: - Text Properties
    
    public var text: String = "" {
        didSet { updateTextLayer() }
    }

    public var fontName: String? = nil {  // nil = use system font
        didSet { updateTextLayer() }
    }

    public var fontSize: CGFloat = 24 {
        didSet { updateTextLayer() }
    }

    public var textColor: UIColor = .label {
        didSet { updateTextLayer() }
    }

    public var textAlignment: NSTextAlignment = .center {
        didSet {
            textLayer.alignmentMode = alignmentToCAMode(textAlignment)
        }
    }
    
    // MARK: - Font Style Properties
    
    public var isBold: Bool = false {
        didSet { updateTextLayer() }
    }
    
    public var isItalic: Bool = false {
        didSet { updateTextLayer() }
    }

    // MARK: - Shadow Properties
    
    public var textShadowEnabled: Bool = false {
        didSet { updateShadow() }
    }
    
    public var textShadowColor: UIColor = .black {
        didSet { updateShadow() }
    }
    
    public var textShadowOffset: CGSize = CGSize(width: 0, height: 2) {
        didSet { updateShadow() }
    }
    
    public var textShadowBlur: CGFloat = 4 {
        didSet { updateShadow() }
    }
    
    public var textShadowOpacity: Float = 0.5 {
        didSet { updateShadow() }
    }
    
    // MARK: - Stroke Properties
    
    public var strokeEnabled: Bool = false {
        didSet { updateTextLayer() }
    }
    
    public var strokeColor: UIColor = .black {
        didSet { updateTextLayer() }
    }
    
    public var strokeWidth: CGFloat = 1.0 {
        didSet { updateTextLayer() }
    }
    
    // MARK: - Layer Opacity
    
    public var textOpacity: Float = 1 {
        didSet { textLayer.opacity = textOpacity }
    }

    // MARK: - Init
    
    override public func customInit() {
        super.customInit()

        textLayer.contentsScale = UIScreen.main.scale
        textLayer.isWrapped = false
        textLayer.truncationMode = .none
        textLayer.alignmentMode = alignmentToCAMode(textAlignment)
        
        contentView.layer.addSublayer(textLayer)
        updateTextLayer()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        textLayer.frame = contentView.bounds
    }

    // MARK: - Update Methods
    
    private func updateTextLayer() {
        let font = SVGPropertyHelper.createFont(
            name: fontName,
            size: fontSize,
            isBold: isBold,
            isItalic: isItalic
        )
        
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        // Add stroke if enabled
        if strokeEnabled {
            attributes[.strokeColor] = strokeColor
            // Negative stroke width = fill + stroke, positive = stroke only
            attributes[.strokeWidth] = -strokeWidth
        }
        
        textLayer.string = NSAttributedString(string: text, attributes: attributes)
    }
    
    private func updateShadow() {
        if textShadowEnabled {
            textLayer.shadowColor = textShadowColor.cgColor
            textLayer.shadowOffset = textShadowOffset
            textLayer.shadowRadius = textShadowBlur
            textLayer.shadowOpacity = textShadowOpacity
        } else {
            textLayer.shadowOpacity = 0
        }
    }
    
    // MARK: - Helpers
    
    private func alignmentToCAMode(_ alignment: NSTextAlignment) -> CATextLayerAlignmentMode {
        switch alignment {
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
        @unknown default:
            return .center
        }
    }
    
    // MARK: - Public API for Editing
    
    /// Apply a new font by name (validates if available in system)
    public func applyFont(named name: String?) {
        self.fontName = name
    }
    
    /// Apply shadow with default or custom values
    public func applyShadow(
        color: UIColor = .black,
        offset: CGSize = CGSize(width: 0, height: 2),
        blur: CGFloat = 4,
        opacity: Float = 0.5
    ) {
        self.textShadowColor = color
        self.textShadowOffset = offset
        self.textShadowBlur = blur
        self.textShadowOpacity = opacity
        self.textShadowEnabled = true
    }
    
    /// Remove shadow
    public func removeShadow() {
        self.textShadowEnabled = false
    }
    
    /// Apply stroke with specified color and width
    public func applyStroke(color: UIColor, width: CGFloat = 1.0) {
        self.strokeColor = color
        self.strokeWidth = width
        self.strokeEnabled = true
    }
    
    /// Remove stroke
    public func removeStroke() {
        self.strokeEnabled = false
    }
}
