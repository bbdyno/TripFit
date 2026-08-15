//
//  TFCardView.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public final class TFCardView: UIView {
    public enum Style {
        case elevated
        case flat
        case outlined
    }

    public init(showShadow: Bool = true) {
        let style: Style = showShadow ? .elevated : .flat
        self.style = style
        super.init(frame: .zero)
        apply(style: style)
    }

    public init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        apply(style: style)
    }

    private var style: Style

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func apply(style: Style) {
        self.style = style
        backgroundColor = TFColor.Surface.card
        layer.cornerRadius = TFRadius.lg
        layer.cornerCurve = .continuous
        clipsToBounds = false
        layer.borderColor = TFColor.Border.subtle.cgColor
        layer.borderWidth = 1 / UIScreen.main.scale
        layer.shadowColor = UIColor.clear.cgColor
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.shadowOffset = .zero

        switch style {
        case .elevated:
            backgroundColor = TFColor.Surface.elevated
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0 : 0.035
            layer.shadowRadius = 8
            layer.shadowOffset = CGSize(width: 0, height: 3)
        case .flat:
            break
        case .outlined:
            layer.borderWidth = 1
            layer.borderColor = TFColor.Border.strong.cgColor
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true else { return }
        apply(style: style)
    }
}
