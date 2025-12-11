//
//  VCTextViewSticker.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 11/12/2025.
//

import UIKit

public class VCTextViewSticker: VCBaseSticker {
    
    // MARK: - Public Properties
    
    @objc public var shadowEnable: Bool = false {
        didSet {
            self.textView.layer.shadowColor = shadowColor
        }
    }
    
    @objc public var textColor = UIColor.black {
        didSet {
            updateTextDisplay()
        }
    }
    
    @objc public var text: String? {
        didSet {
            guard let newText = text, !newText.isEmpty else { return }
            setupInitialLayout()
        }
    }
    
    @objc private var shadowColor: CGColor {
        return self.shadowEnable ? UIColor.black.cgColor : UIColor.clear.cgColor
    }
    
    // MARK: - Private Properties
    
    /// The reference font size when text is first set
    private var referenceFontSize: CGFloat = 24
    
    /// The reference bounds when text layout is established
    private var referenceBounds: CGSize = .zero
    
    /// Flag to track if initial layout has been established
    private var isLayoutEstablished: Bool = false
    
    // MARK: - UI Components
    
    public lazy var textView: UITextView = {
        let textView = UITextView()
        
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        
        textView.tintColor = self.textColor
        textView.textColor = self.textColor
        textView.textAlignment = .center
        textView.font = UIFont.systemFont(ofSize: 24)
        
        // Shadow configuration
        textView.layer.shadowColor = shadowColor
        textView.layer.shadowOffset = CGSize(width: 0, height: 5)
        textView.layer.shadowOpacity = 1.0
        textView.layer.shadowRadius = 4.0
        
        return textView
    }()
    
    // MARK: - Initialization
    
    @objc public init(center: CGPoint, text: String = "") {
        let frame = CGRect(
            x: center.x - kMinFrameWidth / 2,
            y: center.y - kMinFrameWidth / 2,
            width: kMinFrameWidth,
            height: kMinFrameWidth
        )
        super.init(frame: frame)
        self.text = text
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    @objc override open func customInit() {
        super.customInit()
        self.contentView.addSubview(textView)
        textView.edgesToSuperview(0)
        
        if let text = self.text, !text.isEmpty {
            setupInitialLayout()
        }
    }
    
    @objc override public func finishEditing() {
        super.finishEditing()
    }
    
    // MARK: - Core Layout System
    
    /// Establishes the initial text layout and reference dimensions
    private func setupInitialLayout() {
        guard let text = self.text, !text.isEmpty else { return }
        
        let font = UIFont.systemFont(ofSize: referenceFontSize)
        
        // Calculate natural text dimensions without wrapping constraints
        let textSize = calculateTextSize(text: text, font: font, maxWidth: CGFloat.greatestFiniteMagnitude)
        
        // Set initial bounds based on natural text size
        let idealWidth = textSize.width + 2 * self.padding + 16
        let idealHeight = textSize.height + 2 * self.padding + 16
        
        let width = max(min(idealWidth, 400), kMinFrameWidth)
        let height = max(idealHeight, kMinFrameHeight)
        
        self.bounds.size = CGSize(width: width, height: height)
        
        // Store reference dimensions
        referenceBounds = self.bounds.size
        isLayoutEstablished = true
        
        // Apply initial text styling
        updateTextDisplay()
    }
    
    /// Updates the text display with proper scaling based on current bounds
    private func updateTextDisplay() {
        guard let text = self.text, !text.isEmpty else { return }
        
        // Compute scale factor based purely on sticker resize
        let widthScale = self.bounds.width / referenceBounds.width
        let heightScale = self.bounds.height / referenceBounds.height
        let scaleFactor = min(widthScale, heightScale)
        
        // Apply scaled font size
        var fontSize = referenceFontSize * scaleFactor
        fontSize = max(14, min(fontSize, 200))   // Safe limits
        
        let font = UIFont.systemFont(ofSize: fontSize)
        
        // Prepare paragraph style
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        
        // Apply attributed string
        let attributes: [NSAttributedString.Key : Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraph
        ]
        
        textView.attributedText = NSAttributedString(string: text, attributes: attributes)
        
        // Prevent overflow – shrink font until text fits
        fitTextToBounds(font: font)
    }

    private func fitTextToBounds(font: UIFont) {
        guard let text = text else { return }

        let maxWidth = bounds.width - 2 * padding - 8
        let maxHeight = bounds.height - 2 * padding - 8

        var currentFont = font
        var size = measure(text: text, font: currentFont, width: maxWidth)

        while size.height > maxHeight && currentFont.pointSize > 10 {
            currentFont = UIFont.systemFont(ofSize: currentFont.pointSize - 1)
            size = measure(text: text, font: currentFont, width: maxWidth)
        }

        textView.font = currentFont
    }

    
    private func measure(text: String, font: UIFont, width: CGFloat) -> CGSize {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attr: [NSAttributedString.Key : Any] = [
            .font: font,
            .paragraphStyle: paragraph
        ]

        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attr,
            context: nil
        )
        
        return rect.size
    }
    
    /// Calculate text size for given parameters
    private func calculateTextSize(text: String, font: UIFont, maxWidth: CGFloat) -> CGSize {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 0
        paragraphStyle.lineHeightMultiple = 1.0
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        
        let size = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).size
        
        return size
    }
    
    /// Calculate true minimum bounds required to keep text readable at minimum font size.
    private func calculateMinimumBounds() -> CGSize {
        guard let text = self.text, !text.isEmpty else {
            return CGSize(width: kMinFrameWidth, height: kMinFrameHeight)
        }

        let minimumFontSize: CGFloat = 10     // You may adjust
        let font = UIFont.systemFont(ofSize: minimumFontSize)

        // Measure text using minimum readable font size
        let minTextSize = measure(text: text, font: font, width: CGFloat.greatestFiniteMagnitude)

        let requiredWidth = minTextSize.width + (padding * 2) + 16
        let requiredHeight = minTextSize.height + (padding * 2) + 16

        return CGSize(
            width: max(requiredWidth, kMinFrameWidth),
            height: max(requiredHeight, kMinFrameHeight)
        )
    }

}

// MARK: - Gesture Overrides

extension VCTextViewSticker {
    
    override func handlePanGesture(gesture: UIPanGestureRecognizer) {
        super.handlePanGesture(gesture: gesture)
    }
    
    override func handleResize(gesture: UIPanGestureRecognizer) {

        if gesture.state == .began && !isLayoutEstablished {
            setupInitialLayout()
        }

        // Perform normal resize first
        super.handleResize(gesture: gesture)

        // Get the true minimum bounds
        let minBounds = calculateMinimumBounds()

        // Prevent sticker from shrinking below minimum text size
        if bounds.width < minBounds.width || bounds.height < minBounds.height {
            bounds.size = CGSize(
                width: max(bounds.width, minBounds.width),
                height: max(bounds.height, minBounds.height)
            )
        }

        // Update text during resize
        if gesture.state == .changed || gesture.state == .ended {
            updateTextDisplay()
        }
    }

    
    override func handleRotate(gesture: UIPanGestureRecognizer) {
        super.handleRotate(gesture: gesture)
    }
}
