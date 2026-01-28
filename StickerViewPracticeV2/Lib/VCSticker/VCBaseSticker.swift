//
//  VCBaseSticker.swift
//  VCCapture
//
//  Created by Vincent on 2019/11/13.
//  Copyright © 2019 Vincent. All rights reserved.
//
//  updated by haroon on 10/12/2025.
//

import UIKit
import AVFoundation

enum VCBorderStyle {
    case dotted
    case solid
    case none
}

let kMinFrameWidth: CGFloat  = 35
let kMinFrameHeight: CGFloat = 35

open class VCBaseSticker: UIView {
    @objc public var onBeginEditing: (() -> Void)?
    @objc public var onFinishEditing: (() -> Void)?
    @objc public var onClose: (() -> Void)?
    
    // Transform tracking for undo/redo
    public var onTransformBegan: ((CGAffineTransform, CGPoint) -> Void)?
    public var onTransformEnded: ((CGAffineTransform, CGPoint) -> Void)?
    
    var closeImage  = VCAsserts.closeImage
    // Reuse resizeImage for both rotate and resize icons for now.
    var resizeImage = VCAsserts.resizeImage
    
    @objc public var borderColor = UIColor.cyan {                // 外边框颜色
        didSet {
            border.strokeColor  = borderColor.cgColor
            closeBtn.tintColor  = borderColor.highlightColor()
            rotateBtn.tintColor = borderColor.highlightColor()
            resizeBtnTopRight.tintColor = borderColor.highlightColor()
            closeBtn.backgroundColor  = borderColor
            rotateBtn.backgroundColor = borderColor
            resizeBtnTopRight.backgroundColor = borderColor
        }
    }
    var borderStyle = VCBorderStyle.solid           // 外边框样式
    var padding: CGFloat = 8                        // 内边距
    
    @objc public var closeBtnEnable: Bool  = true                // 是否显示关闭按钮
    // Bottom-right rotate-only button enable
    @objc public var rotateBtnEnable: Bool = true
    // Top-right resize-only button enable
    @objc public var resizeTopRightBtnEnable: Bool = true
    @objc public var restrictionEnable: Bool = false             // 是否开启边缘限制
    
    
    public var initState = -1
    public var isEditing: Bool = false
    public var isLocked: Bool = false
    
    /// 记录缩放/旋转的开始时的状态
    private var lastAngle: CGFloat!
    private var lastDistance: CGFloat!
    
    // For undo/redo: capture state at gesture start
    private var transformAtGestureStart: CGAffineTransform?
    private var centerAtGestureStart: CGPoint?
    
    private lazy var border: CAShapeLayer = {       // 外边框
        let layer = CAShapeLayer()
        
        layer.fillColor = nil                       // 禁用填充颜色
        
        switch self.borderStyle {
        case .none:
            layer.strokeColor = nil
        case .dotted:
            layer.lineDashPattern = [4, 3]          // 使用虚线边框
            fallthrough
        case .solid:
            fallthrough
        default:
            layer.strokeColor = borderColor.cgColor // 边框颜色
        }
        
        return layer
    }()
    
    private lazy var closeBtn: UIImageView = {             // 关闭按钮（左上）
        let button = self.getItemImageView(self.closeImage)
        return button
    }()
    
    // Bottom-right rotate-only control
    private lazy var rotateBtn: UIImageView = {
        let button = self.getItemImageView(self.resizeImage)
        return button
    }()
    
    // Top-right resize-only control
    private lazy var resizeBtnTopRight: UIImageView = {
        let button = self.getItemImageView(UIImage(systemName: "square.resize")!)
        return button
    }()
    
    lazy public var contentView = UIView()
    lazy public var borderView = UIView() // Hosts the border layer separate from content
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if initState == -1 {
            initState = 0
            removeAutoLayout()
        } else if initState == 0 {
            initState = 1
            customInit()
        }
        
        border.path  = UIBezierPath(rect: borderView.bounds).cgPath
        border.frame = borderView.bounds
        
