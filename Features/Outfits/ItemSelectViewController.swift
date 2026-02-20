//
//  ItemSelectViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class ItemSelectViewController: UIViewController {
    private struct CategoryFilter {
        let title: String
        let category: ClothingCategory?
    }

    private let context: ModelContext
    private var allItems: [ClothingItem] = []
    private var filteredItems: [ClothingItem] = []
    private var selectedItems: Set<UUID>
    private var selectedCategory: ClothingCategory?
    private var searchQuery: String = ""
    private var filterChips: [TFChip] = []
    private let filters: [CategoryFilter] = [
        CategoryFilter(title: "All Items", category: nil),
        CategoryFilter(title: "Tops", category: .tops),
        CategoryFilter(title: "Bottoms", category: .bottoms),
        CategoryFilter(title: "Outerwear", category: .outerwear),
        CategoryFilter(title: "Shoes", category: .shoes),
        CategoryFilter(title: "Accessories", category: .accessories),
    ]

    public var onDone: (([ClothingItem]) -> Void)?

    private let searchContainer = UIView()
    private let searchIcon = UIImageView(
        image: TFMaterialIcon.image(named: "search", pointSize: 18, weight: .regular)
            ?? UIImage(systemName: "magnifyingglass")
    )
    private let searchField = UITextField()
    private let filterScrollView = UIScrollView()
    private let filterStack = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    private let bottomFadeView = UIView()
    private let bottomFadeLayer = CAGradientLayer()
    private let bottomBar = UIView()
    private let doneButton = UIButton(type: .system)
    private let doneButtonGradientLayer = CAGradientLayer()

    public init(context: ModelContext, selectedItems: [ClothingItem]) {
        self.context = context
        self.selectedItems = Set(selectedItems.map(\.id))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = TFColor.Surface.canvas
        setupNavigation()
        setupLayout()
        setupFilters()
        fetchItems()
        updateDoneButtonState()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomFadeLayer.frame = bottomFadeView.bounds
        doneButtonGradientLayer.frame = doneButton.bounds
    }

    private func setupNavigation() {
        title = "Select Items"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.leftBarButtonItem?.setTitleTextAttributes(
            [.font: TFTypography.body.withSize(17)],
            for: .normal
        )
    }

    private func setupLayout() {
        searchContainer.backgroundColor = TFColor.Surface.input
        searchContainer.layer.cornerRadius = 18
        view.addSubview(searchContainer)
        searchContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
            make.height.equalTo(44)
        }

        searchIcon.tintColor = TFColor.Text.tertiary
        searchContainer.addSubview(searchIcon)
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }

        searchField.placeholder = "Search wardrobe..."
        searchField.font = TFTypography.bodyRegular.withSize(16)
        searchField.textColor = TFColor.Text.primary
        searchField.clearButtonMode = .whileEditing
        searchField.returnKeyType = .search
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        searchContainer.addSubview(searchField)
        searchField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }

        filterScrollView.showsHorizontalScrollIndicator = false
        filterScrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(filterScrollView)
        filterScrollView.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        filterStack.axis = .horizontal
        filterStack.spacing = 8
        filterScrollView.addSubview(filterStack)
        filterStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 16, bottom: 2, right: 16))
            make.height.equalToSuperview().offset(-4)
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .onDrag
        tableView.register(SelectableClothingCell.self, forCellReuseIdentifier: SelectableClothingCell.reuseID)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(filterScrollView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }

        emptyLabel.text = "No items found"
        emptyLabel.font = TFTypography.bodyRegular.withSize(16)
        emptyLabel.textColor = TFColor.Text.tertiary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(tableView)
        }

        bottomBar.backgroundColor = .clear
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }

        bottomFadeView.isUserInteractionEnabled = false
        view.addSubview(bottomFadeView)
        bottomFadeView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
            make.height.equalTo(56)
        }
        bottomFadeLayer.colors = [
            TFColor.Surface.card.withAlphaComponent(0).cgColor,
            TFColor.Surface.card.withAlphaComponent(0.9).cgColor,
            TFColor.Surface.card.cgColor,
        ]
        bottomFadeLayer.startPoint = CGPoint(x: 0.5, y: 0)
        bottomFadeLayer.endPoint = CGPoint(x: 0.5, y: 1)
        bottomFadeView.layer.addSublayer(bottomFadeLayer)

        doneButton.setTitleColor(.white, for: .normal)
        doneButton.titleLabel?.font = TFTypography.button.withSize(17)
        doneButton.layer.cornerRadius = 28
        doneButton.layer.masksToBounds = true
        doneButton.layer.insertSublayer(doneButtonGradientLayer, at: 0)
        doneButtonGradientLayer.colors = [UIColor(hex: 0x58C4FF).cgColor, UIColor(hex: 0x3AB0FF).cgColor]
        doneButtonGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        doneButtonGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        bottomBar.addSubview(doneButton)
        doneButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
            make.bottom.equalTo(bottomBar.safeAreaLayoutGuide.snp.bottom).inset(10)
            make.height.equalTo(56)
        }
    }

    private func setupFilters() {
        for (index, filter) in filters.enumerated() {
            let chip = TFChip(title: filter.title)
            chip.setStyle(.darkFilter)
            chip.tag = index
            chip.isChipSelected = index == 0
            chip.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
            filterChips.append(chip)
            filterStack.addArrangedSubview(chip)
        }
    }

    private func fetchItems() {
        let descriptor = FetchDescriptor<ClothingItem>(sortBy: [SortDescriptor(\.name)])
        allItems = (try? context.fetch(descriptor)) ?? []
        applyFilters()
    }

    private func applyFilters() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        filteredItems = allItems.filter { item in
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            let matchesQuery = query.isEmpty
                || item.name.lowercased().contains(query)
                || item.category.displayName.lowercased().contains(query)
            return matchesCategory && matchesQuery
        }
        tableView.reloadData()
        emptyLabel.isHidden = !filteredItems.isEmpty
        updateDoneButtonState()
    }

    private func updateDoneButtonState() {
        let selectedCount = selectedItems.count
        doneButton.setTitle("Add selected (\(selectedCount))", for: .normal)
        doneButton.isEnabled = selectedCount > 0
        doneButton.alpha = selectedCount > 0 ? 1 : 0.45
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        let selected = allItems.filter { selectedItems.contains($0.id) }
        onDone?(selected)
        dismiss(animated: true)
    }

    @objc private func searchChanged() {
        searchQuery = searchField.text ?? ""
        applyFilters()
    }

    @objc private func filterTapped(_ sender: TFChip) {
        guard sender.tag < filters.count else { return }
        selectedCategory = filters[sender.tag].category
        for (index, chip) in filterChips.enumerated() {
            chip.isChipSelected = (index == sender.tag)
        }
        applyFilters()
    }
}

