//
//  MainTabBarController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import Features
import SwiftData
import UIKit

final class MainTabBarController: UITabBarController {
    private struct DockItem {
        let title: String
        let symbol: String
        let selectedSymbol: String
    }

    private let environment: AppEnvironment
    private let dockView = UIView()
    private let dockStack = UIStackView()
    private let selectionIndicator = UIView()
    private var dockButtons: [UIButton] = []
    private var dockItems: [DockItem] = []
    private var indicatorCenterConstraint: NSLayoutConstraint?
    private var isDockVisible = true

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.isHidden = true

        let home = HomeDashboardViewController(environment: environment)
        let homeVC = UINavigationController(rootViewController: home)
        let wardrobeVC = UINavigationController(
            rootViewController: WardrobeViewController(context: environment.context)
        )
        let outfitsVC = UINavigationController(
            rootViewController: OutfitsListViewController(context: environment.context)
        )
        let tripsVC = UINavigationController(
            rootViewController: TripsListViewController(
                context: environment.context,
                authService: environment.authService,
                collaborationRepository: environment.collaborationRepository,
                pendingInviteStore: environment.pendingInviteStore
            )
        )
        let controllers = [homeVC, wardrobeVC, outfitsVC, tripsVC]
        controllers.forEach {
            $0.delegate = self
            $0.additionalSafeAreaInsets.bottom = 62
        }
        viewControllers = controllers

        home.onSelectTab = { [weak self] index in
            self?.selectTab(index)
        }

        let korean = TFAppLanguage.current() == .korean
        dockItems = [
            DockItem(title: korean ? "홈" : "Home", symbol: "house", selectedSymbol: "house.fill"),
            DockItem(title: korean ? "옷장" : "Wardrobe", symbol: "tshirt", selectedSymbol: "tshirt.fill"),
            DockItem(title: korean ? "코디" : "Outfits", symbol: "sparkles", selectedSymbol: "sparkles"),
            DockItem(
                title: korean ? "여행" : "Trips",
                symbol: "suitcase.rolling",
                selectedSymbol: "suitcase.rolling.fill"
            ),
        ]
        setupDock()
        updateDockSelection()
    }

    private func setupDock() {
        dockView.translatesAutoresizingMaskIntoConstraints = false
        dockView.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.98)
        dockView.layer.borderWidth = 0
        dockView.layer.shadowColor = TFColor.Text.primary.cgColor
        dockView.layer.shadowOpacity = 0.055
        dockView.layer.shadowRadius = 12
        dockView.layer.shadowOffset = CGSize(width: 0, height: -4)
        view.addSubview(dockView)

        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.backgroundColor = TFColor.Brand.primary
        selectionIndicator.layer.cornerRadius = 1.5
        dockView.addSubview(selectionIndicator)

        dockStack.translatesAutoresizingMaskIntoConstraints = false
        dockStack.axis = .horizontal
        dockStack.distribution = .fillEqually
        dockStack.spacing = 0
        dockView.addSubview(dockStack)

        dockButtons = dockItems.enumerated().map { index, item in
            let button = UIButton(type: .system)
            button.tag = index
            button.accessibilityLabel = item.title
            button.addTarget(self, action: #selector(dockButtonTapped(_:)), for: .touchUpInside)
            dockStack.addArrangedSubview(button)
            return button
        }

        NSLayoutConstraint.activate([
            dockView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dockView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dockView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dockView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -62),

            dockStack.topAnchor.constraint(equalTo: dockView.topAnchor, constant: 8),
            dockStack.leadingAnchor.constraint(equalTo: dockView.leadingAnchor, constant: 10),
            dockStack.trailingAnchor.constraint(equalTo: dockView.trailingAnchor, constant: -10),
            dockStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),

            selectionIndicator.topAnchor.constraint(equalTo: dockView.topAnchor),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 26),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 3),
        ])
        if let firstButton = dockButtons.first {
            indicatorCenterConstraint = selectionIndicator.centerXAnchor.constraint(equalTo: firstButton.centerXAnchor)
            indicatorCenterConstraint?.isActive = true
        }
    }

    @objc private func dockButtonTapped(_ sender: UIButton) {
        guard viewControllers?.indices.contains(sender.tag) == true else { return }
        if sender.tag == selectedIndex,
           let navigationController = selectedViewController as? UINavigationController {
            navigationController.popToRootViewController(animated: true)
        }
        selectTab(sender.tag)
    }

    private func selectTab(_ index: Int) {
        guard viewControllers?.indices.contains(index) == true else { return }
        selectedIndex = index
        updateDockSelection()
        updateDockVisibility(animated: true)
    }

    private func updateDockSelection() {
        for (index, button) in dockButtons.enumerated() {
            let item = dockItems[index]
            let isSelected = index == selectedIndex
            button.isSelected = isSelected

            var configuration = UIButton.Configuration.plain()
            configuration.title = item.title
            configuration.image = UIImage(
                systemName: isSelected ? item.selectedSymbol : item.symbol,
                withConfiguration: UIImage.SymbolConfiguration(
                    pointSize: 17,
                    weight: isSelected ? .semibold : .regular
                )
            )
            configuration.imagePlacement = .top
            configuration.imagePadding = 3
            configuration.baseForegroundColor = isSelected ? TFColor.Brand.primary : TFColor.Text.secondary
            configuration.background.backgroundColor = .clear
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 6, bottom: 1, trailing: 6)
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var attributes = incoming
                attributes.font = isSelected
                    ? TFTypography.caption.withSize(10)
                    : TFTypography.footnote.withSize(10)
                return attributes
            }
            button.configuration = configuration
        }

        guard dockButtons.indices.contains(selectedIndex) else { return }
        indicatorCenterConstraint?.isActive = false
        indicatorCenterConstraint = selectionIndicator.centerXAnchor.constraint(
            equalTo: dockButtons[selectedIndex].centerXAnchor
        )
        indicatorCenterConstraint?.isActive = true
        UIView.animate(withDuration: 0.2) {
            self.dockView.layoutIfNeeded()
        }
    }

    private func updateDockVisibility(animated: Bool) {
        let shouldShow: Bool
        if let nav = selectedViewController as? UINavigationController {
            shouldShow = nav.topViewController?.hidesBottomBarWhenPushed != true
        } else {
            shouldShow = true
        }
        guard shouldShow != isDockVisible else { return }

        let changes = {
            self.dockView.alpha = shouldShow ? 1 : 0
            self.dockView.transform = shouldShow
                ? .identity
                : CGAffineTransform(translationX: 0, y: self.dockView.bounds.height)
        }
        if animated {
            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: changes
            )
        } else {
            changes()
        }
        dockView.isUserInteractionEnabled = shouldShow
        isDockVisible = shouldShow
    }
}

