//
//  AppearanceSettingsViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Core
import SnapKit
import UIKit

final class AppearanceSettingsViewController: UIViewController {
    private let headerBackground = UIView()
    private let headerView = MoreDetailHeaderView(
        title: "Appearance",
        leadingText: nil,
        leadingIcon: "arrow_back_ios_new",
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
            make.top.equalTo(scrollView.contentLayoutGuide.snp.top).offset(16)
            make.leading.equalTo(scrollView.frameLayoutGuide.snp.leading).offset(MoreMetrics.horizontalInset)
            make.trailing.equalTo(scrollView.frameLayoutGuide.snp.trailing).inset(MoreMetrics.horizontalInset)
            make.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom).inset(120)
        }
    }

    private func setupContent() {
        contentStack.addArrangedSubview(makeSectionTitle("Preview"))
        contentStack.addArrangedSubview(makePreviewCard())

        contentStack.addArrangedSubview(makeSectionTitle("Accent Color"))
        contentStack.addArrangedSubview(makeAccentCard())

        contentStack.addArrangedSubview(makeSectionTitle("Theme"))
        contentStack.addArrangedSubview(makeThemeCard())

        contentStack.addArrangedSubview(makeSectionTitle("Experience"))
        contentStack.addArrangedSubview(makeExperienceCard())

        let footerLabel = UILabel()
        footerLabel.numberOfLines = 0
        footerLabel.font = TFTypography.footnote.withSize(13)
        footerLabel.textColor = MorePalette.subtitle
        footerLabel.text = "Turn off animations if you prefer a static interface or want to save battery life."
        contentStack.addArrangedSubview(footerLabel)
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = TFTypography.caption.withSize(12)
        label.textColor = UIColor(hex: 0x966A80)
        return label
    }

    private func makePreviewCard() -> UIView {
        let card = makeCardContainer()
        card.snp.makeConstraints { make in
            make.height.equalTo(164)
        }

        let decoCircle = UIView()
        decoCircle.backgroundColor = MorePalette.pink.withAlphaComponent(0.08)
        decoCircle.layer.cornerRadius = 56
        card.addSubview(decoCircle)
        decoCircle.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(-24)
            make.size.equalTo(112)
        }

        let iconCircle = UIView()
        iconCircle.backgroundColor = MorePalette.pageBackground
        iconCircle.layer.cornerRadius = 20
        card.addSubview(iconCircle)
        iconCircle.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(18)
            make.size.equalTo(40)
        }

        let iconView = UIImageView()
        iconView.tintColor = MorePalette.pink
        iconView.image = TFMaterialIcon.image(named: "palette", pointSize: 20, weight: .regular)
        iconCircle.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }

        let titleLabel = UILabel()
        titleLabel.text = "Theme Preview"
        titleLabel.font = TFTypography.subtitle.withSize(17)
        titleLabel.textColor = TFColor.Text.primary

        let subtitleLabel = UILabel()
        subtitleLabel.text = "How your app looks"
        subtitleLabel.font = TFTypography.bodyRegular.withSize(16)
        subtitleLabel.textColor = UIColor(hex: 0x966A80)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 1
        card.addSubview(textStack)
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconCircle.snp.trailing).offset(12)
            make.centerY.equalTo(iconCircle)
        }

        let buttonsRow = UIStackView()
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 12
        buttonsRow.alignment = .center
        card.addSubview(buttonsRow)
        buttonsRow.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }

        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save Changes", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = TFTypography.headline.withSize(17)
        saveButton.backgroundColor = MorePalette.pink
        saveButton.layer.cornerRadius = 14
        saveButton.layer.shadowColor = MorePalette.pink.cgColor
        saveButton.layer.shadowOpacity = 0.28
        saveButton.layer.shadowRadius = 8
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        saveButton.contentEdgeInsets = UIEdgeInsets(top: 9, left: 18, bottom: 9, right: 18)
        buttonsRow.addArrangedSubview(saveButton)

        let chipButton = UIButton(type: .system)
        chipButton.setTitle("✓  Active Chip", for: .normal)
        chipButton.setTitleColor(MorePalette.pink, for: .normal)
        chipButton.titleLabel?.font = TFTypography.bodyRegular.withSize(16)
        chipButton.backgroundColor = MorePalette.pink.withAlphaComponent(0.12)
        chipButton.layer.cornerRadius = 14
        chipButton.layer.borderWidth = 1
        chipButton.layer.borderColor = MorePalette.pink.withAlphaComponent(0.26).cgColor
        chipButton.contentEdgeInsets = UIEdgeInsets(top: 9, left: 18, bottom: 9, right: 18)
        buttonsRow.addArrangedSubview(chipButton)

        return card
    }

    private func makeAccentCard() -> UIView {
        let card = makeCardContainer()
        card.snp.makeConstraints { make in
            make.height.equalTo(128)
        }

        let colors: [(String, UIColor, Bool)] = [
            ("Pink", UIColor(hex: 0xFF5DA2), true),
            ("Sky", UIColor(hex: 0x58C4FF), false),
            ("Purple", UIColor(hex: 0xB28DFF), false),
        ]

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        card.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        for item in colors {
            let option = makeColorOption(name: item.0, color: item.1, isSelected: item.2)
            stack.addArrangedSubview(option)
        }

        let addOption = makeAddColorOption()
        stack.addArrangedSubview(addOption)

        return card
    }

    private func makeThemeCard() -> UIView {
        let card = makeCardContainer()
        card.snp.makeConstraints { make in
            make.height.equalTo(74)
        }

        let segmentedBackground = UIView()
        segmentedBackground.backgroundColor = MorePalette.pageBackground
        segmentedBackground.layer.cornerRadius = 20
        card.addSubview(segmentedBackground)
        segmentedBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 4
        segmentedBackground.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }

        stack.addArrangedSubview(makeThemeItem(icon: "settings_brightness", text: "System", isActive: false))
        stack.addArrangedSubview(makeThemeItem(icon: "light_mode", text: "Light", isActive: true))
        stack.addArrangedSubview(makeThemeItem(icon: "dark_mode", text: "Dark", isActive: false))
        return card
    }

    private func makeExperienceCard() -> UIView {
        let card = makeCardContainer()

        let firstRow = MoreToggleRowView(
            title: "Haptic Feedback",
            iconLigature: "vibration",
            iconTintColor: MorePalette.pink,
            iconBackgroundColor: MorePalette.pageBackground,
            isOn: false
        )
        card.addSubview(firstRow)
        firstRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
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
            title: "Reduce Motion",
            iconLigature: "animation",
            iconTintColor: UIColor(hex: 0x966A80),
            iconBackgroundColor: MorePalette.pageBackground,
            isOn: false
        )
        card.addSubview(secondRow)
        secondRow.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        return card
    }

    private func makeCardContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = MorePalette.cardBackground
        view.layer.cornerRadius = 22
        view.layer.borderWidth = 1 / UIScreen.main.scale
        view.layer.borderColor = MorePalette.cardBorder.cgColor
        view.clipsToBounds = true
        return view
    }

    private func makeColorOption(name: String, color: UIColor, isSelected: Bool) -> UIView {
        let container = UIView()

        let colorView = UIView()
        colorView.backgroundColor = color
        colorView.layer.cornerRadius = 22
        colorView.layer.borderWidth = 4
        colorView.layer.borderColor = isSelected ? color.withAlphaComponent(0.28).cgColor : UIColor.clear.cgColor
        container.addSubview(colorView)
        colorView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(44)
        }

        let label = UILabel()
        label.text = name
        label.font = TFTypography.footnote.withSize(13)
        label.textColor = UIColor(hex: 0x966A80)
        label.textAlignment = .center
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(colorView.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }

        return container
    }

    private func makeAddColorOption() -> UIView {
        let container = UIView()

        let circle = UIView()
        circle.layer.cornerRadius = 22
        circle.layer.borderWidth = 1
        circle.layer.borderColor = UIColor(hex: 0xCDAEBE).cgColor
        circle.backgroundColor = MorePalette.pageBackground
        container.addSubview(circle)
        circle.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(44)
        }

        let iconView = UIImageView()
        iconView.tintColor = UIColor(hex: 0x966A80)
        iconView.image = TFMaterialIcon.image(named: "add", pointSize: 18, weight: .regular)
        circle.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }

        return container
    }

    private func makeThemeItem(icon: String, text: String, isActive: Bool) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = 14
        container.backgroundColor = isActive ? MorePalette.cardBackground : .clear
        if isActive {
            container.layer.borderWidth = 1 / UIScreen.main.scale
            container.layer.borderColor = MorePalette.cardBorder.cgColor
        }

        let iconView = UIImageView()
        iconView.tintColor = isActive ? MorePalette.pink : UIColor(hex: 0x966A80)
        iconView.image = TFMaterialIcon.image(named: icon, pointSize: 16, weight: .regular)
        container.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        let label = UILabel()
        label.text = text
        label.font = TFTypography.headline.withSize(16)
        label.textColor = isActive ? MorePalette.pink : UIColor(hex: 0x966A80)
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(4)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        return container
    }
}
