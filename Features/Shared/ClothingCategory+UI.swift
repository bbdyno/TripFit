//
//  ClothingCategory+UI.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import UIKit

extension ClothingCategory {
    var pictogram: TFPictogram {
        switch self {
        case .tops: .top
        case .bottoms: .bottom
        case .outerwear: .outerwear
        case .shoes: .shoes
        case .accessories: .accessories
        }
    }

    var tintColor: UIColor {
        switch self {
        case .tops:
            TFColor.Category.tops
        case .bottoms:
            TFColor.Category.bottoms
        case .outerwear:
            TFColor.Category.outerwear
        case .shoes:
            TFColor.Category.shoes
        case .accessories:
            TFColor.Category.accessories
        }
    }

    var badgeBackgroundColor: UIColor {
        tintColor.withAlphaComponent(0.14)
    }
}
