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
                iconBackground: MorePalette.pink.withAlphaComponent(0.14)
            ),
            makeRow(
                title: "Import Data",
                icon: "download",
                iconTint: MorePalette.pink,
                iconBackground: MorePalette.pink.withAlphaComponent(0.14)
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
                titleColor: UIColor(hex: 0xF45D5D)
            ),
            makeRow(
                title: "Reset iCloud Data",
                icon: "cloud_off",
                iconTint: UIColor(hex: 0xF45D5D),
                iconBackground: UIColor(hex: 0xF45D5D).withAlphaComponent(0.14),
                titleColor: UIColor(hex: 0xF45D5D)
            ),
        ])
        contentStack.addArrangedSubview(dangerSection)
    }

    private func makeRow(
        title: String,
        icon: String,
        iconTint: UIColor,
        iconBackground: UIColor,
        titleColor: UIColor = TFColor.Text.primary
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
        row.addAction(UIAction { [weak self] _ in
            self?.showNotConnectedAlert(title: title)
        }, for: .touchUpInside)
        return row
    }

    private func showNotConnectedAlert(title: String) {
        let alert = UIAlertController(
            title: title,
            message: "Action wiring can be connected to real logic in the next step.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
