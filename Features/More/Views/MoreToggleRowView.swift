//
//  MoreToggleRowView.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Core
import SnapKit
import UIKit

final class MoreToggleRowView: UIView {
    let toggleSwitch = UISwitch()

    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    init(
        title: String,
        iconLigature: String? = nil,
        iconTintColor: UIColor = TFColor.Brand.primary,
        iconBackgroundColor: UIColor = UIColor.clear,
        isOn: Bool
    ) {
        super.init(frame: .zero)
        setupLayout()
        configure(
            title: title,
            iconLigature: iconLigature,
            iconTintColor: iconTintColor,
            iconBackgroundColor: iconBackgroundColor,
            isOn: isOn
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(
        title: String,
        iconLigature: String?,
        iconTintColor: UIColor,
        iconBackgroundColor: UIColor,
        isOn: Bool
    ) {
        titleLabel.text = title
        toggleSwitch.isOn = isOn
        toggleSwitch.onTintColor = MorePalette.blue
        toggleSwitch.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)

        if let iconLigature {
            iconContainer.isHidden = false
            iconContainer.backgroundColor = iconBackgroundColor
            iconView.tintColor = iconTintColor
            iconView.image = TFMaterialIcon.image(
                named: iconLigature,
                pointSize: 18,
                weight: .medium
            ) ?? UIImage(systemName: iconLigature)
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(iconContainer.snp.trailing).offset(12)
                make.centerY.equalToSuperview()
            }
        } else {
            iconContainer.isHidden = true
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
            }
        }
    }

    private func setupLayout() {
        addSubview(iconContainer)
        iconContainer.layer.cornerRadius = 8
        iconContainer.clipsToBounds = true
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(32)
        }

        iconContainer.addSubview(iconView)
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }

        titleLabel.font = TFTypography.headline.withSize(17)
        titleLabel.textColor = TFColor.Text.primary
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        addSubview(toggleSwitch)
        toggleSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }

        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(50)
        }
    }
}
