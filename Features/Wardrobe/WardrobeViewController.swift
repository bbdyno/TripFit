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

    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let searchContainer = UIView()
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let searchField = UITextField()
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
        view.backgroundColor = TFColor.Surface.canvas

        setupHeader()
        setupChips()
        setupCollectionView()
        setupEmptyView()

        viewModel.onChange = { [weak self] in self?.applySnapshot() }
        viewModel.fetchItems()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.fetchItems()
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

        titleLabel.text = "Wardrobe"
        titleLabel.font = TFTypography.largeTitle
        titleLabel.textColor = TFColor.Text.primary

        addButton.setImage(
            UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .bold)),
            for: .normal
        )
        addButton.tintColor = TFColor.Brand.primary
        addButton.backgroundColor = TFColor.Brand.primary.withAlphaComponent(0.12)
        addButton.layer.cornerRadius = 20
        addButton.layer.borderWidth = 1
        addButton.layer.borderColor = TFColor.Brand.primary.withAlphaComponent(0.24).cgColor
        addButton.addAction(UIAction { [weak self] _ in self?.addTapped() }, for: .touchUpInside)

        let titleRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), addButton])
        titleRow.alignment = .center
        titleRow.spacing = TFSpacing.md
        headerContainer.addSubview(titleRow)
        titleRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
        }
        addButton.snp.makeConstraints { make in
            make.size.equalTo(40)
        }

        searchContainer.backgroundColor = TFColor.Surface.card
        searchContainer.layer.cornerRadius = 12
        searchContainer.layer.borderWidth = 1
        searchContainer.layer.borderColor = TFColor.Border.subtle.cgColor
        headerContainer.addSubview(searchContainer)
        searchContainer.snp.makeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom).offset(TFSpacing.sm)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().inset(6)
        }

        searchIcon.tintColor = TFColor.Text.tertiary
        searchIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        searchContainer.addSubview(searchIcon)
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }

        searchField.placeholder = "Search your closet"
        searchField.textColor = TFColor.Text.primary
        searchField.tintColor = TFColor.Brand.primary
        searchField.clearButtonMode = .whileEditing
        searchField.returnKeyType = .search
        searchField.font = TFTypography.bodyRegular
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        searchContainer.addSubview(searchField)
        searchField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
    }

    private func setupChips() {
        chipScrollView.showsHorizontalScrollIndicator = false
        chipScrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(chipScrollView)
        chipScrollView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(54)
        }

        chipStack.axis = .horizontal
        chipStack.spacing = 10
        chipScrollView.addSubview(chipStack)
        chipStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
            make.height.equalToSuperview().offset(-16)
        }

        let allChip = TFChip(title: "All")
        allChip.setStyle(.neutralFilter)
        allChip.isChipSelected = true
        allChip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        chipStack.addArrangedSubview(allChip)

        for category in ClothingCategory.allCases {
            let chip = TFChip(title: category.displayName)
            chip.setStyle(.neutralFilter)
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
        layout.minimumInteritemSpacing = TFSpacing.md
        layout.minimumLineSpacing = TFSpacing.md
        layout.sectionInset = UIEdgeInsets(top: TFSpacing.sm, left: TFSpacing.md, bottom: 104, right: TFSpacing.md)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(ClothingCell.self, forCellWithReuseIdentifier: ClothingCell.reuseId)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(chipScrollView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, itemId in
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
            make.top.equalTo(chipScrollView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.actionButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }

    @objc private func addTapped() {
        let editVC = ClothingEditViewController(context: context)
        let nav = UINavigationController(rootViewController: editVC)
        present(nav, animated: true)
    }

    @objc private func searchTextChanged() {
        viewModel.searchText = searchField.text ?? ""
        viewModel.fetchItems()
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
        guard
            let itemID = dataSource.itemIdentifier(for: indexPath),
            let item = viewModel.items.first(where: { $0.id == itemID })
        else { return }
        let detailVC = ClothingDetailViewController(context: context, item: item)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard
            let itemID = dataSource.itemIdentifier(for: indexPath),
            let item = viewModel.items.first(where: { $0.id == itemID })
        else { return nil }
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { _ in
                guard let self else { return }
                let editVC = ClothingEditViewController(context: self.context, editingItem: item)
                let nav = UINavigationController(rootViewController: editVC)
                self.present(nav, animated: true)
            }
            let delete = UIAction(title: "Delete", attributes: .destructive) { _ in
                self?.viewModel.deleteItem(item)
            }
            return UIMenu(children: [edit, delete])
        })
    }
}

extension WardrobeViewController: UICollectionViewDelegateFlowLayout {
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

extension WardrobeViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
