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
        super.init(frame: .zero)
        apply(style: style)
    }

    public init(style: Style) {
        super.init(frame: .zero)
        apply(style: style)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func apply(style: Style) {
        backgroundColor = TFColor.Surface.card
        layer.cornerRadius = TFRadius.lg
        clipsToBounds = false
        layer.borderColor = TFColor.Border.subtle.cgColor
        layer.borderWidth = 1
        layer.shadowColor = UIColor.clear.cgColor
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.shadowOffset = .zero

        switch style {
        case .elevated:
            layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
            layer.shadowOpacity = 1
            layer.shadowRadius = 16
            layer.shadowOffset = CGSize(width: 0, height: 8)
        case .flat:
            break
        case .outlined:
            layer.borderWidth = 1.5
            layer.borderColor = TFColor.Border.strong.cgColor
        }
    }
}
