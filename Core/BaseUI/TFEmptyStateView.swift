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
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let cardView = TFCardView(style: .elevated)
    public let actionButton = TFPrimaryButton(title: "")

    public init(icon: String, title: String, subtitle: String, buttonTitle: String?) {
        super.init(frame: .zero)

        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = TFColor.Brand.primary
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)

        titleLabel.text = title
        titleLabel.font = TFTypography.title
        titleLabel.textColor = TFColor.Text.primary
        titleLabel.textAlignment = .center

        subtitleLabel.text = subtitle
        subtitleLabel.font = TFTypography.bodyRegular
        subtitleLabel.textColor = TFColor.Text.secondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center

        if let buttonTitle {
            actionButton.setTitle(buttonTitle, for: .normal)
            stack.addArrangedSubview(actionButton)
            stack.setCustomSpacing(24, after: subtitleLabel)
            actionButton.snp.makeConstraints { $0.width.equalTo(200) }
        } else {
            actionButton.isHidden = true
        }

        addSubview(cardView)
        cardView.addSubview(stack)

        cardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }

        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(24)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
