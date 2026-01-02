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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }
    
    
    // format
    
    @IBAction func formatChanged(_ sender: UISegmentedControl) {
    }
    
    // quality
    
    @IBAction func qualityChanged(_ sender: UISegmentedControl) {
    }
    
    // export
    
    @IBAction func exportActionBtn(_ sender: Any) {
    }
    
    // cancel
    
    @IBAction func cancelActionBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
