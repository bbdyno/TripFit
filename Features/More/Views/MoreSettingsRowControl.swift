//
//  MoreSettingsRowControl.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Core
import SnapKit
import UIKit

final class MoreSettingsRowControl: UIControl {
    struct Model {
        let title: String
        var subtitle: String? = nil
        var value: String? = nil
        let iconLigature: String
        let iconTintColor: UIColor
        let iconBackgroundColor: UIColor
        var showsChevron: Bool = true
        var iconWeight: UIFont.Weight = .regular
        var titleColor: UIColor = TFColor.Text.primary
        var valueColor: UIColor = MorePalette.subtitle
    }

    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStack = UIStackView()
    private let trailingStack = UIStackView()
    private let valueLabel = UILabel()
    private let chevronView = UIImageView()

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? MorePalette.rowHighlight : .clear
        }
    }

    init(model: Model) {
        super.init(frame: .zero)
        setupLayout()
        configure(with: model)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with model: Model) {
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        subtitleLabel.isHidden = model.subtitle == nil
        valueLabel.text = model.value
        valueLabel.isHidden = model.value == nil
        chevronView.isHidden = !model.showsChevron
        titleLabel.textColor = model.titleColor
        valueLabel.textColor = model.valueColor

        iconContainer.backgroundColor = model.iconBackgroundColor
        iconView.tintColor = model.iconTintColor
        iconView.image = TFMaterialIcon.image(
            named: model.iconLigature,
            pointSize: 20,
            weight: model.iconWeight
        ) ?? UIImage(systemName: model.iconLigature)

        accessibilityLabel = model.title
        accessibilityHint = model.showsChevron ? CoreStrings.Common.opensDetails : nil
        accessibilityTraits = .button
    }

    private func setupLayout() {
        backgroundColor = .clear

        iconContainer.layer.cornerRadius = MoreMetrics.iconCorner
        iconContainer.clipsToBounds = true
        iconContainer.isUserInteractionEnabled = false
        addSubview(iconContainer)
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(32).priority(.high)
        }

        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false
        iconContainer.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }

        textStack.axis = .vertical
        textStack.spacing = 1
        textStack.isUserInteractionEnabled = false
        addSubview(textStack)
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.top.equalToSuperview().inset(9)
            make.bottom.equalToSuperview().inset(9)
            make.height.greaterThanOrEqualTo(MoreMetrics.rowHeight - 18)
        }

        titleLabel.font = TFTypography.headline.withSize(17)
        titleLabel.textColor = TFColor.Text.primary
        titleLabel.numberOfLines = 1
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        textStack.addArrangedSubview(titleLabel)

        subtitleLabel.font = TFTypography.footnote.withSize(13)
        subtitleLabel.textColor = MorePalette.subtitle
        subtitleLabel.numberOfLines = 1
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        textStack.addArrangedSubview(subtitleLabel)

        trailingStack.axis = .horizontal
        trailingStack.alignment = .center
        trailingStack.spacing = 6
        trailingStack.isUserInteractionEnabled = false
        addSubview(trailingStack)
        trailingStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(textStack.snp.trailing).offset(8).priority(.high)
        }

        valueLabel.font = TFTypography.bodyRegular.withSize(17)
        valueLabel.textColor = MorePalette.subtitle
        valueLabel.numberOfLines = 1
        trailingStack.addArrangedSubview(valueLabel)

        chevronView.contentMode = .scaleAspectFit
        chevronView.tintColor = MorePalette.chevron
        chevronView.image = TFMaterialIcon.image(named: "chevron_right", pointSize: 20, weight: .regular)
        trailingStack.addArrangedSubview(chevronView)
        chevronView.snp.makeConstraints { make in
            make.size.equalTo(20).priority(.high)
        }
    }
}
