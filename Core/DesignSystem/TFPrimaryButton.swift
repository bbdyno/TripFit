//
//  TFPrimaryButton.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public final class TFPrimaryButton: UIButton {
    private let gradientLayer = CAGradientLayer()

    public init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(TFColor.Text.inverse, for: .normal)
        titleLabel?.font = TFTypography.button
        layer.cornerRadius = TFRadius.md
        clipsToBounds = true

        gradientLayer.colors = [TFColor.Brand.primary.cgColor, TFColor.Brand.primaryLight.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)

        configureHeight()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func configureHeight() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 56).isActive = true
    }

    public override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.45
        }
    }
}