        // Apply inverse scale to control buttons so they remain a constant visual size
        let currentScale = sqrt(transform.a * transform.a + transform.c * transform.c)
        if currentScale > 0.001 {
            let inverseScale = 1.0 / currentScale
            let inverseTransform = CGAffineTransform(scaleX: inverseScale, y: inverseScale)
            closeBtn.transform = inverseTransform
            rotateBtn.transform = inverseTransform
            resizeBtnTopRight.transform = inverseTransform
            
            // Also scale the border line width inversely
            border.lineWidth = 1.0 * inverseScale
        }
    }
    
    // 删除外部设置的无用约束(约束会影响当前代码中设置bound和frame的效果)
    private func removeAutoLayout() {
        // 遍历自身约束
        for con in self.constraints {
            self.removeConstraint(con)
        }
        
        // 遍历父视图约束
        if let superConstraints = self.superview?.constraints {
            for con in superConstraints {
                if con.firstItem?.isEqual(self) ?? false {
                    self.superview?.removeConstraint(con)
                }
            }
        }
        
        // 使用frame布局
        self.translatesAutoresizingMaskIntoConstraints = true
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    /// 自定义初始化，为了兼容外部设置约束的情况，将初始化放在layoutSubviews中调用
    open func customInit() {
        frame.size.width = max(frame.width, kMinFrameWidth)
        frame.size.height = max(frame.height, kMinFrameHeight)
        
        setupSubViews()
        setupGestures()
        
        self.beginEditing()
    }
    
    /// 初始化subview，用VFL添加约束
    private func setupSubViews() {
        
        self.addSubview(contentView)
        self.contentView.edgesToSuperview(self.padding)
        
        // Add borderView above contentView but with same constraints
        self.addSubview(borderView)
        self.borderView.isUserInteractionEnabled = false // Pass touches through
        self.borderView.edgesToSuperview(self.padding)
        
        if closeBtnEnable {
            self.addSubview(closeBtn)
            self.closeBtn.topLeftToSuperview(0, size: self.padding*2)
        }
        
        if rotateBtnEnable {
            self.addSubview(rotateBtn)
            self.rotateBtn.bottomRightToSuperview(0, size: self.padding*2)
        }
        
        if resizeTopRightBtnEnable {
            self.addSubview(resizeBtnTopRight)
            // Place at top-right
            self.resizeBtnTopRight.topRightToSuperview(0, size: self.padding*2)
        }
    }
    
    /// 初始化自定义手势
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(gesture:)))
        self.addGestureRecognizer(panGesture)
        
        // Rotate-only on bottom-right
        let rotateGesture = UIPanGestureRecognizer(target: self, action: #selector(handleRotate(gesture:)))
        self.rotateBtn.addGestureRecognizer(rotateGesture)
        
        // Scale-only on top-right
        let scaleGesture = UIPanGestureRecognizer(target: self, action: #selector(handleResize(gesture:)))
        self.resizeBtnTopRight.addGestureRecognizer(scaleGesture)
        
        let bodyTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapBody))
        self.addGestureRecognizer(bodyTapGesture)
        
        let closeTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapClose))
        self.closeBtn.addGestureRecognizer(closeTapGesture)
    }
    
    /// 获取图标按钮视图
    private func getItemImageView(_ image: UIImage) -> UIImageView {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.padding*2, height: self.padding*2))
        
        imageView.image = image
        imageView.tintColor = .black
        imageView.backgroundColor = self.borderColor
        imageView.layer.cornerRadius = self.padding
        imageView.isUserInteractionEnabled = true
        
        return imageView
    }
    
    /// 开始编辑，显示控制组件
    @objc open func beginEditing() {
        isEditing = true
        
        closeBtn.isHidden  = !closeBtnEnable
        rotateBtn.isHidden = !rotateBtnEnable
        resizeBtnTopRight.isHidden = !resizeTopRightBtnEnable
        
        // Add border to borderView instead of contentView
        borderView.layer.addSublayer(border)
        onBeginEditing?()
    }
    
    /// 结束编辑，隐藏控制组件
    @objc open func finishEditing() {
        isEditing = false
        
        closeBtn.isHidden  = true
        rotateBtn.isHidden = true
        resizeBtnTopRight.isHidden = true
        border.removeFromSuperlayer()
        onFinishEditing?()
    }
    
    // MARK: - Preview Snapshot
    
    /// Renders contentView content for layer preview.
    /// Excludes controls (siblings) and border (now in borderView).
    /// Does NOT modify sticker state to avoid visual jitter on canvas.
    public func cleanPreviewSnapshot(size: CGSize = CGSize(width: 80, height: 80)) -> UIImage {
        let contentBounds = contentView.bounds
        guard contentBounds.width > 0 && contentBounds.height > 0 else {
            return UIImage()
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        
        // Render contentView.layer directly (excludes sibling controls AND borderView)
        let renderer = UIGraphicsImageRenderer(size: contentBounds.size, format: format)
        let contentImage = renderer.image { context in
            contentView.layer.render(in: context.cgContext)
        }
        
        guard contentImage.size.width > 0 && contentImage.size.height > 0 else {
            return UIImage()
        }
        
        // Scale to fit within target size
        let targetRect = AVMakeRect(aspectRatio: contentImage.size, insideRect: CGRect(origin: .zero, size: size))
        
        let finalRenderer = UIGraphicsImageRenderer(size: size, format: format)
        return finalRenderer.image { context in
            contentImage.draw(in: targetRect)
        }
    }
    // MARK: - Animations
    
    public func performEntranceAnimation(delay: TimeInterval) {
        let finalTransform = self.transform
        
        // Initial state: small and transparent
        self.transform = finalTransform.scaledBy(x: 0.01, y: 0.01)
        self.alpha = 0
        
        UIView.animate(
            withDuration: 0.6,
            delay: delay,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: {
                self.transform = finalTransform
                self.alpha = 1
            },
            completion: nil
        )
    }
}

