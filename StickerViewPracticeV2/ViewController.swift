//
//  ViewController.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 10/12/2025.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var stickerView: UIView!
    
    
    var textStickers: [VCTextViewSticker] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        setupSticker()
    }
    
    
    
    @IBAction func addTextStickerAction(_ sender: Any) {
        let textViewEditVC = self.getTextViewEditorVC()
        
        textViewEditVC.onDoneTap = { [weak self] text in
            guard let self = self else { return }
            let _ = self.createTextSticker(text: text)
//            let textSticker = self.createTextSticker(text: text)
//            self.textStickers.append(textSticker)
//            self.setupAllTextStickers()
            
        }
        
        self.present(textViewEditVC, animated: true)
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
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture))
        gesture.numberOfTapsRequired = 2
        
        textSticker.isUserInteractionEnabled = true
        textSticker.addGestureRecognizer(gesture)
    }
    
    
    @objc
    func handleDoubleTapGesture(_ gesture: UITapGestureRecognizer){
        guard let stickerView = gesture.view as? VCTextViewSticker else {return}
        
        let textViewEditorVC = self.getTextViewEditorVC()
        textViewEditorVC.text = stickerView.text
        
        textViewEditorVC.onDoneTap = { text in
            stickerView.text = text
        }
        
        present(textViewEditorVC, animated: true)
    }
    
    
    func getTextViewEditorVC() -> TextViewEditorViewController {
        let textViewEditorVC = self.storyboard?.instantiateViewController(withIdentifier: "TextViewEditorViewController") as! TextViewEditorViewController
        return textViewEditorVC
    }
    
    
    
    func createTextSticker(text: String) -> VCTextViewSticker {
        let textSticker = VCTextViewSticker(center: self.view.center)
        textSticker.borderStyle = .dotted
        textSticker.borderColor = .systemTeal
        
        textSticker.text = text
        textSticker.stickerTextColor = .label
        textSticker.stickerAlignment = .center
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture))
        gesture.numberOfTapsRequired = 2
        
        textSticker.isUserInteractionEnabled = true
        textSticker.addGestureRecognizer(gesture)
        
        self.stickerView.addSubview(textSticker)
        
        return textSticker
    }
    
    
    func setupAllTextStickers(){
        for sticker in textStickers {
            self.stickerView.addSubview(sticker)
        }
    }


}

