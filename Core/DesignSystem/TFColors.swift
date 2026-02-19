import UIKit

public enum TFColor {
    public static let pink = UIColor(hex: 0xFF5FA2)
    public static let sky = UIColor(hex: 0x5AC8FF)
    public static let lavender = UIColor(hex: 0xB18CFF)
    public static let mint = UIColor(hex: 0x34D399)

    public static let cardBackground = UIColor.secondarySystemBackground
    public static let pageBackground = UIColor.systemBackground
    public static let textPrimary = UIColor.label
    public static let textSecondary = UIColor.secondaryLabel
}

public extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
