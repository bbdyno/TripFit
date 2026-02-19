import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class TripsListViewController: UIViewController {
    private let context: ModelContext
    private var trips: [Trip] = []
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
        title = "Trips"
        view.backgroundColor = TFColor.pageBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        setupCollectionView()
        setupEmptyView()
        setupNavBar()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchTrips()
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
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 100)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(TripCell.self, forCellWithReuseIdentifier: TripCell.reuseId)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            [weak self] collectionView, indexPath, itemId in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TripCell.reuseId, for: indexPath
            ) as! TripCell
            if let trip = self?.trips.first(where: { $0.id == itemId }) {
                cell.configure(with: trip)
            }
            return cell
        }
    }

    private func setupEmptyView() {
        emptyView = TFEmptyStateView(
            icon: "suitcase",
            title: "No Trips Yet",
            subtitle: "Plan your first trip\nand start packing",
            buttonTitle: "Create Trip"
        )
        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyView.actionButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }

    @objc private func addTapped() {
        let editVC = TripEditViewController(context: context)
        let nav = UINavigationController(rootViewController: editVC)
        present(nav, animated: true)
    }

    private func fetchTrips() {
        let descriptor = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        trips = (try? context.fetch(descriptor)) ?? []
        applySnapshot()
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0])
        snapshot.appendItems(trips.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: true)
        emptyView.isHidden = !trips.isEmpty
    }
}

extension TripsListViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < trips.count else { return }
        let detail = TripDetailViewController(context: context, trip: trips[indexPath.item])
        navigationController?.pushViewController(detail, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard indexPath.item < trips.count else { return nil }
        let trip = trips[indexPath.item]
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            let delete = UIAction(title: "Delete", attributes: .destructive) { _ in
                self?.context.delete(trip)
                try? self?.context.save()
                self?.fetchTrips()
            }
            return UIMenu(children: [delete])
        })
    }
}
