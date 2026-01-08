//
//  DraftScreenCollectionViewCell.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 06/01/2026.
//

import UIKit

class DraftScreenCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    var onLongPress: (() -> Void)?
    
    /// Unique ID for current async load - changes every time cell is configured
    var loadId: UUID?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupGesture()
        
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.mainView.alpha = self.isHighlighted ? 0.7 : 1.0
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.imageView.image = nil
        self.onLongPress = nil
        self.loadId = nil  // Invalidate any pending async loads
    }
    
    
    func setupGesture(){
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        gesture.minimumPressDuration = 0.5
        self.mainView.addGestureRecognizer(gesture)
        self.mainView.isUserInteractionEnabled = true
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            // Visual feedback
            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            } completion: { _ in
                UIView.animate(withDuration: 0.1) {
                    self.transform = .identity
                }
            }
            
            onLongPress?()
        }
    }
}
