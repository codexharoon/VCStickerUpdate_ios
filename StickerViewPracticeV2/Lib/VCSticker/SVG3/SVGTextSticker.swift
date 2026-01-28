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
        didSet { updateTextLayerAndResize() }
    }

    public var fontName: String? = nil {  // nil = use system font
        didSet { updateTextLayerAndResize() }
    }

    public var fontSize: CGFloat = 24 {
        didSet { updateTextLayerAndResize() }
    }

    public var textColor: UIColor = .label {
        didSet { updateTextLayer() }  // Color doesn't affect size
    }

    public var textAlignment: NSTextAlignment = .center {
        didSet {
            textLayer.alignmentMode = alignmentToCAMode(textAlignment)
        }
    }
    
    // MARK: - Font Style Properties
    
    public var isBold: Bool = false {
        didSet { updateTextLayerAndResize() }
    }
    
    public var isItalic: Bool = false {
        didSet { updateTextLayerAndResize() }
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
        updateTextLayerAndResize()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        
        // Disable implicit animations to prevent UI lag/jumping during resize gestures
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let contentBounds = contentView.bounds
        let textSize = textLayer.preferredFrameSize()
        let yOffset = max(0, (contentBounds.height - textSize.height) / 2)
        
        textLayer.frame = CGRect(
             x: 0,
             y: yOffset,
             width: contentBounds.width,
             height: textSize.height
         )
        
        // Fix for blurry text on resize:
        // Adjust contentsScale based on the view's current transform scale
        let scale = sqrt(transform.a * transform.a + transform.c * transform.c)
        // Avoid setting 0 or extremely small scale
        let safeScale = max(scale, 0.01)
        textLayer.contentsScale = UIScreen.main.scale * safeScale
        
        CATransaction.commit()
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
    
    /// Update text layer and resize sticker to fit the new text
    private func updateTextLayerAndResize() {
        updateTextLayer()
        
        // Only resize if the view is already in the view hierarchy
        if superview != nil {
            sizeToFitText()
        }
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
    
    // MARK: - Size Adjustment
    
    /// Resize the sticker to fit the current text content
    public func sizeToFitText(padding: CGFloat = 10, animated: Bool = true) {
        let font = SVGPropertyHelper.createFont(
            name: fontName,
            size: fontSize,
            isBold: isBold,
            isItalic: isItalic
        )
        
        // Calculate the size needed for the text
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let textSize = (text as NSString).boundingRect(
            with: maxSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).size
        
        // Add padding
        let newWidth = ceil(textSize.width) + padding * 2
        let newHeight = ceil(textSize.height) + padding * 2
        
        // Get the current center before changing bounds
        let currentCenter = self.center
        let newBounds = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
        
        if animated && superview != nil {
            // Smooth animation for professional feel
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                options: [.curveEaseInOut, .allowUserInteraction],
                animations: {
                    self.bounds = newBounds
                    self.center = currentCenter
                    self.layoutIfNeeded()
                },
                completion: nil
            )
        } else {
            // No animation
            self.bounds = newBounds
            self.center = currentCenter
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
}
