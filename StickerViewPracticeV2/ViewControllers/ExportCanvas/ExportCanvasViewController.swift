//
//  ExportCanvasViewController.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 02/01/2026.
//

import UIKit

class ExportCanvasViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var handleView: UIView!
    
    @IBOutlet weak var formatSegmentedControl: UISegmentedControl!
    @IBOutlet weak var qualitySegmentedControl: UISegmentedControl!
    @IBOutlet weak var sizeInfoLabel: UILabel!
    
    private var selectedFormat: ExportFormat = .png
    private var selectedQuality: ExportQuality = .high
    
    var onExportTap: ((ExportConfiguration) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        containerView.layer.cornerRadius = 24
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        handleView.layer.cornerRadius = 2.5
        
        self.updateSizeInfo()
        
        qualitySegmentedControl.selectedSegmentIndex = ExportQuality.allCases.firstIndex(of: selectedQuality) ?? 0
        
        // bg click dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    
    @objc
    func handleBackgroundTap(_ gesture: UIGestureRecognizer){
        let location = gesture.location(in: self.view)
        
        if !self.containerView.frame.contains(location){
            self.dismiss(animated: true)
        }
    }
    
    // format
    
    @IBAction func formatChanged(_ sender: UISegmentedControl) {
        self.selectedFormat = ExportFormat.allCases[sender.selectedSegmentIndex]
        self.updateSizeInfo()
    }
    
    // quality
    
    @IBAction func qualityChanged(_ sender: UISegmentedControl) {
        self.selectedQuality = ExportQuality.allCases[sender.selectedSegmentIndex]
        self.updateSizeInfo()
    }
    
    // export
    
    @IBAction func exportActionBtn(_ sender: Any) {
        let configuration = ExportConfiguration(format: self.selectedFormat, quality: self.selectedQuality)
        
        self.dismiss(animated: true, completion: {[weak self] in
            guard let self else {return}
            self.onExportTap?(configuration)
        })
    }
    
    // cancel
    
    @IBAction func cancelActionBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    private func updateSizeInfo() {
        var info = selectedQuality.sizeDescription
        
        if selectedFormat == .jpeg {
            let qualityPercent = Int(selectedQuality.jpegCompressionQuality * 100)
            info += " • \(qualityPercent)% compression"
        } else if selectedFormat == .pdf {
            info += " • Vector"
        }
        
        sizeInfoLabel.text = info
    }
}
