//
//  StepProgressView.swift
//  Show step-by-step progress.
//
//  Usage:
//      progress = StepProgressView(frame: someFrame)
//      progress.steps = ["First", "Second", "Third", "Last"]
//      progress.currentStep = 0
//      ... when all done:
//      progress.currentStep = 4
//
//  Created by Yonat Sharon on 13/2/15.
//  Copyright (c) 2016 Yonat Sharon. All rights reserved.
//

import SweeterSwift
import UIKit

@IBDesignable
open class StepProgressView: UIView {
    // MARK: - Behavior
    open var steps: [String] = [] { didSet { needsSetup = true } }
    open var details: [Int: String] = [:] { didSet { needsSetup = true } }
    open var currentStep: Int = -1 {
        didSet {
            needsColor = true
            accessibilityValue = steps.indices.contains(currentStep) ? steps[currentStep] : nil
        }
    }

    // MARK: - Appearance
    @objc(StepProgressViewShape)
    public enum Shape: Int {
        case circle, square, triangle, downTriangle, rhombus
    }

    @objc open dynamic var stepShape: Shape = .circle { didSet { needsSetup = true } }
    @objc open dynamic var firstStepShape: Shape = .circle { didSet { needsSetup = true } }
    @objc open dynamic var lastStepShape: Shape = .square { didSet { needsSetup = true } }
    
    @IBInspectable open dynamic var lineWidth: CGFloat = 1 { didSet { needsSetup = true } }
    @objc open dynamic var textFont = UIFont.systemFont(ofSize: UIFont.buttonFontSize) { didSet { needsSetup = true } }
    @objc open dynamic var detailFont = UIFont.systemFont(ofSize: UIFont.systemFontSize) { didSet { needsSetup = true } }

    @IBInspectable open dynamic var verticalPadding: CGFloat = 0 { didSet { needsSetup = true } }
    @IBInspectable open dynamic var horizontalPadding: CGFloat = 0 { didSet { needsSetup = true } }

