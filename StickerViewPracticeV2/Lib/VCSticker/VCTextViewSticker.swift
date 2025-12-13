//
//  VCTextViewSticker.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 11/12/2025.
//

import UIKit

public class VCTextViewSticker: VCBaseSticker {

    // MARK: - Public Styling Properties
    // ----------------------------------------------------------

    @objc public var stickerTextColor: UIColor = .black {
        didSet { applyTextAttributes() }
    }

    @objc public var stickerOpacity: CGFloat = 1.0 {
        didSet { self.alpha = min(max(stickerOpacity, 0), 1) }
    }

    @objc public var stickerFontName: String = UIFont.systemFont(ofSize: 24).fontName {
        didSet { applyTextAttributes() }
    }

    @objc public var stickerIsBold: Bool = false {
        didSet { applyTextAttributes() }
    }

    @objc public var stickerIsItalic: Bool = false {
        didSet { applyTextAttributes() }
    }

    @objc public var stickerAlignment: NSTextAlignment = .center {
        didSet { applyTextAttributes() }
    }

    @objc public var lineSpacing: CGFloat = 0 {
        didSet { applyTextAttributes() }
    }

    @objc public var letterSpacing: CGFloat = 0 {
        didSet { applyTextAttributes() }
    }

    // SHADOW PROPERTIES
    @objc public var stickerShadowColor: UIColor = .black {
        didSet { applyShadow() }
    }

    @objc public var stickerShadowOffset: CGSize = CGSize(width: 0, height: 5) {
        didSet { applyShadow() }
    }

    @objc public var stickerShadowOpacity: Float = 1.0 {
        didSet { applyShadow() }
    }

    @objc public var stickerShadowRadius: CGFloat = 4 {
        didSet { applyShadow() }
    }

    // Required for backward compatibility
    @objc public var shadowEnable: Bool = false {
        didSet {
            stickerShadowOpacity = shadowEnable ? 1 : 0
            applyShadow()
        }
    }

    // MARK: - Original Properties
    // ----------------------------------------------------------

    @objc public var text: String? {
        didSet {
            guard let newText = text, !newText.isEmpty else { return }
            // Only establish initial layout once. After that, keep current size and reflow text.
            if !isLayoutEstablished {
                setupInitialLayout()
            } else {
                updateTextDisplay()
            }
        }
    }

    private var referenceFontSize: CGFloat = 24
    private var referenceBounds: CGSize = .zero
    private var isLayoutEstablished: Bool = false

    // MARK: - UI Component
    // ----------------------------------------------------------