@MainActor
private final class HomeDashboardViewController: UIViewController {
    var onSelectTab: ((Int) -> Void)?

    private let environment: AppEnvironment
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let headlineLabel = UILabel()
    private let dateLabel = UILabel()
    private let heroView = HomeTripHeroView()
    private let readinessView = HomeReadinessView()
    private let recentScrollView = UIScrollView()
    private let recentStack = UIStackView()
    private var upcomingTrip: Trip?
    private var recentOutfits: [Outfit] = []

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = TFColor.Surface.canvas
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        refreshContent()
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 8, left: 20, bottom: 28, right: 20)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        contentStack.addArrangedSubview(makeHeader())
        contentStack.addArrangedSubview(heroView)
        heroView.heightAnchor.constraint(equalToConstant: 226).isActive = true
        heroView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(heroTapped)))

        contentStack.addArrangedSubview(makeSectionHeader(
            title: localized("준비 현황", "Readiness"),
            actionTitle: localized("여행 보기", "View trips"),
            action: #selector(openTrips)
        ))
        contentStack.setCustomSpacing(10, after: contentStack.arrangedSubviews[2])
        contentStack.addArrangedSubview(readinessView)
        readinessView.heightAnchor.constraint(equalToConstant: 142).isActive = true

        contentStack.addArrangedSubview(makeSectionHeader(
            title: localized("빠른 시작", "Quick start"),
            actionTitle: nil,
            action: nil
        ))
        contentStack.setCustomSpacing(10, after: contentStack.arrangedSubviews[4])
        let actions = makeQuickActions()
        contentStack.addArrangedSubview(actions)
        actions.heightAnchor.constraint(equalToConstant: 90).isActive = true

        contentStack.addArrangedSubview(makeSectionHeader(
            title: localized("최근 코디", "Recent looks"),
            actionTitle: localized("전체 보기", "See all"),
            action: #selector(openOutfits)
        ))
        contentStack.setCustomSpacing(10, after: contentStack.arrangedSubviews[6])
        setupRecentLooks()
        contentStack.addArrangedSubview(recentScrollView)
        recentScrollView.heightAnchor.constraint(equalToConstant: 188).isActive = true
    }

    private func makeHeader() -> UIView {
        let container = UIView()
        let brand = UILabel()
        brand.text = "TRIPFIT"
        brand.font = TFTypography.caption.withSize(12)
        brand.textColor = TFColor.Brand.primary

        headlineLabel.text = localized("여행 준비를 시작해요", "Start planning your journey")
        headlineLabel.font = TFTypography.title.withSize(24)
        headlineLabel.textColor = TFColor.Text.primary

        dateLabel.font = TFTypography.footnote.withSize(11)
        dateLabel.textColor = TFColor.Text.secondary

        let textStack = UIStackView(arrangedSubviews: [brand, headlineLabel, dateLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 2
        container.addSubview(textStack)

        let settingsButton = UIButton(type: .system)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setImage(
            UIImage(systemName: "person.crop.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)),
            for: .normal
        )
        settingsButton.tintColor = TFColor.Text.primary
        settingsButton.backgroundColor = TFColor.Surface.card
        settingsButton.layer.cornerRadius = 20
        settingsButton.layer.borderWidth = 1
        settingsButton.layer.borderColor = TFColor.Border.subtle.cgColor
        settingsButton.accessibilityLabel = localized("설정", "Settings")
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        container.addSubview(settingsButton)

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: container.topAnchor),
            textStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: settingsButton.leadingAnchor, constant: -12),
            settingsButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            settingsButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
        ])
        return container
    }

    private func makeSectionHeader(title: String, actionTitle: String?, action: Selector?) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center

        let label = UILabel()
        label.text = title
        label.font = TFTypography.subtitle.withSize(18)
        label.textColor = TFColor.Text.primary
        row.addArrangedSubview(label)
        row.addArrangedSubview(UIView())

        if let actionTitle, let action {
            let button = UIButton(type: .system)
            button.setTitle(actionTitle, for: .normal)
            button.setTitleColor(TFColor.Brand.primary, for: .normal)
            button.titleLabel?.font = TFTypography.footnote.withSize(11)
            button.addTarget(self, action: action, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        return row
    }

    private func makeQuickActions() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        let actions: [(String, String, UIColor, Selector)] = [
            (localized("옷 추가", "Add item"), "plus", TFColor.Brand.primary, #selector(addClothing)),
            (localized("코디 만들기", "Build look"), "sparkles", TFColor.Brand.accentPurple, #selector(addOutfit)),
            (localized("여행 계획", "Plan trip"), "suitcase.rolling.fill", TFColor.Brand.accentMint, #selector(addTrip)),
        ]
        for (title, symbol, color, selector) in actions {
            let button = HomeQuickActionButton(title: title, symbol: symbol, color: color)
            button.addTarget(self, action: selector, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
        return stack
    }

    private func setupRecentLooks() {
        recentScrollView.showsHorizontalScrollIndicator = false
        recentScrollView.alwaysBounceHorizontal = true
        recentScrollView.clipsToBounds = false

        recentStack.translatesAutoresizingMaskIntoConstraints = false
        recentStack.axis = .horizontal
        recentStack.spacing = 12
        recentScrollView.addSubview(recentStack)
        NSLayoutConstraint.activate([
            recentStack.topAnchor.constraint(equalTo: recentScrollView.contentLayoutGuide.topAnchor),
            recentStack.leadingAnchor.constraint(equalTo: recentScrollView.contentLayoutGuide.leadingAnchor),
            recentStack.trailingAnchor.constraint(equalTo: recentScrollView.contentLayoutGuide.trailingAnchor),
            recentStack.bottomAnchor.constraint(equalTo: recentScrollView.contentLayoutGuide.bottomAnchor),
            recentStack.heightAnchor.constraint(equalTo: recentScrollView.frameLayoutGuide.heightAnchor),
        ])
    }

    private func refreshContent() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let trips = (try? environment.context.fetch(
            FetchDescriptor<Trip>(sortBy: [SortDescriptor(\.startDate)])
        )) ?? []
        upcomingTrip = trips.first { calendar.startOfDay(for: $0.endDate) >= today }
        headlineLabel.text = upcomingTrip == nil
            ? localized("여행 준비를 시작해요", "Start planning your journey")
            : localized("여행 준비를 이어가세요", "Keep your trip moving")
        recentOutfits = Array(((try? environment.context.fetch(
            FetchDescriptor<Outfit>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        )) ?? []).prefix(3))
        let clothingCount = (try? environment.context.fetchCount(FetchDescriptor<ClothingItem>())) ?? 0
        let outfitCount = (try? environment.context.fetchCount(FetchDescriptor<Outfit>())) ?? 0

        let formatter = DateFormatter()
        formatter.locale = TFAppLanguage.current() == .korean ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US")
        formatter.dateFormat = TFAppLanguage.current() == .korean ? "M월 d일 EEEE" : "EEEE, MMM d"
        dateLabel.text = formatter.string(from: Date())

        heroView.configure(trip: upcomingTrip)
        let packingProgress: Float
        if let trip = upcomingTrip, trip.totalCount > 0 {
            packingProgress = Float(trip.packedCount) / Float(trip.totalCount)
        } else {
            packingProgress = 0
        }
        let wardrobeScore = min(Float(clothingCount) / 8, 1)
        let outfitScore = min(Float(outfitCount) / 3, 1)
        let overall = (wardrobeScore + outfitScore + packingProgress) / 3
        readinessView.configure(
            progress: overall,
            clothingCount: clothingCount,
            outfitCount: outfitCount,
            packingProgress: packingProgress
        )
        renderRecentLooks()
    }

    private func renderRecentLooks() {
        recentStack.arrangedSubviews.forEach {
            recentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if recentOutfits.isEmpty {
            let empty = HomeEmptyLookCard()
            empty.addTarget(self, action: #selector(addOutfit), for: .touchUpInside)
            recentStack.addArrangedSubview(empty)
            empty.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40).isActive = true
            return
        }

        for (index, outfit) in recentOutfits.enumerated() {
            let card = HomeLookCard(outfit: outfit)
            card.tag = index
            card.addTarget(self, action: #selector(recentLookTapped(_:)), for: .touchUpInside)
            recentStack.addArrangedSubview(card)
            card.widthAnchor.constraint(equalToConstant: 168).isActive = true
        }
    }

    @objc private func heroTapped() {
        guard let upcomingTrip else {
            onSelectTab?(3)
            return
        }
        let detail = TripDetailViewController(context: environment.context, trip: upcomingTrip)
        detail.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detail, animated: true)
    }

    @objc private func recentLookTapped(_ sender: UIControl) {
        guard recentOutfits.indices.contains(sender.tag) else { return }
        let detail = OutfitDetailViewController(context: environment.context, outfit: recentOutfits[sender.tag])
        detail.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detail, animated: true)
    }

    @objc private func settingsTapped() {
        let settings = MoreSettingsHomeViewController(
            context: environment.context,
            authService: environment.authService,
            accountDeletionService: environment.accountDeletionService
        )
        settings.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(settings, animated: true)
    }

    @objc private func addClothing() {
        presentEditor(ClothingEditViewController(context: environment.context))
    }

    @objc private func addOutfit() {
        presentEditor(OutfitEditViewController(context: environment.context))
    }

    @objc private func addTrip() {
        presentEditor(TripEditViewController(context: environment.context))
    }

    @objc private func openOutfits() { onSelectTab?(2) }
    @objc private func openTrips() { onSelectTab?(3) }

    private func presentEditor(_ controller: UIViewController) {
        let navigation = UINavigationController(rootViewController: controller)
        navigation.modalPresentationStyle = .fullScreen
        present(navigation, animated: true)
    }

    private func localized(_ korean: String, _ english: String) -> String {
        TFAppLanguage.current() == .korean ? korean : english
    }
}

private final class HomeTripHeroView: UIControl {
    private let imageView = UIImageView()
    private let gradient = CAGradientLayer()
    private let badgeLabel = UILabel()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let arrowStage = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = TFColor.Surface.hero
        layer.cornerRadius = 26
        layer.cornerCurve = .continuous
        clipsToBounds = true

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        gradient.colors = [UIColor.clear.cgColor, UIColor(hex: 0x0D1535, alpha: 0.92).cgColor]
        gradient.locations = [0.28, 1]
        layer.addSublayer(gradient)

        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.font = TFTypography.caption.withSize(10)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = TFColor.Brand.primary.withAlphaComponent(0.9)
        badgeLabel.layer.cornerRadius = 12
        badgeLabel.clipsToBounds = true
        badgeLabel.textAlignment = .center

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = TFTypography.title.withSize(24)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = TFTypography.footnote.withSize(11)
        detailLabel.textColor = UIColor.white.withAlphaComponent(0.78)

        arrowStage.translatesAutoresizingMaskIntoConstraints = false
        arrowStage.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        arrowStage.layer.cornerRadius = 18
        let arrow = UIImageView(image: UIImage(systemName: "arrow.up.right"))
        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.tintColor = .white
        arrowStage.addSubview(arrow)

        [badgeLabel, titleLabel, detailLabel, arrowStage].forEach(addSubview)
        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            badgeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 52),
            badgeLabel.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowStage.leadingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: detailLabel.topAnchor, constant: -5),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowStage.leadingAnchor, constant: -12),
            detailLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),

            arrowStage.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            arrowStage.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            arrowStage.widthAnchor.constraint(equalToConstant: 36),
            arrowStage.heightAnchor.constraint(equalToConstant: 36),
            arrow.centerXAnchor.constraint(equalTo: arrowStage.centerXAnchor),
            arrow.centerYAnchor.constraint(equalTo: arrowStage.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    func configure(trip: Trip?) {
        let korean = TFAppLanguage.current() == .korean
        guard let trip else {
            imageView.image = UIImage(named: "TFPackingEditorialV2")
            badgeLabel.text = korean ? "시작하기" : "START"
            titleLabel.text = korean ? "첫 여행을 계획해보세요" : "Plan your first journey"
            detailLabel.text = korean ? "날짜부터 코디와 짐까지 한곳에서" : "Dates, looks and packing in one place"
            return
        }

        imageView.image = UIImage(named: assetName(for: trip))
        let days = max(Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: trip.startDate)
        ).day ?? 0, 0)
        badgeLabel.text = days == 0 ? (korean ? "오늘" : "TODAY") : "D-\(days)"
        titleLabel.text = trip.name
        detailLabel.text = "\(trip.destination ?? (korean ? "목적지 미정" : "Destination TBD"))  ·  \(TFDateFormatter.tripRange(start: trip.startDate, end: trip.endDate))"
    }

    private func assetName(for trip: Trip) -> String {
        switch trip.destinationCountryCode?.uppercased() {
        case "JP": "TFDestinationTokyoV2"
        case "FR": "TFDestinationParisV2"
        case "IT": "TFDestinationAmalfiV2"
        default: "TFDestinationGenericV2"
        }
    }
}

