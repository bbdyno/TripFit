//
//  TFAuroraBackdropView.swift
//  TripFit
//
//  Created by bbdyno on 8/10/26.
//

import UIKit

public final class TFAuroraBackdropView: UIView {
    private let baseLayer = CAGradientLayer()
    private let pinkGlow = CAGradientLayer()
    private let mintGlow = CAGradientLayer()
    private let skyGlow = CAGradientLayer()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        clipsToBounds = true

        baseLayer.colors = [
            TFColor.Surface.hero.cgColor,
            UIColor(hex: 0x15232B).cgColor,
            UIColor(hex: 0x233039).cgColor,
        ]
        baseLayer.startPoint = CGPoint(x: 0, y: 0)
        baseLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(baseLayer)

        configureGlow(
            pinkGlow,
            color: TFColor.Brand.primary.withAlphaComponent(0.78),
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: 0.74, y: 0.72)
        )
        configureGlow(
            mintGlow,
            color: TFColor.Brand.accentMint.withAlphaComponent(0.58),
            start: CGPoint(x: 1, y: 0.18),
            end: CGPoint(x: 0.34, y: 0.84)
        )
        configureGlow(
            skyGlow,
            color: TFColor.Brand.accentSky.withAlphaComponent(0.48),
            start: CGPoint(x: 0.9, y: 1),
            end: CGPoint(x: 0.26, y: 0.34)
        )
        blurView.alpha = 0.28
        blurView.isUserInteractionEnabled = false
        addSubview(blurView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        baseLayer.frame = bounds
        pinkGlow.frame = CGRect(x: -bounds.width * 0.28, y: -bounds.height * 0.42, width: bounds.width, height: bounds.height)
        mintGlow.frame = CGRect(x: bounds.width * 0.38, y: -bounds.height * 0.2, width: bounds.width * 0.9, height: bounds.height * 0.9)
        skyGlow.frame = CGRect(x: bounds.width * 0.18, y: bounds.height * 0.46, width: bounds.width, height: bounds.height)
        blurView.frame = bounds
    }

    private func configureGlow(
        _ gradient: CAGradientLayer,
        color: UIColor,
        start: CGPoint,
        end: CGPoint
    ) {
        gradient.type = .radial
        gradient.colors = [color.cgColor, color.withAlphaComponent(0).cgColor]
        gradient.locations = [0, 1]
        gradient.startPoint = start
        gradient.endPoint = end
        layer.addSublayer(gradient)
    }
}