extension ItemSelectViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SelectableClothingCell.reuseID,
            for: indexPath
        ) as! SelectableClothingCell
        let item = filteredItems[indexPath.row]
        let isSelected = selectedItems.contains(item.id)
        cell.configure(with: item, isSelected: isSelected)
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = filteredItems[indexPath.row]
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
        updateDoneButtonState()
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        88
    }
}

private final class SelectableClothingCell: UITableViewCell {
    static let reuseID = "SelectableClothingCell"

    private let card = TFCardView(style: .flat)
    private let thumbnailImageView = UIImageView()
    private let nameLabel = UILabel()
    private let categoryBadge = BadgeLabel(insets: UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8))
    private let checkmarkView = UIImageView()
    private var imageRequestToken: UUID?
    private var imageRequestID = UUID()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        thumbnailImageView.layer.cornerRadius = 12
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.backgroundColor = TFColor.Surface.input

        nameLabel.font = TFTypography.body.withSize(16)
        nameLabel.textColor = TFColor.Text.primary
        nameLabel.numberOfLines = 1

        categoryBadge.font = TFTypography.footnote.withSize(11)
        categoryBadge.textColor = TFColor.Text.secondary
        categoryBadge.backgroundColor = TFColor.Surface.input
        categoryBadge.layer.cornerRadius = 8
        categoryBadge.layer.masksToBounds = true

        checkmarkView.contentMode = .scaleAspectFit
        checkmarkView.tintColor = UIColor(hex: 0x58C4FF)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, categoryBadge])
        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.alignment = .leading

        contentView.addSubview(card)
        card.addSubview(thumbnailImageView)
        card.addSubview(textStack)
        card.addSubview(checkmarkView)

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }
        thumbnailImageView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(10)
            make.width.equalTo(56)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(checkmarkView.snp.leading).offset(-12)
        }
        checkmarkView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(22)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        TFRemoteImageLoader.shared.cancel(imageRequestToken)
        imageRequestToken = nil
        imageRequestID = UUID()
        thumbnailImageView.image = nil
    }

    func configure(with item: ClothingItem, isSelected: Bool) {
        nameLabel.text = item.name
        categoryBadge.text = item.category.displayName
        card.layer.borderColor = isSelected ? UIColor(hex: 0x58C4FF).withAlphaComponent(0.5).cgColor : TFColor.Border.subtle.cgColor
        card.layer.borderWidth = isSelected ? 1.5 : 1
        checkmarkView.image = TFMaterialIcon.image(
            named: isSelected ? "check_circle" : "radio_button_unchecked",
            pointSize: 22,
            weight: .regular
        ) ?? UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")

        TFRemoteImageLoader.shared.cancel(imageRequestToken)
        imageRequestToken = nil
        imageRequestID = UUID()

        if let data = item.imageData, let image = UIImage(data: data) {
            thumbnailImageView.image = image
            thumbnailImageView.contentMode = .scaleAspectFill
            thumbnailImageView.tintColor = nil
            return
        }

        thumbnailImageView.image = UIImage(systemName: item.category.icon)
        thumbnailImageView.contentMode = .scaleAspectFit
        thumbnailImageView.tintColor = item.category.tintColor

        let requestID = imageRequestID
        imageRequestToken = TFRemoteImageLoader.shared.load(from: item.imageURL) { [weak self] image in
            guard let self, self.imageRequestID == requestID, let image else { return }
            self.thumbnailImageView.image = image
            self.thumbnailImageView.contentMode = .scaleAspectFill
            self.thumbnailImageView.tintColor = nil
        }
    }
}

private final class BadgeLabel: UILabel {
    private let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}
