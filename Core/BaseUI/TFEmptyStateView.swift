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
        self.systemIcon = icon
        self.pictogram = nil
        super.init(frame: .zero)
        setup(title: title, subtitle: subtitle, buttonTitle: buttonTitle)
    }

    public init(pictogram: TFPictogram, title: String, subtitle: String, buttonTitle: String?) {
        self.systemIcon = nil
        self.pictogram = pictogram
        super.init(frame: .zero)
        setup(title: title, subtitle: subtitle, buttonTitle: buttonTitle)
    }

    private let systemIcon: String?
    private let pictogram: TFPictogram?

    private func setup(title: String, subtitle: String, buttonTitle: String?) {
        iconImageView.image = pictogram?.image ?? systemIcon.flatMap { UIImage(systemName: $0) }
        iconImageView.tintColor = TFColor.Brand.primary
        iconImageView.contentMode = .scaleAspectFit
        if pictogram == nil {
            iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        }

        iconContainer.backgroundColor = TFColor.Surface.highlight
        iconContainer.layer.cornerRadius = 30
        iconContainer.layer.cornerCurve = .continuous
        iconContainer.layer.borderWidth = 1
        iconContainer.layer.borderColor = TFColor.Brand.primary.withAlphaComponent(0.12).cgColor
        iconContainer.layer.shadowColor = TFColor.Brand.primary.cgColor
        iconContainer.layer.shadowOpacity = 0.08
        iconContainer.layer.shadowRadius = 18
        iconContainer.layer.shadowOffset = CGSize(width: 0, height: 8)

        iconContainer.addSubview(iconImageView)
        iconContainer.snp.makeConstraints { make in
            make.size.equalTo(108)
        }
        iconImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(pictogram == nil ? 30 : 18)
        }

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
        stack.spacing = 8
        stack.alignment = .center
        stack.setCustomSpacing(24, after: iconContainer)

        if let buttonTitle {
            actionButton.setTitle(buttonTitle, for: .normal)
            stack.addArrangedSubview(actionButton)
            stack.setCustomSpacing(24, after: subtitleLabel)
            actionButton.snp.makeConstraints { $0.width.equalTo(200) }
        } else {
            actionButton.isHidden = true
        }

        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-34)
            make.leading.trailing.equalToSuperview().inset(44)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
