//
//  TFColors.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public enum TFColor {
    public enum Brand {
        public static let primary = UIColor(hex: 0xFF5CA3)
        public static let primaryLight = UIColor(hex: 0xFF8BC0)
        public static let primaryDark = UIColor(hex: 0xD94385)
        public static let accentSky = UIColor(hex: 0x58C4FF)
        public static let accentPurple = UIColor(hex: 0xB28DFF)
        public static let accentMint = UIColor(hex: 0x34D399)
        public static let accentOrange = UIColor(hex: 0xFB923C)
    }

    public enum Surface {
        public static let canvas = UIColor.dynamic(
            light: UIColor(hex: 0xF8F5F7),
            dark: UIColor(hex: 0x230F18)
        )
        public static let card = UIColor.dynamic(
            light: .white,
            dark: UIColor(hex: 0x2D1622)
        )
        public static let elevated = UIColor.dynamic(
            light: .white,
            dark: UIColor(hex: 0x351A24)
        )
        public static let input = UIColor.dynamic(
            light: UIColor(hex: 0xF0EEF2),
            dark: UIColor(hex: 0x3A1C29)
        )
        public static let chip = UIColor.dynamic(
            light: UIColor(hex: 0xF8F4F6),
            dark: UIColor(hex: 0x351A24)
        )
    }

    public enum Text {
        public static let primary = UIColor.dynamic(
            light: UIColor(hex: 0x1E1E1E),
            dark: UIColor(hex: 0xF9F5F7)
        )
        public static let secondary = UIColor.dynamic(
            light: UIColor(hex: 0x8D5E72),
            dark: UIColor(hex: 0xCBAFBC)
        )
        public static let tertiary = UIColor.dynamic(
            light: UIColor(hex: 0xB794A7),
            dark: UIColor(hex: 0x9D7E8B)
        )
        public static let inverse = UIColor.white
    }

    public enum Border {
        public static let subtle = UIColor.dynamic(
            light: UIColor(hex: 0xF1E8ED),
            dark: UIColor(hex: 0x4B2C38)
        )
        public static let strong = UIColor.dynamic(
            light: UIColor(hex: 0xE5D4DD),
            dark: UIColor(hex: 0x5B3545)
        )
    }

    public enum Category {
        public static let tops = UIColor(hex: 0xF06292)
        public static let bottoms = UIColor(hex: 0x38BDF8)
        public static let outerwear = UIColor(hex: 0x8B5CF6)
        public static let shoes = UIColor(hex: 0xF59E0B)
        public static let accessories = UIColor(hex: 0x14B8A6)
    }

    // Legacy aliases
    public static let pink = Brand.primary
    public static let sky = Brand.accentSky
    public static let lavender = Brand.accentPurple
    public static let mint = Brand.accentMint

    public static let cardBackground = Surface.card
    public static let pageBackground = Surface.canvas
    public static let textPrimary = Text.primary
    public static let textSecondary = Text.secondary
}

public extension UIColor {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        }
    }

    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
