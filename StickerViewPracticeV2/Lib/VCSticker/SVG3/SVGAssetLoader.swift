//
//  SVGAssetLoader.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 17/12/2025.
//


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
    
    /// Load SVG from a file path (for draft restoration)
    static func loadSVG(fromPath path: String) -> SVGKImage? {
        let url = URL(fileURLWithPath: path)
        
        guard FileManager.default.fileExists(atPath: path) else {
            print("❌ SVG file not found at path:", path)
            return nil
        }
        
        guard let svgImage = SVGKImage(contentsOf: url) else {
            print("❌ Failed to load SVG from path:", path)
            return nil
        }
        
        return svgImage
    }
}
