//
//  TFPrimaryButton.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public final class TFPrimaryButton: UIButton {
    private let fallbackMaterialView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let fallbackTintView = UIView()

    public init(title: String) {
        super.init(frame: .zero)
        configureAppearance(title: title)
        configureHeight()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configureHeight() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 56).isActive = true
    }

    private func configureAppearance(title: String) {
        tintColor = TFColor.Text.inverse
        layer.cornerCurve = .continuous

        if #available(iOS 26.0, *) {
            var config = UIButton.Configuration.prominentGlass()
            config.title = title
            config.baseBackgroundColor = TFColor.Brand.primary
            config.baseForegroundColor = TFColor.Text.inverse
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 24, bottom: 15, trailing: 24)
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = TFTypography.button
                return outgoing
            }
            configuration = config
        } else {
            configureFallbackGlass(title: title)
        }
    }

    private func configureFallbackGlass(title: String) {
        backgroundColor = .clear
        setTitle(title, for: .normal)
        setTitleColor(TFColor.Text.inverse, for: .normal)
        titleLabel?.font = TFTypography.button

        layer.cornerRadius = 28
        layer.shadowColor = TFColor.Brand.primary.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 8)

        fallbackMaterialView.isUserInteractionEnabled = false
        fallbackMaterialView.clipsToBounds = true
        fallbackMaterialView.layer.cornerRadius = 28
        fallbackMaterialView.layer.cornerCurve = .continuous
        fallbackMaterialView.layer.borderWidth = 1
        fallbackMaterialView.layer.borderColor = UIColor.white.withAlphaComponent(0.42).cgColor

        fallbackTintView.backgroundColor = TFColor.Brand.primary.withAlphaComponent(0.78)
        fallbackTintView.isUserInteractionEnabled = false
        fallbackMaterialView.contentView.addSubview(fallbackTintView)
        insertSubview(fallbackMaterialView, at: 0)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard #unavailable(iOS 26.0) else { return }
        fallbackMaterialView.frame = bounds
        fallbackTintView.frame = fallbackMaterialView.bounds
    }

    public override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        guard state == .normal else { return }
        if #available(iOS 26.0, *), var config = configuration {
            config.title = title
            configuration = config
        }
    }

    public override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.45
        }
    }

    public override var isHighlighted: Bool {
        didSet {
            if #unavailable(iOS 26.0) {
                fallbackTintView.backgroundColor = (
                    isHighlighted ? TFColor.Brand.primaryDark : TFColor.Brand.primary
                ).withAlphaComponent(0.78)
            }
            transform = isHighlighted ? CGAffineTransform(scaleX: 0.985, y: 0.985) : .identity
        }
    }
}
