//
//  TFPrimaryButton.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public final class TFPrimaryButton: UIButton {
    public init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(TFColor.Text.inverse, for: .normal)
        titleLabel?.font = TFTypography.button
        layer.cornerRadius = TFRadius.md
        layer.cornerCurve = .continuous
        clipsToBounds = true
        backgroundColor = TFColor.Brand.primary

        configureHeight()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configureHeight() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 56).isActive = true
    }

    public override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.45
        }
    }

    public override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? TFColor.Brand.primaryDark : TFColor.Brand.primary
            transform = isHighlighted ? CGAffineTransform(scaleX: 0.985, y: 0.985) : .identity
        }
    }
}
