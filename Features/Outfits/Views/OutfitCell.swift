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

    private let card = TFCardView()
    private let nameLabel = UILabel()
    private let countLabel = UILabel()
    private let noteLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.textColor = TFColor.textPrimary

        countLabel.font = .preferredFont(forTextStyle: .caption1)
        countLabel.textColor = TFColor.sky

        noteLabel.font = .preferredFont(forTextStyle: .caption1)
        noteLabel.textColor = TFColor.textSecondary
        noteLabel.numberOfLines = 1

        let vStack = UIStackView(arrangedSubviews: [nameLabel, countLabel, noteLabel])
        vStack.axis = .vertical
        vStack.spacing = 4
        card.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    func configure(with outfit: Outfit) {
        nameLabel.text = outfit.name
        countLabel.text = "\(outfit.items.count) items"
        noteLabel.text = outfit.note
        noteLabel.isHidden = outfit.note?.isEmpty != false
    }
}
