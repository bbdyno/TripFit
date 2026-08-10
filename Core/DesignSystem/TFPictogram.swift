//
//  TFPictogram.swift
//  TripFit
//
//  Created by bbdyno on 8/10/26.
//

import UIKit

public enum TFPictogram: String, CaseIterable {
    case wardrobe = "TFIconWardrobe"
    case outfit = "TFIconOutfit"
    case suitcase = "TFIconSuitcase"
    case together = "TFIconTogether"
    case top = "TFIconTop"
    case bottom = "TFIconBottom"
    case outerwear = "TFIconOuterwear"
    case shoes = "TFIconShoes"
    case accessories = "TFIconAccessories"
    case packing = "TFIconPacking"
    case calendar = "TFIconCalendar"
    case destination = "TFIconDestination"

    public var image: UIImage? {
        UIImage(named: rawValue, in: .main, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal)
    }

    public func image(pointSize: CGFloat) -> UIImage? {
        guard let image else { return nil }
        let size = CGSize(width: pointSize, height: pointSize)
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }.withRenderingMode(.alwaysOriginal)
    }
}

public enum TFHeroPictogram: String {
    case wardrobe = "TFHeroWardrobe"
    case outfit = "TFHeroOutfit"
    case trip = "TFHeroTrip"
    case together = "TFHeroTogether"

    public var image: UIImage? {
        UIImage(named: rawValue, in: .main, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal)
    }
}
