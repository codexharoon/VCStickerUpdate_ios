//
//  SVGImageSticker.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 17/12/2025.
//

import UIKit
import AVFoundation

public final class SVGImageSticker: VCBaseSticker {

    // Root container for SVG layers
    public let svgLayer = CALayer()
    
    // Track original node index from SVG file (independent of layer order)
    public var originalNodeIndex: Int = 0
    
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
    // Value can be CGColor (for shapes) or [CGColor] (for gradients)
    private var originalColors: [CALayer: Any?] = [:]

    override public func customInit() {
        super.customInit()

        svgLayer.contentsScale = UIScreen.main.scale
        contentView.layer.addSublayer(svgLayer)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        svgLayer.frame = contentView.bounds
        
        // Ensure the content layer fills the view
        if let contentLayer = svgLayer.sublayers?.first {
            contentLayer.frame = svgLayer.bounds
            
            // CRITICAL FIX: Masks do not auto-resize with their parent layer.
            // If the sticker bounds change (e.g. restore from draft), we must resize the mask too
            // to prevent content from being clipped/broken.
            if let mask = contentLayer.mask {
                mask.frame = contentLayer.bounds
            }
        }
    }

    // Attach SVG-generated layer
    public func setSVGLayer(_ layer: CALayer) {
        svgLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        svgLayer.addSublayer(layer)
        
        // Don't squash the frame here - let layoutSubviews handle sizing
        // layer.frame = svgLayer.bounds 
        
        // Store original colors for reset
        storeOriginalColors(in: layer)
    }
    
    // MARK: - Color Methods
    
    /// Apply tint color to all layers recursively
    private func applyTintColor() {
        guard let color = shapeTintColor else {
            // Reset to original colors
            resetColors()
            return
        }
        
        applyColorRecursively(to: svgLayer, color: color.cgColor)
    }
    
    /// Apply color to all layers recursively
    private func applyColorRecursively(to layer: CALayer, color: CGColor) {
        
        // 1. Handle Shape Layers (Standard Fill)
        if let shapeLayer = layer as? CAShapeLayer {
            if shapeLayer.fillColor != nil {
                shapeLayer.fillColor = color
            } else if shapeLayer.sublayers == nil && layer.mask == nil {
               // Force fill if it's a leaf shape without fill (often black by default in some SVGs)
               // Only if it has a path
               if shapeLayer.path != nil {
                   shapeLayer.fillColor = color
               }
            }
        }
        
        // 2. Handle Gradient Layers (Overwrite gradient with solid tint)
        if let gradientLayer = layer as? CAGradientLayer {
            // Create a solid gradient (start and end colors same)
            gradientLayer.colors = [color, color]
        }
        
        // 3. Recurse
        layer.sublayers?.forEach { sublayer in
            applyColorRecursively(to: sublayer, color: color)
        }
    }
    
    /// Store original colors of all layers
    private func storeOriginalColors(in layer: CALayer) {
        // Store Shape Fill
        if let shapeLayer = layer as? CAShapeLayer {
            // Only store if not already stored (preserve the very first state)
            if originalColors[shapeLayer] == nil {
                originalColors[shapeLayer] = shapeLayer.fillColor
            }
        }
        
        // Store Gradient Colors
        if let gradientLayer = layer as? CAGradientLayer {
            if originalColors[gradientLayer] == nil {
                originalColors[gradientLayer] = gradientLayer.colors
            }
        }
        
        layer.sublayers?.forEach { sublayer in
            storeOriginalColors(in: sublayer)
        }
    }
    
    /// Reset to original colors
    private func resetColors() {
        for (layer, originalValue) in originalColors {
            
            // Restore Shape Fill
            if let shapeLayer = layer as? CAShapeLayer {
                // We cast explicitly to what we expect
                shapeLayer.fillColor = (originalValue as! CGColor?)
            }
            
            // Restore Gradient Colors
            if let gradientLayer = layer as? CAGradientLayer {
                gradientLayer.colors = (originalValue as! [Any]?)
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
    
    // MARK: - Preview Snapshot
    
    /// Renders SVG content directly for layer preview.
    /// Renders svgLayer only (excludes border which is on contentView.layer).
    public override func cleanPreviewSnapshot(size: CGSize = CGSize(width: 80, height: 80)) -> UIImage {
        // Ensure svgLayer frame matches contentView
        svgLayer.frame = contentView.bounds
        svgLayer.sublayers?.first?.frame = svgLayer.bounds
        
        let layerBounds = svgLayer.bounds
        guard layerBounds.width > 0 && layerBounds.height > 0 else {
            return UIImage()
        }
        
        // Render svgLayer directly (excludes border on contentView.layer)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: layerBounds.size, format: format)
        let contentImage = renderer.image { context in
            svgLayer.render(in: context.cgContext)
        }
        
        guard contentImage.size.width > 0 && contentImage.size.height > 0 else {
            return UIImage()
        }
        
        // Scale to fit within target size
        let targetRect = AVMakeRect(aspectRatio: contentImage.size, insideRect: CGRect(origin: .zero, size: size))
        
        let finalRenderer = UIGraphicsImageRenderer(size: size, format: format)
        return finalRenderer.image { context in
            contentImage.draw(in: targetRect)
        }
    }
}
