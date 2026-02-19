import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class OutfitsListViewController: UIViewController {
    private let context: ModelContext
    private var outfits: [Outfit] = []
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, UUID>!
    private var emptyView: TFEmptyStateView!

    public init(context: ModelContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Outfits"
        view.backgroundColor = TFColor.pageBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        setupCollectionView()
        setupEmptyView()
        setupNavBar()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchOutfits()
    }

    private func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: UIAction { [weak self] _ in self?.addTapped() }
        )
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 80)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(OutfitCell.self, forCellWithReuseIdentifier: OutfitCell.reuseId)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            [weak self] collectionView, indexPath, itemId in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OutfitCell.reuseId, for: indexPath
            ) as! OutfitCell
            if let outfit = self?.outfits.first(where: { $0.id == itemId }) {
                cell.configure(with: outfit)
            }
            return cell
        }
    }

    private func setupEmptyView() {
        emptyView = TFEmptyStateView(
            icon: "person.crop.rectangle.stack",
            title: "No Outfits Yet",
            subtitle: "Create your first outfit\ncombination",
            buttonTitle: "Create Outfit"
        )
        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyView.actionButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }

    @objc private func addTapped() {
        let editVC = OutfitEditViewController(context: context)
        let nav = UINavigationController(rootViewController: editVC)
        present(nav, animated: true)
    }

    private func fetchOutfits() {
        let descriptor = FetchDescriptor<Outfit>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        outfits = (try? context.fetch(descriptor)) ?? []
        applySnapshot()
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0])
        snapshot.appendItems(outfits.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: true)
        emptyView.isHidden = !outfits.isEmpty
    }
}

extension OutfitsListViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < outfits.count else { return }
        let detail = OutfitDetailViewController(context: context, outfit: outfits[indexPath.item])
        navigationController?.pushViewController(detail, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard indexPath.item < outfits.count else { return nil }
        let outfit = outfits[indexPath.item]
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            let delete = UIAction(title: "Delete", attributes: .destructive) { _ in
                self?.context.delete(outfit)
                try? self?.context.save()
                self?.fetchOutfits()
            }
            return UIMenu(children: [delete])
        })
    }
}
