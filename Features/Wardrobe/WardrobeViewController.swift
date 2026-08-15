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
    private enum SortMode {
        case recentlyUpdated
        case name
    }

    private let viewModel: WardrobeViewModel
    private let context: ModelContext

    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let itemModeControl = UISegmentedControl()
    private let categoryScrollView = UIScrollView()
    private let categoryStack = UIStackView()
    private var categoryButtons: [WardrobeCategoryButton] = []
    private let toolRow = UIView()
    private let searchContainer = UIView()
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let searchField = UITextField()
    private let sortButton = UIButton(type: .system)
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, UUID>!
    private var emptyView: TFEmptyStateView!
    private var sortMode: SortMode = .recentlyUpdated

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
        headerContainer.backgroundColor = TFColor.Surface.canvas
        view.addSubview(headerContainer)
        headerContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        titleLabel.text = CoreStrings.Wardrobe.title
        titleLabel.font = TFTypography.largeTitle
        titleLabel.textColor = TFColor.Text.primary

        subtitleLabel.text = localized("내 여행 옷장", "My travel wardrobe")
        subtitleLabel.font = TFTypography.footnote.withSize(13)
        subtitleLabel.textColor = TFColor.Text.secondary

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 1

        addButton.setImage(
            UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)),
            for: .normal
        )
        addButton.tintColor = .white
        addButton.backgroundColor = TFColor.Brand.primaryDark
        addButton.layer.cornerRadius = 13
        addButton.layer.cornerCurve = .continuous
        addButton.addAction(UIAction { [weak self] _ in self?.addTapped() }, for: .touchUpInside)

        let titleRow = UIStackView(arrangedSubviews: [titleStack, UIView(), addButton])
        titleRow.alignment = .center
        titleRow.spacing = TFSpacing.md
        headerContainer.addSubview(titleRow)
        titleRow.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.lg)
        }
        addButton.snp.makeConstraints { make in
            make.size.equalTo(36)
        }
        addButton.accessibilityLabel = localized("옷 추가", "Add clothing")

        itemModeControl.insertSegment(withTitle: localized("아이템", "Items"), at: 0, animated: false)
        itemModeControl.insertSegment(withTitle: localized("즐겨찾기", "Favorites"), at: 1, animated: false)
        itemModeControl.selectedSegmentIndex = 0
        itemModeControl.selectedSegmentTintColor = TFColor.Surface.card
        itemModeControl.backgroundColor = TFColor.Surface.chip
        itemModeControl.setTitleTextAttributes([.foregroundColor: TFColor.Text.secondary], for: .normal)
        itemModeControl.setTitleTextAttributes([
            .foregroundColor: TFColor.Brand.primaryDark,
            .font: TFTypography.caption.withSize(13),
        ], for: .selected)
        itemModeControl.addTarget(self, action: #selector(itemModeChanged), for: .valueChanged)
        headerContainer.addSubview(itemModeControl)
        itemModeControl.snp.makeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.lg)
            make.height.equalTo(32)
            make.bottom.equalToSuperview().inset(6)
        }
    }

    private func setupChips() {
        categoryScrollView.showsHorizontalScrollIndicator = false
        categoryScrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(categoryScrollView)
        categoryScrollView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(66)
        }

        categoryStack.axis = .horizontal
        categoryStack.alignment = .top
        categoryStack.spacing = 8
        categoryScrollView.addSubview(categoryStack)
        categoryStack.snp.makeConstraints { make in
            make.edges.equalTo(categoryScrollView.contentLayoutGuide).inset(
                UIEdgeInsets(top: 2, left: TFSpacing.md, bottom: 2, right: TFSpacing.md)
            )
            make.height.equalTo(categoryScrollView.frameLayoutGuide).offset(-4)
        }

        let categories: [(String, UIImage?, ClothingCategory?)] = [
            (localized("전체", "All"), UIImage(systemName: "square.grid.3x3.fill"), nil),
            (localizedCategoryName(.tops), TFPictogram.top.image(pointSize: 17), .tops),
            (localizedCategoryName(.bottoms), TFPictogram.bottom.image(pointSize: 17), .bottoms),
            (localizedCategoryName(.outerwear), TFPictogram.outerwear.image(pointSize: 17), .outerwear),
            (localizedCategoryName(.shoes), TFPictogram.shoes.image(pointSize: 17), .shoes),
            (localizedCategoryName(.accessories), TFPictogram.accessories.image(pointSize: 17), .accessories),
        ]
        for (title, image, category) in categories {
            let button = WardrobeCategoryButton(title: title, image: image, category: category)
            button.isCategorySelected = category == nil
            button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            categoryButtons.append(button)
            categoryStack.addArrangedSubview(button)
        }

        toolRow.backgroundColor = .clear
        view.addSubview(toolRow)
        toolRow.snp.makeConstraints { make in
            make.top.equalTo(categoryScrollView.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
            make.height.equalTo(46)
        }

        searchContainer.backgroundColor = TFColor.Surface.card
        searchContainer.layer.cornerRadius = 14
        searchContainer.layer.cornerCurve = .continuous
        searchContainer.layer.borderWidth = 1
        searchContainer.layer.borderColor = TFColor.Border.subtle.cgColor
        searchContainer.clipsToBounds = true
        toolRow.addSubview(searchContainer)
        searchContainer.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(3)
        }

        searchIcon.tintColor = TFColor.Text.tertiary
        searchIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        searchContainer.addSubview(searchIcon)
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(17)
        }

        searchField.placeholder = CoreStrings.Wardrobe.searchPlaceholder
        searchField.textColor = TFColor.Text.primary
        searchField.tintColor = TFColor.Brand.primary
        searchField.clearButtonMode = .whileEditing
        searchField.returnKeyType = .search
        searchField.font = TFTypography.bodyRegular
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        searchContainer.addSubview(searchField)
        searchField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }

        var sortConfig = UIButton.Configuration.filled()
        sortConfig.image = UIImage(systemName: "arrow.up.arrow.down")
        sortConfig.baseForegroundColor = TFColor.Text.secondary
        sortConfig.baseBackgroundColor = TFColor.Surface.card
        sortConfig.cornerStyle = .medium
        sortButton.configuration = sortConfig
        sortButton.layer.borderWidth = 1
        sortButton.layer.borderColor = TFColor.Border.subtle.cgColor
        sortButton.layer.cornerRadius = 14
        sortButton.showsMenuAsPrimaryAction = true
        sortButton.menu = makeSortMenu()
        toolRow.addSubview(sortButton)
        sortButton.snp.makeConstraints { make in
            make.leading.equalTo(searchContainer.snp.trailing).offset(6)
            make.trailing.top.bottom.equalToSuperview().inset(3)
            make.size.equalTo(40)
        }
    }

    @objc private func categoryTapped(_ sender: WardrobeCategoryButton) {
        categoryButtons.forEach { $0.isCategorySelected = ($0 === sender) }
        viewModel.selectedCategory = sender.category
        viewModel.fetchItems()
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: TFSpacing.sm, left: TFSpacing.md, bottom: 104, right: TFSpacing.md)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(ClothingCell.self, forCellWithReuseIdentifier: ClothingCell.reuseId)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(toolRow.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, itemId in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ClothingCell.reuseId, for: indexPath
            ) as! ClothingCell
            if let item = self?.displayedItems.first(where: { $0.id == itemId }) {
                let isFavorite = TFFavoritesStore.shared.isFavorite(item.id)
                cell.configure(with: item, isFavorite: isFavorite)
                cell.onToggleFavorite = { [weak self] in
                    self?.toggleFavorite(itemID: item.id)
                }
            }
            return cell
        }
    }

    private func setupEmptyView() {
        emptyView = TFEmptyStateView(
            heroImageName: "TFWardrobeEditorialV2",
            title: CoreStrings.Wardrobe.emptyTitle,
            subtitle: CoreStrings.Wardrobe.emptySubtitle,
            buttonTitle: CoreStrings.Wardrobe.emptyAction
        )
        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(toolRow.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.actionButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }

    private func localizedCategoryName(_ category: ClothingCategory) -> String {
        switch category {
        case .tops:
            CoreStrings.Category.tops
        case .bottoms:
            CoreStrings.Category.bottoms
        case .outerwear:
            CoreStrings.Category.outerwear
        case .shoes:
            CoreStrings.Category.shoes
        case .accessories:
            CoreStrings.Category.accessories
        }
    }

    private func localized(_ korean: String, _ english: String) -> String {
        TFAppLanguage.current() == .korean ? korean : english
    }

    @objc private func addTapped() {
        let editVC = ClothingEditViewController(context: context)
        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func searchTextChanged() {
        viewModel.searchText = searchField.text ?? ""
        viewModel.fetchItems()
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0])
        snapshot.appendItems(displayedItems.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: true)
        emptyView.isHidden = !displayedItems.isEmpty
        subtitleLabel.text = localized(
            "아이템 \(displayedItems.count)개",
            "\(displayedItems.count) pieces"
        )
    }

    private func toggleFavorite(itemID: UUID) {
        TFFavoritesStore.shared.toggleFavorite(itemID)
        applySnapshot()
    }

    @objc private func itemModeChanged() {
        applySnapshot()
    }

    private var displayedItems: [ClothingItem] {
        var items = viewModel.items
        if itemModeControl.selectedSegmentIndex == 1 {
            items = items.filter { TFFavoritesStore.shared.isFavorite($0.id) }
        }
        switch sortMode {
        case .recentlyUpdated:
            return items.sorted { $0.updatedAt > $1.updatedAt }
        case .name:
            return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    private func makeSortMenu() -> UIMenu {
        UIMenu(children: [
            UIAction(title: localized("최근 수정순", "Recently updated"), image: UIImage(systemName: "clock")) { [weak self] _ in
                self?.sortMode = .recentlyUpdated
                self?.applySnapshot()
            },
            UIAction(title: localized("이름순", "Name"), image: UIImage(systemName: "textformat.abc")) { [weak self] _ in
                self?.sortMode = .name
                self?.applySnapshot()
            },
        ])
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
            let edit = UIAction(title: CoreStrings.Common.edit, image: UIImage(systemName: "pencil")) { _ in
                guard let self else { return }
                let editVC = ClothingEditViewController(context: self.context, editingItem: item)
                let nav = UINavigationController(rootViewController: editVC)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true)
            }
            let delete = UIAction(title: CoreStrings.Common.delete, attributes: .destructive) { _ in
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
        let spacing: CGFloat = 16
        let width = floor((collectionView.bounds.width - inset - spacing) / 3)
        return CGSize(width: width, height: width + 36)
    }
}

private final class WardrobeCategoryButton: UIControl {
    let category: ClothingCategory?
    private let iconStage = UIView()
    private let iconView = UIImageView()
    private let label = UILabel()

    var isCategorySelected = false {
        didSet { applyState() }
    }

    init(title: String, image: UIImage?, category: ClothingCategory?) {
        self.category = category
        super.init(frame: .zero)

        iconStage.layer.cornerRadius = 18
        iconStage.layer.cornerCurve = .continuous
        iconStage.layer.borderWidth = 1
        iconView.image = (image ?? UIImage(systemName: "circle.grid.2x2.fill"))?.withRenderingMode(.alwaysTemplate)
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        label.text = title
        label.font = TFTypography.footnote.withSize(10)
        label.textAlignment = .center
        label.numberOfLines = 1

        let stack = UIStackView(arrangedSubviews: [iconStage, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 3
        addSubview(stack)
        iconStage.addSubview(iconView)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        iconStage.snp.makeConstraints { $0.size.equalTo(36) }
        iconView.snp.makeConstraints { $0.center.equalToSuperview() }
        snp.makeConstraints { make in
            make.width.equalTo(54)
            make.height.equalTo(58)
        }
        applyState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func applyState() {
        iconStage.backgroundColor = isCategorySelected ? TFColor.Brand.primary : TFColor.Surface.card
        iconStage.layer.borderColor = (isCategorySelected ? TFColor.Brand.primary : TFColor.Border.subtle).cgColor
        iconView.tintColor = isCategorySelected ? .white : TFColor.Text.secondary
        label.textColor = isCategorySelected ? TFColor.Brand.primaryDark : TFColor.Text.secondary
    }
}

extension WardrobeViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
