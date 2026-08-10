//
//  TFEmptyStateView.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import SnapKit
import UIKit

public final class TFEmptyStateView: UIView {
    private let iconImageView = UIImageView()
    private let iconContainer = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    public let actionButton = TFPrimaryButton(title: "")

    public init(icon: String, title: String, subtitle: String, buttonTitle: String?) {
        super.init(frame: .zero)

        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = TFColor.Brand.primary
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        iconContainer.backgroundColor = TFColor.Surface.highlight
        iconContainer.layer.cornerRadius = 30
        iconContainer.layer.cornerCurve = .continuous
        iconContainer.addSubview(iconImageView)
        iconContainer.snp.makeConstraints { $0.size.equalTo(60) }
        iconImageView.snp.makeConstraints { $0.center.equalToSuperview() }

        titleLabel.text = title
        titleLabel.font = TFTypography.title
        titleLabel.textColor = TFColor.Text.primary
        titleLabel.textAlignment = .center

        subtitleLabel.text = subtitle
        subtitleLabel.font = TFTypography.bodyRegular
        subtitleLabel.textColor = TFColor.Text.secondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [iconContainer, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .center

        if let buttonTitle {
            actionButton.setTitle(buttonTitle, for: .normal)
            stack.addArrangedSubview(actionButton)
            stack.setCustomSpacing(22, after: subtitleLabel)
            actionButton.snp.makeConstraints { $0.width.equalTo(220) }
        } else {
            actionButton.isHidden = true
        }

        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
