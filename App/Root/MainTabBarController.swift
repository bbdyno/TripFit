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
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        tabAppearance.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.94)
        tabAppearance.shadowColor = TFColor.Border.subtle
        tabAppearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 1)
        tabAppearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 1)
        tabAppearance.stackedLayoutAppearance.selected.iconColor = TFColor.Brand.primary
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: TFColor.Brand.primary,
            .font: TFTypography.caption.withSize(10),
        ]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = TFColor.Text.tertiary
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: TFColor.Text.tertiary,
            .font: TFTypography.footnote.withSize(10),
        ]
        tabBar.standardAppearance = tabAppearance
        tabBar.scrollEdgeAppearance = tabAppearance
        tabBar.tintColor = TFColor.Brand.primary
        tabBar.unselectedItemTintColor = TFColor.Text.tertiary
        tabBar.itemPositioning = .automatic

        let wardrobeVC = UINavigationController(
            rootViewController: WardrobeViewController(context: environment.context)
        )
        wardrobeVC.tabBarItem = UITabBarItem(
            title: "Wardrobe",
            image: UIImage(
                systemName: "checkroom",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
            ),
            selectedImage: UIImage(
                systemName: "checkroom",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
            )
        )
        wardrobeVC.tabBarItem.tag = 0

        let outfitsVC = UINavigationController(
            rootViewController: OutfitsListViewController(context: environment.context)
        )
        outfitsVC.tabBarItem = UITabBarItem(
            title: "Outfits",
            image: UIImage(
                systemName: "styler",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
            ),
            selectedImage: UIImage(
                systemName: "styler",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .bold)
            )
        )
        outfitsVC.tabBarItem.tag = 1

        let tripsVC = UINavigationController(
            rootViewController: TripsListViewController(context: environment.context)
        )
        tripsVC.tabBarItem = UITabBarItem(
            title: "Trips",
            image: UIImage(
                systemName: "flight_takeoff",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
            ),
            selectedImage: UIImage(
                systemName: "flight_takeoff",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .bold)
            )
        )
        tripsVC.tabBarItem.tag = 2

        viewControllers = [wardrobeVC, outfitsVC, tripsVC]
        updateSelectionIndicator()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSelectionIndicator()
    }

    private func updateSelectionIndicator() {
        guard let items = tabBar.items, !items.isEmpty else { return }
        let itemWidth = tabBar.bounds.width / CGFloat(items.count)
        let size = CGSize(width: itemWidth, height: tabBar.bounds.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))

        let indicatorRect = CGRect(
            x: (itemWidth - 32) / 2,
            y: 2,
            width: 32,
            height: 4
        )
        TFColor.Brand.primary.setFill()
        UIBezierPath(roundedRect: indicatorRect, cornerRadius: 2).fill()

        tabBar.selectionIndicatorImage = UIGraphicsGetImageFromCurrentImageContext()
    }
}
