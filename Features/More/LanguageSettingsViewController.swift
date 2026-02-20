//
//  LanguageSettingsViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Core
import SnapKit
import UIKit

final class LanguageSettingsViewController: UIViewController {
    private let headerBackground = UIView()
    private let headerView = MoreDetailHeaderView(
        title: CoreStrings.Common.language,
        leadingText: CoreStrings.Common.settings,
        leadingIcon: "chevron_left",
        leadingTint: MorePalette.blue
    )
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private lazy var languageSection = MoreSectionCardView(
        title: CoreStrings.More.appLanguage,
        footer: CoreStrings.More.languageCaption
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MorePalette.pageBackground
        setupLayout()
        setupContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        applyLocalizedCopy()
        refreshLanguageRows()
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
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.text = CoreStrings.Common.language
        titleLabel.font = TFTypography.subtitle.withSize(20)
        titleLabel.textColor = TFColor.Text.primary
        contentStack.addArrangedSubview(titleLabel)

        let captionLabel = UILabel()
        captionLabel.numberOfLines = 0
        captionLabel.font = TFTypography.bodyRegular.withSize(15)
        captionLabel.textColor = MorePalette.subtitle
        captionLabel.text = CoreStrings.More.languageCaption
        contentStack.addArrangedSubview(captionLabel)

        contentStack.addArrangedSubview(languageSection)
        refreshLanguageRows()
    }

    private func refreshLanguageRows() {
        let currentLanguage = TFAppLanguage.current()
        let rows = TFAppLanguage.allCases.map { language in
            makeLanguageRow(
                language: language,
                isSelected: language == currentLanguage,
                displayLanguage: currentLanguage
            )
        }
        languageSection.setRows(rows, separatorLeading: 16)
    }

    private func makeLanguageRow(
        language: TFAppLanguage,
        isSelected: Bool,
        displayLanguage: TFAppLanguage
    ) -> MoreSettingsRowControl {
        let row = MoreSettingsRowControl(
            model: .init(
                title: language.displayName(in: displayLanguage),
                subtitle: nil,
                value: isSelected ? CoreStrings.Common.selected : nil,
                iconLigature: isSelected ? "check_circle" : "language",
                iconTintColor: isSelected ? MorePalette.blue : MorePalette.slate,
                iconBackgroundColor: isSelected
                    ? MorePalette.blue.withAlphaComponent(0.16)
                    : MorePalette.pageBackground,
                showsChevron: false
            )
        )
        row.addAction(UIAction { [weak self] _ in
            self?.selectLanguage(language)
        }, for: .touchUpInside)
        return row
    }

    private func selectLanguage(_ language: TFAppLanguage) {
        let changed = TFAppLanguageCenter.setLanguage(language)
        refreshLanguageRows()
        if changed {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func applyLocalizedCopy() {
        headerView.configure(
            title: CoreStrings.Common.language,
            leadingText: CoreStrings.Common.settings,
            leadingIcon: "chevron_left",
            leadingTint: MorePalette.blue,
            trailingText: nil
        )
    }
}
