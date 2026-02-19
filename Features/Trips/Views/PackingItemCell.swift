//
//  PackingItemCell.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import UIKit

final class PackingItemCell: UITableViewCell {
    static let reuseId = "PackingItemCell"

    private let nameLabel = UILabel()
    private let quantityLabel = UILabel()
    private let decrementButton = UIButton(type: .system)
    private let incrementButton = UIButton(type: .system)
    private let checkButton = UIButton(type: .system)

    private var item: PackingItem?
    private var onChange: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        nameLabel.font = TFTypography.body
        nameLabel.textColor = TFColor.Text.primary
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        quantityLabel.font = TFTypography.caption
        quantityLabel.textColor = TFColor.Text.primary
        quantityLabel.textAlignment = .center

        [decrementButton, incrementButton].forEach { button in
            button.tintColor = TFColor.Brand.primary
            button.backgroundColor = TFColor.Surface.input
            button.layer.cornerRadius = 12
            button.titleLabel?.font = TFTypography.headline
            button.snp.makeConstraints { $0.size.equalTo(24) }
        }
        decrementButton.setImage(UIImage(systemName: "minus"), for: .normal)
        incrementButton.setImage(UIImage(systemName: "plus"), for: .normal)
        decrementButton.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)
        incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)

        checkButton.addTarget(self, action: #selector(checkTapped), for: .touchUpInside)

        let quantityContainer = UIStackView(arrangedSubviews: [decrementButton, quantityLabel, incrementButton])
        quantityContainer.axis = .horizontal
        quantityContainer.spacing = 6
        quantityContainer.alignment = .center
        quantityContainer.backgroundColor = TFColor.Surface.input
        quantityContainer.layer.cornerRadius = 10
        quantityContainer.layoutMargins = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        quantityContainer.isLayoutMarginsRelativeArrangement = true

        let rightStack = UIStackView(arrangedSubviews: [quantityContainer, checkButton])
        rightStack.spacing = 10
        rightStack.alignment = .center

        let mainStack = UIStackView(arrangedSubviews: [nameLabel, rightStack])
        mainStack.spacing = 12
        mainStack.alignment = .center

        let card = TFCardView(style: .flat)
        card.addSubview(mainStack)
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }

        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12))
        }

        checkButton.snp.makeConstraints { $0.size.equalTo(28) }
        quantityLabel.snp.makeConstraints { $0.width.equalTo(28) }
    }

    func configure(with item: PackingItem, onChange: @escaping () -> Void) {
        self.item = item
        self.onChange = onChange
        nameLabel.text = item.displayName
        quantityLabel.text = "\(item.quantity)"
        updateCheckState()

        if item.isPacked {
            nameLabel.textColor = TFColor.Text.secondary
        } else {
            nameLabel.textColor = TFColor.Text.primary
        }
    }

    private func updateCheckState() {
        guard let item else { return }
        let imageName = item.isPacked ? "checkmark.circle.fill" : "circle"
        let color = item.isPacked ? TFColor.Brand.accentMint : TFColor.Text.tertiary
        checkButton.setImage(UIImage(systemName: imageName), for: .normal)
        checkButton.tintColor = color
    }

    @objc private func decrementTapped() {
        guard let item, item.quantity > 1 else { return }
        item.quantity -= 1
        item.updatedAt = Date()
        quantityLabel.text = "\(item.quantity)"
        try? item.modelContext?.save()
        onChange?()
    }

    @objc private func incrementTapped() {
        guard let item else { return }
        item.quantity += 1
        item.updatedAt = Date()
        quantityLabel.text = "\(item.quantity)"
        try? item.modelContext?.save()
        onChange?()
    }

    @objc private func checkTapped() {
        guard let item else { return }
        item.isPacked.toggle()
        item.updatedAt = Date()
        try? item.modelContext?.save()
        updateCheckState()
        nameLabel.textColor = item.isPacked ? TFColor.Text.secondary : TFColor.Text.primary
        onChange?()
    }
}
