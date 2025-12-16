//
//  TextViewEditorViewController.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 12/12/2025.
//

import UIKit

class TextViewEditorViewController: UIViewController {
    
    
    @IBOutlet weak var textView: UITextView!
    
    var text: String?
    
    var onDoneTap: ((_ text: String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        textView.isEditable = true
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.label.cgColor
        textView.layer.cornerRadius = 15
        
        self.textView.text = text
    }
    
    
    
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    
    @IBAction func doneAction(_ sender: Any) {
        self.onDoneTap?(textView.text)
        self.dismiss(animated: true)
    }
    
 

}
