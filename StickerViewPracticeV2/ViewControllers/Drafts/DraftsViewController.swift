//
//  DraftsViewController.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 05/01/2026.
//

import UIKit

class DraftsViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .systemBackground
        cv.delegate = self
        cv.dataSource = self
        cv.register(DraftCollectionViewCell.self, forCellWithReuseIdentifier: DraftCollectionViewCell.identifier)
        return cv
    }()
    
    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No drafts yet"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Drafts"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    // MARK: - Properties
    
    private var drafts: [DraftModel] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDrafts()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data
    
    private func loadDrafts() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let drafts = DraftManager.shared.getAllDrafts()
            
            DispatchQueue.main.async {
                self?.drafts = drafts
                self?.collectionView.reloadData()
                self?.emptyLabel.isHidden = !drafts.isEmpty
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func openDraft(_ draft: DraftModel) {
        guard let storyboard = self.storyboard ?? UIStoryboard(name: "Main", bundle: nil).self as UIStoryboard? else { return }
        
        guard let mainVC = storyboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController else { return }
        
        mainVC.loadFromDraft(draft)
        mainVC.modalPresentationStyle = .fullScreen
        
        present(mainVC, animated: true)
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
            self.collectionView.deleteItems(at: [indexPath])
            self.emptyLabel.isHidden = !self.drafts.isEmpty
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension DraftsViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return drafts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DraftCollectionViewCell.identifier,
            for: indexPath
        ) as? DraftCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let draft = drafts[indexPath.item]
        
        // Configure immediately with placeholder
        cell.configure(with: draft, thumbnail: nil)
        
        // Long press to delete
        cell.onLongPress = { [weak self] in
            self?.deleteDraft(draft, at: indexPath)
        }
        
        // Load thumbnail asynchronously
        let draftId = draft.id
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = DraftManager.shared.getThumbnail(forDraftId: draftId)
            
            DispatchQueue.main.async {
                // Verify cell is still displaying the same draft (reuse safety)
                guard let currentIndexPath = collectionView.indexPath(for: cell),
                      currentIndexPath == indexPath else { return }
                
                cell.configure(with: draft, thumbnail: thumbnail)
            }
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension DraftsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let draft = drafts[indexPath.item]
        openDraft(draft)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension DraftsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
        let padding: CGFloat = 16
        let spacing: CGFloat = 16
        let totalSpacing = padding * 2 + spacing * (itemsPerRow - 1)
        let itemWidth = (collectionView.bounds.width - totalSpacing) / itemsPerRow
        let itemHeight = itemWidth * 1.3  // Aspect ratio for thumbnail + label
        
        return CGSize(width: itemWidth, height: itemHeight)
    }
}
