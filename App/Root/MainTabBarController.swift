//
//  MainTabBarController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Features
import SwiftData
import UIKit

final class MainTabBarController: UITabBarController {
    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundEffect = nil
        tabAppearance.backgroundColor = TFColor.Surface.card
        tabAppearance.shadowColor = TFColor.Border.subtle
        configureTabItemAppearance(tabAppearance.stackedLayoutAppearance)
        configureTabItemAppearance(tabAppearance.inlineLayoutAppearance)
        configureTabItemAppearance(tabAppearance.compactInlineLayoutAppearance)
        tabBar.standardAppearance = tabAppearance
        tabBar.scrollEdgeAppearance = tabAppearance
        tabBar.tintColor = TFColor.Brand.primary
        tabBar.unselectedItemTintColor = TFColor.Text.tertiary
        tabBar.itemPositioning = .fill

        let wardrobeVC = UINavigationController(
            rootViewController: WardrobeViewController(context: environment.context)
        )
        wardrobeVC.tabBarItem = UITabBarItem(
            title: CoreStrings.Tab.wardrobe,
            image: makeTabIcon(systemName: "tshirt", weight: .regular),
            selectedImage: makeTabIcon(systemName: "tshirt.fill", weight: .semibold)
        )
        wardrobeVC.tabBarItem.tag = 0

        let outfitsVC = UINavigationController(
            rootViewController: OutfitsListViewController(context: environment.context)
        )
        outfitsVC.tabBarItem = UITabBarItem(
            title: CoreStrings.Tab.outfits,
            image: makeTabIcon(systemName: "rectangle.stack", weight: .regular),
            selectedImage: makeTabIcon(systemName: "rectangle.stack.fill", weight: .semibold)
        )
        outfitsVC.tabBarItem.tag = 1

        let tripsVC = UINavigationController(
            rootViewController: TripsListViewController(
                context: environment.context,
                authService: environment.authService,
                collaborationRepository: environment.collaborationRepository,
                pendingInviteStore: environment.pendingInviteStore
            )
        )
        tripsVC.tabBarItem = UITabBarItem(
            title: CoreStrings.Tab.trips,
            image: makeTabIcon(systemName: "suitcase.rolling", weight: .regular),
            selectedImage: makeTabIcon(systemName: "suitcase.rolling.fill", weight: .semibold)
        )
        tripsVC.tabBarItem.tag = 2

        let moreVC = UINavigationController(
            rootViewController: MoreSettingsHomeViewController(
                context: environment.context,
                authService: environment.authService,
                accountDeletionService: environment.accountDeletionService
            )
        )
        moreVC.tabBarItem = UITabBarItem(
            title: CoreStrings.Tab.more,
            image: makeTabIcon(systemName: "ellipsis.circle", weight: .regular),
            selectedImage: makeTabIcon(systemName: "ellipsis.circle.fill", weight: .semibold)
        )
        moreVC.tabBarItem.tag = 3

        viewControllers = [wardrobeVC, outfitsVC, tripsVC, moreVC]
    }

    private func configureTabItemAppearance(_ itemAppearance: UITabBarItemAppearance) {
        itemAppearance.normal.iconColor = TFColor.Text.tertiary
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: TFColor.Text.tertiary,
            .font: TFTypography.footnote.withSize(10),
        ]
        itemAppearance.selected.iconColor = TFColor.Brand.primary
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: TFColor.Brand.primary,
            .font: TFTypography.caption.withSize(10),
        ]
        itemAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 1)
        itemAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 1)
    }

    private func makeTabIcon(systemName: String, weight: UIImage.SymbolWeight) -> UIImage? {
        UIImage(
            systemName: systemName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: weight)
        )?.withRenderingMode(.alwaysTemplate)
    }
}
