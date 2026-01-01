//
//  LayerTableViewCell.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 29/12/2025.
//

import UIKit

class LayerTableViewCell: UITableViewCell {
    
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var unlockBtn: UIButton!
    @IBOutlet weak var hideBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var dragBtn: UIButton!
    
    var onUnlockTap: (() -> Void)?
    var onHideTap: (() -> Void)?
    var onDeleteTap: (() -> Void)?
    var onDragTap: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Clear preview image to prevent overlapping/blurry artifacts
        previewImageView.image = nil
    }
    
    
    @IBAction func unlockBtnAction(_ sender: Any) {
        onUnlockTap?()
    }
    
    
    @IBAction func hideBtnAction(_ sender: Any) {
        onHideTap?()
    }
    
    
    @IBAction func deleteBtnAction(_ sender: Any) {
        onDeleteTap?()
    }
    
    
    @IBAction func dragBtnAction(_ sender: Any) {
        onDragTap?()
    }
    
}
