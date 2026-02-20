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

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

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
        titleLabel.text = "More"
        titleLabel.font = TFTypography.largeTitle
        titleLabel.textColor = TFColor.Text.primary
        contentStack.addArrangedSubview(titleLabel)

        let profileCard = makeProfileCard()
        contentStack.addArrangedSubview(profileCard)

        let syncSection = MoreSectionCardView(
            title: "Sync Status",
            footer: "Your wardrobe and outfits are securely synced via iCloud. You can access them on all your devices."
        )
        syncSection.setRows([
            makeRow(
                title: "iCloud Sync",
                value: "On",
                icon: "cloud_sync",
                iconTint: MorePalette.blue,
                iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                action: { [weak self] in
                    self?.pushICloudSync()
                }
            ),
            makeRow(
                title: "Last Backup",
                value: "Just now",
                icon: "history",
                iconTint: MorePalette.cyan,
                iconBackground: MorePalette.cyan.withAlphaComponent(0.16),
                showsChevron: false
            ),
        ])
        contentStack.addArrangedSubview(syncSection)

        let dataSection = MoreSectionCardView(title: "Data Management")
        dataSection.setRows([
            makeRow(
                title: "Export Data",
                icon: "upload",
                iconTint: MorePalette.mint,
                iconBackground: MorePalette.mint.withAlphaComponent(0.14),
                action: { [weak self] in
                    self?.pushDataManagement()
                }
            ),
            makeRow(
                title: "Import Data",
                icon: "download",
                iconTint: MorePalette.orange,
                iconBackground: MorePalette.orange.withAlphaComponent(0.15),
                action: { [weak self] in
                    self?.pushDataManagement()
                }
            ),
        ])
        contentStack.addArrangedSubview(dataSection)

        let preferencesSection = MoreSectionCardView(title: "Preferences")
        preferencesSection.setRows([
            makeRow(
                title: "Appearance",
                value: "System",
                icon: "palette",
                iconTint: MorePalette.purple,
                iconBackground: MorePalette.purple.withAlphaComponent(0.16),
                action: { [weak self] in
                    self?.pushAppearance()
                }
            ),
            makeRow(
                title: "Notifications",
                icon: "notifications",
                iconTint: MorePalette.red,
                iconBackground: MorePalette.red.withAlphaComponent(0.16),
                action: { [weak self] in
                    self?.pushNotifications()
                }
            ),
        ])
        contentStack.addArrangedSubview(preferencesSection)

        let supportSection = MoreSectionCardView(title: "Support")
        supportSection.setRows([
            makeRow(
                title: "User Guide",
                icon: "menu_book",
                iconTint: MorePalette.teal,
                iconBackground: MorePalette.teal.withAlphaComponent(0.16),
                action: { [weak self] in
                    self?.pushUserGuide()
                }
            ),
            makeRow(
                title: "Contact Support",
                icon: "mail",
                iconTint: MorePalette.blue,
                iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                action: { [weak self] in
                    self?.pushContactSupport()
                }
            ),
            makeRow(
                title: "Rate TripFit",
                icon: "star",
                iconTint: MorePalette.yellow,
                iconBackground: MorePalette.yellow.withAlphaComponent(0.16),
                action: { [weak self] in
                    self?.pushRateTripFit()
                }
            ),
            makeRow(
                title: "About",
                icon: "info",
                iconTint: MorePalette.slate,
                iconBackground: MorePalette.slate.withAlphaComponent(0.16),
                action: { [weak self] in
                    self?.pushAbout()
                }
            ),
        ])
        contentStack.addArrangedSubview(supportSection)

        let advancedSection = MoreSectionCardView(title: "Advanced")
        advancedSection.setRows([
            makeRow(
                title: "Developer Options",
                icon: "build",
                iconTint: .white,
                iconBackground: MorePalette.slate,
                action: { [weak self] in
                    self?.pushDeveloper()
                }
            ),
        ])
        contentStack.addArrangedSubview(advancedSection)

        let footerStack = UIStackView()
        footerStack.axis = .vertical
        footerStack.spacing = 2
        footerStack.alignment = .center
        footerStack.layoutMargins = UIEdgeInsets(top: 6, left: 0, bottom: 4, right: 0)
        footerStack.isLayoutMarginsRelativeArrangement = true

        let versionLabel = UILabel()
        versionLabel.font = TFTypography.footnote.withSize(12)
        versionLabel.textColor = MorePalette.subtitle
        versionLabel.text = "TripFit \(TFAppInfo.shortVersionDescription)"

        let creditLabel = UILabel()
        creditLabel.font = TFTypography.footnote.withSize(10)
        creditLabel.textColor = MorePalette.subtitle.withAlphaComponent(0.75)
        creditLabel.text = "Made with ❤️ for travelers"

        footerStack.addArrangedSubview(versionLabel)
        footerStack.addArrangedSubview(creditLabel)
        contentStack.addArrangedSubview(footerStack)
    }

    private func makeProfileCard() -> UIView {
        let card = UIView()
        card.backgroundColor = MorePalette.cardBackground
        card.layer.cornerRadius = MoreMetrics.cardCorner
        card.layer.borderWidth = 1 / UIScreen.main.scale
        card.layer.borderColor = MorePalette.cardBorder.cgColor
        card.clipsToBounds = true
        card.snp.makeConstraints { make in
            make.height.equalTo(84)
        }

        let iconContainer = UIView()
        iconContainer.layer.cornerRadius = 12
        iconContainer.clipsToBounds = true
        card.addSubview(iconContainer)
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(56).priority(.high)
        }

        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(hex: 0x66B6FF).cgColor, MorePalette.blue.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0.3)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        iconContainer.layer.insertSublayer(gradient, at: 0)

        let luggageIcon = UIImageView()
        luggageIcon.tintColor = .white
        luggageIcon.contentMode = .scaleAspectFit
        luggageIcon.image = TFMaterialIcon.image(named: "luggage", pointSize: 28, weight: .regular)
        iconContainer.addSubview(luggageIcon)
        luggageIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }

        let titleLabel = UILabel()
        titleLabel.text = "TripFit"
        titleLabel.font = TFTypography.subtitle.withSize(20)
        titleLabel.textColor = TFColor.Text.primary
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Offline-first • iCloud optional"
        subtitleLabel.font = TFTypography.bodyRegular.withSize(14)
        subtitleLabel.textColor = MorePalette.subtitle
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        card.addSubview(textStack)
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.centerY.equalTo(iconContainer)
        }

        let qrButton = UIButton(type: .system)
        qrButton.tintColor = MorePalette.subtitle.withAlphaComponent(0.8)
        qrButton.backgroundColor = MorePalette.pageBackground
        qrButton.layer.cornerRadius = 16
        qrButton.setImage(TFMaterialIcon.image(named: "qr_code_2", pointSize: 18, weight: .regular), for: .normal)
        card.addSubview(qrButton)
        qrButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalTo(iconContainer)
            make.size.equalTo(32).priority(.high)
        }

        textStack.snp.makeConstraints { make in
            make.trailing.lessThanOrEqualTo(qrButton.snp.leading).offset(-10).priority(.high)
        }

        gradient.frame = CGRect(x: 0, y: 0, width: 56, height: 56)
        return card
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

    private func pushICloudSync() {
        navigationController?.pushViewController(ICloudSyncSettingsViewController(), animated: true)
    }

    private func pushDataManagement() {
        navigationController?.pushViewController(DataManagementViewController(), animated: true)
    }

    private func pushAppearance() {
        navigationController?.pushViewController(AppearanceSettingsViewController(), animated: true)
    }

    private func pushDeveloper() {
        navigationController?.pushViewController(DeveloperOptionsViewController(context: context), animated: true)
    }

    private func pushAbout() {
        navigationController?.pushViewController(AboutTripFitViewController(), animated: true)
    }

    private func pushNotifications() {
        let screen = MoreInfoViewController(
            title: "Notifications",
            leadingTint: MorePalette.red,
            hero: .init(
                icon: "notifications_active",
                iconTint: MorePalette.red,
                iconBackground: MorePalette.red.withAlphaComponent(0.16),
                title: "Manage Alerts",
                subtitle: "Choose which reminders and updates you want to receive."
            ),
            sections: [
                .init(
                    title: "Channels",
                    footer: "Quiet hours can be configured in your system settings.",
                    rows: [
                        .init(
                            title: "Trip Reminder",
                            subtitle: "24h before departure",
                            value: "On",
                            icon: "flight_takeoff",
                            iconTint: MorePalette.blue,
                            iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: "Packing Checklist",
                            subtitle: "Missing essentials",
                            value: "On",
                            icon: "inventory_2",
                            iconTint: MorePalette.teal,
                            iconBackground: MorePalette.teal.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: "Product Updates",
                            subtitle: nil,
                            value: "Off",
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
            title: "User Guide",
            leadingTint: MorePalette.teal,
            hero: .init(
                icon: "menu_book",
                iconTint: MorePalette.teal,
                iconBackground: MorePalette.teal.withAlphaComponent(0.16),
                title: "Getting Started",
                subtitle: "Follow these guides to set up wardrobe, outfits, and trips quickly."
            ),
            sections: [
                .init(
                    title: "Topics",
                    footer: "Guide contents are bundled in-app for offline access.",
                    rows: [
                        .init(
                            title: "Add Wardrobe Items",
                            subtitle: "Photo, category, season",
                            value: nil,
                            icon: "checkroom",
                            iconTint: MorePalette.pink,
                            iconBackground: MorePalette.pink.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: "Create Outfits",
                            subtitle: "Mix items and save combinations",
                            value: nil,
                            icon: "styler",
                            iconTint: MorePalette.purple,
                            iconBackground: MorePalette.purple.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: "Plan a Trip",
                            subtitle: "Dates, destination, checklist",
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
            title: "Contact Support",
            leadingTint: MorePalette.blue,
            hero: .init(
                icon: "support_agent",
                iconTint: MorePalette.blue,
                iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                title: "Need Help?",
                subtitle: "Reach us through your preferred channel. Average response time is under 24 hours."
            ),
            sections: [
                .init(
                    title: "Support Channels",
                    footer: "Include app version and device model when reporting issues.",
                    rows: [
                        .init(
                            title: "Email",
                            subtitle: "support@tripfit.app",
                            value: nil,
                            icon: "mail",
                            iconTint: MorePalette.blue,
                            iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: "FAQ",
                            subtitle: "Common troubleshooting tips",
                            value: nil,
                            icon: "help",
                            iconTint: MorePalette.teal,
                            iconBackground: MorePalette.teal.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: "Bug Report",
                            subtitle: "Attach screenshots and logs",
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
        let screen = MoreInfoViewController(
            title: "Rate TripFit",
            leadingTint: MorePalette.yellow,
            hero: .init(
                icon: "star",
                iconTint: MorePalette.yellow,
                iconBackground: MorePalette.yellow.withAlphaComponent(0.16),
                title: "Share Your Feedback",
                subtitle: "Ratings help us prioritize updates and improve your daily trip planning workflow."
            ),
            sections: [
                .init(
                    title: "Rating",
                    footer: "Thanks for helping TripFit grow.",
                    rows: [
                        .init(
                            title: "Current Satisfaction",
                            subtitle: "Based on recent usage",
                            value: "★★★★★",
                            icon: "sentiment_satisfied",
                            iconTint: MorePalette.yellow,
                            iconBackground: MorePalette.yellow.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: "Write a Review",
                            subtitle: "App Store review flow",
                            value: "Available",
                            icon: "edit_note",
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
}
