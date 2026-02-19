//
//  TFSecondaryButton.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public final class TFSecondaryButton: UIButton {
    public init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(TFColor.Brand.accentSky, for: .normal)
        titleLabel?.font = TFTypography.headline
        layer.cornerRadius = TFRadius.md
        layer.borderWidth = 1
        layer.borderColor = TFColor.Brand.accentSky.withAlphaComponent(0.35).cgColor
        backgroundColor = TFColor.Brand.accentSky.withAlphaComponent(0.1)

        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 52).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.5
        }
    }
}
