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
    private let centerAddButton = UIButton(type: .system)
    private var isCenterAddVisible = true
    private var tabNavigationControllers: [UINavigationController] = []

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

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
            title: CoreStrings.Tab.wardrobe,
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
            title: CoreStrings.Tab.outfits,
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
            title: CoreStrings.Tab.trips,
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
            title: CoreStrings.Tab.more,
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

        tabNavigationControllers = [wardrobeVC, outfitsVC, tripsVC, moreVC]
        tabNavigationControllers.forEach { $0.delegate = self }
        viewControllers = tabNavigationControllers
        setupCenterAddButton()
        updateCenterAddVisibility(animated: false)
        updateSelectionIndicator()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutCenterAddButton()
        updateCenterAddVisibility(animated: false)
        updateSelectionIndicator()
    }

    private func setupCenterAddButton() {
        centerAddButton.backgroundColor = TFColor.Brand.primary
        centerAddButton.tintColor = .white
        centerAddButton.layer.borderWidth = 2
        centerAddButton.layer.borderColor = TFColor.Surface.card.cgColor
        centerAddButton.layer.shadowColor = TFColor.Brand.primary.cgColor
        centerAddButton.layer.shadowOpacity = 0.3
        centerAddButton.layer.shadowRadius = 10
        centerAddButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        centerAddButton.adjustsImageWhenHighlighted = true
        centerAddButton.setImage(
            TFMaterialIcon.image(named: "add", pointSize: 30, weight: .medium)
                ?? UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)),
            for: .normal
        )
        centerAddButton.addAction(UIAction { [weak self] _ in
            self?.didTapCenterAddButton()
        }, for: .touchUpInside)
        view.addSubview(centerAddButton)
    }

    private func layoutCenterAddButton() {
        let size: CGFloat = 60
        centerAddButton.frame = CGRect(
            x: tabBar.frame.midX - (size / 2),
            y: tabBar.frame.minY - (size / 2) - 6,
            width: size,
            height: size
        )
        centerAddButton.layer.cornerRadius = size / 2
        view.bringSubviewToFront(centerAddButton)
    }

    private func didTapCenterAddButton() {
        switch selectedIndex {
        case 0:
            presentAddWardrobeItem()
        case 1:
            presentAddOutfit()
        case 2:
            presentAddTrip()
        default:
            return
        }
    }

    private func presentAddWardrobeItem() {
        let editVC = ClothingEditViewController(context: environment.context)
        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .fullScreen
        presentFromSelectedHost(nav)
    }

    private func presentAddOutfit() {
        let editVC = OutfitEditViewController(context: environment.context)
        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .fullScreen
        presentFromSelectedHost(nav)
    }

    private func presentAddTrip() {
        let editVC = TripEditViewController(context: environment.context)
        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .fullScreen
        presentFromSelectedHost(nav)
    }

    private func presentFromSelectedHost(_ viewController: UIViewController) {
        let host: UIViewController
        if let nav = selectedViewController as? UINavigationController {
            host = nav.visibleViewController ?? nav
        } else if let selectedViewController {
            host = selectedViewController
        } else {
            host = self
        }
        guard host.presentedViewController == nil else { return }
        host.present(viewController, animated: true)
    }

    private func updateCenterAddVisibility(animated: Bool) {
        let shouldShow = shouldShowCenterAddButton()

        guard shouldShow != isCenterAddVisible || centerAddButton.isHidden else { return }

        let applyState = {
            self.centerAddButton.alpha = shouldShow ? 1 : 0
            self.centerAddButton.transform = shouldShow ? .identity : CGAffineTransform(scaleX: 0.88, y: 0.88)
        }

        if shouldShow {
            centerAddButton.isHidden = false
        }

        if animated {
            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState]
            ) {
                applyState()
            } completion: { _ in
                self.centerAddButton.isHidden = !shouldShow
                self.centerAddButton.isUserInteractionEnabled = shouldShow
                self.isCenterAddVisible = shouldShow
            }
        } else {
            applyState()
            centerAddButton.isHidden = !shouldShow
            centerAddButton.isUserInteractionEnabled = shouldShow
            isCenterAddVisible = shouldShow
        }
    }

    private func shouldShowCenterAddButton() -> Bool {
        guard selectedIndex >= 0, selectedIndex <= 2, !tabBar.isHidden else { return false }
        guard let nav = selectedViewController as? UINavigationController else { return false }
        guard let root = nav.viewControllers.first else { return false }
        return nav.topViewController === root
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

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateCenterAddVisibility(animated: true)
    }
}

extension MainTabBarController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        guard navigationController === selectedViewController else { return }
        updateCenterAddVisibility(animated: true)
    }
}
