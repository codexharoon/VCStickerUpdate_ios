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
    @IBOutlet weak var stickerViewContainer: UIView!
    
    @IBOutlet weak var stickersToolContainer: UIView!
    
    @IBOutlet weak var imagesToolsContainer: UIView!
    @IBOutlet weak var imgOpacitySlider: UISlider!
    
    @IBOutlet weak var textToolsContainer: UIView!
    @IBOutlet weak var boldBtn: UIButton!
    @IBOutlet weak var italicBtn: UIButton!
    @IBOutlet weak var redColorBtn: UIButton!
    @IBOutlet weak var labelColorBtn: UIButton!
    @IBOutlet weak var shadowSwitch: UISwitch!
    
    @IBOutlet weak var undoBtn: UIButton!
    @IBOutlet weak var redoBtn: UIButton!
    
    @IBOutlet weak var layerBtn: UIButton!
    @IBOutlet weak var layerContainer: UIView!
    @IBOutlet weak var layerContainerWidth: NSLayoutConstraint!
    @IBOutlet weak var layerTableView: UITableView!
    
    var allStickers: [VCBaseSticker] = []
    
    var activeSticker: VCBaseSticker?
    
    // Undo/Redo Manager (internal so extensions can register layer changes)
    let canvasUndoManager = CanvasUndoManager()
    
    var isLayerVisible = false
    
    var svgName: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        setupSticker()
        
        stickerViewContainer.layer.borderColor = UIColor.gray.cgColor
        stickerViewContainer.layer.borderWidth = 1.0
        stickerViewContainer.layer.cornerRadius = 20
        stickerViewContainer.clipsToBounds = true
        
        stickersToolContainer.layer.borderColor = UIColor.gray.cgColor
        stickersToolContainer.layer.borderWidth = 1.0
        stickersToolContainer.layer.cornerRadius = 20
        
        stickerToolsContainerIsHidden(true)
        
        imgOpacitySlider.isContinuous = false
        
        layerContainerWidth.constant = 0
        setupLayerTableView()
        
        // Setup undo manager
        setupUndoManager()
        
        loadSvg()
    }
    
    
    func loadSvg(){
        guard let name = self.svgName else { return }
        SVGCanvasLoader.load(
                svgNamed: name,
                into: stickerView,
                stickers: &allStickers
            ){ sticker in
                sticker.borderStyle = .dotted
                self.wireStickerCallbacks(sticker)
                
                // NOTE: Initial SVG load is NOT registered for undo
                // Undo/redo only applies to user changes (move, edit, delete, add new)
                
                // Add double-tap gesture for text editing on SVG text stickers
                if sticker is SVGTextSticker {
                    let gesture = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTapGesture))
                    gesture.numberOfTapsRequired = 2
                    sticker.isUserInteractionEnabled = true
                    sticker.addGestureRecognizer(gesture)
                }
        }
        
        DispatchQueue.main.async {
            self.layerTableView.reloadData()
        }
    }
    
    
    @IBAction func backBtnAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    // MARK: - Undo Manager Setup
    
    private func setupUndoManager() {
        canvasUndoManager.canvasView = stickerView
        
        canvasUndoManager.addSticker = { [weak self] sticker in
            self?.allStickers.append(sticker)
        }
        
        canvasUndoManager.insertSticker = { [weak self] sticker, index in
            guard let self = self else { return }
            // Insert at specific index, clamping to valid range
            let safeIndex = min(index, self.allStickers.count)
            self.allStickers.insert(sticker, at: safeIndex)
        }
        
        canvasUndoManager.removeSticker = { [weak self] sticker in
            if let idx = self?.allStickers.firstIndex(where: { $0 === sticker }) {
                self?.allStickers.remove(at: idx)
            }
        }
        
        canvasUndoManager.getArrayIndex = { [weak self] sticker in
            return self?.allStickers.firstIndex(where: { $0 === sticker })
        }
        
        // Wire sticker callbacks when restoring from undo
        canvasUndoManager.wireSticker = { [weak self] sticker in
            self?.wireStickerCallbacks(sticker)
        }
        
        // Focus sticker after undo/redo operations
        canvasUndoManager.selectSticker = { [weak self] sticker in
            guard let self = self else { return }
            
            // Finish editing on all stickers first
            for other in self.allStickers {
                other.finishEditing()
            }
            
            // Set the active sticker and begin editing
            self.activeSticker = sticker
            if let sticker = sticker {
                sticker.beginEditing()
            }
            self.handleToolsForActiveSticker()
        }
        
        canvasUndoManager.onUndoRedoStateChanged = { [weak self] in
            self?.updateUndoRedoButtons()
        }
        
        // Layer synchronization callbacks
        canvasUndoManager.onLayersChanged = { [weak self] in
            self?.layerTableView.reloadData()
        }
        
        canvasUndoManager.reorderStickers = { [weak self] fromIndex, toIndex in
            guard let self = self else { return }
            guard fromIndex >= 0 && fromIndex < self.allStickers.count else { return }
            
            let sticker = self.allStickers.remove(at: fromIndex)
            let safeToIndex = min(toIndex, self.allStickers.count)
            self.allStickers.insert(sticker, at: safeToIndex)
        }
        
        canvasUndoManager.updateStickerZOrder = { [weak self] in
            self?.setupAllStickers()
        }
        
        // Initial button state
        updateUndoRedoButtons()
    }

    
    private func updateUndoRedoButtons() {
        undoBtn.isEnabled = canvasUndoManager.canUndo
        redoBtn.isEnabled = canvasUndoManager.canRedo
        
        // Visual feedback for disabled state
        undoBtn.alpha = canvasUndoManager.canUndo ? 1.0 : 0.5
        redoBtn.alpha = canvasUndoManager.canRedo ? 1.0 : 0.5
    }
    
    
    
    @IBAction func layerBtnAction(_ sender: Any) {
        isLayerVisible.toggle()
        layerTableView.reloadData()
        
        let width: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 300 : 250

        layerContainerWidth.constant = isLayerVisible ? width : 0

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseInOut,
                       animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    
    @IBAction func addTextStickerAction(_ sender: Any) {
        let textViewEditVC = self.getTextViewEditorVC()
        
        textViewEditVC.onDoneTap = { [weak self] text in
            guard let self = self else { return }
            
            let textSticker = self.createSvgTextSticker(text: text)
            self.allStickers.append(textSticker)
            self.setupAllStickers()
            
            // Register for undo (user-added sticker should be undoable)
            self.canvasUndoManager.registerAddSticker(textSticker)
            
            textSticker.beginEditing()
            
            DispatchQueue.main.async {
                self.layerTableView.reloadData()
            }
        }
        
        self.present(textViewEditVC, animated: true)
        
    }
    
    
    @IBAction func saveSvgAction(_ sender: Any) {
        if let exportedImage = SVGCanvasExporter.exportCanvasAsPNG(
            stickerView,
            stickers: allStickers
        ){
            activeSticker = nil
            
            presentExportShareSheet(for: exportedImage, fileName: "Design_ \(Date().timeIntervalSince1970)", sourceView: self.view)
        }
        
    }
    
    
    // undo
    
    @IBAction func undoAction(_ sender: Any) {
        canvasUndoManager.undo()
    }
    
    // redo
    
    @IBAction func redoAction(_ sender: Any) {
        canvasUndoManager.redo()
    }
    
    // reset
    
    @IBAction func resetCanvasAction(_ sender: Any) {
        // Remove all stickers
        for sticker in allStickers {
            sticker.removeFromSuperview()
        }
        allStickers.removeAll()
        activeSticker = nil
        canvasUndoManager.clearAll()
        stickerToolsContainerIsHidden(true)
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
            let oldValue = sticker.stickerIsBold
            sticker.stickerIsBold = !sticker.stickerIsBold
            let newValue = sticker.stickerIsBold
            canvasUndoManager.registerChange(
                for: sticker,
                undo: { [weak self] in
                    sticker.stickerIsBold = oldValue
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    sticker.stickerIsBold = newValue
                    self?.refreshLayerPanel()
                },
                actionName: "Bold"
            )
            refreshLayerPanel()
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            let oldValue = svgTextSticker.isBold
            svgTextSticker.isBold = !svgTextSticker.isBold
            let newValue = svgTextSticker.isBold
            canvasUndoManager.registerChange(
                for: svgTextSticker,
                undo: { [weak self] in
                    svgTextSticker.isBold = oldValue
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    svgTextSticker.isBold = newValue
                    self?.refreshLayerPanel()
                },
                actionName: "Bold"
            )
            refreshLayerPanel()
        }
    }
    
    
    @IBAction func italicAction(_ sender: Any) {
        if let sticker = self.activeSticker as? VCTextViewSticker {
            let oldValue = sticker.stickerIsItalic
            sticker.stickerIsItalic = !sticker.stickerIsItalic
            let newValue = sticker.stickerIsItalic
            canvasUndoManager.registerChange(
                for: sticker,
                undo: { [weak self] in
                    sticker.stickerIsItalic = oldValue
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    sticker.stickerIsItalic = newValue
                    self?.refreshLayerPanel()
                },
                actionName: "Italic"
            )
            refreshLayerPanel()
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            let oldValue = svgTextSticker.isItalic
            svgTextSticker.isItalic = !svgTextSticker.isItalic
            let newValue = svgTextSticker.isItalic
            canvasUndoManager.registerChange(
                for: svgTextSticker,
                undo: { [weak self] in
                    svgTextSticker.isItalic = oldValue
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    svgTextSticker.isItalic = newValue
                    self?.refreshLayerPanel()
                },
                actionName: "Italic"
            )
            refreshLayerPanel()
        }
    }
    
    
    @IBAction func redColorAction(_ sender: Any) {
        if let sticker = self.activeSticker as? VCTextViewSticker {
            let oldValue = sticker.stickerTextColor
            sticker.stickerTextColor = .systemRed
            canvasUndoManager.registerChange(
                for: sticker,
                undo: { [weak self] in
                    sticker.stickerTextColor = oldValue
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    sticker.stickerTextColor = .systemRed
                    self?.refreshLayerPanel()
                },
                actionName: "Text Color"
            )
            refreshLayerPanel()
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            let oldValue = svgTextSticker.textColor
            svgTextSticker.textColor = .systemRed
            canvasUndoManager.registerChange(
                for: svgTextSticker,
                undo: { [weak self] in
                    svgTextSticker.textColor = oldValue
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    svgTextSticker.textColor = .systemRed
                    self?.refreshLayerPanel()
                },
                actionName: "Text Color"
            )
            refreshLayerPanel()
        }
    }
    
    
    @IBAction func labelColorBtnAction(_ sender: Any) {
        if let sticker = self.activeSticker as? VCTextViewSticker {
            let oldValue = sticker.stickerTextColor
            sticker.stickerTextColor = .label
            canvasUndoManager.registerChange(
                for: sticker,
                undo: { [weak self] in
                    sticker.stickerTextColor = oldValue
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    sticker.stickerTextColor = .label
                    self?.refreshLayerPanel()
                },
                actionName: "Text Color"
            )
            refreshLayerPanel()
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            let oldValue = svgTextSticker.textColor
            svgTextSticker.textColor = .black
            canvasUndoManager.registerChange(
                for: svgTextSticker,
                undo: { [weak self] in
                    svgTextSticker.textColor = oldValue
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    svgTextSticker.textColor = .black
                    self?.refreshLayerPanel()
                },
                actionName: "Text Color"
            )
            refreshLayerPanel()
        }
    }
    
    
    @IBAction func font1Action(_ sender: Any) {
        if let sticker = self.activeSticker as? VCTextViewSticker {
            let oldValue = sticker.stickerFontName
            sticker.stickerFontName = "Georgia"
            canvasUndoManager.registerChange(
                for: sticker,
                undo: { [weak self] in
                    sticker.stickerFontName = oldValue
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    sticker.stickerFontName = "Georgia"
                    self?.refreshLayerPanel()
                },
                actionName: "Font"
            )
            refreshLayerPanel()
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            let oldValue = svgTextSticker.fontName
            svgTextSticker.fontName = "Georgia"
            canvasUndoManager.registerChange(
                for: svgTextSticker,
                undo: { [weak self] in
                    svgTextSticker.fontName = oldValue
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    svgTextSticker.fontName = "Georgia"
                    self?.refreshLayerPanel()
                },
                actionName: "Font"
            )
            refreshLayerPanel()
        }
    }
    
    
    @IBAction func font2Action(_ sender: Any) {
        if let sticker = self.activeSticker as? VCTextViewSticker {
            let oldValue = sticker.stickerFontName
            sticker.stickerFontName = "NewYork-Regular"
            canvasUndoManager.registerChange(
                for: sticker,
                undo: { [weak self] in
                    sticker.stickerFontName = oldValue
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    sticker.stickerFontName = "NewYork-Regular"
                    self?.refreshLayerPanel()
                },
                actionName: "Font"
            )
            refreshLayerPanel()
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            let oldValue = svgTextSticker.fontName
            svgTextSticker.fontName = "NewYork-Regular"
            canvasUndoManager.registerChange(
                for: svgTextSticker,
                undo: { [weak self] in
                    svgTextSticker.fontName = oldValue
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    svgTextSticker.fontName = "NewYork-Regular"
                    self?.refreshLayerPanel()
                },
                actionName: "Font"
            )
            refreshLayerPanel()
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
            refreshLayerPanel()
        } else if let svgTextSticker = self.activeSticker as? SVGTextSticker {
            if sender.isOn {
                svgTextSticker.applyStroke(color: .white, width: 6)
                
                let newStrokeColor = svgTextSticker.strokeColor
                let newStrokeWidth = svgTextSticker.strokeWidth
                
                canvasUndoManager.registerChange(
                    undo: { [weak self] in
                        svgTextSticker.removeStroke()
                        self?.refreshLayerPanel()
                    },
                    redo: { [weak self] in
                        svgTextSticker.applyStroke(color: newStrokeColor, width: newStrokeWidth)
                        self?.refreshLayerPanel()
                    },
                    actionName: "Stroke"
                )
                
            } else {
                svgTextSticker.removeStroke()
            }
            refreshLayerPanel()
        }
    }
    
    
    // images tools
    
    @IBAction func imgOpacitySliderAction(_ sender: UISlider) {
        let opacity = sender.value  // 0.0 to 1.0
        if let imageSticker = self.activeSticker as? VCImageSticker {
            imageSticker.imageView.alpha = CGFloat(opacity)
            refreshLayerPanel()
        } else if let svgImageSticker = self.activeSticker as? SVGImageSticker {
            let old = svgImageSticker.imageOpacity
            svgImageSticker.imageOpacity = opacity
            let new = svgImageSticker.imageOpacity
            
            canvasUndoManager.registerChange(undo: { [weak self] in
                svgImageSticker.imageOpacity = old
                sender.value = old
                self?.refreshLayerPanel()
            }, redo: { [weak self] in
                svgImageSticker.imageOpacity = new
                sender.value = new
                self?.refreshLayerPanel()
            }, actionName: "Image Opacity")
            
            refreshLayerPanel()
        }
    }
    
    
    @IBAction func imgRedBtn(_ sender: Any) {
        if let imageSticker = self.activeSticker as? VCImageSticker {
            let oldTint = imageSticker.imageView.tintColor
            let oldImage = imageSticker.imageView.image
            imageSticker.imageView.tintColor = .systemRed
            imageSticker.imageView.image = imageSticker.imageView.image?.withRenderingMode(.alwaysTemplate)
            let newImage = imageSticker.imageView.image
            canvasUndoManager.registerChange(
                for: imageSticker,
                undo: { [weak self] in
                    imageSticker.imageView.tintColor = oldTint
                    imageSticker.imageView.image = oldImage
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    imageSticker.imageView.tintColor = .systemRed
                    imageSticker.imageView.image = newImage
                    self?.refreshLayerPanel()
                },
                actionName: "Image Tint"
            )
            refreshLayerPanel()
        } else if let svgImageSticker = self.activeSticker as? SVGImageSticker {
            let oldTint = svgImageSticker.currentTintColor
            svgImageSticker.applyTint(.systemRed)
            canvasUndoManager.registerChange(
                for: svgImageSticker,
                undo: { [weak self] in
                    svgImageSticker.applyTint(oldTint)
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    svgImageSticker.applyTint(.systemRed)
                    self?.refreshLayerPanel()
                },
                actionName: "Image Tint"
            )
            refreshLayerPanel()
        }
    }
    
    
    @IBAction func imgLabelBtn(_ sender: Any) {
        // Reset to original colors
        if let imageSticker = self.activeSticker as? VCImageSticker {
            let oldTint = imageSticker.imageView.tintColor
            let oldImage = imageSticker.imageView.image
            imageSticker.imageView.tintColor = nil
            imageSticker.imageView.image = imageSticker.imageView.image?.withRenderingMode(.alwaysOriginal)
            let newImage = imageSticker.imageView.image
            canvasUndoManager.registerChange(
                for: imageSticker,
                undo: { [weak self] in
                    imageSticker.imageView.tintColor = oldTint
                    imageSticker.imageView.image = oldImage
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    imageSticker.imageView.tintColor = nil
                    imageSticker.imageView.image = newImage
                    self?.refreshLayerPanel()
                },
                actionName: "Image Tint"
            )
            refreshLayerPanel()
        } else if let svgImageSticker = self.activeSticker as? SVGImageSticker {
            let oldTint = svgImageSticker.currentTintColor
            svgImageSticker.applyTint(nil)  // Reset to original
            canvasUndoManager.registerChange(
                for: svgImageSticker,
                undo: { [weak self] in
                    svgImageSticker.applyTint(oldTint)
                    self?.refreshLayerPanel()
                },
                redo: { [weak self] in
                    svgImageSticker.applyTint(nil)
                    self?.refreshLayerPanel()
                },
                actionName: "Image Tint"
            )
            refreshLayerPanel()
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
                let old = textViewSticker.text
                textViewSticker.text = text
                
                self.canvasUndoManager.registerChange(
                    for: textViewSticker,
                    undo: { [weak self] in
                        textViewSticker.text = old
                        self?.refreshLayerPanel()
                    },
                    redo: { [weak self] in
                        textViewSticker.text = text
                        self?.refreshLayerPanel()
                    },
                    actionName: "Text Edit"
                )
                
                self.setupAllStickers()
                textViewSticker.beginEditing()
                
                DispatchQueue.main.async {
                    self.refreshLayerPanel()
                }
            }
            
            present(textViewEditorVC, animated: true)
        }
        // Handle SVGTextSticker
        else if let svgTextSticker = gesture.view as? SVGTextSticker {
            let textViewEditorVC = self.getTextViewEditorVC()
            textViewEditorVC.text = svgTextSticker.text
            
            textViewEditorVC.onDoneTap = { [weak self, weak svgTextSticker] text in
                guard let self = self, let svgTextSticker = svgTextSticker else { return }
                
                let oldText = svgTextSticker.text
                svgTextSticker.text = text
                
                // Register undo/redo for text change
                self.canvasUndoManager.registerChange(
                    for: svgTextSticker,
                    undo: { [weak self] in
                        svgTextSticker.text = oldText
                        self?.refreshLayerPanel()
                    },
                    redo: { [weak self] in
                        svgTextSticker.text = text
                        self?.refreshLayerPanel()
                    },
                    actionName: "Text Edit"
                )
                
                svgTextSticker.beginEditing()
                
                // Sync layer panel
                DispatchQueue.main.async {
                    self.refreshLayerPanel()
                }
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
    
    func createSvgTextSticker(text: String) -> SVGTextSticker {
        let sticker = SVGTextSticker(frame: CGRect(x: stickerView.bounds.midX - 75 , y: stickerView.bounds.midY - 75, width: 150, height: 150))
        
        // Apply all extracted properties
        sticker.text = text
        sticker.fontSize = 24
        sticker.fontName = nil
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture))
        gesture.numberOfTapsRequired = 2
        
        sticker.isUserInteractionEnabled = true
        sticker.addGestureRecognizer(gesture)
        
        // Wire selection and close callbacks so selecting one finishes others
        wireStickerCallbacks(sticker)
        
        return sticker
    }
    
    
    func createImageSticker(image: UIImage) -> VCImageSticker {
        let imageSticker = VCImageSticker(frame: CGRect(x: stickerView.bounds.midX - 75 , y: stickerView.bounds.midY - 75, width: 150, height: 150))
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
        
        if let a = self.activeSticker {
            a.beginEditing()
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
            
            self.handleRemoveSticker(sticker: s)
        }
        
        // Register transform changes for undo
        sticker.onTransformEnded = { [weak self, weak sticker] oldTransform, oldCenter in
            guard let self = self, let s = sticker else { return }
            self.canvasUndoManager.registerTransformChange(for: s, from: oldTransform, oldCenter: oldCenter)
        }
    }
    
    
    func handleRemoveSticker(sticker: VCBaseSticker?){
        guard let s = sticker else { return }
        
        // Register undo for delete BEFORE removing
        self.canvasUndoManager.registerRemoveSticker(s)
        
        // Remove from our tracking array when closed
        if let idx = self.allStickers.firstIndex(where: { $0 === s }) {
            self.allStickers.remove(at: idx)
        }
        
        // Remove from view (VCBaseSticker no longer auto-removes when onClose is set)
        s.removeFromSuperview()
        
        self.activeSticker = nil
        self.handleToolsForActiveSticker()
        
        self.layerTableView.reloadData()
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
            
            shadowSwitch.isOn = svgTextSticker.strokeEnabled
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
    
    
    /// Refresh the layer panel preview for the active sticker only (efficient).
    /// Reloading a single row is much faster than reloading the entire table.
    func refreshLayerPanel() {
        guard isLayerVisible else { return }
        
        let numOfRows = layerTableView.numberOfRows(inSection: 0)
        if numOfRows != allStickers.count {
            layerTableView.reloadData()
            return
        }
        
        if let sticker = activeSticker,
           let index = allStickers.firstIndex(where: { $0 === sticker }),
           index < numOfRows {
            layerTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
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
                            let sticker = self.createImageSticker(image: selectedImage)
                            self.allStickers.append(sticker)
                            self.setupAllStickers()
                            
                            // Register for undo (user-added sticker should be undoable)
                            self.canvasUndoManager.registerAddSticker(sticker)
                            
                            sticker.beginEditing()
                            
                            DispatchQueue.main.async {
                                self.layerTableView.reloadData()
                            }
                        }
                    }
                }
            }
            
        }
    }
}
