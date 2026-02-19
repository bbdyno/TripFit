//
//  TripsListViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class TripsListViewController: UIViewController {
    private let context: ModelContext
    private var trips: [Trip] = []
    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let addButton = UIButton(type: .system)
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
        view.backgroundColor = TFColor.Surface.canvas
        setupHeader()
        setupCollectionView()
        setupEmptyView()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchTrips()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupHeader() {
        headerContainer.backgroundColor = TFColor.Surface.canvas.withAlphaComponent(0.96)
        view.addSubview(headerContainer)
        headerContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }

        titleLabel.text = "Trips"
        titleLabel.font = TFTypography.largeTitle.withSize(36)
        titleLabel.textColor = TFColor.Text.primary

        subtitleLabel.text = "Ready for your next adventure?"
        subtitleLabel.font = TFTypography.caption
        subtitleLabel.textColor = TFColor.Text.secondary

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 2

        addButton.setImage(
            UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .bold)),
            for: .normal
        )
        addButton.tintColor = .white
        addButton.backgroundColor = TFColor.Brand.primary
        addButton.layer.cornerRadius = 22
        addButton.layer.shadowColor = TFColor.Brand.primary.cgColor
        addButton.layer.shadowOpacity = 0.3
        addButton.layer.shadowRadius = 10
        addButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addButton.addAction(UIAction { [weak self] _ in self?.addTapped() }, for: .touchUpInside)

        let titleRow = UIStackView(arrangedSubviews: [titleStack, UIView(), addButton])
        titleRow.alignment = .center
        titleRow.spacing = TFSpacing.md
        headerContainer.addSubview(titleRow)
        titleRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
            make.bottom.equalToSuperview().inset(8)
        }
        addButton.snp.makeConstraints { make in
            make.size.equalTo(44)
        }
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = TFSpacing.lg
        layout.sectionInset = UIEdgeInsets(top: TFSpacing.md, left: TFSpacing.md, bottom: 112, right: TFSpacing.md)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(TripCell.self, forCellWithReuseIdentifier: TripCell.reuseId)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, itemId in
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
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
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
        guard
            let itemID = dataSource.itemIdentifier(for: indexPath),
            let trip = trips.first(where: { $0.id == itemID })
        else { return }
        let detail = TripDetailViewController(context: context, trip: trip)
        navigationController?.pushViewController(detail, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard
            let itemID = dataSource.itemIdentifier(for: indexPath),
            let trip = trips.first(where: { $0.id == itemID })
        else { return nil }
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

extension TripsListViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.bounds.width - (TFSpacing.md * 2)
        return CGSize(width: width, height: 292)
    }
}
