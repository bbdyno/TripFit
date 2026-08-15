//
//  TFColors.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public enum TFColor {
    public enum Brand {
        public static let primary = UIColor(hex: 0x586FEA)
        public static let primaryLight = UIColor(hex: 0x8E9CF4)
        public static let primaryDark = UIColor(hex: 0x3D50BD)
        public static let ink = UIColor.dynamic(
            light: UIColor(hex: 0x1C2440),
            dark: UIColor(hex: 0xF2F4FF)
        )
        public static let accentSky = UIColor(hex: 0x4C9FE6)
        public static let accentPurple = UIColor(hex: 0x7B68D8)
        public static let accentMint = UIColor(hex: 0x25A3A0)
        public static let accentOrange = UIColor(hex: 0x36AEC0)
    }

    public enum Surface {
        public static let canvas = UIColor.dynamic(
            light: UIColor(hex: 0xF4F6FA),
            dark: UIColor(hex: 0x101421)
        )
        public static let card = UIColor.dynamic(
            light: UIColor(hex: 0xFFFFFF),
            dark: UIColor(hex: 0x181D2B)
        )
        public static let elevated = UIColor.dynamic(
            light: UIColor(hex: 0xFFFFFF),
            dark: UIColor(hex: 0x1D2333)
        )
        public static let input = UIColor.dynamic(
            light: UIColor(hex: 0xECEFF5),
            dark: UIColor(hex: 0x252C3E)
        )
        public static let chip = UIColor.dynamic(
            light: UIColor(hex: 0xEEF1F7),
            dark: UIColor(hex: 0x252C3E)
        )
        public static let hero = UIColor.dynamic(
            light: UIColor(hex: 0x202B5C),
            dark: UIColor(hex: 0x263161)
        )
        public static let highlight = UIColor.dynamic(
            light: UIColor(hex: 0xE8ECFF),
            dark: UIColor(hex: 0x2B3154)
        )
    }

    public enum Text {
        public static let primary = UIColor.dynamic(
            light: UIColor(hex: 0x1C2440),
            dark: UIColor(hex: 0xF3F5FF)
        )
        public static let secondary = UIColor.dynamic(
            light: UIColor(hex: 0x626B80),
            dark: UIColor(hex: 0xB7BED0)
        )
        public static let tertiary = UIColor.dynamic(
            light: UIColor(hex: 0x929AAD),
            dark: UIColor(hex: 0x8992A8)
        )
        public static let inverse = UIColor.white
    }

    public enum Border {
        public static let subtle = UIColor.dynamic(
            light: UIColor(hex: 0xE1E5EF),
            dark: UIColor(hex: 0x30384D)
        )
        public static let strong = UIColor.dynamic(
            light: UIColor(hex: 0xC9D0E1),
            dark: UIColor(hex: 0x414B64)
        )
    }

    public enum Category {
        public static let tops = UIColor(hex: 0x586FEA)
        public static let bottoms = UIColor(hex: 0x4C9FE6)
        public static let outerwear = UIColor(hex: 0x7B68D8)
        public static let shoes = UIColor(hex: 0x25A3A0)
        public static let accessories = UIColor(hex: 0x64708D)
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
