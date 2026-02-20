//
//  MoreDesignTokens.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Core
import UIKit

enum MorePalette {
    static let pageBackground = UIColor.dynamic(
        light: UIColor(hex: 0xF2F2F7),
        dark: UIColor(hex: 0x101922)
    )
    static let cardBackground = UIColor.dynamic(
        light: .white,
        dark: UIColor(hex: 0x1C2127)
    )
    static let cardBorder = UIColor.dynamic(
        light: UIColor(hex: 0xE2E7EE),
        dark: UIColor(hex: 0x283039)
    )
    static let sectionTitle = UIColor.dynamic(
        light: UIColor(hex: 0x7C8EA7),
        dark: UIColor(hex: 0x6D7D90)
    )
    static let subtitle = UIColor.dynamic(
        light: UIColor(hex: 0x8EA0B7),
        dark: UIColor(hex: 0x8A97A8)
    )
    static let chevron = UIColor.dynamic(
        light: UIColor(hex: 0xBFCCDC),
        dark: UIColor(hex: 0x5B6878)
    )
    static let separator = UIColor.dynamic(
        light: UIColor(hex: 0xE7ECF2),
        dark: UIColor(hex: 0x2E3743)
    )
    static let rowHighlight = UIColor.dynamic(
        light: UIColor(hex: 0xF6F9FD),
        dark: UIColor(hex: 0x232B35)
    )

    static let blue = UIColor(hex: 0x2B8CEE)
    static let sky = UIColor(hex: 0x5BC4FF)
    static let cyan = UIColor(hex: 0x2CB8C7)
    static let mint = UIColor(hex: 0x2BB673)
    static let orange = UIColor(hex: 0xF59B3D)
    static let purple = UIColor(hex: 0xA66BFF)
    static let red = UIColor(hex: 0xF45D5D)
    static let yellow = UIColor(hex: 0xF2B742)
    static let teal = UIColor(hex: 0x34B7A8)
    static let slate = UIColor(hex: 0x7589A1)

    static let pink = TFColor.Brand.primary
}

enum MoreMetrics {
    static let horizontalInset: CGFloat = 16
    static let cardCorner: CGFloat = 14
    static let iconCorner: CGFloat = 8
    static let rowHeight: CGFloat = 50
}
