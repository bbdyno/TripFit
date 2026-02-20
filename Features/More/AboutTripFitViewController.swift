//
//  AboutTripFitViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Core
import SnapKit
import UIKit

final class AboutTripFitViewController: UIViewController {
    private enum AboutLink {
        case rateAppStore
        case privacyPolicy
        case openSource
        case terms
    }

    private let backButton = UIButton(type: .system)
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

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
        backButton.tintColor = MorePalette.pink
        backButton.setImage(TFMaterialIcon.image(named: "arrow_back_ios_new", pointSize: 20, weight: .regular), for: .normal)
        backButton.addAction(UIAction { [weak self] _ in
            self?.morePopOrDismiss()
        }, for: .touchUpInside)
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(4)
            make.size.equalTo(36)
        }

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        view.bringSubviewToFront(backButton)

        contentStack.axis = .vertical
        contentStack.spacing = 18
        contentStack.alignment = .fill
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide.snp.top).offset(28)
            make.leading.equalTo(scrollView.frameLayoutGuide.snp.leading).offset(20)
            make.trailing.equalTo(scrollView.frameLayoutGuide.snp.trailing).inset(20)
            make.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom).inset(120)
        }
    }

    private func setupContent() {
        let topStack = UIStackView()
        topStack.axis = .vertical
        topStack.spacing = 10
        topStack.alignment = .center

        let iconShell = UIView()
        iconShell.backgroundColor = MorePalette.cardBackground
        iconShell.layer.cornerRadius = 16
        iconShell.layer.borderWidth = 1 / UIScreen.main.scale
        iconShell.layer.borderColor = MorePalette.cardBorder.cgColor
        iconShell.layer.shadowColor = MorePalette.pink.cgColor
        iconShell.layer.shadowOpacity = 0.14
        iconShell.layer.shadowRadius = 10
        iconShell.layer.shadowOffset = CGSize(width: 0, height: 4)
        iconShell.snp.makeConstraints { make in
            make.size.equalTo(96)
        }

        let iconView = UIImageView()
        iconView.tintColor = MorePalette.pink
        iconView.image = TFMaterialIcon.image(named: "travel_explore", pointSize: 52, weight: .regular)
        iconShell.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(52)
        }
        topStack.addArrangedSubview(iconShell)

        let titleLabel = UILabel()
        titleLabel.text = "TripFit"
        titleLabel.font = TFTypography.largeTitle.withSize(23)
        titleLabel.textColor = TFColor.Text.primary
        topStack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = CoreStrings.More.About.tagline
        subtitleLabel.font = TFTypography.caption.withSize(11)
        subtitleLabel.textColor = MorePalette.pink
        topStack.addArrangedSubview(subtitleLabel)

        let versionChip = UILabel()
        versionChip.text = TFAppInfo.aboutVersionDescription
        versionChip.font = TFTypography.footnote.withSize(13)
        versionChip.textColor = MorePalette.subtitle
        versionChip.backgroundColor = MorePalette.pageBackground
        versionChip.layer.cornerRadius = 14
        versionChip.layer.borderWidth = 1 / UIScreen.main.scale
        versionChip.layer.borderColor = MorePalette.cardBorder.cgColor
        versionChip.clipsToBounds = true
        versionChip.textAlignment = .center
        versionChip.snp.makeConstraints { make in
            make.height.equalTo(28)
        }
        topStack.addArrangedSubview(versionChip)

        contentStack.addArrangedSubview(topStack)

        let menuCard = UIView()
        menuCard.backgroundColor = MorePalette.cardBackground
        menuCard.layer.cornerRadius = 16
        menuCard.layer.borderWidth = 1 / UIScreen.main.scale
        menuCard.layer.borderColor = MorePalette.cardBorder.cgColor
        menuCard.clipsToBounds = true
        contentStack.addArrangedSubview(menuCard)

        let rows = [
            makeRow(
                title: CoreStrings.More.About.rateAppStore,
                icon: "star",
                tint: UIColor(hex: 0xF39A35),
                bg: UIColor(hex: 0xF39A35).withAlphaComponent(0.15),
                action: { [weak self] in self?.pushLinkDetail(.rateAppStore) }
            ),
            makeRow(
                title: CoreStrings.More.About.privacyPolicy,
                icon: "shield",
                tint: UIColor(hex: 0x4B8DF2),
                bg: UIColor(hex: 0x4B8DF2).withAlphaComponent(0.15),
                action: { [weak self] in self?.pushLinkDetail(.privacyPolicy) }
            ),
            makeRow(
                title: CoreStrings.More.About.openSource,
                icon: "code",
                tint: UIColor(hex: 0x1FBF84),
                bg: UIColor(hex: 0x1FBF84).withAlphaComponent(0.15),
                action: { [weak self] in self?.pushLinkDetail(.openSource) }
            ),
            makeRow(
                title: CoreStrings.More.About.terms,
                icon: "description",
                tint: UIColor(hex: 0x9E6BFF),
                bg: UIColor(hex: 0x9E6BFF).withAlphaComponent(0.15),
                action: { [weak self] in self?.pushLinkDetail(.terms) }
            ),
        ]
        layoutRows(rows, in: menuCard)

        let footerStack = UIStackView()
        footerStack.axis = .vertical
        footerStack.spacing = 4
        footerStack.alignment = .center

        let madeWithLabel = UILabel()
        madeWithLabel.text = CoreStrings.More.About.madeBy
        madeWithLabel.font = TFTypography.bodyRegular.withSize(16)
        madeWithLabel.textColor = MorePalette.subtitle
        footerStack.addArrangedSubview(madeWithLabel)

        let copyrightLabel = UILabel()
        copyrightLabel.text = "© 2026 TaeinKim. All rights reserved."
        copyrightLabel.font = TFTypography.footnote.withSize(13)
        copyrightLabel.textColor = MorePalette.subtitle.withAlphaComponent(0.7)
        footerStack.addArrangedSubview(copyrightLabel)

        contentStack.addArrangedSubview(footerStack)
    }

    private func makeRow(
        title: String,
        icon: String,
        tint: UIColor,
        bg: UIColor,
        action: @escaping () -> Void
    ) -> MoreSettingsRowControl {
        let row = MoreSettingsRowControl(
            model: .init(
                title: title,
                subtitle: nil,
                value: nil,
                iconLigature: icon,
                iconTintColor: tint,
                iconBackgroundColor: bg,
                showsChevron: true
            )
        )
        row.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return row
    }

    private func layoutRows(_ rows: [MoreSettingsRowControl], in container: UIView) {
        var previous: UIView?
        for (index, row) in rows.enumerated() {
            container.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                if let previous {
                    make.top.equalTo(previous.snp.bottom)
                } else {
                    make.top.equalToSuperview()
                }
            }

            if index < rows.count - 1 {
                let separator = UIView()
                separator.backgroundColor = MorePalette.separator
                container.addSubview(separator)
                separator.snp.makeConstraints { make in
                    make.leading.equalToSuperview().inset(52)
                    make.trailing.equalToSuperview()
                    make.top.equalTo(row.snp.bottom)
                    make.height.equalTo(1 / UIScreen.main.scale)
                }
                previous = separator
            } else {
                row.snp.makeConstraints { make in
                    make.bottom.equalToSuperview()
                }
            }
        }
    }

    private func pushLinkDetail(_ link: AboutLink) {
        if link == .rateAppStore {
            TFAppStore.requestInAppReview()
            if TFAppStore.openWriteReview() {
                return
            }
            _ = TFAppStore.openAppStorePage()
            return
        }

        let title: String
        let icon: String
        let tint: UIColor
        switch link {
        case .privacyPolicy:
            title = CoreStrings.More.About.privacyPolicy
            if TFLegalDocuments.open(.privacyPolicy) {
                return
            }
            icon = "shield"
            tint = UIColor(hex: 0x4B8DF2)
        case .openSource:
            title = CoreStrings.More.About.openSource
            if TFLegalDocuments.open(.openSourceLicenses) {
                return
            }
            icon = "code"
            tint = UIColor(hex: 0x1FBF84)
        case .terms:
            title = CoreStrings.More.About.terms
            if TFLegalDocuments.open(.termsOfService) {
                return
            }
            icon = "description"
            tint = UIColor(hex: 0x9E6BFF)
        case .rateAppStore:
            title = CoreStrings.More.About.rateAppStore
            icon = "info"
            tint = MorePalette.slate
        }

        let screen = MoreInfoViewController(
            title: title,
            leadingTint: MorePalette.pink,
            hero: .init(
                icon: icon,
                iconTint: tint,
                iconBackground: tint.withAlphaComponent(0.14),
                title: title,
                subtitle: CoreStrings.More.About.placeholderSubtitle
            ),
            sections: [
                .init(
                    title: CoreStrings.More.About.details,
                    footer: CoreStrings.More.About.detailsFooter,
                    rows: [
                        .init(
                            title: CoreStrings.More.About.status,
                            subtitle: nil,
                            value: CoreStrings.Common.ready,
                            icon: "check_circle",
                            iconTint: UIColor(hex: 0x27C16E),
                            iconBackground: UIColor(hex: 0x27C16E).withAlphaComponent(0.14),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: CoreStrings.More.About.lastUpdated,
                            subtitle: nil,
                            value: "2026",
                            icon: "history",
                            iconTint: MorePalette.cyan,
                            iconBackground: MorePalette.cyan.withAlphaComponent(0.14),
                            titleColor: TFColor.Text.primary
                        ),
                    ]
                )
            ]
        )
        navigationController?.pushViewController(screen, animated: true)
    }
}
