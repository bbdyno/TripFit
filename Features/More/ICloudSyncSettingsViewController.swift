//
//  ICloudSyncSettingsViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Core
import SnapKit
import UIKit

final class ICloudSyncSettingsViewController: UIViewController {
    private let headerBackground = UIView()
    private let headerView = MoreDetailHeaderView(
        title: "iCloud Sync",
        leadingText: "Settings",
        leadingIcon: "chevron_left",
        leadingTint: MorePalette.blue
    )
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let syncNowButton = UIButton(type: .system)
    private let syncNowGradient = CAGradientLayer()

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        syncNowGradient.frame = syncNowButton.bounds
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
            self?.navigationController?.popViewController(animated: true)
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
            make.top.equalTo(scrollView.contentLayoutGuide.snp.top).offset(20)
            make.leading.equalTo(scrollView.frameLayoutGuide.snp.leading).offset(MoreMetrics.horizontalInset)
            make.trailing.equalTo(scrollView.frameLayoutGuide.snp.trailing).inset(MoreMetrics.horizontalInset)
            make.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom).inset(120)
        }
    }

    private func setupContent() {
        contentStack.addArrangedSubview(makeMasterToggleCard())
        contentStack.addArrangedSubview(makeSyncStatusCard())
        contentStack.addArrangedSubview(makeOptionsCard())
        contentStack.addArrangedSubview(makeSyncNowButton())
        contentStack.addArrangedSubview(makeFooterLabel())
    }

    private func makeMasterToggleCard() -> UIView {
        let card = makeCardContainer()

        let iconCircle = UIView()
        iconCircle.backgroundColor = MorePalette.blue.withAlphaComponent(0.14)
        iconCircle.layer.cornerRadius = 20
        card.addSubview(iconCircle)
        iconCircle.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }

        let iconView = UIImageView()
        iconView.tintColor = MorePalette.blue
        iconView.image = TFMaterialIcon.image(named: "cloud_sync", pointSize: 22, weight: .regular)
        iconCircle.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }

        let titleLabel = UILabel()
        titleLabel.text = "Sync with iCloud"
        titleLabel.font = TFTypography.headline.withSize(17)
        titleLabel.textColor = TFColor.Text.primary

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Keep your wardrobe & trips backed up."
        subtitleLabel.font = TFTypography.footnote.withSize(13)
        subtitleLabel.textColor = MorePalette.subtitle

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 1
        card.addSubview(textStack)
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconCircle.snp.trailing).offset(12)
            make.centerY.equalTo(iconCircle)
        }

        let toggle = UISwitch()
        toggle.onTintColor = MorePalette.blue
        toggle.isOn = true
        toggle.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        card.addSubview(toggle)
        toggle.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(textStack.snp.trailing).offset(10)
        }

        card.snp.makeConstraints { make in
            make.height.equalTo(78)
        }
        return card
    }

    private func makeSyncStatusCard() -> UIView {
        let card = makeCardContainer()

        let sectionTitle = makeInnerSectionTitle("Sync Status")
        card.addSubview(sectionTitle)
        sectionTitle.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(42)
        }

        let accountRow = UIView()
        card.addSubview(accountRow)
        accountRow.snp.makeConstraints { make in
            make.top.equalTo(sectionTitle.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(58)
        }

        let avatarView = UIView()
        avatarView.backgroundColor = UIColor(hex: 0x6AA6FF)
        avatarView.layer.cornerRadius = 18
        accountRow.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }

        let avatarLabel = UILabel()
        avatarLabel.text = "JD"
        avatarLabel.font = TFTypography.caption.withSize(14)
        avatarLabel.textColor = .white
        avatarView.addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let emailLabel = UILabel()
        emailLabel.text = "user@icloud.com"
        emailLabel.font = TFTypography.headline.withSize(17)
        emailLabel.textColor = TFColor.Text.primary

        let storageLabel = UILabel()
        storageLabel.text = "iCloud Drive • 15GB Available"
        storageLabel.font = TFTypography.footnote.withSize(13)
        storageLabel.textColor = MorePalette.subtitle

        let accountTextStack = UIStackView(arrangedSubviews: [emailLabel, storageLabel])
        accountTextStack.axis = .vertical
        accountTextStack.spacing = 1
        accountRow.addSubview(accountTextStack)
        accountTextStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }

        let statusIcon = UIImageView()
        statusIcon.tintColor = UIColor(hex: 0x27C16E)
        statusIcon.image = TFMaterialIcon.image(named: "check_circle", pointSize: 20, weight: .regular)
        accountRow.addSubview(statusIcon)
        statusIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(accountTextStack.snp.trailing).offset(8)
            make.size.equalTo(20)
        }

        let gridStack = UIStackView()
        gridStack.axis = .horizontal
        gridStack.spacing = 10
        gridStack.distribution = .fillEqually
        card.addSubview(gridStack)
        gridStack.snp.makeConstraints { make in
            make.top.equalTo(accountRow.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().inset(14)
            make.height.equalTo(76)
        }

        gridStack.addArrangedSubview(
            makeStatusBox(title: "Status", value: "Up to date", dotColor: UIColor(hex: 0x27C16E))
        )
        gridStack.addArrangedSubview(
            makeStatusBox(title: "Last Sync", value: "Just now", dotColor: nil)
        )

        return card
    }

    private func makeOptionsCard() -> UIView {
        let card = makeCardContainer()

        let sectionTitle = makeInnerSectionTitle("Options")
        card.addSubview(sectionTitle)
        sectionTitle.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(42)
        }

        let firstRow = MoreToggleRowView(
            title: "Include Wardrobe Photos",
            iconLigature: nil,
            isOn: true
        )
        card.addSubview(firstRow)
        firstRow.snp.makeConstraints { make in
            make.top.equalTo(sectionTitle.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }

        let separator = UIView()
        separator.backgroundColor = MorePalette.separator
        card.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview()
            make.top.equalTo(firstRow.snp.bottom)
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        let secondRow = MoreToggleRowView(
            title: "Sync Settings & Preferences",
            iconLigature: nil,
            isOn: true
        )
        card.addSubview(secondRow)
        secondRow.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        return card
    }

    private func makeSyncNowButton() -> UIView {
        syncNowButton.layer.cornerRadius = 12
        syncNowButton.clipsToBounds = true
        syncNowButton.setTitle("Sync Now", for: .normal)
        syncNowButton.setTitleColor(.white, for: .normal)
        syncNowButton.titleLabel?.font = TFTypography.button.withSize(16)
        syncNowButton.layer.insertSublayer(syncNowGradient, at: 0)
        syncNowGradient.colors = [
            UIColor(hex: 0x2A96EA).cgColor,
            UIColor(hex: 0x4BB2F0).cgColor,
        ]
        syncNowGradient.startPoint = CGPoint(x: 0, y: 0.5)
        syncNowGradient.endPoint = CGPoint(x: 1, y: 0.5)
        syncNowButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        return syncNowButton
    }

    private func makeFooterLabel() -> UIView {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = TFTypography.footnote.withSize(13)
        label.textColor = MorePalette.subtitle
        label.text = "TripFit is offline-first. Your data is stored locally and synced to iCloud when a connection is available to keep your devices in harmony. Privacy Policy"

        let text = label.text ?? ""
        let attributed = NSMutableAttributedString(string: text)
        if let range = text.range(of: "Privacy Policy") {
            let nsRange = NSRange(range, in: text)
            attributed.addAttribute(.foregroundColor, value: MorePalette.blue, range: nsRange)
        }
        label.attributedText = attributed
        return label
    }

    private func makeCardContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = MorePalette.cardBackground
        view.layer.cornerRadius = MoreMetrics.cardCorner
        view.layer.borderWidth = 1 / UIScreen.main.scale
        view.layer.borderColor = MorePalette.cardBorder.cgColor
        view.clipsToBounds = true
        return view
    }

    private func makeInnerSectionTitle(_ text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = MorePalette.pageBackground.withAlphaComponent(0.45)

        let label = UILabel()
        label.text = text.uppercased()
        label.font = TFTypography.caption.withSize(12)
        label.textColor = MorePalette.sectionTitle
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
        return container
    }

    private func makeStatusBox(title: String, value: String, dotColor: UIColor?) -> UIView {
        let box = UIView()
        box.backgroundColor = MorePalette.pageBackground
        box.layer.cornerRadius = 8

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = TFTypography.footnote.withSize(12)
        titleLabel.textColor = MorePalette.subtitle
        box.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(10)
        }

        let valueLabel = UILabel()
        valueLabel.font = TFTypography.headline.withSize(17)
        valueLabel.textColor = TFColor.Text.primary
        if let dotColor {
            let attributed = NSMutableAttributedString(string: "● \(value)")
            attributed.addAttributes([
                .foregroundColor: dotColor,
                .font: TFTypography.headline.withSize(16),
            ], range: NSRange(location: 0, length: 1))
            attributed.addAttributes([
                .foregroundColor: TFColor.Text.primary,
                .font: TFTypography.headline.withSize(16),
            ], range: NSRange(location: 1, length: attributed.length - 1))
            valueLabel.attributedText = attributed
        } else {
            valueLabel.text = value
        }
        box.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(10)
        }

        return box
    }
}
