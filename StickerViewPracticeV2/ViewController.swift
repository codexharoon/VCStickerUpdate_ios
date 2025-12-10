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
        let image = VCImageSticker(frame: CGRect(x: 20, y: 40, width: 200, height: 200))
        image.borderStyle = .dotted
        image.borderColor = .systemTeal
        image.imageView.image = UIImage(named: "ImageScannerIcon")
        stickerView.addSubview(image)
        
        let label = VCLabelSticker(center: self.view.center)
        label.borderStyle = .dotted
        label.borderColor = .systemTeal
        label.text = "Haroon"
        label.textColor = .label
        stickerView.addSubview(label)
    }


}

