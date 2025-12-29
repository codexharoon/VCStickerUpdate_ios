//
//  layerTableView.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 29/12/2025.
//

import Foundation
import UIKit


extension ViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDragDelegate, UITableViewDropDelegate {

    func setupLayerTableView() {
        layerTableView.delegate = self
        layerTableView.dataSource = self
        layerTableView.dragDelegate = self
        layerTableView.dropDelegate = self
        layerTableView.dragInteractionEnabled = true
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allStickers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LayerTableViewCell", for: indexPath) as! LayerTableViewCell
        
        let stickerView = allStickers[indexPath.row]
        cell.previewImageView.image = stickerView.snapshotImage()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = allStickers[indexPath.row]
        
        self.activeSticker = item
        self.activeSticker?.beginEditing()
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = NSItemProvider(object: NSString(string: "\(indexPath.row)"))
        return [UIDragItem(itemProvider: item)]
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: any UITableViewDropCoordinator) {
        guard let destIndexPath = coordinator.destinationIndexPath else {return}
        
        coordinator.items.forEach { dropItem in
            if let sourceIndexPath = dropItem.sourceIndexPath {
                // Capture original indices for undo
                let fromIndex = sourceIndexPath.row
                let toIndex = destIndexPath.row
                
                tableView.beginUpdates()
                let removedItem = allStickers.remove(at: sourceIndexPath.row)
                allStickers.insert(removedItem, at: destIndexPath.row)
                tableView.moveRow(at: sourceIndexPath, to: destIndexPath)
                tableView.endUpdates()
                
                self.setupAllStickers()
                
                // Register for undo/redo
                canvasUndoManager.registerLayerReorder(from: fromIndex, to: toIndex)
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: any UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
}


extension UIView {
    func snapshotImage() -> UIImage {
        // Guard against zero-sized views
        guard self.bounds.width > 0 && self.bounds.height > 0 else {
            return UIImage()
        }
        
        // Force layout to complete before snapshotting
        self.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(bounds: self.bounds)
        return renderer.image { context in
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
        }
    }
}

