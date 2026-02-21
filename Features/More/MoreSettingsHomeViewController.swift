//
//  MoreSettingsHomeViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Core
import SnapKit
import SwiftData
import UIKit

public final class MoreSettingsHomeViewController: UIViewController {
    private let context: ModelContext
    // Keep Appearance implementation intact, but hide the entry from More for now.
    private let showsAppearanceMenu = false
    private let developerGitHubURL = URL(string: "https://github.com/bbdyno/TripFit")

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private weak var languageRowControl: MoreSettingsRowControl?

    public init(context: ModelContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MorePalette.pageBackground
        setupScrollLayout()
        setupContent()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        refreshLanguageRow()
    }

    private func setupScrollLayout() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .automatic
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStack.axis = .vertical
        contentStack.spacing = 20
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide.snp.top).offset(8)
            make.leading.equalTo(scrollView.frameLayoutGuide.snp.leading).offset(MoreMetrics.horizontalInset)
            make.trailing.equalTo(scrollView.frameLayoutGuide.snp.trailing).inset(MoreMetrics.horizontalInset)
            make.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom).inset(120)
        }
    }

    private func setupContent() {
        let titleLabel = UILabel()
        titleLabel.text = CoreStrings.More.title
        titleLabel.font = TFTypography.largeTitle
        titleLabel.textColor = TFColor.Text.primary
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(makeDeveloperGitHubButton())

        let syncSection = MoreSectionCardView(
            title: CoreStrings.More.syncStatus,
            footer: CoreStrings.More.syncFooter
        )
        syncSection.setRows([
            makeRow(
                title: CoreStrings.More.icloudSync,
                value: CoreStrings.Common.on,
                icon: "cloud_sync",
                iconTint: MorePalette.blue,
                iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                action: { [weak self] in
                    self?.pushICloudSync()
                }
            ),
            makeRow(
                title: CoreStrings.More.lastBackup,
                value: CoreStrings.More.Icloud.justNow,
                icon: "history",
                iconTint: MorePalette.cyan,
                iconBackground: MorePalette.cyan.withAlphaComponent(0.16),
                showsChevron: false
            ),
        ])
        contentStack.addArrangedSubview(syncSection)

        let dataSection = MoreSectionCardView(title: CoreStrings.More.dataManagement)
        dataSection.setRows([
            makeRow(
                title: CoreStrings.More.exportData,
                icon: "upload",
                iconTint: MorePalette.mint,
                iconBackground: MorePalette.mint.withAlphaComponent(0.14),
                action: { [weak self] in
                    self?.pushDataManagement()
                }
            ),
            makeRow(
                title: CoreStrings.More.importData,
                icon: "download",
                iconTint: MorePalette.orange,
                iconBackground: MorePalette.orange.withAlphaComponent(0.15),
                action: { [weak self] in
                    self?.pushDataManagement()
                }
            ),
        ])
        contentStack.addArrangedSubview(dataSection)

        let preferencesSection = MoreSectionCardView(title: CoreStrings.More.preferences)
        let languageRow = makeLanguageRow()
        languageRowControl = languageRow
        var preferenceRows: [MoreSettingsRowControl] = []
        if showsAppearanceMenu {
            preferenceRows.append(
                makeRow(
                    title: CoreStrings.More.appearance,
                    value: CoreStrings.Common.system,
                    icon: "palette",
                    iconTint: MorePalette.purple,
                    iconBackground: MorePalette.purple.withAlphaComponent(0.16),
                    action: { [weak self] in
                        self?.pushAppearance()
                    }
                )
            )
        }
        preferenceRows.append(languageRow)
        preferenceRows.append(
            makeRow(
                title: CoreStrings.More.notifications,
                icon: "notifications",
                iconTint: MorePalette.red,
                iconBackground: MorePalette.red.withAlphaComponent(0.16),
                action: { [weak self] in
                    self?.pushNotifications()
                }
            )
        )
        preferencesSection.setRows(preferenceRows)
        contentStack.addArrangedSubview(preferencesSection)

        let supportSection = MoreSectionCardView(title: CoreStrings.More.support)
        supportSection.setRows([
            makeRow(
                title: CoreStrings.More.userGuide,
                icon: "menu_book",
                iconTint: MorePalette.teal,
                iconBackground: MorePalette.teal.withAlphaComponent(0.16),
                action: { [weak self] in
                    self?.pushUserGuide()
                }
            ),
            makeRow(
                title: CoreStrings.More.contactSupport,
                icon: "mail",
                iconTint: MorePalette.blue,
                iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                action: { [weak self] in
                    self?.pushContactSupport()
                }
            ),
            makeRow(
                title: CoreStrings.More.rateTripFit,
                icon: "star",
                iconTint: MorePalette.yellow,
                iconBackground: MorePalette.yellow.withAlphaComponent(0.16),
                action: { [weak self] in
                    self?.pushRateTripFit()
                }
            ),
            makeRow(
                title: CoreStrings.More.about,
                icon: "info",
                iconTint: MorePalette.slate,
                iconBackground: MorePalette.slate.withAlphaComponent(0.16),
                action: { [weak self] in
                    self?.pushAbout()
                }
            ),
        ])
        contentStack.addArrangedSubview(supportSection)

#if DEBUG
        let advancedSection = MoreSectionCardView(title: CoreStrings.More.advanced)
        advancedSection.setRows([
            makeRow(
                title: CoreStrings.More.developerOptions,
                icon: "build",
                iconTint: .white,
                iconBackground: MorePalette.slate,
                action: { [weak self] in
                    self?.pushDeveloper()
                }
            ),
        ])
        contentStack.addArrangedSubview(advancedSection)
#endif

        let footerStack = UIStackView()
        footerStack.axis = .vertical
        footerStack.spacing = 2
        footerStack.alignment = .center
        footerStack.layoutMargins = UIEdgeInsets(top: 6, left: 0, bottom: 4, right: 0)
        footerStack.isLayoutMarginsRelativeArrangement = true

        let versionLabel = UILabel()
        versionLabel.font = TFTypography.footnote.withSize(12)
        versionLabel.textColor = MorePalette.subtitle
        versionLabel.text = CoreStrings.Format.tripfitVersion(TFAppInfo.shortVersionDescription)

        let creditLabel = UILabel()
        creditLabel.font = TFTypography.footnote.withSize(10)
        creditLabel.textColor = MorePalette.subtitle.withAlphaComponent(0.75)
        creditLabel.text = CoreStrings.More.madeWithLove

        footerStack.addArrangedSubview(versionLabel)
        footerStack.addArrangedSubview(creditLabel)
        contentStack.addArrangedSubview(footerStack)
    }

    private func makeRow(
        title: String,
        value: String? = nil,
        icon: String,
        iconTint: UIColor,
        iconBackground: UIColor,
        showsChevron: Bool = true,
        action: (() -> Void)? = nil
    ) -> MoreSettingsRowControl {
        let row = MoreSettingsRowControl(
            model: .init(
                title: title,
                subtitle: nil,
                value: value,
                iconLigature: icon,
                iconTintColor: iconTint,
                iconBackgroundColor: iconBackground,
                showsChevron: showsChevron
            )
        )
        if let action {
            row.addAction(UIAction { _ in action() }, for: .touchUpInside)
        } else {
            row.isEnabled = false
        }
        return row
    }

    private func makeDeveloperGitHubButton() -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = localized("개발자 GitHub 바로가기", "Visit Developer GitHub")
        config.subtitle = "github.com/bbdyno/TripFit"
        config.titleAlignment = .leading
        config.baseBackgroundColor = MorePalette.blue
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        config.image = TFMaterialIcon.image(named: "open_in_new", pointSize: 18, weight: .semibold)
        config.imagePlacement = .trailing
        config.imagePadding = 8
        button.configuration = config
        button.addAction(UIAction { [weak self] _ in
            self?.openDeveloperGitHub()
        }, for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(56)
        }
        return button
    }

    private func pushICloudSync() {
        navigationController?.pushViewController(ICloudSyncSettingsViewController(context: context), animated: true)
    }

    private func pushDataManagement() {
        navigationController?.pushViewController(DataManagementViewController(), animated: true)
    }

    private func pushAppearance() {
        navigationController?.pushViewController(AppearanceSettingsViewController(), animated: true)
    }

    private func pushLanguage() {
        navigationController?.pushViewController(LanguageSettingsViewController(), animated: true)
    }

