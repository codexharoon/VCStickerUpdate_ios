//
//  SVGImageSticker.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 17/12/2025.
//

import UIKit

public final class SVGImageSticker: VCBaseSticker {

    // Root container for SVG layers
    public let svgLayer = CALayer()
    
    // MARK: - Appearance Properties
    
    /// Opacity of the image (0.0 - 1.0)
    public var imageOpacity: Float = 1.0 {
        didSet {
            svgLayer.opacity = imageOpacity
        }
    }
    
    /// Tint color overlay for the shapes
    public var shapeTintColor: UIColor? = nil {
        didSet {
            applyTintColor()
        }
    }
    
    // Store original sublayers for color reset
    private var originalColors: [CALayer: CGColor?] = [:]

    override public func customInit() {
        super.customInit()

        svgLayer.contentsScale = UIScreen.main.scale
        contentView.layer.addSublayer(svgLayer)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        svgLayer.frame = contentView.bounds
    }

    // Attach SVG-generated layer
    public func setSVGLayer(_ layer: CALayer) {
        svgLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        svgLayer.addSublayer(layer)
        layer.frame = svgLayer.bounds
        
        // Store original colors for reset
        storeOriginalColors(in: layer)
    }
    
    // MARK: - Color Methods
    
    /// Apply tint color to all shape layers
    private func applyTintColor() {
        guard let color = shapeTintColor else {
            // Reset to original colors
            resetColors()
            return
        }
        
        applyColorRecursively(to: svgLayer, color: color.cgColor)
    }
    
    /// Apply color to all CAShapeLayer sublayers recursively
    private func applyColorRecursively(to layer: CALayer, color: CGColor) {
        if let shapeLayer = layer as? CAShapeLayer {
            // Apply to fill and stroke
            if shapeLayer.fillColor != nil {
                shapeLayer.fillColor = color
            }
        }
        
        layer.sublayers?.forEach { sublayer in
            applyColorRecursively(to: sublayer, color: color)
        }
    }
    
    /// Store original colors of all shape layers
    private func storeOriginalColors(in layer: CALayer) {
        if let shapeLayer = layer as? CAShapeLayer {
            originalColors[shapeLayer] = shapeLayer.fillColor
        }
        
        layer.sublayers?.forEach { sublayer in
            storeOriginalColors(in: sublayer)
        }
    }
    
    /// Reset to original colors
    private func resetColors() {
        for (layer, originalColor) in originalColors {
            if let shapeLayer = layer as? CAShapeLayer {
                shapeLayer.fillColor = originalColor
            }
        }
    }
    
    // MARK: - Public API
    
    /// Set opacity with optional animation
    public func setOpacity(_ opacity: Float, animated: Bool = false) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.imageOpacity = opacity
            }
        } else {
            self.imageOpacity = opacity
        }
    }
    
    /// Apply a tint color (set to nil to reset)
    public func applyTint(_ color: UIColor?) {
        self.shapeTintColor = color
    }
    
    /// Get current tint color (for undo support)
    public var currentTintColor: UIColor? {
        return shapeTintColor
    }
    
    /// Reset to original appearance
    public func resetAppearance() {
        self.imageOpacity = 1.0
        self.shapeTintColor = nil
    }
}
