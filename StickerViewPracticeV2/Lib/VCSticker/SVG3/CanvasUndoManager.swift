//
//  CanvasUndoManager.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 25/12/2025.
//

import UIKit

/// Manages undo/redo operations for the sticker canvas
final class CanvasUndoManager {
    
    private let undoManager = UndoManager()
    
    /// Callback to update UI button states
    var onUndoRedoStateChanged: (() -> Void)?
    
    /// Reference to the canvas view (for re-adding stickers)
    weak var canvasView: UIView?
    
    /// Callbacks for sticker management
    var addSticker: ((VCBaseSticker) -> Void)?
    var insertSticker: ((VCBaseSticker, Int) -> Void)?  // Insert at specific index
    var removeSticker: ((VCBaseSticker) -> Void)?
    var getArrayIndex: ((VCBaseSticker) -> Int?)?  // Get current array index
    var wireSticker: ((VCBaseSticker) -> Void)?  // Re-wire callbacks after restore
    var selectSticker: ((VCBaseSticker?) -> Void)?  // Focus sticker after undo/redo
    
    // MARK: - Undo/Redo State
    
    var canUndo: Bool { undoManager.canUndo }
    var canRedo: Bool { undoManager.canRedo }
    
    // MARK: - Actions
    
    func undo() {
        undoManager.undo()
        notifyStateChanged()
    }
    
    func redo() {
        undoManager.redo()
        notifyStateChanged()
    }
    
    func clearAll() {
        undoManager.removeAllActions()
        notifyStateChanged()
    }
    
    private func notifyStateChanged() {
        onUndoRedoStateChanged?()
    }
    
    // MARK: - Register Add Sticker
    
    func registerAddSticker(_ sticker: VCBaseSticker) {
        undoManager.registerUndo(withTarget: self) { [weak self, weak sticker] manager in
            guard let self = self, let sticker = sticker else { return }
            
            // Remove from array and view
            self.removeSticker?(sticker)
            sticker.removeFromSuperview()
            
            // Clear selection since sticker is removed
            self.selectSticker?(nil)
            
            // Register redo (re-add)
            self.registerAddStickerRedo(sticker)
        }
        undoManager.setActionName("Add Sticker")
        notifyStateChanged()
    }
    
    private func registerAddStickerRedo(_ sticker: VCBaseSticker) {
        undoManager.registerUndo(withTarget: self) { [weak self, weak sticker] manager in
            guard let self = self, let sticker = sticker else { return }
            
            // Re-add to array and view
            self.addSticker?(sticker)
            self.canvasView?.addSubview(sticker)
            self.wireSticker?(sticker)
            
            // Focus the restored sticker
            self.selectSticker?(sticker)
            
            // Register undo again
            self.registerAddSticker(sticker)
        }
        notifyStateChanged()
    }
    
    // MARK: - Register Remove Sticker (Delete)
    
    func registerRemoveSticker(_ sticker: VCBaseSticker) {
        // NOTE: We use a STRONG reference to sticker here because after deletion,
        // the sticker is removed from view and array - without a strong reference
        // it would be deallocated and undo would fail.
        // Since the sticker object is kept alive, it maintains its own state
        // (frame, transform, center) - we don't need to capture and restore these.
        
        // Capture z-index (subview order) for proper layer restoration
        let zIndex = sticker.superview?.subviews.firstIndex(of: sticker)
        
        // Capture array index for proper order restoration
        let arrayIndex = getArrayIndex?(sticker)
        
        undoManager.registerUndo(withTarget: self) { [weak self, sticker] manager in
            guard let self = self else { return }
            
            // Restore to array at original index
            if let arrayIndex = arrayIndex {
                self.insertSticker?(sticker, arrayIndex)
            } else {
                self.addSticker?(sticker)
            }
            
            // Restore to view at original z-index
            // The sticker already has its correct frame/transform/center
            if let zIndex = zIndex, let canvasView = self.canvasView {
                if zIndex < canvasView.subviews.count {
                    canvasView.insertSubview(sticker, at: zIndex)
                } else {
                    canvasView.addSubview(sticker)
                }
            } else {
                self.canvasView?.addSubview(sticker)
            }
            
            // Re-wire callbacks (sticker was removed so callbacks need reconnecting)
            self.wireSticker?(sticker)
            
            // Focus the restored sticker
            self.selectSticker?(sticker)
            
            // Register redo (delete again)
            self.registerRemoveStickerRedo(sticker, zIndex: zIndex, arrayIndex: arrayIndex)
        }
        undoManager.setActionName("Delete Sticker")
        notifyStateChanged()
    }
    
    private func registerRemoveStickerRedo(_ sticker: VCBaseSticker, zIndex: Int?, arrayIndex: Int?) {
        // Strong reference needed to keep sticker alive in redo stack
        undoManager.registerUndo(withTarget: self) { [weak self, sticker] manager in
            guard let self = self else { return }
            
            // Remove again
            self.removeSticker?(sticker)
            sticker.removeFromSuperview()
            
            // Clear selection since sticker is removed
            self.selectSticker?(nil)
            
            // Register undo again with saved indices
            self.registerRemoveStickerWithIndices(sticker, zIndex: zIndex, arrayIndex: arrayIndex)
        }
        notifyStateChanged()
    }
    