#if DEBUG
    private func pushDeveloper() {
        navigationController?.pushViewController(DeveloperOptionsViewController(context: context), animated: true)
    }
#endif

    private func pushAbout() {
        navigationController?.pushViewController(AboutTripFitViewController(), animated: true)
    }

    private func pushNotifications() {
        let screen = MoreInfoViewController(
            title: CoreStrings.More.notifications,
            leadingTint: MorePalette.red,
            hero: .init(
                icon: "notifications_active",
                iconTint: MorePalette.red,
                iconBackground: MorePalette.red.withAlphaComponent(0.16),
                title: CoreStrings.More.Support.manageAlerts,
                subtitle: CoreStrings.More.Support.chooseNotifications
            ),
            sections: [
                .init(
                    title: CoreStrings.More.Support.channels,
                    footer: CoreStrings.More.Support.quietHours,
                    rows: [
                        .init(
                            title: CoreStrings.More.Support.tripReminder,
                            subtitle: CoreStrings.More.Support.beforeDeparture,
                            value: CoreStrings.Common.on,
                            icon: "flight_takeoff",
                            iconTint: MorePalette.blue,
                            iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: CoreStrings.More.Support.packingChecklist,
                            subtitle: CoreStrings.More.Support.missingEssentials,
                            value: CoreStrings.Common.on,
                            icon: "inventory_2",
                            iconTint: MorePalette.teal,
                            iconBackground: MorePalette.teal.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: CoreStrings.More.Support.productUpdates,
                            subtitle: nil,
                            value: CoreStrings.Common.off,
                            icon: "new_releases",
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

    private func pushUserGuide() {
        let screen = MoreInfoViewController(
            title: CoreStrings.More.userGuide,
            leadingTint: MorePalette.teal,
            hero: .init(
                icon: "menu_book",
                iconTint: MorePalette.teal,
                iconBackground: MorePalette.teal.withAlphaComponent(0.16),
                title: CoreStrings.More.Support.gettingStarted,
                subtitle: CoreStrings.More.Support.guideSubtitle
            ),
            sections: [
                .init(
                    title: CoreStrings.More.Support.topics,
                    footer: CoreStrings.More.Support.guideFooter,
                    rows: [
                        .init(
                            title: CoreStrings.More.Support.addWardrobeItems,
                            subtitle: CoreStrings.More.Support.photoCategorySeason,
                            value: nil,
                            icon: "checkroom",
                            iconTint: MorePalette.pink,
                            iconBackground: MorePalette.pink.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: CoreStrings.More.Support.createOutfits,
                            subtitle: CoreStrings.More.Support.mixSave,
                            value: nil,
                            icon: "styler",
                            iconTint: MorePalette.purple,
                            iconBackground: MorePalette.purple.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: CoreStrings.More.Support.planTrip,
                            subtitle: CoreStrings.More.Support.datesDestinationChecklist,
                            value: nil,
                            icon: "flight_takeoff",
                            iconTint: MorePalette.blue,
                            iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                    ]
                )
            ]
        )
        navigationController?.pushViewController(screen, animated: true)
    }

    private func pushContactSupport() {
        let screen = MoreInfoViewController(
            title: CoreStrings.More.contactSupport,
            leadingTint: MorePalette.blue,
            hero: .init(
                icon: "support_agent",
                iconTint: MorePalette.blue,
                iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                title: CoreStrings.More.Support.needHelp,
                subtitle: CoreStrings.More.Support.contactSubtitle
            ),
            sections: [
                .init(
                    title: CoreStrings.More.Support.supportChannels,
                    footer: CoreStrings.More.Support.includeVersion,
                    rows: [
                        .init(
                            title: CoreStrings.More.Support.email,
                            subtitle: "support@tripfit.app",
                            value: nil,
                            icon: "mail",
                            iconTint: MorePalette.blue,
                            iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: CoreStrings.More.Support.faq,
                            subtitle: CoreStrings.More.Support.commonTips,
                            value: nil,
                            icon: "help",
                            iconTint: MorePalette.teal,
                            iconBackground: MorePalette.teal.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: CoreStrings.More.Support.bugReport,
                            subtitle: CoreStrings.More.Support.attachLogs,
                            value: nil,
                            icon: "bug_report",
                            iconTint: MorePalette.red,
                            iconBackground: MorePalette.red.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                    ]
                )
            ]
        )
        navigationController?.pushViewController(screen, animated: true)
    }

    private func pushRateTripFit() {
        TFAppStore.requestInAppReview()
        if TFAppStore.openWriteReview() {
            return
        }
        _ = TFAppStore.openAppStorePage()
    }

    private func makeLanguageRowModel() -> MoreSettingsRowControl.Model {
        let currentLanguage = TFAppLanguage.current()
        return .init(
            title: CoreStrings.Common.language,
            subtitle: nil,
            value: currentLanguage.displayName(in: currentLanguage),
            iconLigature: "language",
            iconTintColor: MorePalette.cyan,
            iconBackgroundColor: MorePalette.cyan.withAlphaComponent(0.16),
            showsChevron: true
        )
    }

    private func makeLanguageRow() -> MoreSettingsRowControl {
        let row = MoreSettingsRowControl(model: makeLanguageRowModel())
        row.addAction(UIAction { [weak self] _ in
            self?.pushLanguage()
        }, for: .touchUpInside)
        return row
    }

    private func refreshLanguageRow() {
        languageRowControl?.configure(with: makeLanguageRowModel())
    }

    private func openDeveloperGitHub() {
        guard let developerGitHubURL else { return }
        UIApplication.shared.open(developerGitHubURL)
    }

    private func localized(_ ko: String, _ en: String) -> String {
        TFAppLanguage.current() == .korean ? ko : en
    }
}
