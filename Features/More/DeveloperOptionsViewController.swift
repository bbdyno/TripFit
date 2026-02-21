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
        title: CoreStrings.Dev.title,
        leadingText: CoreStrings.Common.back,
        leadingIcon: "arrow_back_ios_new",
        leadingTint: MorePalette.blue,
        trailingText: CoreStrings.Common.done
    )
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private lazy var selfTestRunner = DeveloperSelfTestRunner(context: context)
    private var selfTestTask: Task<Void, Never>?
    private weak var selfTestLoadingAlert: UIAlertController?

    init(context: ModelContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        selfTestTask?.cancel()
    }

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

        let qualitySection = MoreSectionCardView(
            title: localized("통합 기능 테스트", "Full Feature Testing"),
            footer: localized(
                "앱 핵심 기능과 알림 동작을 자동 점검합니다.",
                "Runs automated checks for core app features, including notifications."
            )
        )
        qualitySection.setRows([
            makeActionRow(
                title: localized("전체 기능 점검 실행", "Run Full Feature Check"),
                icon: "fact_check",
                tint: UIColor(hex: 0x27C16E),
                bg: UIColor(hex: 0x27C16E).withAlphaComponent(0.18),
                action: { [weak self] in
                    self?.runFullFeatureSelfTest()
                }
            ),
        ])
        contentStack.addArrangedSubview(qualitySection)

        let dataSection = MoreSectionCardView(
            title: CoreStrings.Dev.dataManagement,
            footer: CoreStrings.Dev.dataFooter
        )
        dataSection.setRows([
            makeActionRow(
                title: CoreStrings.Dev.seedWardrobe,
                icon: "checkroom",
                tint: UIColor(hex: 0x5A8FEF),
                bg: UIColor(hex: 0x5A8FEF).withAlphaComponent(0.18)
            ),
            makeActionRow(
                title: CoreStrings.Dev.seedTrip,
                icon: "flight_takeoff",
                tint: UIColor(hex: 0x24BD84),
                bg: UIColor(hex: 0x24BD84).withAlphaComponent(0.18)
            ),
        ])
        contentStack.addArrangedSubview(dataSection)

        let syncSection = UIView()
        syncSection.addSubview(makeSectionTitle(CoreStrings.Dev.syncTesting))
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
            title: CoreStrings.Dev.simulateConflict,
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
            title: CoreStrings.Dev.logSyncEvents,
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
        uiSection.addSubview(makeSectionTitle(CoreStrings.Dev.uiDebugging))
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
            title: CoreStrings.Dev.showOverlay,
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
            title: CoreStrings.Dev.forceCrash,
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
            title: CoreStrings.Dev.dangerZone,
            footer: CoreStrings.Dev.actionsFooter
        )
        dangerSection.setTitleColor(UIColor(hex: 0xFF5252))
        dangerSection.setRows([
            makeActionRow(
                title: CoreStrings.Dev.resetCache,
                icon: "dangerous",
                tint: UIColor(hex: 0xFF5252),
                bg: UIColor(hex: 0xFF5252).withAlphaComponent(0.18),
                titleColor: UIColor(hex: 0xFF5252),
                showsChevron: false
            ),
            makeActionRow(
                title: CoreStrings.Dev.clearAllData,
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

        let title = makeSectionTitle(CoreStrings.Dev.buildInfo)
        container.addSubview(title)
        title.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        let versionRow = makeInfoRow(left: CoreStrings.Dev.version, right: TFAppInfo.shortVersionDescription)
        container.addSubview(versionRow)
        versionRow.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(2)
        }

        let envRow = makeInfoRow(
            left: CoreStrings.Dev.environment,
            right: CoreStrings.Dev.staging,
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
        showsChevron: Bool = true,
        action: (() -> Void)? = nil
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
            if let action {
                action()
            } else {
                self?.pushDeveloperAction(title: title, tint: tint)
            }
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

    private func runFullFeatureSelfTest() {
        guard selfTestTask == nil else {
            let alert = UIAlertController(
                title: localized("테스트 진행 중", "Test In Progress"),
                message: localized(
                    "이미 전체 기능 점검을 실행 중입니다.",
                    "A full feature check is already running."
                ),
                preferredStyle: .alert
            )
            alert.overrideUserInterfaceStyle = .dark
            alert.addAction(UIAlertAction(title: CoreStrings.Common.ok, style: .default))
            present(alert, animated: true)
            return
        }

        let loadingAlert = makeLoadingAlert(
            title: localized("전체 기능 점검 실행 중", "Running Full Feature Check"),
            message: localized(
                "데이터/유틸/알림 검증을 순차 실행하고 있습니다.",
                "Validating data, utilities, and notification flows."
            )
        )
        selfTestLoadingAlert = loadingAlert
        present(loadingAlert, animated: true)

        selfTestTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let report = await self.selfTestRunner.runAllChecks()
            guard !Task.isCancelled else { return }

            self.selfTestLoadingAlert?.dismiss(animated: true) { [weak self] in
                self?.presentSelfTestReport(report)
            }
            self.selfTestLoadingAlert = nil
            self.selfTestTask = nil
        }
    }

    private func makeLoadingAlert(title: String, message: String) -> UIAlertController {
        let alert = UIAlertController(
            title: title,
            message: "\(message)\n\n",
            preferredStyle: .alert
        )
        alert.overrideUserInterfaceStyle = .dark
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        alert.view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            spinner.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -20),
        ])
        return alert
    }

    private func presentSelfTestReport(_ report: DeveloperSelfTestRunner.Report) {
        let hasWarning = report.warningCount > 0
        let hasFailure = report.hasBlockingFailure

        let heroTint: UIColor
        let heroIcon: String
        let heroTitle: String

        if hasFailure {
            heroTint = UIColor(hex: 0xFF5B5B)
            heroIcon = "error"
            heroTitle = localized("실패 항목이 있습니다", "Blocking Failures Detected")
        } else if hasWarning {
            heroTint = UIColor(hex: 0xF2B742)
            heroIcon = "warning"
            heroTitle = localized("경고와 함께 완료", "Completed With Warnings")
        } else {
            heroTint = UIColor(hex: 0x27C16E)
            heroIcon = "verified"
            heroTitle = localized("전체 기능 점검 통과", "All Checks Passed")
        }

        let summarySubtitle = localized(
            "성공 \(report.passedCount) · 경고 \(report.warningCount) · 실패 \(report.failedCount)",
            "Pass \(report.passedCount) · Warn \(report.warningCount) · Fail \(report.failedCount)"
        )

        let summaryRows: [MoreInfoViewController.Row] = [
            .init(
                title: localized("총 검사 항목", "Total Checks"),
                subtitle: nil,
                value: "\(report.checks.count)",
                icon: "playlist_add_check_circle",
                iconTint: MorePalette.blue,
                iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                titleColor: TFColor.Text.primary
            ),
            .init(
                title: localized("실행 시간", "Duration"),
                subtitle: nil,
                value: String(format: "%.2fs", report.elapsedSeconds),
                icon: "timer",
                iconTint: MorePalette.teal,
                iconBackground: MorePalette.teal.withAlphaComponent(0.16),
                titleColor: TFColor.Text.primary
            ),
        ]

        let checkRows: [MoreInfoViewController.Row] = report.checks.map { check in
            let style = style(for: check.status)
            return .init(
                title: check.title,
                subtitle: check.detail,
                value: style.label,
                icon: style.icon,
                iconTint: style.tint,
                iconBackground: style.tint.withAlphaComponent(0.18),
                titleColor: TFColor.Text.primary
            )
        }

        let endedAt = DateFormatter.localizedString(
            from: report.finishedAt,
            dateStyle: .medium,
            timeStyle: .medium
        )

        let screen = MoreInfoViewController(
            title: localized("기능 점검 결과", "Feature Check Report"),
            leadingText: CoreStrings.Common.back,
            leadingIcon: "arrow_back_ios_new",
            leadingTint: MorePalette.blue,
            hero: .init(
                icon: heroIcon,
                iconTint: heroTint,
                iconBackground: heroTint.withAlphaComponent(0.18),
                title: heroTitle,
                subtitle: summarySubtitle
            ),
            sections: [
                .init(
                    title: localized("요약", "Summary"),
                    footer: localized("마지막 실행: \(endedAt)", "Last run: \(endedAt)"),
                    rows: summaryRows
                ),
                .init(
                    title: localized("검사 항목", "Checks"),
                    footer: localized(
                        "알림 권한이 거부된 경우 알림 검사는 경고로 표시됩니다.",
                        "Notification check is marked warning when permission is denied."
                    ),
                    rows: checkRows
                ),
            ]
        )
        screen.overrideUserInterfaceStyle = .dark
        navigationController?.pushViewController(screen, animated: true)
    }

    private func style(for status: DeveloperSelfTestRunner.Status) -> (icon: String, tint: UIColor, label: String) {
        switch status {
        case .passed:
            return ("check_circle", UIColor(hex: 0x27C16E), "PASS")
        case .warning:
            return ("warning", UIColor(hex: 0xF2B742), "WARN")
        case .failed:
            return ("error", UIColor(hex: 0xFF5B5B), "FAIL")
        }
    }

    private func localized(_ ko: String, _ en: String) -> String {
        TFAppLanguage.current() == .korean ? ko : en
    }

    private func pushDeveloperAction(title: String, tint: UIColor) {
        let screen = MoreInfoViewController(
            title: title,
            leadingText: CoreStrings.Common.back,
            leadingIcon: "arrow_back_ios_new",
            leadingTint: MorePalette.blue,
            hero: .init(
                icon: "terminal",
                iconTint: tint,
                iconBackground: tint.withAlphaComponent(0.18),
                title: title,
                subtitle: CoreStrings.Dev.actionMapped
            ),
            sections: [
                .init(
                    title: CoreStrings.Dev.execution,
                    footer: CoreStrings.Dev.executionFooter,
                    rows: [
                        .init(
                            title: CoreStrings.Dev.actionType,
                            subtitle: nil,
                            value: CoreStrings.Dev.manual,
                            icon: "build",
                            iconTint: MorePalette.blue,
                            iconBackground: MorePalette.blue.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: CoreStrings.Dev.scope,
                            subtitle: nil,
                            value: CoreStrings.Dev.localDevice,
                            icon: "smartphone",
                            iconTint: MorePalette.teal,
                            iconBackground: MorePalette.teal.withAlphaComponent(0.16),
                            titleColor: TFColor.Text.primary
                        ),
                        .init(
                            title: CoreStrings.Dev.safety,
                            subtitle: nil,
                            value: CoreStrings.Dev.protected,
                            icon: "verified_user",
                            iconTint: UIColor(hex: 0x27C16E),
                            iconBackground: UIColor(hex: 0x27C16E).withAlphaComponent(0.14),
                            titleColor: TFColor.Text.primary
                        ),
                    ]
                )
            ]
        )
        screen.overrideUserInterfaceStyle = .dark
        navigationController?.pushViewController(screen, animated: true)
    }
}
