//
//  MainTabBarController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Features
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
    private var dockButtons: [UIButton] = []
    private var dockItems: [DockItem] = []
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
        let moreVC = UINavigationController(
            rootViewController: MoreSettingsHomeViewController(
                context: environment.context,
                authService: environment.authService,
                accountDeletionService: environment.accountDeletionService
            )
        )

        let controllers = [wardrobeVC, outfitsVC, tripsVC, moreVC]
        controllers.forEach {
            $0.delegate = self
            $0.additionalSafeAreaInsets.bottom = 76
        }
        viewControllers = controllers

        let korean = TFAppLanguage.current() == .korean
        dockItems = [
            DockItem(title: korean ? "옷장" : "Wardrobe", symbol: "tshirt", selectedSymbol: "tshirt.fill"),
            DockItem(title: korean ? "코디" : "Outfits", symbol: "sparkles", selectedSymbol: "sparkles"),
            DockItem(
                title: korean ? "여행" : "Trips",
                symbol: "suitcase.rolling",
                selectedSymbol: "suitcase.rolling.fill"
            ),
            DockItem(title: korean ? "더보기" : "More", symbol: "ellipsis", selectedSymbol: "ellipsis"),
        ]
        setupDock()
        updateDockSelection()
    }

    private func setupDock() {
        dockView.translatesAutoresizingMaskIntoConstraints = false
        dockView.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.97)
        dockView.layer.cornerRadius = 26
        dockView.layer.cornerCurve = .continuous
        dockView.layer.borderWidth = 1 / UIScreen.main.scale
        dockView.layer.borderColor = TFColor.Border.subtle.cgColor
        dockView.layer.shadowColor = TFColor.Text.primary.cgColor
        dockView.layer.shadowOpacity = 0.09
        dockView.layer.shadowRadius = 18
        dockView.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.addSubview(dockView)

        dockStack.translatesAutoresizingMaskIntoConstraints = false
        dockStack.axis = .horizontal
        dockStack.distribution = .fillEqually
        dockStack.spacing = 4
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
            dockView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dockView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            dockView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            dockView.widthAnchor.constraint(equalToConstant: 360).withPriority(.defaultHigh),
            dockView.heightAnchor.constraint(equalToConstant: 64),
            dockView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            dockStack.topAnchor.constraint(equalTo: dockView.topAnchor, constant: 6),
            dockStack.leadingAnchor.constraint(equalTo: dockView.leadingAnchor, constant: 6),
            dockStack.trailingAnchor.constraint(equalTo: dockView.trailingAnchor, constant: -6),
            dockStack.bottomAnchor.constraint(equalTo: dockView.bottomAnchor, constant: -6),
        ])
    }

    @objc private func dockButtonTapped(_ sender: UIButton) {
        guard viewControllers?.indices.contains(sender.tag) == true else { return }
        selectedIndex = sender.tag
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
            configuration.imagePadding = 2
            configuration.baseForegroundColor = isSelected ? TFColor.Brand.primary : TFColor.Text.secondary
            configuration.background.backgroundColor = isSelected
                ? TFColor.Brand.primary.withAlphaComponent(0.10)
                : .clear
            configuration.background.cornerRadius = 20
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 6, bottom: 4, trailing: 6)
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var attributes = incoming
                attributes.font = isSelected
                    ? TFTypography.caption.withSize(10)
                    : TFTypography.footnote.withSize(10)
                return attributes
            }
            button.configuration = configuration
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
                : CGAffineTransform(translationX: 0, y: 28)
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

private extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
