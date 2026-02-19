//
//  ClothingCategory.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Foundation

public enum ClothingCategory: String, CaseIterable, Codable {
    case tops
    case bottoms
    case outerwear
    case shoes
    case accessories

    public var displayName: String {
        switch self {
        case .tops: "Tops"
        case .bottoms: "Bottoms"
        case .outerwear: "Outerwear"
        case .shoes: "Shoes"
        case .accessories: "Accessories"
        }
    }

    public var icon: String {
        switch self {
        case .tops: "tshirt"
        case .bottoms: "figure.walk"
        case .outerwear: "cloud.rain"
        case .shoes: "shoeprints.fill"
        case .accessories: "eyeglasses"
        }
    }
}
