//
//  SVGCanvasLoader.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 17/12/2025.
//

import UIKit
import SVGKit

final class SVGCanvasLoader {

    static func load(
        svgNamed name: String,
        into canvas: UIView,
        stickers: inout [VCBaseSticker],
        wire: (VCBaseSticker) -> Void
    ) {

        guard let svg = SVGAssetLoader.loadSVG(named: name) else { return }

        let nodes = SVGNodeExtractor.extract(from: svg)

        var newStickers: [VCBaseSticker] = []

        for node in nodes {
            let sticker = SVGStickerFactory.makeSticker(from: node)
            newStickers.append(sticker)
        }
        
        if newStickers.isEmpty { return }
        
        // 1. Calculate Union Rect of all stickers
        var totalRect: CGRect = .null
        for sticker in newStickers {
            totalRect = totalRect.isNull ? sticker.frame : totalRect.union(sticker.frame)
        }
        
        // Avoid divide by zero
        let contentWidth = max(totalRect.width, 1)
        let contentHeight = max(totalRect.height, 1)
        
        // 2. Calculate Scale to fit canvas
        let padding: CGFloat = 20
        let safeArea = canvas.bounds.insetBy(dx: padding, dy: padding)
        
        let scaleX = safeArea.width / contentWidth
        let scaleY = safeArea.height / contentHeight
        let scale = min(scaleX, scaleY)
        
        // 3. Calculate Target Origin to center the content
        let scaledWidth = contentWidth * scale
        let scaledHeight = contentHeight * scale
        
        let targetX = (canvas.bounds.width - scaledWidth) / 2.0
        let targetY = (canvas.bounds.height - scaledHeight) / 2.0
        
        // 4. Apply Scaling and Positioning
        for sticker in newStickers {
            
            // Calculate new center position
            let oldCenter = sticker.center
            let relX = (oldCenter.x - totalRect.origin.x)
            let relY = (oldCenter.y - totalRect.origin.y)
            
            let newX = targetX + (relX * scale)
            let newY = targetY + (relY * scale)
            
            sticker.center = CGPoint(x: newX, y: newY)
            sticker.transform = sticker.transform.scaledBy(x: scale, y: scale)
            
            wire(sticker)
            stickers.append(sticker)
            canvas.addSubview(sticker)
        }
    }
}
