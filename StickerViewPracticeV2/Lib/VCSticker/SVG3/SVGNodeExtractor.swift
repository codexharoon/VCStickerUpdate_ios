//
//  SVGNodeExtractor.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 17/12/2025.
//

import SVGKit
import UIKit

final class SVGNodeExtractor {

    static func extract(from svg: SVGKImage) -> [SVGNode] {

        guard let rootLayer = svg.caLayerTree else {
            return []
        }

        var nodes: [SVGNode] = []
        walk(layer: rootLayer, rootLayer: rootLayer, nodes: &nodes)
        return nodes
    }

    private static func walk(layer: CALayer, rootLayer: CALayer, nodes: inout [SVGNode]) {

        // TEXT - Check for CATextLayer
        if let textLayer = layer as? CATextLayer {
            
            // Use SVGPropertyHelper for comprehensive extraction
            let properties = SVGPropertyHelper.extractTextProperties(from: textLayer)
//            let validFrame = SVGPropertyHelper.validateFrame(properties.frame)
            
            // Convert frame to root coordinate space
            let absoluteFrame = rootLayer.convert(textLayer.bounds, from: textLayer)
            
            let adjustedProperties = SVGTextProperties(
                text: properties.text,
                fontSize: properties.fontSize,
                fontName: properties.fontName,
                textColor: properties.textColor,
                alignment: properties.alignment,
                isBold: properties.isBold,
                isItalic: properties.isItalic,
                frame: absoluteFrame // Use absolute frame
            )
            
            let node = SVGNode.textNode(from: adjustedProperties, transform: textLayer.affineTransform())
            nodes.append(node)
            
            // Don't recurse into text layer sublayers
            return
        }

        // SHAPE / IMAGE - Only if it's a shape layer or has image content
        else if layer is CAShapeLayer || layer is CAGradientLayer || layer.contents != nil || layer.mask != nil {
            
            // VISIBILITY CHECK: Skip leaf shape layers that are strictly invisible
            if let shape = layer as? CAShapeLayer {
                let hasFill = shape.fillColor != nil && shape.fillColor!.alpha > 0.01
                let hasStroke = shape.strokeColor != nil && shape.lineWidth > 0 && shape.strokeColor!.alpha > 0.01
                let hasSublayers = (shape.sublayers?.count ?? 0) > 0
                let hasContents = shape.contents != nil
                
                // If it has no visual properties and no children, it's a ghost layer intended for masking or hit-testing only
                if !hasFill && !hasStroke && !hasSublayers && !hasContents {
                    return
                }
            }

            // Skip if this is just a container layer
            // Note: Gradient layers and masked layers are content, not just containers
            let isContainer = (layer.sublayers?.count ?? 0) > 0 && 
                             !(layer is CAShapeLayer) && 
                             !(layer is CAGradientLayer) && 
                             layer.contents == nil && 
                             layer.mask == nil
            
            if !isContainer {
                // Convert frame to root coordinate space
                let absoluteFrame = rootLayer.convert(layer.bounds, from: layer)
                
                let node = SVGNode.shapeNode(
                    frame: absoluteFrame, // Use absolute frame
                    transform: layer.affineTransform(),
                    layer: layer
                )
                nodes.append(node)
                
                // CRITICAL: Once we extract this layer as a node, we treat it as an atomic unit.
                // Do NOT recurse into its sublayers, otherwise we extract them as duplicate/ghost stickers.
                return
            }
        }

        // Recurse into sublayers
        layer.sublayers?.forEach {
            walk(layer: $0, rootLayer: rootLayer, nodes: &nodes)
        }
    }
}
