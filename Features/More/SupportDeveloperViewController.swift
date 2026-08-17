//
//  SupportDeveloperViewController.swift
//  TripFit
//

import Core
import SnapKit
import UIKit

final class SupportDeveloperViewController: UIViewController {
    private let store = TFSupportStore.shared
    private let headerBackground = UIView()
    private lazy var headerView = MoreDetailHeaderView(
        title: CoreStrings.Support.title,
        leadingText: CoreStrings.Common.back,
        leadingIcon: "chevron_left",
        leadingTint: MorePalette.pink
    )
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private var purchaseButtons: [TFSupportProductID: UIButton] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MorePalette.pageBackground
        setupLayout()
        setupContent()
        loadOfferings()
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
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(56)
        }
        headerView.onLeadingTap = { [weak self] in self?.morePopOrDismiss() }

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerBackground.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentStack.axis = .vertical
        contentStack.spacing = 14
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(20)
            make.leading.trailing.equalTo(scrollView.frameLayoutGuide).inset(MoreMetrics.horizontalInset)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(28)
        }
    }

    private func setupContent() {
        let hero = TFCardView(style: .flat)
        hero.backgroundColor = TFColor.Brand.primary.withAlphaComponent(0.08)
        hero.layer.cornerRadius = 20

        let icon = UIImageView(image: TFMaterialIcon.image(named: "volunteer_activism", pointSize: 30, weight: .semibold))
        icon.tintColor = MorePalette.pink
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = CoreStrings.Support.title
        title.font = TFTypography.title
        title.textColor = TFColor.Text.primary
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = CoreStrings.Support.subtitle
        subtitle.font = TFTypography.bodyRegular
        subtitle.textColor = TFColor.Text.secondary
        subtitle.numberOfLines = 0

        let heroStack = UIStackView(arrangedSubviews: [icon, title, subtitle])
        heroStack.axis = .vertical
        heroStack.spacing = 10
        hero.addSubview(heroStack)
        heroStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(18) }
        icon.snp.makeConstraints { $0.size.equalTo(38) }
        contentStack.addArrangedSubview(hero)

        contentStack.addArrangedSubview(makeSupportCard(
            id: .coffee,
            title: CoreStrings.Support.Small.title,
            subtitle: CoreStrings.Support.Small.subtitle,
            icon: "local_cafe",
            color: MorePalette.orange
        ))
        contentStack.addArrangedSubview(makeSupportCard(
            id: .chicken,
            title: CoreStrings.Support.Large.title,
            subtitle: CoreStrings.Support.Large.subtitle,
            icon: "restaurant",
            color: MorePalette.purple
        ))

        let statusStack = UIStackView(arrangedSubviews: [loadingIndicator, statusLabel, retryButton])
        statusStack.axis = .vertical
        statusStack.alignment = .center
        statusStack.spacing = 8
        statusLabel.font = TFTypography.footnote
        statusLabel.textColor = TFColor.Text.secondary
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        retryButton.setTitle(CoreStrings.Support.retry, for: .normal)
        retryButton.addAction(UIAction { [weak self] _ in self?.loadOfferings() }, for: .touchUpInside)
        retryButton.isHidden = true
        contentStack.addArrangedSubview(statusStack)

        let note = UILabel()
        note.text = "\(CoreStrings.Support.optionalNote)\n\n\(CoreStrings.Support.appleNotice)"
        note.font = TFTypography.footnote.withSize(11)
        note.textColor = TFColor.Text.tertiary
        note.numberOfLines = 0
        note.textAlignment = .center
        contentStack.addArrangedSubview(note)
    }

    private func makeSupportCard(
        id: TFSupportProductID,
        title: String,
        subtitle: String,
        icon: String,
        color: UIColor
    ) -> UIView {
        let card = TFCardView(style: .outlined)
        card.layer.cornerRadius = 18

        let iconView = UIImageView(image: TFMaterialIcon.image(named: icon, pointSize: 24, weight: .semibold))
        iconView.tintColor = color
        iconView.contentMode = .center
        iconView.backgroundColor = color.withAlphaComponent(0.14)
        iconView.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = TFTypography.headline
        titleLabel.textColor = TFColor.Text.primary

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = TFTypography.footnote
        subtitleLabel.textColor = TFColor.Text.secondary
        subtitleLabel.numberOfLines = 0

        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 3

        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "—"
        configuration.baseBackgroundColor = color
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 13, bottom: 8, trailing: 13)
        button.configuration = configuration
        button.isEnabled = false
        button.addAction(UIAction { [weak self] _ in self?.purchase(id) }, for: .touchUpInside)
        purchaseButtons[id] = button

        let row = UIStackView(arrangedSubviews: [iconView, labels, button])
        row.alignment = .center
        row.spacing = 12
        card.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
        iconView.snp.makeConstraints { $0.size.equalTo(48) }
        button.snp.makeConstraints { $0.width.greaterThanOrEqualTo(82) }
        return card
    }

    private func loadOfferings() {
#if DEBUG
        if ProcessInfo.processInfo.environment["TRIPFIT_SCREENSHOT_MODE"] == "1" {
            let prices = screenshotPrices()
            purchaseButtons[.coffee]?.configuration?.title = prices.coffee
            purchaseButtons[.chicken]?.configuration?.title = prices.chicken
            purchaseButtons.values.forEach { $0.isEnabled = true }
            statusLabel.text = nil
            retryButton.isHidden = true
            loadingIndicator.stopAnimating()
            return
        }
#endif
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let offerings = try await store.loadOfferings()
                guard offerings.count == TFSupportProductID.allCases.count else {
                    throw TFSupportStoreError.productUnavailable
                }
                for offering in offerings {
                    purchaseButtons[offering.id]?.configuration?.title = offering.displayPrice
                    purchaseButtons[offering.id]?.isEnabled = true
                }
                statusLabel.text = nil
                retryButton.isHidden = true
                loadingIndicator.stopAnimating()
            } catch {
                setLoading(false)
                statusLabel.text = CoreStrings.Support.unavailable
                retryButton.isHidden = false
            }
        }
    }

#if DEBUG
    private func screenshotPrices() -> (coffee: String, chicken: String) {
        if TFAppLanguage.current() == .korean {
            return ("₩4,400", "₩29,000")
        }
        return ("$2.99", "$17.99")
    }
#endif

    private func setLoading(_ loading: Bool) {
        purchaseButtons.values.forEach { $0.isEnabled = false }
        retryButton.isHidden = true
        statusLabel.text = loading ? CoreStrings.Support.loading : nil
        loading ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
    }

    private func purchase(_ id: TFSupportProductID) {
        setLoading(true)
        statusLabel.text = CoreStrings.Support.purchasing
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await store.purchase(id)
                await reloadAfterPurchase()
                switch result {
                case .purchased:
                    showAlert(title: CoreStrings.Support.thankYouTitle, message: CoreStrings.Support.thankYouMessage)
                case .pending:
                    showAlert(title: CoreStrings.Support.pendingTitle, message: CoreStrings.Support.pendingMessage)
                case .cancelled:
                    break
                }
            } catch {
                await reloadAfterPurchase()
                showAlert(title: CoreStrings.Support.errorTitle, message: CoreStrings.Support.errorMessage)
            }
        }
    }

    private func reloadAfterPurchase() async {
        do {
            let offerings = try await store.loadOfferings()
            for offering in offerings {
                purchaseButtons[offering.id]?.configuration?.title = offering.displayPrice
                purchaseButtons[offering.id]?.isEnabled = true
            }
            statusLabel.text = nil
            loadingIndicator.stopAnimating()
        } catch {
            setLoading(false)
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CoreStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }
}
