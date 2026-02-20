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
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    private let card = TFCardView(style: .elevated)
    private let imageView = UIImageView()
    private let favoriteButton = UIButton(type: .system)
    private let nameLabel = UILabel()
    private let categoryLabel = InsetLabel(insets: UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8))
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
        card.layer.cornerRadius = 16
        card.layer.borderColor = TFColor.Border.subtle.cgColor

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = TFColor.Surface.input

        favoriteButton.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.88)
        favoriteButton.layer.cornerRadius = 14
        favoriteButton.layer.borderWidth = 1
        favoriteButton.layer.borderColor = TFColor.Border.subtle.cgColor
        favoriteButton.tintColor = TFColor.Text.tertiary
        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)

        nameLabel.font = TFTypography.caption.withSize(14)
        nameLabel.textColor = TFColor.Text.primary
        nameLabel.numberOfLines = 1

        categoryLabel.font = TFTypography.footnote.withSize(10)
        categoryLabel.layer.cornerRadius = 6
        categoryLabel.clipsToBounds = true

        metaLabel.font = TFTypography.footnote
        metaLabel.textColor = TFColor.Text.secondary
        metaLabel.numberOfLines = 1

        card.addSubview(imageView)
        imageView.addSubview(favoriteButton)
        card.addSubview(categoryLabel)
        card.addSubview(nameLabel)
        card.addSubview(metaLabel)

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(imageView.snp.width).multipliedBy(1.25)
        }

        favoriteButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(8)
            make.size.equalTo(28)
        }

        categoryLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(12)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        metaLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
    }

    func configure(with item: ClothingItem, isFavorite: Bool) {
        nameLabel.text = item.name
        metaLabel.text = "Updated \(Self.relativeFormatter.localizedString(for: item.updatedAt, relativeTo: Date()))"
        categoryLabel.text = item.category.displayName.uppercased()
        categoryLabel.textColor = item.category.tintColor
        categoryLabel.backgroundColor = item.category.badgeBackgroundColor
        updateFavoriteUI(isFavorite)

        TFRemoteImageLoader.shared.cancel(imageRequestToken)
        imageRequestToken = nil
        imageRequestID = UUID()

        if let data = item.imageData, let image = UIImage(data: data) {
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            imageView.tintColor = nil
            return
        }

        setPlaceholder(for: item)

        let requestID = imageRequestID
        imageRequestToken = TFRemoteImageLoader.shared.load(from: item.imageURL) { [weak self] image in
            guard let self, self.imageRequestID == requestID, let image else { return }
            self.imageView.image = image
            self.imageView.contentMode = .scaleAspectFill
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
        imageView.image = UIImage(systemName: item.category.icon)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = item.category.tintColor
        imageView.backgroundColor = item.category.tintColor.withAlphaComponent(0.12)
    }
}

private final class InsetLabel: UILabel {
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