    // MARK: - New Appearance
    @IBInspectable open dynamic var shapeScale: CGFloat = 1.0 { didSet { needsSetup = true } }
    @IBInspectable open dynamic var showStepNumbers: Bool = false { didSet { needsSetup = true } }
    @objc open dynamic var numberFont = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize) { didSet { needsSetup = true } }

    // MARK: - Colors
    @IBInspectable open dynamic var futureStepColor: UIColor = .lightGray { didSet { needsColor = true } }
    @IBInspectable open dynamic var pastStepColor: UIColor = .lightGray { didSet { needsColor = true } }
    @IBInspectable open dynamic var currentStepColor: UIColor? { didSet { needsColor = true } }
    @IBInspectable open dynamic var currentDetailColor: UIColor? = .darkGray { didSet { needsColor = true } }

    @IBInspectable open dynamic var futureStepFillColor: UIColor = .clear { didSet { needsColor = true } }
    @IBInspectable open dynamic var pastStepFillColor: UIColor = .lightGray { didSet { needsColor = true } }
    @IBInspectable open dynamic var currentStepFillColor: UIColor = .clear { didSet { needsColor = true } }

    @IBInspectable open dynamic var futureTextColor: UIColor = .lightGray { didSet { needsColor = true } }
    @IBInspectable open dynamic var pastTextColor: UIColor = .lightGray { didSet { needsColor = true } }
    @IBInspectable open dynamic var currentTextColor: UIColor? { didSet { needsColor = true } }

    // New Colors
    @IBInspectable open dynamic var futureDetailColor: UIColor = .lightGray { didSet { needsColor = true } }
    @IBInspectable open dynamic var pastDetailColor: UIColor = .lightGray { didSet { needsColor = true } }
    @IBInspectable open dynamic var pastNumberColor: UIColor = .white { didSet { needsColor = true } }
    @IBInspectable open dynamic var futureNumberColor: UIColor = .lightGray { didSet { needsColor = true } }
    @IBInspectable open dynamic var currentNumberColor: UIColor = .black { didSet { needsColor = true } }

    // MARK: - Private
    private var stepViews: [SingleStepView] = []
    private var needsSetup = false {
        didSet {
            if needsSetup && !oldValue {
                DispatchQueue.main.async { [weak self] in self?.setupStepViews() }
            }
        }
    }
    private var needsColor = false {
        didSet {
            if needsColor && !oldValue {
                DispatchQueue.main.async { [weak self] in self?.colorSteps() }
            }
        }
    }

    // MARK: - Lifecycle
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initAccessibility()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        initAccessibility()
    }

    override open func tintColorDidChange() {
        if currentStepColor == nil || currentTextColor == nil {
            needsColor = true
        }
    }

    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        steps = ["First Step", "Second Step", "This Step", "Last Step"]
        details = [0: "The beginning", 3: "the end"]
    }

    override open var intrinsicContentSize: CGSize {
        if stepViews.isEmpty { return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric) }
        let stepSizes = stepViews.map { $0.intrinsicContentSize }
        return CGSize(
            width: stepSizes.map { $0.width }.max() ?? 0,
            height: stepSizes.map { $0.height }.reduce(0, +)
        )
    }

    private func initAccessibility() {
        isAccessibilityElement = true
        accessibilityLabel = "Step Progress"
        accessibilityIdentifier = "StepProgress"
    }

    func setupStepViews() {
        needsSetup = false
        stepViews.forEach { $0.removeFromSuperview() }
        stepViews.removeAll(keepingCapacity: true)

        var shape = firstStepShape
        let shapeSize = textFont.pointSize * 1.2 * shapeScale
        if horizontalPadding.isZero { horizontalPadding = shapeSize / 2 }
        if verticalPadding.isZero { verticalPadding = shapeSize }

        var prevView: UIView = self
        var prevAttribute: NSLayoutConstraint.Attribute = .top

        for i in 0..<steps.count {
            if i == steps.count - 1 {
                shape = lastStepShape
            } else if i > 0 {
                shape = stepShape
            }

            let stepView = SingleStepView(
                index: i,
                text: steps[i],
                detail: details[i],
                font: textFont,
                detailFont: detailFont,
                numberFont: numberFont,
                shape: shape,
                shapeSize: shapeSize,
                lineWidth: lineWidth,
                hPadding: horizontalPadding,
                vPadding: verticalPadding,
                showNumber: showStepNumbers
            )
            stepViews.append(stepView)

            addConstrainedSubview(stepView, constrain: .leading, .trailing)
            constrain(stepView, at: .top, to: prevView, at: prevAttribute)
            prevView = stepView
            prevAttribute = .bottom
        }
        if let lastStepView = stepViews.last {
            lastStepView.lineView.isHidden = true
            constrain(lastStepView, at: .bottom)
        }
        colorSteps()
    }

    private func colorSteps() {
        needsColor = false
        let n = stepViews.count

        if currentStep < n - 1 {
            for i in max(0, currentStep + 1)..<n {
                stepViews[i].color(
                    text: futureTextColor,
                    detail: futureDetailColor,
                    stroke: futureStepColor,
                    fill: futureStepFillColor,
                    line: futureStepColor,
                    numberColor: futureNumberColor
                )
            }
        }

        if currentStep < n && currentStep >= 0 {
            let textColor = currentTextColor ?? tintColor
            let detailColor = currentDetailColor ?? textColor
            stepViews[currentStep].color(
                text: textColor ?? UIColor.black,
                detail: detailColor ?? UIColor.black,
                stroke: textColor ?? UIColor.black,
                fill: currentStepFillColor,
                line: futureStepColor,
                numberColor: currentNumberColor
            )
        }

        if currentStep > 0 {
            for i in 0..<min(currentStep, n) {
                stepViews[i].color(
                    text: pastTextColor,
                    detail: pastDetailColor,
                    stroke: pastStepColor,
                    fill: pastStepFillColor,
                    line: pastStepColor,
                    numberColor: pastNumberColor
                )
            }
        }
    }
}

private class SingleStepView: UIView {
    private var textLabel = UILabel()
    private var detailLabel = UILabel()
    private var shapeLayer = CAShapeLayer()
    var lineView = UIView()
    private var numberLabel: UILabel?

    private var leadingSpace: CGFloat = 0
    private var bottomSpace: CGFloat = 0

