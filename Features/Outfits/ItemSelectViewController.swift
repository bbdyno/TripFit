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
    private let context: ModelContext
    private var allItems: [ClothingItem] = []
    private var selectedItems: Set<UUID>

    public var onDone: (([ClothingItem]) -> Void)?

    private let tableView = UITableView(frame: .zero, style: .plain)

    public init(context: ModelContext, selectedItems: [ClothingItem]) {
        self.context = context
        self.selectedItems = Set(selectedItems.map(\.id))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Items"
        view.backgroundColor = TFColor.Surface.canvas

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak self] _ in self?.doneTapped() }
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(SelectableClothingCell.self, forCellReuseIdentifier: SelectableClothingCell.reuseId)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        fetchItems()
    }

    private func fetchItems() {
        let descriptor = FetchDescriptor<ClothingItem>(sortBy: [SortDescriptor(\.name)])
        allItems = (try? context.fetch(descriptor)) ?? []
        tableView.reloadData()
    }

    private func doneTapped() {
        let selected = allItems.filter { selectedItems.contains($0.id) }
        onDone?(selected)
        dismiss(animated: true)
    }
}

extension ItemSelectViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SelectableClothingCell.reuseId, for: indexPath
        ) as! SelectableClothingCell
        let item = allItems[indexPath.row]
        let isSelected = selectedItems.contains(item.id)
        cell.configure(with: item, isSelected: isSelected)
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = allItems[indexPath.row]
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

private final class SelectableClothingCell: UITableViewCell {
    static let reuseId = "SelectableClothingCell"

    private let card = TFCardView(style: .flat)
    private let thumbnailImageView = UIImageView()
    private let nameLabel = UILabel()
    private let categoryLabel = UILabel()
    private let checkmarkView = UIImageView()
    private var imageRequestToken: UUID?
    private var imageRequestID = UUID()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.backgroundColor = TFColor.Surface.input

        nameLabel.font = TFTypography.body
        nameLabel.textColor = TFColor.Text.primary

        categoryLabel.font = TFTypography.footnote
        categoryLabel.textColor = TFColor.Text.secondary

        checkmarkView.contentMode = .scaleAspectFit
        checkmarkView.tintColor = TFColor.Brand.primary

        let textStack = UIStackView(arrangedSubviews: [nameLabel, categoryLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        contentView.addSubview(card)
        card.addSubview(thumbnailImageView)
        card.addSubview(textStack)
        card.addSubview(checkmarkView)

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }
        thumbnailImageView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(10)
            make.width.equalTo(44)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        checkmarkView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
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
        categoryLabel.text = item.category.displayName
        checkmarkView.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")

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
