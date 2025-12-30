//
//  VCImageSticker.swift
//  VCCapture
//
//  Created by Vincent on 2019/11/13.
//  Copyright © 2019 Vincent. All rights reserved.
//

import UIKit
import AVFoundation

public class VCImageSticker: VCBaseSticker {  
    @objc public var imageView = UIImageView()
    
    override open func customInit() {
         super.customInit()
         self.contentView.addSubview(imageView)
         imageView.edgesToSuperview(0)
     }
    
    // MARK: - Preview Snapshot
    
    /// Renders image content directly for layer preview.
    /// Renders imageView.layer only (excludes border on contentView.layer).
    public override func cleanPreviewSnapshot(size: CGSize = CGSize(width: 80, height: 80)) -> UIImage {
        let imageBounds = imageView.bounds
        guard imageBounds.width > 0 && imageBounds.height > 0,
              imageView.image != nil else {
            return UIImage()
        }
        
        // Render imageView layer directly (includes tint, alpha)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: imageBounds.size, format: format)
        let contentImage = renderer.image { context in
            imageView.layer.render(in: context.cgContext)
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