// 手势动作
extension VCBaseSticker {
    
    /// 拖动手势
    @objc func handlePanGesture(gesture: UIPanGestureRecognizer) {
        // Prevent manipulation when locked
        if isLocked { return }
        
        if !isEditing {
            beginEditing()
        }
        
        // Capture initial state for undo
        if gesture.state == .began {
            transformAtGestureStart = self.transform
            centerAtGestureStart = self.center
            onTransformBegan?(self.transform, self.center)
        }
        
        // 1.获取手势在视图上的平移增量
        let translation = gesture.translation(in: gesture.view!.superview)
        // 2.设置中心点
        let center = gesture.view!.center
        let newCenter = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        // 判断是否超出边缘
        if restrictionEnable {
            if (newCenter.x + self.frame.width*0.5 <= self.superview!.frame.width)
                && (newCenter.x - self.frame.width*0.5 >= 0) {
                gesture.view!.center.x = newCenter.x
            }
            
            if (newCenter.y + self.frame.height*0.5 <= self.superview!.frame.height)
                && (newCenter.y - self.frame.height*0.5 >= 0) {
                gesture.view!.center.y = newCenter.y
            }
        } else {
            gesture.view!.center = newCenter
        }
        
        // 3.将上一次的平移增量置为0
        gesture.setTranslation(CGPoint(x: 0.0, y: 0.0), in: gesture.view)
        
        // Fire callback at gesture end for undo registration
        if gesture.state == .ended || gesture.state == .cancelled {
            if let oldTransform = transformAtGestureStart,
               let oldCenter = centerAtGestureStart {
                onTransformEnded?(oldTransform, oldCenter)
            }
            transformAtGestureStart = nil
            centerAtGestureStart = nil
        }
    }
    
    /// 旋转控制（底部右侧按钮）
    @objc func handleRotate(gesture: UIPanGestureRecognizer) {
        // Prevent manipulation when locked
        if isLocked { return }
        
        // 以当前父页面为计算参考
        let location = gesture.location(in: self.superview)
        let center = self.center
        
        let angle = atan2(location.y - center.y, location.x - center.x)
        
        if gesture.state == .began {
            self.lastAngle = angle
            transformAtGestureStart = self.transform
            centerAtGestureStart = self.center
            onTransformBegan?(self.transform, self.center)
        } else if gesture.state == .changed {
            // 旋转
            let delta = angle - self.lastAngle
            self.transform = self.transform.rotated(by: delta)
            self.lastAngle = angle
            
            // Trigger layout update to recalculate inverse scale for buttons
            setNeedsLayout()
        } else if gesture.state == .ended || gesture.state == .cancelled {
            if let oldTransform = transformAtGestureStart,
               let oldCenter = centerAtGestureStart {
                onTransformEnded?(oldTransform, oldCenter)
            }
            transformAtGestureStart = nil
            centerAtGestureStart = nil
        }
    }
    
    /// 缩放控制（右上角按钮）- 保留原方法名以兼容子类覆盖
    @objc func handleResize(gesture: UIPanGestureRecognizer) {
        // Prevent manipulation when locked
        if isLocked { return }
        
        // 以当前父页面为计算参考
        let location = gesture.location(in: self.superview)
        let center = self.center
        
        let distance = VCStickerUtils.getDistance(point1: location, point2: center)
        
        if gesture.state == .began {
            self.lastDistance = distance
            transformAtGestureStart = self.transform
            centerAtGestureStart = self.center
            onTransformBegan?(self.transform, self.center)
        } else if gesture.state == .changed {
            // Calculate scale factor relative to last distance
            let scaleFactor = distance / self.lastDistance
            
            // Apply scale to transform (works with existing transforms)
            self.transform = self.transform.scaledBy(x: scaleFactor, y: scaleFactor)
            self.lastDistance = distance
            
            // Trigger layout update to recalculate inverse scale for buttons
            setNeedsLayout()
        } else if gesture.state == .ended || gesture.state == .cancelled {
            if let oldTransform = transformAtGestureStart,
               let oldCenter = centerAtGestureStart {
                onTransformEnded?(oldTransform, oldCenter)
            }
            transformAtGestureStart = nil
            centerAtGestureStart = nil
        }
    }
    
    /// 点击关闭
    @objc func handleTapClose() {
        self.onClose?()
        // NOTE: removeFromSuperview is now handled by the onClose callback
        // This allows undo manager to control the sticker lifecycle
        // If no onClose is set, we still remove from superview for safety
        if self.onClose == nil {
            self.removeFromSuperview()
        }
    }
    
    /// 点击当前控件整体（显示/隐藏）
    @objc func handleTapBody() {
        isEditing ? finishEditing() : beginEditing()
    }
    
}
