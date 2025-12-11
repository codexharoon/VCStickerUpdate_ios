//
//  ViewController.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 10/12/2025.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var stickerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupSticker()
    }
    
    
    
    func setupSticker(){
        let imageSticker = VCImageSticker(frame: CGRect(x: 20, y: 40, width: 200, height: 200))
        imageSticker.borderStyle = .dotted
        imageSticker.borderColor = .systemTeal
        imageSticker.imageView.image = UIImage(named: "ImageScannerIcon")
        stickerView.addSubview(imageSticker)
        
        let textSticker = VCTextViewSticker(center: self.view.center)
        textSticker.borderStyle = .dotted
        textSticker.borderColor = .systemTeal
        textSticker.text = "Haroon. this is large text \n testing is the process \n testing is testing Haroon. this is large text \n testing is the process \n testing is testing"
        textSticker.stickerTextColor = .label
        textSticker.stickerAlignment = .left
        textSticker.stickerFontName = "SF Mono"
        textSticker.stickerIsBold = true
        textSticker.stickerIsItalic = true
//        textSticker.shadowEnable = true
//        textSticker.stickerShadowOffset = CGSize(width: 0, height: 0)
        stickerView.addSubview(textSticker)
    }


}

