//
//  TFProgressRingView.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public final class TFProgressRingView: UIView {
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let valueLabel = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        setupLabel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let lineWidth: CGFloat = 4
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let start = -CGFloat.pi / 2
        let end = start + (2 * .pi)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: start, endAngle: end, clockwise: true)
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }

    public func setProgress(current: Int, total: Int) {
        let progress: CGFloat
        if total <= 0 {
            progress = 0
        } else {
            progress = min(max(CGFloat(current) / CGFloat(total), 0), 1)
        }

        progressLayer.strokeEnd = progress
        valueLabel.text = "\(Int(progress * 100))%"
    }

    private func setupLayers() {
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = TFColor.Brand.accentPurple.withAlphaComponent(0.2).cgColor
        trackLayer.lineWidth = 4

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = TFColor.Brand.accentPurple.cgColor
        progressLayer.lineWidth = 4
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0

        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
    }

    private func setupLabel() {
        valueLabel.font = TFTypography.footnote
        valueLabel.textColor = TFColor.Text.primary
        valueLabel.textAlignment = .center
        addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            valueLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