private final class HomeReadinessView: UIView {
    private let percentageLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private var valueLabels: [UILabel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = TFColor.Surface.card
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = TFColor.Border.subtle.cgColor

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = TFAppLanguage.current() == .korean ? "전체 준비율" : "Overall readiness"
        title.font = TFTypography.caption.withSize(12)
        title.textColor = TFColor.Text.secondary
        addSubview(title)

        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        percentageLabel.font = TFTypography.subtitle.withSize(18)
        percentageLabel.textColor = TFColor.Text.primary
        addSubview(percentageLabel)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = TFColor.Brand.primary
        progressView.trackTintColor = TFColor.Surface.input
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        addSubview(progressView)

        let metrics = UIStackView()
        metrics.translatesAutoresizingMaskIntoConstraints = false
        metrics.axis = .horizontal
        metrics.distribution = .fillEqually
        let titles = TFAppLanguage.current() == .korean
            ? ["옷장", "코디", "패킹"]
            : ["Wardrobe", "Looks", "Packing"]
        let symbols = ["tshirt.fill", "sparkles", "checkmark.circle.fill"]
        for index in titles.indices {
            let icon = UIImageView(image: UIImage(systemName: symbols[index]))
            icon.tintColor = [TFColor.Brand.primary, TFColor.Brand.accentPurple, TFColor.Brand.accentMint][index]
            icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            icon.contentMode = .scaleAspectFit
            icon.widthAnchor.constraint(equalToConstant: 20).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 20).isActive = true
            let value = UILabel()
            value.font = TFTypography.headline.withSize(15)
            value.textColor = TFColor.Text.primary
            valueLabels.append(value)
            let caption = UILabel()
            caption.text = titles[index]
            caption.font = TFTypography.footnote.withSize(9)
            caption.textColor = TFColor.Text.secondary
            let text = UIStackView(arrangedSubviews: [value, caption])
            text.axis = .vertical
            text.spacing = 1
            let metric = UIStackView(arrangedSubviews: [icon, text])
            metric.axis = .horizontal
            metric.alignment = .center
            metric.spacing = 7
            metrics.addArrangedSubview(metric)
        }
        addSubview(metrics)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            percentageLabel.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            percentageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            progressView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            progressView.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: percentageLabel.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            metrics.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 17),
            metrics.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            metrics.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            metrics.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(progress: Float, clothingCount: Int, outfitCount: Int, packingProgress: Float) {
        percentageLabel.text = "\(Int((progress * 100).rounded()))%"
        progressView.setProgress(progress, animated: false)
        valueLabels[0].text = "\(clothingCount)"
        valueLabels[1].text = "\(outfitCount)"
        valueLabels[2].text = "\(Int((packingProgress * 100).rounded()))%"
    }
}

