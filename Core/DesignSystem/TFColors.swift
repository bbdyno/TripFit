//
//  TFColors.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public enum TFColor {
    public enum Brand {
        public static let primary = UIColor(hex: 0xF24F91)
        public static let primaryLight = UIColor(hex: 0xFF8AB8)
        public static let primaryDark = UIColor(hex: 0xC93472)
        public static let ink = UIColor.dynamic(
            light: UIColor(hex: 0x20262B),
            dark: UIColor(hex: 0xF4F0F2)
        )
        public static let accentSky = UIColor(hex: 0x4AA8D8)
        public static let accentPurple = UIColor(hex: 0x8E78D6)
        public static let accentMint = UIColor(hex: 0x2EAE83)
        public static let accentOrange = UIColor(hex: 0xE9853F)
    }

    public enum Surface {
        public static let canvas = UIColor.dynamic(
            light: UIColor(hex: 0xF7F5F2),
            dark: UIColor(hex: 0x0F171D)
        )
        public static let card = UIColor.dynamic(
            light: UIColor(hex: 0xFFFEFC),
            dark: UIColor(hex: 0x172129)
        )
        public static let elevated = UIColor.dynamic(
            light: .white,
            dark: UIColor(hex: 0x1C2730)
        )
        public static let input = UIColor.dynamic(
            light: UIColor(hex: 0xEEEAE6),
            dark: UIColor(hex: 0x222E37)
        )
        public static let chip = UIColor.dynamic(
            light: UIColor(hex: 0xF0ECE8),
            dark: UIColor(hex: 0x222E37)
        )
        public static let hero = UIColor.dynamic(
            light: UIColor(hex: 0x242B31),
            dark: UIColor(hex: 0x202C35)
        )
        public static let highlight = UIColor.dynamic(
            light: UIColor(hex: 0xFFE1EC),
            dark: UIColor(hex: 0x38202C)
        )
    }

    public enum Text {
        public static let primary = UIColor.dynamic(
            light: UIColor(hex: 0x20262B),
            dark: UIColor(hex: 0xF6F2F4)
        )
        public static let secondary = UIColor.dynamic(
            light: UIColor(hex: 0x62686D),
            dark: UIColor(hex: 0xB4BEC5)
        )
        public static let tertiary = UIColor.dynamic(
            light: UIColor(hex: 0x8E9498),
            dark: UIColor(hex: 0x81909A)
        )
        public static let inverse = UIColor.white
    }

    public enum Border {
        public static let subtle = UIColor.dynamic(
            light: UIColor(hex: 0xE8E3DE),
            dark: UIColor(hex: 0x2B3943)
        )
        public static let strong = UIColor.dynamic(
            light: UIColor(hex: 0xD7D0CA),
            dark: UIColor(hex: 0x3A4A56)
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
