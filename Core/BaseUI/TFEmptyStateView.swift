import UIKit
import SnapKit

public final class TFEmptyStateView: UIView {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    public let actionButton = TFPrimaryButton(title: "")

    public init(icon: String, title: String, subtitle: String, buttonTitle: String?) {
        super.init(frame: .zero)

        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = TFColor.lavender
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)

        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textColor = TFColor.textPrimary
        titleLabel.textAlignment = .center

        subtitleLabel.text = subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.textColor = TFColor.textSecondary
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

        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