private final class HomeQuickActionButton: UIControl {
    init(title: String, symbol: String, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor = TFColor.Surface.card
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = TFColor.Border.subtle.cgColor

        let stage = UIView()
        stage.backgroundColor = color.withAlphaComponent(0.12)
        stage.layer.cornerRadius = 15
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = color
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        stage.addSubview(icon)
        stage.translatesAutoresizingMaskIntoConstraints = false
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = TFTypography.footnote.withSize(10)
        label.textColor = TFColor.Text.primary
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stage)
        addSubview(label)
        NSLayoutConstraint.activate([
            stage.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stage.centerXAnchor.constraint(equalTo: centerXAnchor),
            stage.widthAnchor.constraint(equalToConstant: 30),
            stage.heightAnchor.constraint(equalToConstant: 30),
            icon.centerXAnchor.constraint(equalTo: stage.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: stage.centerYAnchor),
            label.topAnchor.constraint(equalTo: stage.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet {
            transform = isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
        }
    }
}

private final class HomeLookCard: UIControl {
    init(outfit: Outfit) {
        super.init(frame: .zero)
        backgroundColor = TFColor.Surface.card
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = TFColor.Border.subtle.cgColor
        clipsToBounds = true

        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        if let data = outfit.items.first?.imageData, let itemImage = UIImage(data: data) {
            image.image = itemImage
        } else {
            image.image = UIImage(named: "TFOutfitEditorialV2")
        }

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = outfit.name
        title.font = TFTypography.caption.withSize(12)
        title.textColor = TFColor.Text.primary
        title.numberOfLines = 1

        let count = UILabel()
        count.translatesAutoresizingMaskIntoConstraints = false
        count.text = TFAppLanguage.current() == .korean
            ? "아이템 \(outfit.items.count)개"
            : "\(outfit.items.count) items"
        count.font = TFTypography.footnote.withSize(9)
        count.textColor = TFColor.Text.secondary

        [image, title, count].forEach(addSubview)
        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: topAnchor),
            image.leadingAnchor.constraint(equalTo: leadingAnchor),
            image.trailingAnchor.constraint(equalTo: trailingAnchor),
            image.heightAnchor.constraint(equalToConstant: 128),
            title.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 10),
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 11),
            title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -11),
            count.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 3),
            count.leadingAnchor.constraint(equalTo: title.leadingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private final class HomeEmptyLookCard: UIControl {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = TFColor.Surface.card
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = TFColor.Border.subtle.cgColor
        clipsToBounds = true

        let image = UIImageView(image: UIImage(named: "TFOutfitEditorialV2"))
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        addSubview(image)

        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.88)
        addSubview(gradientView)

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = TFAppLanguage.current() == .korean ? "첫 코디를 만들어보세요" : "Build your first look"
        title.font = TFTypography.headline.withSize(15)
        title.textColor = TFColor.Text.primary
        gradientView.addSubview(title)

        let arrow = UIImageView(image: UIImage(systemName: "arrow.right"))
        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.tintColor = TFColor.Brand.primary
        gradientView.addSubview(arrow)

        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: topAnchor),
            image.leadingAnchor.constraint(equalTo: leadingAnchor),
            image.bottomAnchor.constraint(equalTo: bottomAnchor),
            image.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.48),
            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: image.trailingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor),
            title.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 18),
            title.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor),
            title.trailingAnchor.constraint(lessThanOrEqualTo: arrow.leadingAnchor, constant: -10),
            arrow.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -18),
            arrow.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension MainTabBarController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        guard navigationController === selectedViewController else { return }
        updateDockSelection()
        updateDockVisibility(animated: true)
    }
}
