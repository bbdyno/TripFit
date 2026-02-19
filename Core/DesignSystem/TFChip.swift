//
//  TFChip.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public final class TFChip: UIButton {
    public var isChipSelected: Bool = false {
        didSet { updateAppearance() }
    }

    private let chipTitle: String

    public init(title: String) {
        self.chipTitle = title
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        layer.cornerRadius = 14
        contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func updateAppearance() {
        if isChipSelected {
            backgroundColor = TFColor.pink
            setTitleColor(.white, for: .normal)
        } else {
            backgroundColor = TFColor.cardBackground
            setTitleColor(TFColor.textSecondary, for: .normal)
        }
    }
}
