//
//  ClothingCell.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import UIKit

final class ClothingCell: UICollectionViewCell {
    static let reuseId = "ClothingCell"

    private let card = TFCardView()
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let categoryLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = TFColor.cardBackground

        nameLabel.font = .preferredFont(forTextStyle: .subheadline)
        nameLabel.textColor = TFColor.textPrimary

        categoryLabel.font = .preferredFont(forTextStyle: .caption1)
        categoryLabel.textColor = TFColor.textSecondary

        card.addSubview(imageView)
        card.addSubview(nameLabel)
        card.addSubview(categoryLabel)

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(imageView.snp.width)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
        }

        categoryLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(8)
        }
    }

    func configure(with item: ClothingItem) {
        nameLabel.text = item.name
        categoryLabel.text = item.category.displayName

        if let data = item.imageData, let image = UIImage(data: data) {
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
        } else {
            imageView.image = UIImage(systemName: item.category.icon)
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = TFColor.lavender
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
