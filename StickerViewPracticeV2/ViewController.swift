//
//  ViewController.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 10/12/2025.
//

import UIKit
import PhotosUI

class ViewController: UIViewController, PHPickerViewControllerDelegate {

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
    
    
    
    @IBAction func addImageStickerAction(_ sender: Any) {
        var pickerConfig = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        pickerConfig.filter = .images
        pickerConfig.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: pickerConfig)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        
        self.present(picker, animated: true)
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
    
    
    func createImageSticker(image: UIImage){
        let imageSticker = VCImageSticker(frame: CGRect(x: stickerView.center.x - 75 , y: stickerView.center.y - 75, width: 150, height: 150))
        imageSticker.borderStyle = .dotted
        imageSticker.borderColor = .systemTeal
        imageSticker.imageView.image = image
        stickerView.addSubview(imageSticker)
    }
    
    
    func setupAllTextStickers(){
        for sticker in textStickers {
            self.stickerView.addSubview(sticker)
        }
    }


}



extension ViewController {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        if let itemprovider = results.first?.itemProvider{
          
            if itemprovider.canLoadObject(ofClass: UIImage.self){
                itemprovider.loadObject(ofClass: UIImage.self) { image , error  in
                    if let error{
                        print(error)
                    }
                    if let selectedImage = image as? UIImage{
                        DispatchQueue.main.async {
                            self.createImageSticker(image: selectedImage)
                        }
                    }
                }
            }
            
        }
    }
}

