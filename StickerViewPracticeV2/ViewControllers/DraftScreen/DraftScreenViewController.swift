//
//  DraftScreenViewController.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 06/01/2026.
//

import UIKit

class DraftScreenViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var draftCollectionView: UICollectionView!
    
    var drafts: [DraftModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        draftCollectionView.delegate = self
        draftCollectionView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadDrafts()
    }
    
    
    @IBAction func backBtnAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    private func loadDrafts() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let drafts = DraftManager.shared.getAllDrafts()
            
            DispatchQueue.main.async {
                self?.drafts = drafts
                self?.draftCollectionView.reloadData()
            }
        }
    }
    
    private func deleteDraft(_ draft: DraftModel, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Delete Draft?",
            message: "This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            DraftManager.shared.deleteDraft(id: draft.id)
            self.drafts.remove(at: indexPath.item)
            self.draftCollectionView.deleteItems(at: [indexPath])
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return drafts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DraftScreenCollectionViewCell", for: indexPath) as! DraftScreenCollectionViewCell
        
        let draft = self.drafts[indexPath.item]
        let draftId = draft.id
        
        // Generate unique load ID - this changes EVERY time cell is configured
        let thisLoadId = UUID()
        cell.loadId = thisLoadId
        cell.imageView.image = UIImage(systemName: "doc.fill")
        
        // Long press to delete
        cell.onLongPress = { [weak self] in
            self?.deleteDraft(draft, at: indexPath)
        }
        
        // Load thumbnail asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = DraftManager.shared.getThumbnail(forDraftId: draftId)
            
            DispatchQueue.main.async { [weak cell] in
                // Verify this is still the SAME load (not a stale one from before reload)
                guard let cell = cell,
                      cell.loadId == thisLoadId else { return }
                
                cell.imageView.image = thumbnail
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let items: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
        return CGSize(width: (collectionView.frame.width) / items - 10, height: 180)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.drafts[indexPath.item]
        
        let MainVC = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        
        MainVC.loadFromDraft(item)
        
        MainVC.modalPresentationStyle = .fullScreen
        self.present(MainVC, animated: true)
        
    }

}
