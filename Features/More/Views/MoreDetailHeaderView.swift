//
//  MoreDetailHeaderView.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Core
import SnapKit
import UIKit

final class MoreDetailHeaderView: UIView {
    var onLeadingTap: (() -> Void)?
    var onTrailingTap: (() -> Void)?

    private let leadingButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let trailingButton = UIButton(type: .system)

    init(
        title: String,
        leadingText: String?,
        leadingIcon: String,
        leadingTint: UIColor,
        trailingText: String? = nil
    ) {
        super.init(frame: .zero)
        setupLayout()
        configure(
            title: title,
            leadingText: leadingText,
            leadingIcon: leadingIcon,
            leadingTint: leadingTint,
            trailingText: trailingText
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(
        title: String,
        leadingText: String?,
        leadingIcon: String,
        leadingTint: UIColor,
        trailingText: String?
    ) {
        titleLabel.text = title

        var leadingConfig = UIButton.Configuration.plain()
        leadingConfig.image = TFMaterialIcon.image(named: leadingIcon, pointSize: 22, weight: .regular)
        leadingConfig.title = leadingText
        leadingConfig.imagePadding = 2
        leadingConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 2, bottom: 6, trailing: 2)
        leadingButton.configuration = leadingConfig
        leadingButton.tintColor = leadingTint
        leadingButton.setTitleColor(leadingTint, for: .normal)
        leadingButton.titleLabel?.font = TFTypography.bodyRegular.withSize(17)

        if let trailingText {
            trailingButton.isHidden = false
            var trailingConfig = UIButton.Configuration.plain()
            trailingConfig.title = trailingText
            trailingConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4)
            trailingButton.configuration = trailingConfig
            trailingButton.tintColor = leadingTint
            trailingButton.setTitleColor(leadingTint, for: .normal)
            trailingButton.titleLabel?.font = TFTypography.headline.withSize(17)
        } else {
            trailingButton.isHidden = true
            trailingButton.configuration = nil
        }
    }

    private func setupLayout() {
        addSubview(leadingButton)
        leadingButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
        }
        leadingButton.addAction(UIAction { [weak self] _ in
            self?.onLeadingTap?()
        }, for: .touchUpInside)

        titleLabel.font = TFTypography.headline.withSize(17)
        titleLabel.textColor = TFColor.Text.primary
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(leadingButton.snp.trailing).offset(8)
        }

        addSubview(trailingButton)
        trailingButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
            make.height.equalTo(40)
        }
        trailingButton.addAction(UIAction { [weak self] _ in
            self?.onTrailingTap?()
        }, for: .touchUpInside)
    }
}
