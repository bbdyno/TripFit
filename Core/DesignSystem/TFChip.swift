//
//  TFChip.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public final class TFChip: UIButton {
    public enum Style {
        case accent
        case neutralFilter
        case darkFilter
    }

    public var isChipSelected: Bool = false {
        didSet { updateAppearance() }
    }

    private var accentColor: UIColor = TFColor.Brand.primary
    private var style: Style = .accent

    public init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = TFTypography.caption.withSize(14)
        layer.cornerRadius = 18
        layer.borderWidth = 1
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18)
            configuration = config
        } else {
            contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
        }
        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func setAccentColor(_ color: UIColor) {
        accentColor = color
        updateAppearance()
    }

    public func setStyle(_ style: Style) {
        self.style = style
        updateAppearance()
    }

    private func updateAppearance() {
        switch style {
        case .accent:
            if isChipSelected {
                backgroundColor = accentColor
                setTitleColor(.white, for: .normal)
                layer.borderColor = accentColor.cgColor
            } else {
                backgroundColor = accentColor.withAlphaComponent(0.12)
                setTitleColor(accentColor, for: .normal)
                layer.borderColor = accentColor.withAlphaComponent(0.35).cgColor
            }
        case .neutralFilter:
            if isChipSelected {
                backgroundColor = TFColor.Brand.primary
                setTitleColor(.white, for: .normal)
                layer.borderColor = TFColor.Brand.primary.cgColor
            } else {
                backgroundColor = TFColor.Surface.card
                setTitleColor(TFColor.Text.secondary, for: .normal)
                layer.borderColor = TFColor.Border.subtle.cgColor
            }
        case .darkFilter:
            let activeColor = UIColor.dynamic(
                light: UIColor(hex: 0x0F172A),
                dark: UIColor(hex: 0xF5EAF0)
            )
            if isChipSelected {
                backgroundColor = activeColor
                setTitleColor(
                    UIColor.dynamic(light: .white, dark: UIColor(hex: 0x230F18)),
                    for: .normal
                )
                layer.borderColor = activeColor.cgColor
            } else {
                backgroundColor = TFColor.Surface.card
                setTitleColor(TFColor.Text.secondary, for: .normal)
                layer.borderColor = TFColor.Border.subtle.cgColor
            }
        }
    }
}