    // Helper to register undo with pre-captured indices (for redo chain)
    // Uses the same simplified approach - sticker maintains its own state
    private func registerRemoveStickerWithIndices(_ sticker: VCBaseSticker, zIndex: Int?, arrayIndex: Int?) {
        undoManager.registerUndo(withTarget: self) { [weak self, sticker] manager in
            guard let self = self else { return }
            
            // Restore to array at original index
            if let arrayIndex = arrayIndex {
                self.insertSticker?(sticker, arrayIndex)
            } else {
                self.addSticker?(sticker)
            }
            
            // Restore to view at original z-index
            // The sticker already has its correct frame/transform/center
            if let zIndex = zIndex, let canvasView = self.canvasView {
                if zIndex < canvasView.subviews.count {
                    canvasView.insertSubview(sticker, at: zIndex)
                } else {
                    canvasView.addSubview(sticker)
                }
            } else {
                self.canvasView?.addSubview(sticker)
            }
            
            // Re-wire callbacks
            self.wireSticker?(sticker)
            
            // Focus the restored sticker
            self.selectSticker?(sticker)
            
            // Register redo (delete again)
            self.registerRemoveStickerRedo(sticker, zIndex: zIndex, arrayIndex: arrayIndex)
        }
        notifyStateChanged()
    }
    
    // MARK: - Register Transform Change
    
    func registerTransformChange(for sticker: VCBaseSticker, from oldTransform: CGAffineTransform, oldCenter: CGPoint) {
        let newTransform = sticker.transform
        let newCenter = sticker.center
        
        undoManager.registerUndo(withTarget: self) { [weak self, weak sticker] manager in
            guard let self = self, let sticker = sticker else { return }
            
            // Restore old state
            sticker.transform = oldTransform
            sticker.center = oldCenter
            sticker.setNeedsLayout()
            
            // Focus the affected sticker
            self.selectSticker?(sticker)
            
            // Register redo
            manager.registerTransformRedo(for: sticker, to: newTransform, newCenter: newCenter, from: oldTransform, oldCenter: oldCenter)
        }
        undoManager.setActionName("Transform")
        notifyStateChanged()
    }
    
    private func registerTransformRedo(for sticker: VCBaseSticker, to newTransform: CGAffineTransform, newCenter: CGPoint, from oldTransform: CGAffineTransform, oldCenter: CGPoint) {
        undoManager.registerUndo(withTarget: self) { [weak self, weak sticker] manager in
            guard let self = self, let sticker = sticker else { return }
            
            sticker.transform = newTransform
            sticker.center = newCenter
            sticker.setNeedsLayout()
            
            // Focus the affected sticker
            self.selectSticker?(sticker)
            
            manager.registerTransformChange(for: sticker, from: oldTransform, oldCenter: oldCenter)
        }
        notifyStateChanged()
    }
    
    // MARK: - Register Property Change (Generic)
    
    func registerPropertyChange<T>(
        for sticker: VCBaseSticker,
        keyPath: ReferenceWritableKeyPath<VCBaseSticker, T>,
        oldValue: T,
        actionName: String
    ) {
        let newValue = sticker[keyPath: keyPath]
        
        undoManager.registerUndo(withTarget: self) { [weak sticker] manager in
            guard let sticker = sticker else { return }
            sticker[keyPath: keyPath] = oldValue
            manager.registerPropertyRedo(for: sticker, keyPath: keyPath, newValue: newValue, oldValue: oldValue, actionName: actionName)
        }
        undoManager.setActionName(actionName)
        notifyStateChanged()
    }
    
    private func registerPropertyRedo<T>(
        for sticker: VCBaseSticker,
        keyPath: ReferenceWritableKeyPath<VCBaseSticker, T>,
        newValue: T,
        oldValue: T,
        actionName: String
    ) {
        undoManager.registerUndo(withTarget: self) { [weak sticker] manager in
            guard let sticker = sticker else { return }
            sticker[keyPath: keyPath] = newValue
            manager.registerPropertyChange(for: sticker, keyPath: keyPath, oldValue: oldValue, actionName: actionName)
        }
        notifyStateChanged()
    }
    
    // MARK: - Closure-based Property Change (for non-keypath properties)
    
    /// Register a property change with optional sticker for focus management
    func registerChange(
        for sticker: VCBaseSticker? = nil,
        undo: @escaping () -> Void,
        redo: @escaping () -> Void,
        actionName: String
    ) {
        undoManager.registerUndo(withTarget: self) { [weak self, weak sticker] manager in
            undo()
            // Focus the affected sticker if provided
            if let sticker = sticker {
                self?.selectSticker?(sticker)
            }
            manager.registerChangeRedo(for: sticker, undo: undo, redo: redo, actionName: actionName)
        }
        undoManager.setActionName(actionName)
        notifyStateChanged()
    }
    
    private func registerChangeRedo(
        for sticker: VCBaseSticker?,
        undo: @escaping () -> Void,
        redo: @escaping () -> Void,
        actionName: String
    ) {
        undoManager.registerUndo(withTarget: self) { [weak self, weak sticker] manager in
            redo()
            // Focus the affected sticker if provided
            if let sticker = sticker {
                self?.selectSticker?(sticker)
            }
            manager.registerChange(for: sticker, undo: undo, redo: redo, actionName: actionName)
        }
        notifyStateChanged()
    }
    
    // MARK: - Grouping
    
    func beginGrouping() {
        undoManager.beginUndoGrouping()
    }
    
    func endGrouping() {
        undoManager.endUndoGrouping()
        notifyStateChanged()
    }
}
