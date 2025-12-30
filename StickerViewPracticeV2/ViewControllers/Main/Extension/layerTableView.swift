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
    
    // MARK: - Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allStickers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LayerTableViewCell", for: indexPath) as! LayerTableViewCell
        let sticker = allStickers[indexPath.row]
        
        cell.previewImageView.image = sticker.cleanPreviewSnapshot(size: CGSize(width: 80, height: 80))
        cell.previewImageView.contentMode = .scaleAspectFit
        cell.previewImageView.clipsToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    // MARK: - Selection
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        activeSticker = allStickers[indexPath.row]
        activeSticker?.beginEditing()
    }
    
    // MARK: - Drag & Drop
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = NSItemProvider(object: NSString(string: "\(indexPath.row)"))
        return [UIDragItem(itemProvider: item)]
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: any UITableViewDropCoordinator) {
        guard let destIndexPath = coordinator.destinationIndexPath else { return }
        
        coordinator.items.forEach { dropItem in
            if let sourceIndexPath = dropItem.sourceIndexPath {
                let fromIndex = sourceIndexPath.row
                let toIndex = destIndexPath.row
                
                tableView.beginUpdates()
                let removedItem = allStickers.remove(at: sourceIndexPath.row)
                allStickers.insert(removedItem, at: destIndexPath.row)
                tableView.moveRow(at: sourceIndexPath, to: destIndexPath)
                tableView.endUpdates()
                
                setupAllStickers()
                canvasUndoManager.registerLayerReorder(from: fromIndex, to: toIndex)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: any UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}
