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
        tabAppearance.shadowColor = UIColor.clear
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
            image: makeMaterialTabIcon(
                ligature: "checkroom",
                pointSize: 24,
                weight: .regular,
                fallbackSystemName: "tshirt"
            ),
            selectedImage: makeMaterialTabIcon(
                ligature: "checkroom",
                pointSize: 24,
                weight: .semibold,
                fallbackSystemName: "tshirt.fill"
            )
        )
        wardrobeVC.tabBarItem.tag = 0

        let outfitsVC = UINavigationController(
            rootViewController: OutfitsListViewController(context: environment.context)
        )
        outfitsVC.tabBarItem = UITabBarItem(
            title: "Outfits",
            image: makeMaterialTabIcon(
                ligature: "styler",
                pointSize: 24,
                weight: .regular,
                fallbackSystemName: "square.grid.2x2"
            ),
            selectedImage: makeMaterialTabIcon(
                ligature: "styler",
                pointSize: 24,
                weight: .semibold,
                fallbackSystemName: "square.grid.2x2.fill"
            )
        )
        outfitsVC.tabBarItem.tag = 1

        let tripsVC = UINavigationController(
            rootViewController: TripsListViewController(context: environment.context)
        )
        tripsVC.tabBarItem = UITabBarItem(
            title: "Trips",
            image: makeMaterialTabIcon(
                ligature: "flight_takeoff",
                pointSize: 24,
                weight: .regular,
                fallbackSystemName: "airplane"
            ),
            selectedImage: makeMaterialTabIcon(
                ligature: "flight_takeoff",
                pointSize: 24,
                weight: .semibold,
                fallbackSystemName: "airplane.departure"
            )
        )
        tripsVC.tabBarItem.tag = 2

        let moreVC = UINavigationController(
            rootViewController: MoreSettingsHomeViewController(context: environment.context)
        )
        moreVC.tabBarItem = UITabBarItem(
            title: "More",
            image: makeMaterialTabIcon(
                ligature: "settings",
                pointSize: 24,
                weight: .regular,
                fallbackSystemName: "gearshape"
            ),
            selectedImage: makeMaterialTabIcon(
                ligature: "settings",
                pointSize: 24,
                weight: .semibold,
                fallbackSystemName: "gearshape.fill"
            )
        )
        moreVC.tabBarItem.tag = 3

        viewControllers = [wardrobeVC, outfitsVC, tripsVC, moreVC]
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

    private func makeMaterialTabIcon(
        ligature: String,
        pointSize: CGFloat,
        weight: UIFont.Weight,
        fallbackSystemName: String
    ) -> UIImage? {
        if let icon = TFMaterialIcon.image(named: ligature, pointSize: pointSize, weight: weight) {
            return icon
        }
        return UIImage(
            systemName: fallbackSystemName,
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: pointSize,
                weight: symbolWeight(for: weight)
            )
        )
    }

    private func symbolWeight(for fontWeight: UIFont.Weight) -> UIImage.SymbolWeight {
        switch fontWeight {
        case ..<UIFont.Weight.ultraLight:
            return .ultraLight
        case UIFont.Weight.ultraLight..<UIFont.Weight.light:
            return .thin
        case UIFont.Weight.light..<UIFont.Weight.regular:
            return .light
        case UIFont.Weight.regular..<UIFont.Weight.medium:
            return .regular
        case UIFont.Weight.medium..<UIFont.Weight.semibold:
            return .medium
        case UIFont.Weight.semibold..<UIFont.Weight.bold:
            return .semibold
        case UIFont.Weight.bold..<UIFont.Weight.heavy:
            return .bold
        case UIFont.Weight.heavy..<UIFont.Weight.black:
            return .heavy
        default:
            return .black
        }
    }
}
