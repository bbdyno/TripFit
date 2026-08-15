//
//  TFColors.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public enum TFColor {
    public enum Brand {
        public static let primary = UIColor(hex: 0xE46F51)
        public static let primaryLight = UIColor(hex: 0xF1A184)
        public static let primaryDark = UIColor(hex: 0xB84C37)
        public static let ink = UIColor.dynamic(
            light: UIColor(hex: 0x23312D),
            dark: UIColor(hex: 0xF5F0E8)
        )
        public static let accentSky = UIColor(hex: 0x6D9FB6)
        public static let accentPurple = UIColor(hex: 0x8C83A8)
        public static let accentMint = UIColor(hex: 0x789A83)
        public static let accentOrange = UIColor(hex: 0xD69C4B)
    }

    public enum Surface {
        public static let canvas = UIColor.dynamic(
            light: UIColor(hex: 0xF7F3EC),
            dark: UIColor(hex: 0x111917)
        )
        public static let card = UIColor.dynamic(
            light: UIColor(hex: 0xFFFCF7),
            dark: UIColor(hex: 0x19231F)
        )
        public static let elevated = UIColor.dynamic(
            light: UIColor(hex: 0xFFFEFB),
            dark: UIColor(hex: 0x1E2A25)
        )
        public static let input = UIColor.dynamic(
            light: UIColor(hex: 0xEFE8DE),
            dark: UIColor(hex: 0x26322D)
        )
        public static let chip = UIColor.dynamic(
            light: UIColor(hex: 0xF1EBE2),
            dark: UIColor(hex: 0x26322D)
        )
        public static let hero = UIColor.dynamic(
            light: UIColor(hex: 0x293732),
            dark: UIColor(hex: 0x26342F)
        )
        public static let highlight = UIColor.dynamic(
            light: UIColor(hex: 0xFBE2D8),
            dark: UIColor(hex: 0x3C2922)
        )
    }

    public enum Text {
        public static let primary = UIColor.dynamic(
            light: UIColor(hex: 0x23312D),
            dark: UIColor(hex: 0xF7F1E8)
        )
        public static let secondary = UIColor.dynamic(
            light: UIColor(hex: 0x66716C),
            dark: UIColor(hex: 0xB7C1BB)
        )
        public static let tertiary = UIColor.dynamic(
            light: UIColor(hex: 0x909792),
            dark: UIColor(hex: 0x87958E)
        )
        public static let inverse = UIColor.white
    }

    public enum Border {
        public static let subtle = UIColor.dynamic(
            light: UIColor(hex: 0xE6DED3),
            dark: UIColor(hex: 0x314039)
        )
        public static let strong = UIColor.dynamic(
            light: UIColor(hex: 0xD5CABC),
            dark: UIColor(hex: 0x42534B)
        )
    }

    public enum Category {
        public static let tops = UIColor(hex: 0xD97962)
        public static let bottoms = UIColor(hex: 0x6D9FB6)
        public static let outerwear = UIColor(hex: 0x7B8496)
        public static let shoes = UIColor(hex: 0xC99345)
        public static let accessories = UIColor(hex: 0x789A83)
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
