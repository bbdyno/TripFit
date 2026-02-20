//
//  OutfitsListViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class OutfitsListViewController: UIViewController {
    private enum FilterType: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
        case summer = "Summer 24"
    }

    private let context: ModelContext
    private var outfits: [Outfit] = []
    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, UUID>!
    private var emptyView: TFEmptyStateView!
    private let filterScrollView = UIScrollView()
    private let filterStack = UIStackView()
    private var filterButtons: [TFChip] = []
    private var selectedFilter: FilterType = .all

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
        setupFilterBar()
        setupCollectionView()
        setupEmptyView()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchOutfits()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupHeader() {
        headerContainer.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.96)
        view.addSubview(headerContainer)
        headerContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        titleLabel.text = "Outfits"
        titleLabel.font = TFTypography.largeTitle
        titleLabel.textColor = TFColor.Text.primary

        addButton.setImage(
            UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)),
            for: .normal
        )
        addButton.tintColor = .white
        addButton.backgroundColor = TFColor.Brand.primary
        addButton.layer.cornerRadius = 20
        addButton.layer.shadowColor = TFColor.Brand.primary.cgColor
        addButton.layer.shadowOpacity = 0.3
        addButton.layer.shadowRadius = 8
        addButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addButton.addAction(UIAction { [weak self] _ in self?.addTapped() }, for: .touchUpInside)

        let titleRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), addButton])
        titleRow.alignment = .center
        titleRow.spacing = TFSpacing.md
        headerContainer.addSubview(titleRow)
        titleRow.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
            make.bottom.equalToSuperview().inset(6)
        }
        addButton.snp.makeConstraints { make in
            make.size.equalTo(40)
        }
        addButton.isHidden = true
    }

    private func setupFilterBar() {
        filterScrollView.showsHorizontalScrollIndicator = false
        filterScrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(filterScrollView)
        filterScrollView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(54)
        }

        filterStack.axis = .horizontal
        filterStack.spacing = 10
        filterScrollView.addSubview(filterStack)
        filterStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
            make.height.equalToSuperview().offset(-16)
        }

        FilterType.allCases.forEach { filter in
            let button = TFChip(title: filter.rawValue)
            button.setStyle(.darkFilter)
            button.tag = filterButtons.count
            button.addTarget(self, action: #selector(filterChipTapped(_:)), for: .touchUpInside)
            filterButtons.append(button)
            filterStack.addArrangedSubview(button)
        }

        updateFilterButtons()
    }

    @objc private func filterChipTapped(_ sender: TFChip) {
        guard sender.tag < FilterType.allCases.count else { return }
        selectedFilter = FilterType.allCases[sender.tag]
        updateFilterButtons()
        applySnapshot()
    }

    private func updateFilterButtons() {
        for (index, button) in filterButtons.enumerated() {
            let filter = FilterType.allCases[index]
            button.isChipSelected = (filter == selectedFilter)
        }
    }

    private var filteredOutfits: [Outfit] {
        switch selectedFilter {
        case .all:
            outfits
        case .favorites:
            outfits.filter { ($0.note?.isEmpty == false) || $0.items.count >= 4 }
        case .summer:
            outfits.filter { outfit in
                outfit.items.contains(where: { $0.season == .summer || $0.season == .all })
            }
        }
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = TFSpacing.md
        layout.minimumInteritemSpacing = TFSpacing.md
        layout.sectionInset = UIEdgeInsets(top: TFSpacing.md, left: TFSpacing.md, bottom: 96, right: TFSpacing.md)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(OutfitCell.self, forCellWithReuseIdentifier: OutfitCell.reuseId)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(filterScrollView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, itemId in
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
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(filterScrollView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.actionButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }

    @objc private func addTapped() {
        let editVC = OutfitEditViewController(context: context)
        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .fullScreen
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
        snapshot.appendItems(filteredOutfits.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: true)
        emptyView.isHidden = !filteredOutfits.isEmpty
    }
}

extension OutfitsListViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let itemID = dataSource.itemIdentifier(for: indexPath),
            let outfit = outfits.first(where: { $0.id == itemID })
        else { return }
        let detail = OutfitDetailViewController(context: context, outfit: outfit)
        navigationController?.pushViewController(detail, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard
            let itemID = dataSource.itemIdentifier(for: indexPath),
            let outfit = outfits.first(where: { $0.id == itemID })
        else { return nil }
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            let delete = UIAction(title: CoreStrings.Common.delete, attributes: .destructive) { _ in
                self?.context.delete(outfit)
                try? self?.context.save()
                self?.fetchOutfits()
            }
            return UIMenu(children: [delete])
        })
    }
}

extension OutfitsListViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let inset: CGFloat = TFSpacing.md * 2
        let spacing: CGFloat = TFSpacing.md
        let width = floor((collectionView.bounds.width - inset - spacing) / 2)
        return CGSize(width: width, height: (width * 1.25) + 72)
    }
}
