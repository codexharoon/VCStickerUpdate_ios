//
//  SVGAssetLoader.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 17/12/2025.
//


import SVGKit

import SVGKit

final class SVGAssetLoader {

    static func loadSVG(named name: String) -> SVGKImage? {

        guard let url = Bundle.main.url(forResource: name, withExtension: "svg") else {
            print("❌ SVG not found:", name)
            return nil
        }

        guard let svgImage = SVGKImage(contentsOf: url) else {
            print("❌ Failed to load SVG:", name)
            return nil
        }

        /*
         SVGKit notes:
         - Do NOT call scaleToFitInside unless you explicitly want scaling
         - Let the SVG keep its intrinsic size
         - This avoids text DPI & assertion issues
        */

        // Force correct screen scale (important for CATextLayer)
//        svgImage.scale = UIScreen.main.scale

        return svgImage
    }
}

