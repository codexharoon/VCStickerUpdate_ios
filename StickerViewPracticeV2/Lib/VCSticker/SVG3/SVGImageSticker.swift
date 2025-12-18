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
    }
}
