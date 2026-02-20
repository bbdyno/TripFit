//
//  DataManagementViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Core
import SnapKit
import UIKit

final class DataManagementViewController: UIViewController {
    private let headerBackground = UIView()
    private let headerView = MoreDetailHeaderView(
        title: CoreStrings.More.Data.title,
        leadingText: CoreStrings.Common.settings,
        leadingIcon: "chevron_left",
        leadingTint: MorePalette.pink
    )
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
        contentStack.spacing = 26
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide.snp.top).offset(20)
            make.leading.equalTo(scrollView.frameLayoutGuide.snp.leading).offset(MoreMetrics.horizontalInset)
            make.trailing.equalTo(scrollView.frameLayoutGuide.snp.trailing).inset(MoreMetrics.horizontalInset)
            make.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom).inset(120)
        }
    }

    private func setupContent() {
        let heroContainer = UIView()

        let iconCircle = UIView()
        iconCircle.backgroundColor = MorePalette.pink.withAlphaComponent(0.14)
        iconCircle.layer.cornerRadius = 42
        heroContainer.addSubview(iconCircle)
        iconCircle.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(84)
        }

        let heroIcon = UIImageView()
        heroIcon.tintColor = MorePalette.pink
        heroIcon.image = TFMaterialIcon.image(named: "cloud_sync", pointSize: 40, weight: .regular)
        iconCircle.addSubview(heroIcon)
        heroIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }

        let heroText = UILabel()
        heroText.numberOfLines = 0
        heroText.textAlignment = .center
        heroText.font = TFTypography.bodyRegular.withSize(16)
        heroText.textColor = MorePalette.subtitle
        heroText.text = CoreStrings.More.Data.hero
        heroContainer.addSubview(heroText)
        heroText.snp.makeConstraints { make in
            make.top.equalTo(iconCircle.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentStack.addArrangedSubview(heroContainer)

        let actionsSection = MoreSectionCardView(
            title: CoreStrings.More.Data.dataActions,
            footer: CoreStrings.More.Data.dataFooter
        )
        actionsSection.setRows([
            makeRow(
                title: CoreStrings.More.exportData,
                icon: "upload",
                iconTint: MorePalette.pink,
                iconBackground: MorePalette.pink.withAlphaComponent(0.14),
                action: { [weak self] in
                    self?.pushDataAction(title: CoreStrings.More.exportData, isDanger: false)
                }
            ),
            makeRow(
                title: CoreStrings.More.importData,
                icon: "download",
                iconTint: MorePalette.pink,
                iconBackground: MorePalette.pink.withAlphaComponent(0.14),
                action: { [weak self] in
                    self?.pushDataAction(title: CoreStrings.More.importData, isDanger: false)
                }
            ),
        ])
        contentStack.addArrangedSubview(actionsSection)

        let dangerSection = MoreSectionCardView(
            title: CoreStrings.More.Data.dangerZone,
            footer: CoreStrings.More.Data.dangerFooter
        )
        dangerSection.setTitleColor(UIColor(hex: 0xF45D5D))
        dangerSection.setRows([
            makeRow(
                title: CoreStrings.More.Data.resetLocal,
                icon: "phonelink_erase",
                iconTint: UIColor(hex: 0xF45D5D),
                iconBackground: UIColor(hex: 0xF45D5D).withAlphaComponent(0.14),
                titleColor: UIColor(hex: 0xF45D5D),
                action: { [weak self] in
                    self?.pushDataAction(title: CoreStrings.More.Data.resetLocal, isDanger: true)
                }
            ),
            makeRow(
                title: CoreStrings.More.Data.resetIcloud,
                icon: "cloud_off",
                iconTint: UIColor(hex: 0xF45D5D),
                iconBackground: UIColor(hex: 0xF45D5D).withAlphaComponent(0.14),
                titleColor: UIColor(hex: 0xF45D5D),
                action: { [weak self] in
                    self?.pushDataAction(title: CoreStrings.More.Data.resetIcloud, isDanger: true)
                }
            ),
        ])
        contentStack.addArrangedSubview(dangerSection)
    }

    private func makeRow(
        title: String,
        icon: String,
        iconTint: UIColor,
        iconBackground: UIColor,
        titleColor: UIColor = TFColor.Text.primary,
        action: (() -> Void)? = nil
    ) -> MoreSettingsRowControl {
        let row = MoreSettingsRowControl(
            model: .init(
                title: title,
                subtitle: nil,
                value: nil,
                iconLigature: icon,
                iconTintColor: iconTint,
                iconBackgroundColor: iconBackground,
                showsChevron: true,
                iconWeight: .regular,
                titleColor: titleColor
            )
        )
        if let action {
            row.addAction(UIAction { _ in action() }, for: .touchUpInside)
        } else {
            row.isEnabled = false
        }
        return row
    }

    private func pushDataAction(title: String, isDanger: Bool) {
        let tint = isDanger ? UIColor(hex: 0xF45D5D) : MorePalette.pink
        let screen = MoreInfoViewController(
            title: title,
            leadingTint: MorePalette.pink,
            hero: .init(
                icon: isDanger ? "warning" : "sync",
                iconTint: tint,
                iconBackground: tint.withAlphaComponent(0.14),
                title: title,
                subtitle: isDanger
                    ? CoreStrings.More.Data.flowDangerSubtitle
                    : CoreStrings.More.Data.flowSafeSubtitle
            ),
            sections: [
                .init(
                    title: CoreStrings.More.Data.checklist,
                    footer: CoreStrings.More.Data.checklistFooter,
                    rows: [
                        .init(
                            title: CoreStrings.More.Data.icloudConnectivity,
                            subtitle: nil,
                            value: CoreStrings.More.Data.checked,
                            icon: "cloud_done",
                            iconTint: MorePalette.blue,
                            iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: CoreStrings.More.Data.localBackupSnapshot,
                            subtitle: nil,
                            value: isDanger ? CoreStrings.Common.required : CoreStrings.Common.ready,
                            icon: "backup",
                            iconTint: MorePalette.teal,
                            iconBackground: MorePalette.teal.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: CoreStrings.More.Data.estimatedDuration,
                            subtitle: nil,
                            value: CoreStrings.More.Data.durationUnderOneMinute,
                            icon: "schedule",
                            iconTint: MorePalette.orange,
                            iconBackground: MorePalette.orange.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                    ]
                )
            ]
        )
        navigationController?.pushViewController(screen, animated: true)
    }
}
