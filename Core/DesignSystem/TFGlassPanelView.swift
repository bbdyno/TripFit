//
//  TFGlassPanelView.swift
//  TripFit
//
//  Created by bbdyno on 8/10/26.
//

import UIKit

public final class TFGlassPanelView: UIView {
    public let contentView = UIView()

    private let effectView: UIVisualEffectView
    private let tintView = UIView()
    private let highlightLayer = CAGradientLayer()

    public init(
        style: UIBlurEffect.Style = .systemUltraThinMaterial,
        cornerRadius: CGFloat = TFRadius.xl,
        tintColor: UIColor = TFColor.Surface.card.withAlphaComponent(0.32)
    ) {
        effectView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        super.init(frame: .zero)

        backgroundColor = .clear
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.42).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: 12)

        effectView.isUserInteractionEnabled = false
        tintView.backgroundColor = tintColor
        tintView.isUserInteractionEnabled = false
        contentView.backgroundColor = .clear

        [effectView, tintView, contentView].forEach {
            $0.clipsToBounds = true
            $0.layer.cornerRadius = cornerRadius
            $0.layer.cornerCurve = .continuous
            addSubview($0)
        }

        highlightLayer.colors = [
            UIColor.white.withAlphaComponent(0.34).cgColor,
            UIColor.white.withAlphaComponent(0.02).cgColor,
            UIColor.clear.cgColor,
        ]
        highlightLayer.locations = [0, 0.38, 1]
        highlightLayer.startPoint = CGPoint(x: 0, y: 0)
        highlightLayer.endPoint = CGPoint(x: 1, y: 1)
        tintView.layer.addSublayer(highlightLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        effectView.frame = bounds
        tintView.frame = bounds
        contentView.frame = bounds
        highlightLayer.frame = bounds
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true else { return }
        layer.borderColor = UIColor.white.withAlphaComponent(
            traitCollection.userInterfaceStyle == .dark ? 0.18 : 0.42
        ).cgColor
        layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.24 : 0.12
    }
}
