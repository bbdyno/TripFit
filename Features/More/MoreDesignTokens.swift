//
//  MoreDesignTokens.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Core
import SnapKit
import UIKit

enum MorePalette {
    static let pageBackground = UIColor.dynamic(
        light: UIColor(hex: 0xF2F2F7),
        dark: UIColor(hex: 0x101922)
    )
    static let cardBackground = UIColor.dynamic(
        light: .white,
        dark: UIColor(hex: 0x1C2127)
    )
    static let cardBorder = UIColor.dynamic(
        light: UIColor(hex: 0xE2E7EE),
        dark: UIColor(hex: 0x283039)
    )
    static let sectionTitle = UIColor.dynamic(
        light: UIColor(hex: 0x7C8EA7),
        dark: UIColor(hex: 0x6D7D90)
    )
    static let subtitle = UIColor.dynamic(
        light: UIColor(hex: 0x8EA0B7),
        dark: UIColor(hex: 0x8A97A8)
    )
    static let chevron = UIColor.dynamic(
        light: UIColor(hex: 0xBFCCDC),
        dark: UIColor(hex: 0x5B6878)
    )
    static let separator = UIColor.dynamic(
        light: UIColor(hex: 0xE7ECF2),
        dark: UIColor(hex: 0x2E3743)
    )
    static let rowHighlight = UIColor.dynamic(
        light: UIColor(hex: 0xF6F9FD),
        dark: UIColor(hex: 0x232B35)
    )

    static let blue = UIColor(hex: 0x2B8CEE)
    static let sky = UIColor(hex: 0x5BC4FF)
    static let cyan = UIColor(hex: 0x2CB8C7)
    static let mint = UIColor(hex: 0x2BB673)
    static let orange = UIColor(hex: 0xF59B3D)
    static let purple = UIColor(hex: 0xA66BFF)
    static let red = UIColor(hex: 0xF45D5D)
    static let yellow = UIColor(hex: 0xF2B742)
    static let teal = UIColor(hex: 0x34B7A8)
    static let slate = UIColor(hex: 0x7589A1)

    static let pink = TFColor.Brand.primary
}

enum MoreMetrics {
    static let horizontalInset: CGFloat = 16
    static let cardCorner: CGFloat = 14
    static let iconCorner: CGFloat = 8
    static let rowHeight: CGFloat = 50
}

extension UIViewController {
    func morePopOrDismiss(animated: Bool = true) {
        if let navigationController, navigationController.viewControllers.first != self {
            navigationController.popViewController(animated: animated)
        } else {
            dismiss(animated: animated)
        }
    }
}

final class MoreInfoViewController: UIViewController {
    struct Hero {
        let icon: String
        let iconTint: UIColor
        let iconBackground: UIColor
        let title: String
        let subtitle: String
    }

    struct Row {
        let title: String
        let subtitle: String?
        let value: String?
        let icon: String
        let iconTint: UIColor
        let iconBackground: UIColor
        let titleColor: UIColor
    }

    struct Section {
        let title: String
        let footer: String?
        let rows: [Row]
    }

    private let screenTitle: String
    private let leadingText: String?
    private let leadingIcon: String
    private let leadingTint: UIColor
    private let hero: Hero?
    private let sections: [Section]
    private let footerText: String?

    private let headerBackground = UIView()
    private lazy var headerView = MoreDetailHeaderView(
        title: screenTitle,
        leadingText: leadingText,
        leadingIcon: leadingIcon,
        leadingTint: leadingTint
    )
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    init(
        title: String,
        leadingText: String? = CoreStrings.Common.settings,
        leadingIcon: String = "chevron_left",
        leadingTint: UIColor,
        hero: Hero?,
        sections: [Section],
        footerText: String? = nil
    ) {
        self.screenTitle = title
        self.leadingText = leadingText
        self.leadingIcon = leadingIcon
        self.leadingTint = leadingTint
        self.hero = hero
        self.sections = sections
        self.footerText = footerText
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MorePalette.pageBackground
        setupLayout()
        setupContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupLayout() {
        headerBackground.backgroundColor = MorePalette.pageBackground.withAlphaComponent(0.96)
        headerBackground.layer.borderWidth = 1 / UIScreen.main.scale
        headerBackground.layer.borderColor = MorePalette.cardBorder.cgColor
        view.addSubview(headerBackground)
        headerBackground.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top).offset(56)
        }

        headerBackground.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(56)
        }
        headerView.onLeadingTap = { [weak self] in
            self?.morePopOrDismiss()
        }

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerBackground.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentStack.axis = .vertical
        contentStack.spacing = 20
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide.snp.top).offset(18)
            make.leading.equalTo(scrollView.frameLayoutGuide.snp.leading).offset(MoreMetrics.horizontalInset)
            make.trailing.equalTo(scrollView.frameLayoutGuide.snp.trailing).inset(MoreMetrics.horizontalInset)
            make.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom).inset(120)
        }
    }

    private func setupContent() {
        if let hero {
            contentStack.addArrangedSubview(makeHeroCard(hero))
        }

        for section in sections {
            let sectionView = MoreSectionCardView(title: section.title, footer: section.footer)
            let rows = section.rows.map(makeRowControl(_:))
            sectionView.setRows(rows)
            contentStack.addArrangedSubview(sectionView)
        }

        if let footerText {
            let label = UILabel()
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = TFTypography.footnote.withSize(13)
            label.textColor = MorePalette.subtitle
            label.text = footerText
            contentStack.addArrangedSubview(label)
        }
    }

    private func makeHeroCard(_ hero: Hero) -> UIView {
        let card = UIView()
        card.backgroundColor = MorePalette.cardBackground
        card.layer.cornerRadius = MoreMetrics.cardCorner
        card.layer.borderWidth = 1 / UIScreen.main.scale
        card.layer.borderColor = MorePalette.cardBorder.cgColor
        card.clipsToBounds = true
        card.snp.makeConstraints { make in
            make.height.equalTo(90)
        }

        let iconCircle = UIView()
        iconCircle.backgroundColor = hero.iconBackground
        iconCircle.layer.cornerRadius = 20
        card.addSubview(iconCircle)
        iconCircle.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }

        let iconView = UIImageView()
        iconView.tintColor = hero.iconTint
        iconView.image = TFMaterialIcon.image(named: hero.icon, pointSize: 22, weight: .regular)
        iconCircle.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }

        let titleLabel = UILabel()
        titleLabel.text = hero.title
        titleLabel.font = TFTypography.headline.withSize(17)
        titleLabel.textColor = TFColor.Text.primary

        let subtitleLabel = UILabel()
        subtitleLabel.text = hero.subtitle
        subtitleLabel.font = TFTypography.footnote.withSize(13)
        subtitleLabel.textColor = MorePalette.subtitle
        subtitleLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        card.addSubview(textStack)
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconCircle.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }

        return card
    }

    private func makeRowControl(_ row: Row) -> MoreSettingsRowControl {
        let control = MoreSettingsRowControl(
            model: .init(
                title: row.title,
                subtitle: row.subtitle,
                value: row.value,
                iconLigature: row.icon,
                iconTintColor: row.iconTint,
                iconBackgroundColor: row.iconBackground,
                showsChevron: false,
                iconWeight: .regular,
                titleColor: row.titleColor
            )
        )
        control.isEnabled = false
        return control
    }
}
