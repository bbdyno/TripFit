//
//  MoreSectionCardView.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Core
import SnapKit
import UIKit

final class MoreSectionCardView: UIView {
    private let titleLabel = UILabel()
    private let cardView = UIView()
    private let rowStack = UIStackView()
    private let footerLabel = UILabel()

    init(title: String, footer: String? = nil) {
        super.init(frame: .zero)
        setupLayout()
        titleLabel.text = title.uppercased()
        setFooterText(footer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setFooterText(_ text: String?) {
        footerLabel.text = text
        footerLabel.isHidden = (text == nil)
    }

    func setTitleColor(_ color: UIColor) {
        titleLabel.textColor = color
    }

    func setRows(_ rows: [MoreSettingsRowControl], separatorLeading: CGFloat = 52) {
        rowStack.arrangedSubviews.forEach {
            rowStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for (index, row) in rows.enumerated() {
            row.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(MoreMetrics.rowHeight)
            }
            rowStack.addArrangedSubview(row)

            guard index < rows.count - 1 else { continue }

            let separatorContainer = UIView()
            separatorContainer.isUserInteractionEnabled = false

            let separator = UIView()
            separator.backgroundColor = MorePalette.separator
            separatorContainer.addSubview(separator)
            separator.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(separatorLeading)
                make.trailing.top.bottom.equalToSuperview()
            }

            separatorContainer.snp.makeConstraints { make in
                make.height.equalTo(1 / UIScreen.main.scale)
            }
            rowStack.addArrangedSubview(separatorContainer)
        }
    }

    private func setupLayout() {
        titleLabel.font = TFTypography.caption.withSize(12)
        titleLabel.textColor = MorePalette.sectionTitle
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        cardView.backgroundColor = MorePalette.cardBackground
        cardView.layer.cornerRadius = MoreMetrics.cardCorner
        cardView.layer.borderWidth = 1 / UIScreen.main.scale
        cardView.layer.borderColor = MorePalette.cardBorder.cgColor
        cardView.clipsToBounds = true
        addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
        }

        rowStack.axis = .vertical
        rowStack.spacing = 0
        cardView.addSubview(rowStack)
        rowStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        footerLabel.numberOfLines = 0
        footerLabel.font = TFTypography.footnote.withSize(13)
        footerLabel.textColor = MorePalette.subtitle
        addSubview(footerLabel)
        footerLabel.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(2)
            make.bottom.equalToSuperview()
        }
    }
}
