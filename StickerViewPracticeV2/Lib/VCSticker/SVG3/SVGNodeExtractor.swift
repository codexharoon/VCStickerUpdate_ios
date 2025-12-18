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
        walk(layer: rootLayer, nodes: &nodes)
        return nodes
    }

    private static func walk(layer: CALayer, nodes: inout [SVGNode]) {

        // TEXT - Check for CATextLayer
        if let textLayer = layer as? CATextLayer {
            
            // Use SVGPropertyHelper for comprehensive extraction
            let properties = SVGPropertyHelper.extractTextProperties(from: textLayer)
            let validFrame = SVGPropertyHelper.validateFrame(properties.frame)
            
            let adjustedProperties = SVGTextProperties(
                text: properties.text,
                fontSize: properties.fontSize,
                fontName: properties.fontName,
                textColor: properties.textColor,
                alignment: properties.alignment,
                isBold: properties.isBold,
                isItalic: properties.isItalic,
                frame: validFrame
            )
            
            let node = SVGNode.textNode(from: adjustedProperties, transform: textLayer.affineTransform())
            nodes.append(node)
            
            // Don't recurse into text layer sublayers
            return
        }

        // SHAPE / IMAGE - Only if it's a shape layer or has image content
        else if layer is CAShapeLayer || layer.contents != nil {
            
            // Skip if this is just a container layer
            let isContainer = (layer.sublayers?.count ?? 0) > 0 && !(layer is CAShapeLayer) && layer.contents == nil
            
            if !isContainer {
                let node = SVGNode.shapeNode(
                    frame: layer.frame,
                    transform: layer.affineTransform(),
                    layer: layer
                )
                nodes.append(node)
            }
        }

        // Recurse into sublayers
        layer.sublayers?.forEach {
            walk(layer: $0, nodes: &nodes)
        }
    }
}
