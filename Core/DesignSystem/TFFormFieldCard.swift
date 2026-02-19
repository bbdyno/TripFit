//
//  TFFormFieldCard.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import SnapKit
import UIKit

public final class TFFormFieldCard: UIView {
    public let titleLabel = UILabel()
    public let contentContainer = UIView()

    public init(title: String, content: UIView, style: TFCardView.Style = .flat) {
        super.init(frame: .zero)

        let card = TFCardView(style: style)
        addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        titleLabel.text = title
        titleLabel.font = TFTypography.caption
        titleLabel.textColor = TFColor.Text.secondary

        card.addSubview(titleLabel)
        card.addSubview(contentContainer)
        contentContainer.addSubview(content)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(TFSpacing.md)
        }

        contentContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(TFSpacing.xs)
            make.leading.trailing.bottom.equalToSuperview().inset(TFSpacing.md)
        }

        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.greaterThanOrEqualTo(36)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
