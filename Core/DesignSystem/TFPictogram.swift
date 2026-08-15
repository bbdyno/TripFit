//
//  TFPictogram.swift
//  TripFit
//
//  Created by bbdyno on 8/10/26.
//

import UIKit

public enum TFPictogram: CaseIterable {
    case wardrobe
    case outfit
    case suitcase
    case together
    case top
    case bottom
    case outerwear
    case shoes
    case accessories
    case packing
    case calendar
    case destination

    public var image: UIImage? {
        image(pointSize: 34)
    }

    public func image(pointSize: CGFloat) -> UIImage? {
        if self == .bottom {
            return Self.pantsImage(pointSize: pointSize, color: tintColor)
        }

        return UIImage(
            systemName: symbolName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        )?.withTintColor(tintColor, renderingMode: .alwaysOriginal)
    }

    private var symbolName: String {
        switch self {
        case .wardrobe: "tshirt.fill"
        case .outfit: "sparkles"
        case .suitcase: "suitcase.rolling.fill"
        case .together: "person.2.fill"
        case .top: "tshirt.fill"
        case .bottom: "hanger"
        case .outerwear: "jacket.fill"
        case .shoes: "shoe.2.fill"
        case .accessories: "handbag.fill"
        case .packing: "checklist"
        case .calendar: "calendar"
        case .destination: "map.fill"
        }
    }

    private var tintColor: UIColor {
        switch self {
        case .wardrobe, .top, .packing:
            TFColor.Brand.primary
        case .outfit, .outerwear, .calendar:
            TFColor.Brand.accentPurple
        case .suitcase, .shoes, .destination:
            TFColor.Brand.accentSky
        case .together, .accessories:
            TFColor.Brand.accentMint
        case .bottom:
            TFColor.Text.secondary
        }
    }

    private static func pantsImage(pointSize: CGFloat, color: UIColor) -> UIImage {
        let scale = pointSize / 34
        return UIGraphicsImageRenderer(size: CGSize(width: pointSize, height: pointSize)).image { _ in
            let legs = UIBezierPath()
            legs.move(to: CGPoint(x: 8 * scale, y: 5 * scale))
            legs.addLine(to: CGPoint(x: 26 * scale, y: 5 * scale))
            legs.addLine(to: CGPoint(x: 24.2 * scale, y: 28.5 * scale))
            legs.addLine(to: CGPoint(x: 18.2 * scale, y: 28.5 * scale))
            legs.addLine(to: CGPoint(x: 17 * scale, y: 17.2 * scale))
            legs.addLine(to: CGPoint(x: 15.8 * scale, y: 28.5 * scale))
            legs.addLine(to: CGPoint(x: 9.8 * scale, y: 28.5 * scale))
            legs.close()
            color.setFill()
            legs.fill()

            let waistband = UIBezierPath(
                roundedRect: CGRect(x: 7.5 * scale, y: 4 * scale, width: 19 * scale, height: 4.5 * scale),
                cornerRadius: 1.5 * scale
            )
            waistband.fill()
        }.withRenderingMode(.alwaysOriginal)
    }
}
