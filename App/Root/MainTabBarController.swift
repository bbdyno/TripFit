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

        let wardrobeVC = UINavigationController(
            rootViewController: WardrobeViewController(context: environment.context)
        )
        wardrobeVC.tabBarItem = UITabBarItem(title: "Wardrobe", image: UIImage(systemName: "tshirt"), tag: 0)

        let outfitsVC = UINavigationController(
            rootViewController: OutfitsListViewController(context: environment.context)
        )
        outfitsVC.tabBarItem = UITabBarItem(
            title: "Outfits",
            image: UIImage(systemName: "person.crop.rectangle.stack"),
            tag: 1
        )

        let tripsVC = UINavigationController(
            rootViewController: TripsListViewController(context: environment.context)
        )
        tripsVC.tabBarItem = UITabBarItem(title: "Trips", image: UIImage(systemName: "suitcase"), tag: 2)

        viewControllers = [wardrobeVC, outfitsVC, tripsVC]
    }
}
