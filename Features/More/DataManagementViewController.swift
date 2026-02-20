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
        title: "Data Management",
        leadingText: "Settings",
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
        heroText.text = "Manage your wardrobe data, export your packing lists, or sync across devices."
        heroContainer.addSubview(heroText)
        heroText.snp.makeConstraints { make in
            make.top.equalTo(iconCircle.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentStack.addArrangedSubview(heroContainer)

        let actionsSection = MoreSectionCardView(
            title: "Data Actions",
            footer: "Your data stays on device unless you enable iCloud sync."
        )
        actionsSection.setRows([
            makeRow(
                title: "Export Data",
                icon: "upload",
                iconTint: MorePalette.pink,
                iconBackground: MorePalette.pink.withAlphaComponent(0.14),
                action: { [weak self] in
                    self?.pushDataAction(title: "Export Data")
                }
            ),
            makeRow(
                title: "Import Data",
                icon: "download",
                iconTint: MorePalette.pink,
                iconBackground: MorePalette.pink.withAlphaComponent(0.14),
                action: { [weak self] in
                    self?.pushDataAction(title: "Import Data")
                }
            ),
        ])
        contentStack.addArrangedSubview(actionsSection)

        let dangerSection = MoreSectionCardView(
            title: "Danger Zone",
            footer: "This action cannot be undone. All your outfits and trips will be permanently deleted."
        )
        dangerSection.setTitleColor(UIColor(hex: 0xF45D5D))
        dangerSection.setRows([
            makeRow(
                title: "Reset Local Data",
                icon: "phonelink_erase",
                iconTint: UIColor(hex: 0xF45D5D),
                iconBackground: UIColor(hex: 0xF45D5D).withAlphaComponent(0.14),
                titleColor: UIColor(hex: 0xF45D5D),
                action: { [weak self] in
                    self?.pushDataAction(title: "Reset Local Data")
                }
            ),
            makeRow(
                title: "Reset iCloud Data",
                icon: "cloud_off",
                iconTint: UIColor(hex: 0xF45D5D),
                iconBackground: UIColor(hex: 0xF45D5D).withAlphaComponent(0.14),
                titleColor: UIColor(hex: 0xF45D5D),
                action: { [weak self] in
                    self?.pushDataAction(title: "Reset iCloud Data")
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

    private func pushDataAction(title: String) {
        let isDanger = title.contains("Reset")
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
                    ? "This flow is protected and requires one more confirmation before execution."
                    : "This flow prepares a local archive and verifies compatibility before continuing."
            ),
            sections: [
                .init(
                    title: "Checklist",
                    footer: "No data change is executed until final confirmation.",
                    rows: [
                        .init(
                            title: "iCloud Connectivity",
                            subtitle: nil,
                            value: "Checked",
                            icon: "cloud_done",
                            iconTint: MorePalette.blue,
                            iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: "Local Backup Snapshot",
                            subtitle: nil,
                            value: isDanger ? "Required" : "Ready",
                            icon: "backup",
                            iconTint: MorePalette.teal,
                            iconBackground: MorePalette.teal.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: "Estimated Duration",
                            subtitle: nil,
                            value: "< 1 min",
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
