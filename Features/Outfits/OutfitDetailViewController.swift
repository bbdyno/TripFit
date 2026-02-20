//
//  OutfitDetailViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

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
    private let summaryCard = TFCardView(style: .elevated)
    private let itemsCountLabel = UILabel()
    private let noteLabel = UILabel()

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
        view.backgroundColor = TFColor.Surface.canvas

        setupNavBar()
        setupSummaryCard()
        setupCollectionView()
        updateSummary()
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
        layout.minimumInteritemSpacing = TFSpacing.sm
        layout.minimumLineSpacing = TFSpacing.sm
        layout.sectionInset = UIEdgeInsets(top: TFSpacing.md, left: TFSpacing.md, bottom: TFSpacing.md, right: TFSpacing.md)
        let width = (UIScreen.main.bounds.width - 44) / 2
        layout.itemSize = CGSize(width: width, height: width + 70)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear

        collectionView.register(ClothingCell.self, forCellWithReuseIdentifier: ClothingCell.reuseId)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(summaryCard.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, itemId in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ClothingCell.reuseId, for: indexPath
            ) as! ClothingCell
            if let item = self?.outfit.items.first(where: { $0.id == itemId }) {
                let isFavorite = TFFavoritesStore.shared.isFavorite(item.id)
                cell.configure(with: item, isFavorite: isFavorite)
                cell.onToggleFavorite = { [weak self] in
                    TFFavoritesStore.shared.toggleFavorite(item.id)
                    self?.applySnapshot()
                }
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
        updateSummary()
        applySnapshot()
    }

    private func setupSummaryCard() {
        let titleLabel = UILabel()
        titleLabel.font = TFTypography.subtitle
        titleLabel.textColor = TFColor.Text.primary
        titleLabel.text = outfit.name

        itemsCountLabel.font = TFTypography.caption
        itemsCountLabel.textColor = TFColor.Brand.primary

        noteLabel.font = TFTypography.bodyRegular
        noteLabel.textColor = TFColor.Text.secondary
        noteLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, itemsCountLabel, noteLabel])
        stack.axis = .vertical
        stack.spacing = TFSpacing.xs

        view.addSubview(summaryCard)
        summaryCard.addSubview(stack)

        summaryCard.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(TFSpacing.sm)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
        }

        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(TFSpacing.md)
        }
    }

    private func updateSummary() {
        itemsCountLabel.text = "\(outfit.items.count) items"
        noteLabel.text = outfit.note?.isEmpty == false ? outfit.note : "No notes yet"
    }
}
