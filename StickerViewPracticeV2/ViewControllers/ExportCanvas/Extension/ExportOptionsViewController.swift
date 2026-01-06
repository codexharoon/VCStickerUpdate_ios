//
//  ExportOptionsViewController.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 02/01/2026.
//

import UIKit

/// View controller for selecting export format and quality options
class ExportOptionsViewController: UIViewController {
    
    // MARK: - Callback
    
    var onExportSelected: ((ExportConfiguration) -> Void)?
    
    // MARK: - Properties
    
    private var selectedFormat: ExportFormat = .png
    private var selectedQuality: ExportQuality = .high
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var handleView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Export Options"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var formatLabel: UILabel = {
        let label = UILabel()
        label.text = "Format"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var formatSegmentedControl: UISegmentedControl = {
        let items = ExportFormat.allCases.map { $0.displayName }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(formatChanged(_:)), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var qualityLabel: UILabel = {
        let label = UILabel()
        label.text = "Quality"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var qualitySegmentedControl: UISegmentedControl = {
        let items = ExportQuality.allCases.map { $0.displayName }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 2 // High by default
        control.addTarget(self, action: #selector(qualityChanged(_:)), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var sizeInfoLabel: UILabel = {
        let label = UILabel()
        label.text = ExportQuality.high.sizeDescription
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var exportButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Export", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        view.addSubview(containerView)
        containerView.addSubview(handleView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(formatLabel)
        containerView.addSubview(formatSegmentedControl)
        containerView.addSubview(qualityLabel)
        containerView.addSubview(qualitySegmentedControl)
        containerView.addSubview(sizeInfoLabel)
        containerView.addSubview(exportButton)
        containerView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            // Container
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Handle
            handleView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            handleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 40),
            handleView.heightAnchor.constraint(equalToConstant: 5),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Format Label
            formatLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            formatLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            // Format Segmented Control
            formatSegmentedControl.topAnchor.constraint(equalTo: formatLabel.bottomAnchor, constant: 12),
            formatSegmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            formatSegmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            formatSegmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            // Quality Label
            qualityLabel.topAnchor.constraint(equalTo: formatSegmentedControl.bottomAnchor, constant: 24),
            qualityLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            // Quality Segmented Control
            qualitySegmentedControl.topAnchor.constraint(equalTo: qualityLabel.bottomAnchor, constant: 12),
            qualitySegmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            qualitySegmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            qualitySegmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            // Size Info Label
            sizeInfoLabel.topAnchor.constraint(equalTo: qualitySegmentedControl.bottomAnchor, constant: 8),
            sizeInfoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            sizeInfoLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Export Button
            exportButton.topAnchor.constraint(equalTo: sizeInfoLabel.bottomAnchor, constant: 28),
            exportButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            exportButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            exportButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Cancel Button
            cancelButton.topAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: 12),
            cancelButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    
    @objc private func formatChanged(_ sender: UISegmentedControl) {
        selectedFormat = ExportFormat.allCases[sender.selectedSegmentIndex]
        updateSizeInfo()
    }
    
    @objc private func qualityChanged(_ sender: UISegmentedControl) {
        selectedQuality = ExportQuality.allCases[sender.selectedSegmentIndex]
        updateSizeInfo()
    }
    
    @objc private func exportTapped() {
        let configuration = ExportConfiguration(format: selectedFormat, quality: selectedQuality)
        dismiss(animated: true) { [weak self] in
            self?.onExportSelected?(configuration)
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !containerView.frame.contains(location) {
            dismiss(animated: true)
        }
    }
    
    // MARK: - Helpers
    
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

// MARK: - UIGestureRecognizerDelegate

extension ExportOptionsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == view
    }
}
