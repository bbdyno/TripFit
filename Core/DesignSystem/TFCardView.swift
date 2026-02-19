//
//  TFCardView.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public final class TFCardView: UIView {
    public init(showShadow: Bool = true) {
        super.init(frame: .zero)
        backgroundColor = TFColor.cardBackground
        layer.cornerRadius = 16
        clipsToBounds = false

        if showShadow {
            layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
            layer.shadowOpacity = 1
            layer.shadowRadius = 12
            layer.shadowOffset = CGSize(width: 0, height: 6)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
