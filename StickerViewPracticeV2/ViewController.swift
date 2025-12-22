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
    
    @IBOutlet weak var stickersToolContainer: UIView!
    
    @IBOutlet weak var imagesToolsContainer: UIView!
    @IBOutlet weak var imgOpacitySlider: UISlider!
    
    @IBOutlet weak var textToolsContainer: UIView!
    @IBOutlet weak var boldBtn: UIButton!
    @IBOutlet weak var italicBtn: UIButton!
    @IBOutlet weak var redColorBtn: UIButton!
    @IBOutlet weak var labelColorBtn: UIButton!
    @IBOutlet weak var shadowSwitch: UISwitch!
    
    var allStickers: [VCBaseSticker] = []
    
    var activeSticker: VCBaseSticker?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        setupSticker()
        
        stickerView.layer.borderColor = UIColor.label.cgColor
        stickerView.layer.borderWidth = 1.0
        stickerView.layer.cornerRadius = 20
        
        stickersToolContainer.layer.borderColor = UIColor.gray.cgColor
        stickersToolContainer.layer.borderWidth = 1.0
        stickersToolContainer.layer.cornerRadius = 20
        
        stickerToolsContainerIsHidden(true)
    }
    
    
    
    @IBAction func addTextStickerAction(_ sender: Any) {
//        let textViewEditVC = self.getTextViewEditorVC()
//        
//        textViewEditVC.onDoneTap = { [weak self] text in
//            guard let self = self else { return }
//            
//            let textSticker = self.createTextSticker(text: text)
//            self.allStickers.append(textSticker)
//            self.setupAllStickers()
//            textSticker.beginEditing()
//        }
//        
//        self.present(textViewEditVC, animated: true)
        
        SVGCanvasLoader.load(
                svgNamed: "3",
                into: stickerView,
                stickers: &allStickers
            ){ sticker in
                self.wireStickerCallbacks(sticker)
                
                // Add double-tap gesture for text editing on SVG text stickers
                if sticker is SVGTextSticker {
                    let gesture = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTapGesture))
                    gesture.numberOfTapsRequired = 2
                    sticker.isUserInteractionEnabled = true
                    sticker.addGestureRecognizer(gesture)
                }
        }
        
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
    
    // text tools
    
    @IBAction func boldAction(_ sender: Any) {
        if let sticker = self.activeSticker as? VCTextViewSticker {
            sticker.stickerIsBold = !sticker.stickerIsBold
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            svgTextSticker.isBold = !svgTextSticker.isBold
        }
    }
    
    
    @IBAction func italicAction(_ sender: Any) {
        if let sticker = self.activeSticker as? VCTextViewSticker {
            sticker.stickerIsItalic = !sticker.stickerIsItalic
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            svgTextSticker.isItalic = !svgTextSticker.isItalic
        }
    }
    
    
    @IBAction func redColorAction(_ sender: Any) {
        if let sticker = self.activeSticker as? VCTextViewSticker {
            sticker.stickerTextColor = .systemRed
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            svgTextSticker.textColor = .systemRed
        }
    }
    
    
    @IBAction func labelColorBtnAction(_ sender: Any) {
        if let sticker = self.activeSticker as? VCTextViewSticker {
            sticker.stickerTextColor = .label
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            svgTextSticker.textColor = .label
        }
    }
    
    
    @IBAction func font1Action(_ sender: Any) {
        if let sticker = self.activeSticker as? VCTextViewSticker {
            sticker.stickerFontName = "Georgia"
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            svgTextSticker.fontName = "Georgia"
        }
    }
    
    
    @IBAction func font2Action(_ sender: Any) {
        if let sticker = self.activeSticker as? VCTextViewSticker {
            sticker.stickerFontName = "NewYork-Regular"
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            svgTextSticker.fontName = "NewYork-Regular"
        }
    }
    
    
    @IBAction func shadowSwitchAction(_ sender: UISwitch) {
        
        if let sticker = self.activeSticker as? VCTextViewSticker {
            if sender.isOn == true {
                sticker.shadowEnable = true
                sticker.stickerShadowColor = .black
                sticker.stickerShadowOpacity = 0.34
                sticker.stickerShadowRadius = 8
                sticker.stickerShadowOffset = CGSize(width: 0, height:  4)
            }
            else{
                sticker.shadowEnable = false
            }
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            if sender.isOn {
                svgTextSticker.applyShadow(
                    color: .black,
                    offset: CGSize(width: 0, height: 4),
                    blur: 8,
                    opacity: 0.34
                )
            } else {
                svgTextSticker.removeShadow()
            }
        }
    }
    
    
    // images tools
    
    @IBAction func imgOpacitySliderAction(_ sender: UISlider) {
        let opacity = sender.value  // 0.0 to 1.0
        
        if let imageSticker = self.activeSticker as? VCImageSticker {
            imageSticker.imageView.alpha = CGFloat(opacity)
        } else if let svgImageSticker = self.activeSticker as? SVGImageSticker {
            svgImageSticker.imageOpacity = opacity
        }
    }
    
    
    @IBAction func imgRedBtn(_ sender: Any) {
        if let imageSticker = self.activeSticker as? VCImageSticker {
            imageSticker.imageView.tintColor = .systemRed
            imageSticker.imageView.image = imageSticker.imageView.image?.withRenderingMode(.alwaysTemplate)
        } else if let svgImageSticker = self.activeSticker as? SVGImageSticker {
            svgImageSticker.applyTint(.systemRed)
        }
    }
    
    
    @IBAction func imgLabelBtn(_ sender: Any) {
        // Reset to original colors
        if let imageSticker = self.activeSticker as? VCImageSticker {
            imageSticker.imageView.tintColor = nil
            imageSticker.imageView.image = imageSticker.imageView.image?.withRenderingMode(.alwaysOriginal)
        } else if let svgImageSticker = self.activeSticker as? SVGImageSticker {
            svgImageSticker.applyTint(nil)  // Reset to original
        }
    }
    
    
    
    
    func setupSticker(){
        let imageSticker = VCImageSticker(frame: CGRect(x: 20, y: 40, width: 200, height: 200))
        imageSticker.borderStyle = .dotted
        imageSticker.borderColor = .systemTeal
        imageSticker.imageView.image = UIImage(named: "ImageScannerIcon")
        wireStickerCallbacks(imageSticker)
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
        wireStickerCallbacks(textSticker)
        stickerView.addSubview(textSticker)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture))
        gesture.numberOfTapsRequired = 2
        
        textSticker.isUserInteractionEnabled = true
        textSticker.addGestureRecognizer(gesture)
    }
    
    
    @objc
    func handleDoubleTapGesture(_ gesture: UITapGestureRecognizer){
        // Handle VCTextViewSticker
        if let textViewSticker = gesture.view as? VCTextViewSticker {
            let textViewEditorVC = self.getTextViewEditorVC()
            textViewEditorVC.text = textViewSticker.text
            
            textViewEditorVC.onDoneTap = { text in
                textViewSticker.text = text
                self.setupAllStickers()
                textViewSticker.beginEditing()
            }
            
            present(textViewEditorVC, animated: true)
        }
        // Handle SVGTextSticker
        else if let svgTextSticker = gesture.view as? SVGTextSticker {
            let textViewEditorVC = self.getTextViewEditorVC()
            textViewEditorVC.text = svgTextSticker.text
            
            textViewEditorVC.onDoneTap = { [weak svgTextSticker] text in
                svgTextSticker?.text = text
                svgTextSticker?.beginEditing()
            }
            
            present(textViewEditorVC, animated: true)
        }
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
        
        // Wire selection and close callbacks so selecting one finishes others
        wireStickerCallbacks(textSticker)
        
        return textSticker
    }
    
    
    func createImageSticker(image: UIImage) -> VCImageSticker {
        let imageSticker = VCImageSticker(frame: CGRect(x: stickerView.center.x - 75 , y: stickerView.center.y - 75, width: 150, height: 150))
        imageSticker.borderStyle = .dotted
        imageSticker.borderColor = .systemTeal
        imageSticker.imageView.image = image
        
        // Wire selection and close callbacks so selecting one finishes others
        wireStickerCallbacks(imageSticker)
        
        return imageSticker
    }
    
    
    func setupAllStickers(){
        // Ensure callbacks are wired for all, and add them to the view
        for sticker in allStickers {
            wireStickerCallbacks(sticker)
            sticker.finishEditing()
            self.stickerView.addSubview(sticker)
        }
    }
    
    // MARK: - Centralized selection handling
    private func wireStickerCallbacks(_ sticker: VCBaseSticker) {
        sticker.onBeginEditing = { [weak self, weak sticker] in
            guard let self = self, let selected = sticker else { return }
            // Finish editing on all other stickers
            for other in self.allStickers where other !== selected {
                other.finishEditing()
            }
            
            self.activeSticker = selected
            self.handleToolsForActiveSticker()
        }
        
        sticker.onFinishEditing = {[weak self] in
            self?.stickerToolsContainerIsHidden(true)
        }
        
        sticker.onClose = { [weak self, weak sticker] in
            guard let self = self, let s = sticker else { return }
            // Remove from our tracking array when closed
            if let idx = self.allStickers.firstIndex(where: { $0 === s }) {
                self.allStickers.remove(at: idx)
            }
            
            self.activeSticker = nil
            self.handleToolsForActiveSticker()
        }
    }
    
    
    func handleToolsForActiveSticker(){
        if let imageSticker = self.activeSticker as? VCImageSticker {
            stickersToolContainer.isHidden = false
            imagesToolsContainer.isHidden = false
            textToolsContainer.isHidden = true
            // Sync slider with current opacity
            imgOpacitySlider.value = Float(imageSticker.imageView.alpha)
        }
        else if let _ = self.activeSticker as? VCTextViewSticker {
            stickersToolContainer.isHidden = false
            imagesToolsContainer.isHidden = true
            textToolsContainer.isHidden = false
        }
        else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            // Show text tools for SVG text stickers too
            stickersToolContainer.isHidden = false
            imagesToolsContainer.isHidden = true
            textToolsContainer.isHidden = false
            
            shadowSwitch.isOn = svgTextSticker.textShadowEnabled
        }
        else if let svgImageSticker = self.activeSticker as? SVGImageSticker {
            // Show image tools for SVG shape stickers
            stickersToolContainer.isHidden = false
            imagesToolsContainer.isHidden = false
            textToolsContainer.isHidden = true
            // Sync slider with current opacity
            imgOpacitySlider.value = svgImageSticker.imageOpacity
            
        }
        else{
            stickerToolsContainerIsHidden(true)
        }
    }
    
    
    func stickerToolsContainerIsHidden(_ status: Bool){
        self.stickersToolContainer.isHidden = status
        self.imagesToolsContainer.isHidden = status
        self.textToolsContainer.isHidden = status
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
                            let sticker = self.createImageSticker(image: selectedImage)
                            self.allStickers.append(sticker)
                            
                            self.setupAllStickers()
                            sticker.beginEditing()
                        }
                    }
                }
            }
            
        }
    }
}
