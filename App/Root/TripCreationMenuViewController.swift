//
//  TripCreationMenuViewController.swift
//  TripFit
//
//  Created by bbdyno on 8/10/26.
//

import Core
import SnapKit
import UIKit

final class TripCreationMenuViewController: UIViewController {
    private let onPersonal: () -> Void
    private let onTogether: () -> Void
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let sheet = TFGlassPanelView(
        style: .systemMaterial,
        cornerRadius: 34,
        tintColor: TFColor.Surface.card.withAlphaComponent(0.56)
    )

    init(onPersonal: @escaping () -> Void, onTogether: @escaping () -> Void) {
        self.onPersonal = onPersonal
        self.onTogether = onTogether
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        setupBackdrop()
        setupSheet()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard UIAccessibility.isReduceMotionEnabled == false else { return }
        sheet.transform = CGAffineTransform(translationX: 0, y: 34)
        sheet.alpha = 0
        UIView.animate(
            withDuration: 0.34,
            delay: 0,
            usingSpringWithDamping: 0.88,
            initialSpringVelocity: 0.4,
            options: [.curveEaseOut]
        ) {
            self.sheet.transform = .identity
            self.sheet.alpha = 1
        }
    }

    private func setupBackdrop() {
        blurView.alpha = 0.58
        view.addSubview(blurView)
        blurView.snp.makeConstraints { $0.edges.equalToSuperview() }
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        blurView.addGestureRecognizer(tap)
    }

    private func setupSheet() {
        view.addSubview(sheet)
        sheet.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(8)
        }

        let eyebrow = UILabel()
        eyebrow.text = "TRIPFIT JOURNEY"
        eyebrow.font = TFTypography.caption.withSize(11)
        eyebrow.textColor = TFColor.Brand.primary

        let title = UILabel()
        title.text = localized("어떤 여행을 시작할까요?", "How do you want to start?")
        title.font = TFTypography.title.withSize(25)
        title.textColor = TFColor.Text.primary

        let subtitle = UILabel()
        subtitle.text = localized(
            "날짜가 정해졌다면 바로 계획하고, 아니라면 친구와 먼저 맞춰보세요.",
            "Plan fixed dates now, or coordinate the best days with friends first."
        )
        subtitle.font = TFTypography.bodyRegular.withSize(14)
        subtitle.textColor = TFColor.Text.secondary
        subtitle.numberOfLines = 0

        let personal = TripCreationOptionControl(
            pictogram: .suitcase,
            title: localized("개인 여행", "Personal Trip"),
            subtitle: localized("정해진 날짜로 바로 계획하기", "Start with dates already decided"),
            badge: localized("바로 시작", "START NOW")
        )
        personal.addAction(UIAction { [weak self] _ in self?.select(self?.onPersonal) }, for: .touchUpInside)

        let together = TripCreationOptionControl(
            pictogram: .together,
            title: localized("함께 준비하는 여행", "Trip Together"),
            subtitle: localized("친구와 가능한 날짜부터 맞추기", "Find dates that work for everyone"),
            badge: localized("공유", "SHARED")
        )
        together.addAction(UIAction { [weak self] _ in self?.select(self?.onTogether) }, for: .touchUpInside)

        let cancel = TFSecondaryButton(title: localized("취소", "Cancel"))
        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [eyebrow, title, subtitle, personal, together, cancel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(3, after: eyebrow)
        stack.setCustomSpacing(8, after: title)
        stack.setCustomSpacing(20, after: subtitle)
        stack.setCustomSpacing(16, after: together)
        sheet.contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 24, left: 20, bottom: 18, right: 20))
        }
        personal.snp.makeConstraints { $0.height.equalTo(98) }
        together.snp.makeConstraints { $0.height.equalTo(98) }
    }

    private func select(_ action: (() -> Void)?) {
        dismiss(animated: true) { action?() }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    private func localized(_ korean: String, _ english: String) -> String {
        TFAppLanguage.current() == .korean ? korean : english
    }
}

private final class TripCreationOptionControl: UIControl {
    init(pictogram: TFPictogram, title: String, subtitle: String, badge: String) {
        super.init(frame: .zero)
        backgroundColor = TFColor.Surface.elevated.withAlphaComponent(0.72)
        layer.cornerRadius = 24
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = TFColor.Border.subtle.cgColor

        let iconStage = UIView()
        iconStage.backgroundColor = TFColor.Surface.highlight.withAlphaComponent(0.74)
        iconStage.layer.cornerRadius = 20
        iconStage.layer.cornerCurve = .continuous
        let icon = UIImageView(image: pictogram.image)
        icon.contentMode = .scaleAspectFit
        iconStage.addSubview(icon)
        icon.snp.makeConstraints { $0.edges.equalToSuperview().inset(6) }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = TFTypography.headline.withSize(17)
        titleLabel.textColor = TFColor.Text.primary

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = TFTypography.footnote.withSize(12)
        subtitleLabel.textColor = TFColor.Text.secondary
        subtitleLabel.numberOfLines = 2

        let text = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        text.axis = .vertical
        text.spacing = 3

        let badgeLabel = InsetLabel(insets: UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8))
        badgeLabel.text = badge
        badgeLabel.font = TFTypography.caption.withSize(9)
        badgeLabel.textColor = TFColor.Brand.primaryDark
        badgeLabel.backgroundColor = TFColor.Brand.primary.withAlphaComponent(0.12)
        badgeLabel.layer.cornerRadius = 11
        badgeLabel.layer.cornerCurve = .continuous
        badgeLabel.clipsToBounds = true

        [iconStage, text, badgeLabel].forEach(addSubview)
        iconStage.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(66)
        }
        text.snp.makeConstraints { make in
            make.leading.equalTo(iconStage.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(badgeLabel.snp.leading).offset(-8)
        }
        badgeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.top.equalToSuperview().inset(14)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet {
            transform = isHighlighted ? CGAffineTransform(scaleX: 0.985, y: 0.985) : .identity
            alpha = isHighlighted ? 0.78 : 1
        }
    }
}

private final class InsetLabel: UILabel {
    private let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}
