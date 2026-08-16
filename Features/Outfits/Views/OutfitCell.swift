//
//  OutfitCell.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import UIKit

final class OutfitCell: UICollectionViewCell {
    static let reuseId = "OutfitCell"

    private let card = TFCardView(style: .flat)
    private let collageContainer = UIView()
    private let singleImageView = UIImageView()
    private let gridContainer = UIView()
    private let gridImageViews: [UIImageView] = (0..<4).map { _ in UIImageView() }
    private let overflowBadge = InsetLabel(insets: UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
    private let favoriteBadge = UIView()
    private let favoriteIcon = UIImageView(image: UIImage(systemName: "heart.fill"))
    private let nameLabel = UILabel()
    private let countLabel = UILabel()

    private var imageRequestTokens: [UUID?] = Array(repeating: nil, count: 4)
    private var imageRequestID = UUID()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 0

        collageContainer.layer.cornerRadius = 14
        collageContainer.clipsToBounds = true
        collageContainer.backgroundColor = TFColor.Surface.highlight

        singleImageView.contentMode = .scaleAspectFill
        singleImageView.clipsToBounds = true
        singleImageView.backgroundColor = TFColor.Surface.input

        for (index, imageView) in gridImageViews.enumerated() {
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = index.isMultiple(of: 2)
                ? TFColor.Surface.card
                : TFColor.Brand.accentSky.withAlphaComponent(0.12)
            imageView.layer.cornerRadius = 12
            imageView.layer.cornerCurve = .continuous
            imageView.layer.borderWidth = 1 / UIScreen.main.scale
            imageView.layer.borderColor = TFColor.Border.subtle.cgColor
            gridContainer.addSubview(imageView)
        }

        overflowBadge.font = TFTypography.footnote.withSize(11)
        overflowBadge.textColor = .white
        overflowBadge.backgroundColor = TFColor.Brand.primary.withAlphaComponent(0.9)
        overflowBadge.layer.cornerRadius = 8
        overflowBadge.clipsToBounds = true
        overflowBadge.isHidden = true

        favoriteBadge.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.9)
        favoriteBadge.layer.cornerRadius = 11
        favoriteBadge.layer.borderWidth = 1
        favoriteBadge.layer.borderColor = TFColor.Border.subtle.cgColor
        favoriteBadge.isHidden = true

