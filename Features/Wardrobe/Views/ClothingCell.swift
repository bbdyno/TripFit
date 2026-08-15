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

    private let card = TFCardView(style: .flat)
    private let imageView = UIImageView()
    private let favoriteButton = UIButton(type: .system)
    private let nameLabel = UILabel()
    private let metaLabel = UILabel()
    private var imageRequestToken: UUID?
    private var imageRequestID = UUID()
    var onToggleFavorite: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 0

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = TFColor.Surface.input

        favoriteButton.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.82)
        favoriteButton.layer.cornerRadius = 10
        favoriteButton.tintColor = TFColor.Text.tertiary
        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)

        nameLabel.font = TFTypography.caption.withSize(12)
        nameLabel.textColor = TFColor.Text.primary
        nameLabel.numberOfLines = 1

        metaLabel.font = TFTypography.footnote.withSize(9)
        metaLabel.textColor = TFColor.Text.secondary
        metaLabel.numberOfLines = 1

        card.addSubview(imageView)
        imageView.addSubview(favoriteButton)
        card.addSubview(nameLabel)
        card.addSubview(metaLabel)

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(imageView.snp.width)
        }

        favoriteButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(6)
            make.size.equalTo(20)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(2)
        }

        metaLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(2)
            make.bottom.equalToSuperview().inset(3)
        }
    }

    func configure(with item: ClothingItem, isFavorite: Bool) {
        nameLabel.text = item.name
        metaLabel.text = localizedCategoryName(item.category)
        updateFavoriteUI(isFavorite)

        TFRemoteImageLoader.shared.cancel(imageRequestToken)
        imageRequestToken = nil
        imageRequestID = UUID()

        if let data = item.imageData, let image = UIImage(data: data) {
            imageView.image = image
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = nil
            return
        }

        setPlaceholder(for: item)

        let requestID = imageRequestID
        imageRequestToken = TFRemoteImageLoader.shared.load(from: item.imageURL) { [weak self] image in
            guard let self, self.imageRequestID == requestID, let image else { return }
            self.imageView.image = image
            self.imageView.contentMode = .scaleAspectFit
            self.imageView.tintColor = nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        TFRemoteImageLoader.shared.cancel(imageRequestToken)
        imageRequestToken = nil
        imageRequestID = UUID()
        imageView.image = nil
        imageView.tintColor = nil
        onToggleFavorite = nil
    }

    @objc private func favoriteTapped() {
        onToggleFavorite?()
    }

    private func updateFavoriteUI(_ isFavorite: Bool) {
        let symbolName = isFavorite ? "heart.fill" : "heart"
        let image = UIImage(
            systemName: symbolName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        )
        favoriteButton.setImage(image, for: .normal)
        favoriteButton.tintColor = isFavorite ? TFColor.Brand.primary : TFColor.Text.tertiary
    }

    private func setPlaceholder(for item: ClothingItem) {
        imageView.image = UIImage(systemName: placeholderSymbol(for: item.category))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = item.category.tintColor
        imageView.backgroundColor = item.category.tintColor.withAlphaComponent(0.12)
    }

    private func placeholderSymbol(for category: ClothingCategory) -> String {
        switch category {
        case .tops: "tshirt.fill"
        case .bottoms: "figure.walk"
        case .outerwear: "wind"
        case .shoes: "shoe.2.fill"
        case .accessories: "handbag.fill"
        }
    }

    private func localizedCategoryName(_ category: ClothingCategory) -> String {
        switch category {
        case .tops: CoreStrings.Category.tops
        case .bottoms: CoreStrings.Category.bottoms
        case .outerwear: CoreStrings.Category.outerwear
        case .shoes: CoreStrings.Category.shoes
        case .accessories: CoreStrings.Category.accessories
        }
    }
}
