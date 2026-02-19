//
//  WardrobeViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class WardrobeViewController: UIViewController {
    private let viewModel: WardrobeViewModel
    private let context: ModelContext

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, UUID>!
    private let chipScrollView = UIScrollView()
    private let chipStack = UIStackView()
    private var emptyView: TFEmptyStateView!

    public init(context: ModelContext) {
        self.context = context
        self.viewModel = WardrobeViewModel(context: context)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Wardrobe"
        view.backgroundColor = TFColor.pageBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        setupSearchController()
        setupChips()
        setupCollectionView()
        setupEmptyView()
        setupNavBar()

        viewModel.onChange = { [weak self] in self?.applySnapshot() }
        viewModel.fetchItems()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchItems()
    }

    private func setupSearchController() {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search clothes..."
        navigationItem.searchController = search
    }

    private func setupChips() {
        chipScrollView.showsHorizontalScrollIndicator = false
        view.addSubview(chipScrollView)
        chipScrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        chipStack.axis = .horizontal
        chipStack.spacing = 8
        chipScrollView.addSubview(chipStack)
        chipStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
            make.height.equalToSuperview().offset(-8)
        }

        let allChip = TFChip(title: "All")
        allChip.isChipSelected = true
        allChip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        chipStack.addArrangedSubview(allChip)

        for category in ClothingCategory.allCases {
            let chip = TFChip(title: category.displayName)
            chip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            chipStack.addArrangedSubview(chip)
        }
    }

    @objc private func chipTapped(_ sender: TFChip) {
        for case let chip as TFChip in chipStack.arrangedSubviews {
            chip.isChipSelected = (chip == sender)
        }

        let title = sender.titleLabel?.text
        if title == "All" {
            viewModel.selectedCategory = nil
        } else {
            viewModel.selectedCategory = ClothingCategory.allCases.first { $0.displayName == title }
        }
        viewModel.fetchItems()
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)
        let width = (UIScreen.main.bounds.width - 44) / 2
        layout.itemSize = CGSize(width: width, height: width + 40)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(ClothingCell.self, forCellWithReuseIdentifier: ClothingCell.reuseId)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(chipScrollView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            [weak self] collectionView, indexPath, itemId in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ClothingCell.reuseId, for: indexPath
            ) as! ClothingCell
            if let item = self?.viewModel.items.first(where: { $0.id == itemId }) {
                cell.configure(with: item)
            }
            return cell
        }
    }

    private func setupEmptyView() {
        emptyView = TFEmptyStateView(
            icon: "tshirt",
            title: "No Clothes Yet",
            subtitle: "Add your first clothing item\nto get started",
            buttonTitle: "Add Item"
        )
        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyView.actionButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }

    private func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .add, primaryAction: UIAction { [weak self] _ in self?.addTapped() }
        )
    }

    @objc private func addTapped() {
        let editVC = ClothingEditViewController(context: context)
        let nav = UINavigationController(rootViewController: editVC)
        present(nav, animated: true)
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.items.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: true)
        emptyView.isHidden = !viewModel.items.isEmpty
    }
}

extension WardrobeViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < viewModel.items.count else { return }
        let item = viewModel.items[indexPath.item]
        let editVC = ClothingEditViewController(context: context, editingItem: item)
        let nav = UINavigationController(rootViewController: editVC)
        present(nav, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard indexPath.item < viewModel.items.count else { return nil }
        let item = viewModel.items[indexPath.item]
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            let delete = UIAction(title: "Delete", attributes: .destructive) { _ in
                self?.viewModel.deleteItem(item)
            }
            return UIMenu(children: [delete])
        })
    }
}

extension WardrobeViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchText = searchController.searchBar.text ?? ""
        viewModel.fetchItems()
    }
}