        favoriteIcon.tintColor = TFColor.Brand.primary
        favoriteIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)

        nameLabel.font = TFTypography.caption.withSize(15)
        nameLabel.textColor = TFColor.Text.primary
        nameLabel.numberOfLines = 1

        countLabel.font = TFTypography.footnote
        countLabel.textColor = TFColor.Text.secondary

        card.addSubview(collageContainer)
        collageContainer.addSubview(singleImageView)
        collageContainer.addSubview(gridContainer)
        gridImageViews[3].addSubview(overflowBadge)
        collageContainer.addSubview(favoriteBadge)
        favoriteBadge.addSubview(favoriteIcon)
        card.addSubview(nameLabel)
        card.addSubview(countLabel)

        collageContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(collageContainer.snp.width).multipliedBy(1.06)
        }

        singleImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        gridContainer.snp.makeConstraints { $0.edges.equalToSuperview() }
        overflowBadge.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        favoriteBadge.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(8)
            make.size.equalTo(22)
        }
        favoriteIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(collageContainer.snp.bottom).offset(9)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        countLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(3)
            make.leading.trailing.bottom.equalToSuperview().inset(10)
        }
    }

    func configure(with outfit: Outfit) {
        nameLabel.text = outfit.name
        countLabel.text = CoreStrings.Format.itemsCount(outfit.items.count)

        imageRequestTokens.forEach { TFRemoteImageLoader.shared.cancel($0) }
        imageRequestTokens = Array(repeating: nil, count: 4)
        imageRequestID = UUID()
        overflowBadge.isHidden = true
        favoriteBadge.isHidden = (outfit.note?.isEmpty ?? true)

        let items = outfit.items
        guard !items.isEmpty else {
            singleImageView.isHidden = false
            gridContainer.isHidden = true
            singleImageView.image = UIImage(named: "TFOutfitEditorialV2")
            singleImageView.tintColor = nil
            singleImageView.contentMode = .scaleAspectFill
            singleImageView.backgroundColor = TFColor.Surface.input
            return
        }

        if items.count == 1 {
            singleImageView.isHidden = false
            gridContainer.isHidden = true
            load(item: items[0], into: singleImageView, at: 0)
            return
        }

        singleImageView.isHidden = true
        gridContainer.isHidden = false
        layoutGrid(for: min(items.count, 4))

        if items.count > 4 {
            for index in 0..<3 {
                load(item: items[index], into: gridImageViews[index], at: index)
            }
            gridImageViews[3].image = nil
            gridImageViews[3].backgroundColor = TFColor.Brand.primary.withAlphaComponent(0.16)
            overflowBadge.text = "+\(items.count - 3)"
            overflowBadge.isHidden = false
        } else {
            for index in 0..<items.count {
                load(item: items[index], into: gridImageViews[index], at: index)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageRequestTokens.forEach { TFRemoteImageLoader.shared.cancel($0) }
        imageRequestTokens = Array(repeating: nil, count: 4)
        imageRequestID = UUID()
        singleImageView.image = nil
        gridImageViews.forEach { imageView in
            imageView.image = nil
            imageView.tintColor = nil
        }
        overflowBadge.isHidden = true
        favoriteBadge.isHidden = true
    }

    private func load(item: ClothingItem, into imageView: UIImageView, at index: Int) {
        if let data = item.imageData, let image = UIImage(data: data) {
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            imageView.tintColor = nil
            imageView.backgroundColor = TFColor.Surface.input
            return
        }

        imageView.image = placeholderImage(for: item.category)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = item.category.tintColor
        imageView.backgroundColor = item.category.tintColor.withAlphaComponent(0.12)

        let requestID = imageRequestID
        imageRequestTokens[index] = TFRemoteImageLoader.shared.load(from: item.imageURL) { [weak self, weak imageView] image in
            guard let self, self.imageRequestID == requestID, let image, let imageView else { return }
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            imageView.tintColor = nil
            imageView.backgroundColor = TFColor.Surface.input
        }
    }

    private func layoutGrid(for itemCount: Int) {
        gridImageViews.forEach { imageView in
            imageView.isHidden = false
            imageView.snp.removeConstraints()
        }

        let gap: CGFloat = 6
        let inset: CGFloat = 7
        switch itemCount {
        case 2:
            gridImageViews[0].snp.makeConstraints { make in
                make.top.bottom.leading.equalToSuperview().inset(inset)
                make.trailing.equalTo(gridContainer.snp.centerX).offset(-gap / 2)
            }
            gridImageViews[1].snp.makeConstraints { make in
                make.top.bottom.trailing.equalToSuperview().inset(inset)
                make.leading.equalTo(gridContainer.snp.centerX).offset(gap / 2)
            }
            gridImageViews[2].isHidden = true
            gridImageViews[3].isHidden = true
        case 3:
            gridImageViews[0].snp.makeConstraints { make in
                make.top.bottom.leading.equalToSuperview().inset(inset)
                make.width.equalToSuperview().multipliedBy(0.54)
            }
            gridImageViews[1].snp.makeConstraints { make in
                make.top.trailing.equalToSuperview().inset(inset)
                make.leading.equalTo(gridImageViews[0].snp.trailing).offset(gap)
                make.bottom.equalTo(gridContainer.snp.centerY).offset(-gap / 2)
            }
            gridImageViews[2].snp.makeConstraints { make in
                make.bottom.trailing.equalToSuperview().inset(inset)
                make.leading.equalTo(gridImageViews[0].snp.trailing).offset(gap)
                make.top.equalTo(gridContainer.snp.centerY).offset(gap / 2)
            }
            gridImageViews[3].isHidden = true
        default:
            gridImageViews[0].snp.makeConstraints { make in
                make.top.leading.equalToSuperview().inset(inset)
                make.trailing.equalTo(gridContainer.snp.centerX).offset(-gap / 2)
                make.bottom.equalTo(gridContainer.snp.centerY).offset(-gap / 2)
            }
            gridImageViews[1].snp.makeConstraints { make in
                make.top.trailing.equalToSuperview().inset(inset)
                make.leading.equalTo(gridContainer.snp.centerX).offset(gap / 2)
                make.bottom.equalTo(gridContainer.snp.centerY).offset(-gap / 2)
            }
            gridImageViews[2].snp.makeConstraints { make in
                make.bottom.leading.equalToSuperview().inset(inset)
                make.trailing.equalTo(gridContainer.snp.centerX).offset(-gap / 2)
                make.top.equalTo(gridContainer.snp.centerY).offset(gap / 2)
            }
            gridImageViews[3].snp.makeConstraints { make in
                make.bottom.trailing.equalToSuperview().inset(inset)
                make.leading.equalTo(gridContainer.snp.centerX).offset(gap / 2)
                make.top.equalTo(gridContainer.snp.centerY).offset(gap / 2)
            }
        }
    }

    private func placeholderImage(for category: ClothingCategory) -> UIImage? {
        switch category {
        case .tops: TFPictogram.top.image(pointSize: 32)
        case .bottoms: TFPictogram.bottom.image(pointSize: 32)
        case .outerwear: TFPictogram.outerwear.image(pointSize: 32)
        case .shoes: TFPictogram.shoes.image(pointSize: 32)
        case .accessories: TFPictogram.accessories.image(pointSize: 32)
        }
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