    public lazy var textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = false
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        tv.textContainer.lineFragmentPadding = 0
        tv.textAlignment = .center
        tv.font = UIFont.systemFont(ofSize: referenceFontSize)
        return tv
    }()

    // MARK: - Initialization
    // ----------------------------------------------------------

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

    override open func customInit() {
        super.customInit()
        contentView.addSubview(textView)
        textView.edgesToSuperview(0)

        if let text = self.text, !text.isEmpty {
            setupInitialLayout()
        }

        applyShadow()
    }

    // MARK: - FONT BUILDER
    // ----------------------------------------------------------

    private func buildFont(pointSize: CGFloat) -> UIFont {
        var font = UIFont(name: stickerFontName, size: pointSize)
            ?? UIFont.systemFont(ofSize: pointSize)

        var traits: UIFontDescriptor.SymbolicTraits = []

        if stickerIsBold { traits.insert(.traitBold) }
        if stickerIsItalic { traits.insert(.traitItalic) }

        if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
            font = UIFont(descriptor: descriptor, size: pointSize)
        }

        return font
    }

    // MARK: - TEXT ATTRIBUTES
    // ----------------------------------------------------------

    private func applyTextAttributes() {
        guard let text = self.text else { return }

        let currentFontSize = textView.font?.pointSize ?? referenceFontSize
        let font = buildFont(pointSize: currentFontSize)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = stickerAlignment
        paragraph.lineSpacing = lineSpacing

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: stickerTextColor,
            .paragraphStyle: paragraph,
            .kern: letterSpacing
        ]

        textView.attributedText = NSAttributedString(string: text, attributes: attributes)
    }

    // MARK: - SHADOW HANDLING
    // ----------------------------------------------------------

    private func applyShadow() {

        if shadowEnable == false {
            textView.layer.shadowOpacity = 0   // fully disable shadow
            return
        }

        // Apply actual shadow settings
        textView.layer.shadowColor = stickerShadowColor.cgColor
        textView.layer.shadowOffset = stickerShadowOffset
        textView.layer.shadowOpacity = stickerShadowOpacity
        textView.layer.shadowRadius = stickerShadowRadius
    }


    // MARK: - CORE LAYOUT (Your Existing Logic)
    // ----------------------------------------------------------

    private func setupInitialLayout() {
        // Guard against re-entry: only compute reference once
        if isLayoutEstablished {
            updateTextDisplay()
            return
        }
        guard let text = self.text else { return }

        let font = buildFont(pointSize: referenceFontSize)

        let textSize = calculateTextSize(text: text, font: font, maxWidth: CGFloat.greatestFiniteMagnitude)

        let idealWidth = textSize.width + 2 * padding + 16
        let idealHeight = textSize.height + 2 * padding + 16

        self.bounds.size = CGSize(
            width: max(min(idealWidth, 400), kMinFrameWidth),
            height: max(idealHeight, kMinFrameHeight)
        )

        // Capture the initial bounds to use as the scaling reference going forward
        referenceBounds = self.bounds.size
        isLayoutEstablished = true
        updateTextDisplay()
    }

    private func updateTextDisplay() {
        guard let text = self.text else { return }
        guard referenceBounds.width > 0 && referenceBounds.height > 0 else {
            // If somehow not established, fall back to initial layout
            setupInitialLayout()
            return
        }

        let widthScale = bounds.width / referenceBounds.width
        let heightScale = bounds.height / referenceBounds.height
        let scaleFactor = min(widthScale, heightScale)

        var fontSize = referenceFontSize * scaleFactor
        fontSize = max(10, min(fontSize, 200))

        let font = buildFont(pointSize: fontSize)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = stickerAlignment

        let attributes: [NSAttributedString.Key : Any] = [
            .font: font,
            .foregroundColor: stickerTextColor,
            .paragraphStyle: paragraph,
            .kern: letterSpacing
        ]

        textView.attributedText = NSAttributedString(string: text, attributes: attributes)

        fitTextToBounds(font: font)

        applyShadow()
    }

    private func fitTextToBounds(font: UIFont) {
        guard let text = text else { return }

        let maxWidth = bounds.width - 2 * padding - 8
        let maxHeight = bounds.height - 2 * padding - 8

        var currentFont = font
        var size = measure(text: text, font: currentFont, width: maxWidth)

        while size.height > maxHeight && currentFont.pointSize > 10 {
            currentFont = buildFont(pointSize: currentFont.pointSize - 1)
            size = measure(text: text, font: currentFont, width: maxWidth)
        }

        textView.font = currentFont
        applyTextAttributes()
    }

    private func measure(text: String, font: UIFont, width: CGFloat) -> CGSize {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = stickerAlignment

        let attr: [NSAttributedString.Key : Any] = [
            .font: font,
            .paragraphStyle: paragraph,
            .kern: letterSpacing
        ]

        return (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attr,
            context: nil
        ).size
    }

    private func calculateTextSize(text: String, font: UIFont, maxWidth: CGFloat) -> CGSize {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = stickerAlignment

        return (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font, .paragraphStyle: paragraphStyle],
            context: nil
        ).size
    }

    private func calculateMinimumBounds() -> CGSize {
        guard let text = self.text else {
            return CGSize(width: kMinFrameWidth, height: kMinFrameHeight)
        }

        let minFont = buildFont(pointSize: 10)
        let minSize = measure(text: text, font: minFont, width: CGFloat.greatestFiniteMagnitude)

        return CGSize(
            width: max(minSize.width + padding * 2 + 16, kMinFrameWidth),
            height: max(minSize.height + padding * 2 + 16, kMinFrameHeight)
        )
    }
}

// MARK: - Gesture Overrides
// ----------------------------------------------------------

extension VCTextViewSticker {

    override func handleResize(gesture: UIPanGestureRecognizer) {

        if gesture.state == .began && !isLayoutEstablished {
            setupInitialLayout()
        }

        super.handleResize(gesture: gesture)

        let minBounds = calculateMinimumBounds()

        if bounds.width < minBounds.width || bounds.height < minBounds.height {
            bounds.size = CGSize(
                width: max(bounds.width, minBounds.width),
                height: max(bounds.height, minBounds.height)
            )
        }

        if gesture.state == .changed || gesture.state == .ended {
            updateTextDisplay()
        }
    }
}
