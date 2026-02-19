import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class OutfitDetailViewController: UIViewController {
    private let context: ModelContext
    private let outfit: Outfit

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, UUID>!

    public init(context: ModelContext, outfit: Outfit) {
        self.context = context
        self.outfit = outfit
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = outfit.name
        view.backgroundColor = TFColor.pageBackground

        setupNavBar()
        setupCollectionView()
        applySnapshot()
    }

    private func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .edit,
            primaryAction: UIAction { [weak self] _ in self?.editTapped() }
        )
    }

    private func editTapped() {
        let editVC = OutfitEditViewController(context: context, editingOutfit: outfit)
        let nav = UINavigationController(rootViewController: editVC)
        present(nav, animated: true)
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
        let width = (UIScreen.main.bounds.width - 44) / 2
        layout.itemSize = CGSize(width: width, height: width + 40)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear

        let headerNib = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { _, _, _ in }

        collectionView.register(ClothingCell.self, forCellWithReuseIdentifier: ClothingCell.reuseId)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            [weak self] collectionView, indexPath, itemId in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ClothingCell.reuseId, for: indexPath
            ) as! ClothingCell
            if let item = self?.outfit.items.first(where: { $0.id == itemId }) {
                cell.configure(with: item)
            }
            return cell
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0])
        snapshot.appendItems(outfit.items.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySnapshot()
    }
}