    convenience init(index: Int, text: String, detail: String?, font: UIFont, detailFont: UIFont, numberFont: UIFont, shape: StepProgressView.Shape, shapeSize: CGFloat, lineWidth: CGFloat, hPadding: CGFloat, vPadding: CGFloat, showNumber: Bool) {
        self.init()

        leadingSpace = hPadding + shapeSize + lineWidth
        bottomSpace = vPadding

        // Shape layer
        shapeLayer.frame = CGRect(origin: CGPoint(x: floor(lineWidth / 2), y: floor(lineWidth / 2)), size: CGSize(width: shapeSize, height: shapeSize))
        shapeLayer.path = UIBezierPath(shape: shape, frame: shapeLayer.bounds).cgPath
        shapeLayer.lineWidth = lineWidth
        layer.addSublayer(shapeLayer)

        // Number label inside shape
        if showNumber {
            let number = UILabel()
            number.text = "\(index + 1)"
            number.font = numberFont
            number.textAlignment = .center
            number.translatesAutoresizingMaskIntoConstraints = false
            addSubview(number)

            NSLayoutConstraint.activate([
                // Center exactly in the shape
                number.centerXAnchor.constraint(equalTo: leadingAnchor, constant: (lineWidth / 2) + (shapeSize / 2)),
                number.centerYAnchor.constraint(equalTo: topAnchor, constant: (lineWidth / 2) + (shapeSize / 2)),
                number.widthAnchor.constraint(equalToConstant: shapeSize * 0.9), // Slightly smaller than shape
                number.heightAnchor.constraint(equalToConstant: shapeSize * 0.9)
            ])
            self.numberLabel = number
        }

        // Text label
        textLabel.font = font
        textLabel.text = text
        textLabel.numberOfLines = 0
        addConstrainedSubview(textLabel, constrain: .top, .trailing)
        constrain(textLabel, at: .leading, diff: leadingSpace)

        // Detail label
        detailLabel.font = detailFont
        detailLabel.text = detail
        detailLabel.numberOfLines = 0
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(detailLabel)
        constrain(detailLabel, at: .top, to: textLabel, at: .bottom)
        constrain(detailLabel, at: .trailing, to: textLabel)
        constrain(detailLabel, at: .leading, to: textLabel)
        constrain(detailLabel, at: .bottom, diff: -vPadding)

        // Line view
        // For properly centering the line
        addConstrainedSubview(lineView, constrain: .bottom)
        // Center the line exactly with the shape's center
        constrain(lineView, at: .leading, diff: (lineWidth / 2) + (shapeSize / 2) - (lineWidth / 2))
        constrain(lineView, at: .top, diff: shapeSize + lineWidth)
        lineView.constrain(.width, to: lineWidth)    }

    func color(text: UIColor, detail: UIColor, stroke: UIColor, fill: UIColor, line: UIColor, numberColor: UIColor) {
        textLabel.textColor = text
        detailLabel.textColor = detail
        lineView.backgroundColor = line
        shapeLayer.strokeColor = stroke.cgColor
        shapeLayer.fillColor = fill.cgColor
        numberLabel?.textColor = numberColor
    }

    override var intrinsicContentSize: CGSize {
        var size = textLabel.intrinsicContentSize
        size.width += leadingSpace
        size.height += detailLabel.intrinsicContentSize.height + bottomSpace
        return size
    }
}


private extension UIBezierPath {
    convenience init(shape: StepProgressView.Shape, frame: CGRect) {
        switch shape {
        case .circle:
            self.init(ovalIn: frame)

        case .square:
            self.init(rect: frame)

        case .triangle:
            self.init()
            move(to: CGPoint(x: frame.midX, y: frame.minY))
            addLine(to: CGPoint(x: frame.maxX, y: frame.maxY))
            addLine(to: CGPoint(x: frame.minX, y: frame.maxY))
            close()

        case .downTriangle:
            self.init()
            move(to: CGPoint(x: frame.midX, y: frame.maxY))
            addLine(to: CGPoint(x: frame.maxX, y: frame.minY))
            addLine(to: CGPoint(x: frame.minX, y: frame.minY))
            close()

        case .rhombus:
            self.init()
            move(to: CGPoint(x: frame.midX, y: frame.minY))
            addLine(to: CGPoint(x: frame.maxX, y: frame.midY))
            addLine(to: CGPoint(x: frame.midX, y: frame.maxY))
            addLine(to: CGPoint(x: frame.minX, y: frame.midY))
            close()
        }
    }
}
