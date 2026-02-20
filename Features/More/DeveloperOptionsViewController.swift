//
//  DeveloperOptionsViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Core
import SnapKit
import SwiftData
import UIKit

final class DeveloperOptionsViewController: UIViewController {
    private let context: ModelContext

    private let headerBackground = UIView()
    private let headerView = MoreDetailHeaderView(
        title: "Developer Options",
        leadingText: "Back",
        leadingIcon: "arrow_back_ios_new",
        leadingTint: MorePalette.blue,
        trailingText: "Done"
    )
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    init(context: ModelContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = UIColor(hex: 0x101922)
        setupLayout()
        setupContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupLayout() {
        headerBackground.backgroundColor = UIColor(hex: 0x111418)
        headerBackground.layer.borderWidth = 1 / UIScreen.main.scale
        headerBackground.layer.borderColor = UIColor(hex: 0x283039).cgColor
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
        headerView.onTrailingTap = { [weak self] in
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
        contentStack.spacing = 22
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide.snp.top).offset(18)
            make.leading.equalTo(scrollView.frameLayoutGuide.snp.leading).offset(MoreMetrics.horizontalInset)
            make.trailing.equalTo(scrollView.frameLayoutGuide.snp.trailing).inset(MoreMetrics.horizontalInset)
            make.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom).inset(120)
        }
    }

    private func setupContent() {
        contentStack.addArrangedSubview(makeBuildInfoSection())

        let dataSection = MoreSectionCardView(
            title: "Data Management",
            footer: "Adds mock data to the local database for UI testing."
        )
        dataSection.setRows([
            makeActionRow(
                title: "Seed Sample Wardrobe",
                icon: "checkroom",
                tint: UIColor(hex: 0x5A8FEF),
                bg: UIColor(hex: 0x5A8FEF).withAlphaComponent(0.18)
            ),
            makeActionRow(
                title: "Seed Upcoming Trip",
                icon: "flight_takeoff",
                tint: UIColor(hex: 0x24BD84),
                bg: UIColor(hex: 0x24BD84).withAlphaComponent(0.18)
            ),
        ])
        contentStack.addArrangedSubview(dataSection)

        let syncSection = UIView()
        syncSection.addSubview(makeSectionTitle("Sync Testing"))
        let syncTitle = syncSection.subviews[0]
        syncTitle.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        let syncCard = makeDarkCard()
        syncSection.addSubview(syncCard)
        syncCard.snp.makeConstraints { make in
            make.top.equalTo(syncTitle.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let syncRow1 = MoreToggleRowView(
            title: "Simulate Conflict",
            iconLigature: "warning",
            iconTintColor: UIColor(hex: 0xEFBB39),
            iconBackgroundColor: UIColor(hex: 0xEFBB39).withAlphaComponent(0.2),
            isOn: false
        )
        syncCard.addSubview(syncRow1)
        syncRow1.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        let syncSep = UIView()
        syncSep.backgroundColor = UIColor(hex: 0x283039)
        syncCard.addSubview(syncSep)
        syncSep.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview()
            make.top.equalTo(syncRow1.snp.bottom)
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        let syncRow2 = MoreToggleRowView(
            title: "Log Sync Events",
            iconLigature: "cloud_sync",
            iconTintColor: UIColor(hex: 0xA774FF),
            iconBackgroundColor: UIColor(hex: 0xA774FF).withAlphaComponent(0.2),
            isOn: true
        )
        syncCard.addSubview(syncRow2)
        syncRow2.snp.makeConstraints { make in
            make.top.equalTo(syncSep.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentStack.addArrangedSubview(syncSection)

        let uiSection = UIView()
        uiSection.addSubview(makeSectionTitle("UI Debugging"))
        let uiTitle = uiSection.subviews[0]
        uiTitle.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        let uiCard = makeDarkCard()
        uiSection.addSubview(uiCard)
        uiCard.snp.makeConstraints { make in
            make.top.equalTo(uiTitle.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let uiRow1 = MoreToggleRowView(
            title: "Show Debug Overlay",
            iconLigature: "layers",
            iconTintColor: UIColor(hex: 0x6D7DFF),
            iconBackgroundColor: UIColor(hex: 0x6D7DFF).withAlphaComponent(0.18),
            isOn: false
        )
        uiCard.addSubview(uiRow1)
        uiRow1.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        let uiSep = UIView()
        uiSep.backgroundColor = UIColor(hex: 0x283039)
        uiCard.addSubview(uiSep)
        uiSep.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview()
            make.top.equalTo(uiRow1.snp.bottom)
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        let uiRow2 = MoreToggleRowView(
            title: "Force Crash Reporting",
            iconLigature: "bug_report",
            iconTintColor: UIColor(hex: 0xEA5AAE),
            iconBackgroundColor: UIColor(hex: 0xEA5AAE).withAlphaComponent(0.18),
            isOn: false
        )
        uiCard.addSubview(uiRow2)
        uiRow2.snp.makeConstraints { make in
            make.top.equalTo(uiSep.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentStack.addArrangedSubview(uiSection)

        let dangerSection = MoreSectionCardView(
            title: "Danger Zone",
            footer: "These actions cannot be undone."
        )
        dangerSection.setTitleColor(UIColor(hex: 0xFF5252))
        dangerSection.setRows([
            makeActionRow(
                title: "Reset User Cache",
                icon: "dangerous",
                tint: UIColor(hex: 0xFF5252),
                bg: UIColor(hex: 0xFF5252).withAlphaComponent(0.18),
                titleColor: UIColor(hex: 0xFF5252),
                showsChevron: false
            ),
            makeActionRow(
                title: "Clear All App Data",
                icon: "delete",
                tint: UIColor(hex: 0xFF5252),
                bg: UIColor(hex: 0xFF5252).withAlphaComponent(0.18),
                titleColor: UIColor(hex: 0xFF5252),
                showsChevron: false
            ),
        ])
        contentStack.addArrangedSubview(dangerSection)
    }

    private func makeBuildInfoSection() -> UIView {
        let container = UIView()

        let title = makeSectionTitle("Build Information")
        container.addSubview(title)
        title.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        let versionRow = makeInfoRow(left: "Version", right: TFAppInfo.shortVersionDescription)
        container.addSubview(versionRow)
        versionRow.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(2)
        }

        let envRow = makeInfoRow(
            left: "Environment",
            right: "Staging",
            rightColor: UIColor(hex: 0x1FD070)
        )
        container.addSubview(envRow)
        envRow.snp.makeConstraints { make in
            make.top.equalTo(versionRow.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(2)
            make.bottom.equalToSuperview()
        }

        return container
    }

    private func makeInfoRow(left: String, right: String, rightColor: UIColor = MorePalette.subtitle) -> UIView {
        let row = UIView()
        let leftLabel = UILabel()
        leftLabel.text = left
        leftLabel.font = TFTypography.bodyRegular.withSize(17)
        leftLabel.textColor = MorePalette.subtitle
        row.addSubview(leftLabel)
        leftLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        let rightLabel = UILabel()
        rightLabel.text = right
        rightLabel.font = TFTypography.bodyRegular.withSize(17)
        rightLabel.textColor = rightColor
        row.addSubview(rightLabel)
        rightLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(leftLabel.snp.trailing).offset(8)
        }
        return row
    }

    private func makeActionRow(
        title: String,
        icon: String,
        tint: UIColor,
        bg: UIColor,
        titleColor: UIColor = TFColor.Text.primary,
        showsChevron: Bool = true
    ) -> MoreSettingsRowControl {
        let row = MoreSettingsRowControl(
            model: .init(
                title: title,
                subtitle: nil,
                value: nil,
                iconLigature: icon,
                iconTintColor: tint,
                iconBackgroundColor: bg,
                showsChevron: showsChevron,
                iconWeight: .regular,
                titleColor: titleColor,
                valueColor: MorePalette.subtitle
            )
        )
        row.addAction(UIAction { [weak self] _ in
            self?.pushDeveloperAction(title: title, tint: tint)
        }, for: .touchUpInside)
        return row
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = TFTypography.caption.withSize(12)
        label.textColor = MorePalette.sectionTitle
        return label
    }

    private func makeDarkCard() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0x1C2127)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1 / UIScreen.main.scale
        view.layer.borderColor = UIColor(hex: 0x283039).cgColor
        view.clipsToBounds = true
        return view
    }

    private func pushDeveloperAction(title: String, tint: UIColor) {
        let screen = MoreInfoViewController(
            title: title,
            leadingText: "Back",
            leadingIcon: "arrow_back_ios_new",
            leadingTint: MorePalette.blue,
            hero: .init(
                icon: "terminal",
                iconTint: tint,
                iconBackground: tint.withAlphaComponent(0.18),
                title: title,
                subtitle: "This action is now mapped to a dedicated diagnostics page."
            ),
            sections: [
                .init(
                    title: "Execution",
                    footer: "Local debug operations are isolated from production data.",
                    rows: [
                        .init(
                            title: "Action Type",
                            subtitle: nil,
                            value: "Manual",
                            icon: "build",
                            iconTint: MorePalette.blue,
                            iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: "Scope",
                            subtitle: nil,
                            value: "Local Device",
                            icon: "smartphone",
                            iconTint: MorePalette.teal,
                            iconBackground: MorePalette.teal.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: "Safety",
                            subtitle: nil,
                            value: "Protected",
                            icon: "verified_user",
                            iconTint: UIColor(hex: 0x27C16E),
                            iconBackground: UIColor(hex: 0x27C16E).withAlphaComponent(0.14),
                            titleColor: TFColor.Text.primary
                        ),
                    ]
                )
            ]
        )
        navigationController?.pushViewController(screen, animated: true)
    }
}
